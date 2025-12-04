//
//  CalendarViewModel.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 22/10/25.
//

import Foundation

private struct YearStructure: Sendable {
    let year: Int
    let days: [String]
    let dates: [Date]
}

@Observable
public class CalendarViewModel {
    public var lessons: [Lesson] = []
    public var days: [[Lesson]] = []
    public var daysString: [String] = []
    
    public var loading: Bool = true
    public var checkingUpdates: Bool = false
    public var showUpdateAlert: Bool = false
    var errorMessage: String? = nil
    public var noLessonsFound: Bool = false
    
    private var pendingNewLessons: [Lesson]? = nil
    private var currentPalette: [String] = []
    private let cacheKey = "calendar_cache.json"
    
    private var cachedStructure: YearStructure? = nil
    
    private let networkService: NetworkServiceProtocol
    
    public init(service: NetworkServiceProtocol = NetworkService()) {
        self.networkService = service
    }
    
    public func loadFromCache(selYear: String, matricola: String) {
        if let cacheResponse = CacheManager.shared.load(fileName: cacheKey, type: ResponseAPI.self) {
            self.lessons = cacheResponse.celle
            self.organizeData(selectedYear: selYear, matricola: matricola)
            
            DispatchQueue.main.async {
                self.loading = false
                if self.lessons.isEmpty {
                    self.noLessonsFound = true
                }
            }
        }
    }
    
    public func loadNetworkFromCache() {
        if let cacheResponse = NetworkCacheManager.shared.load(fileName: "network_cache.json", type: NetworkCache.self) {
            NetworkCache.shared.years = cacheResponse.years
            NetworkCache.shared.courses = cacheResponse.courses
            NetworkCache.shared.academicYears = cacheResponse.academicYears
        }
    }
    
    @MainActor
    public func loadLessons(corso: String, anno: String, selYear: String, matricola: String) async {
        guard corso != "0" else { return }
        
        if !lessons.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.checkingUpdates = true
            }
        }
        self.errorMessage = nil
        
        do {
            let response = try await networkService.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            
            var fetchedLessons = response.celle
            self.currentPalette = response.colori
            
            if fetchedLessons.isEmpty {
                noLessonsFound = true
                self.applyNewData(fetchedLessons, palette: self.currentPalette, selectedYear: selYear, matricola: matricola)
            } else {
                assignColors(to: &fetchedLessons, palette: self.currentPalette)
                
                noLessonsFound = false
                if self.lessons.isEmpty {
                    self.applyNewData(fetchedLessons, palette: self.currentPalette, selectedYear: selYear, matricola: matricola)
                } else {
                    if self.lessons != fetchedLessons {
                        self.pendingNewLessons = fetchedLessons
                        self.showUpdateAlert = true
                    }
                }
            }
        } catch {
            if let netError = error as? NetworkError {
                self.errorMessage = netError.localizedDescription
            } else {
                self.errorMessage = String(localized: "Errore Generico: \(error.localizedDescription)")
            }
            print("Debug Error: \(error)")
        }
        
        if self.loading {
            self.loading = false
        }
        self.checkingUpdates = false
    }
    
    public func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        showUpdateAlert = false
    }
    
    public func confirmUpdate(selectedYear: String, matricola: String) {
        guard let newLessons = pendingNewLessons else { return }
        
        applyNewData(newLessons, palette: self.currentPalette, selectedYear: selectedYear, matricola: matricola)
        
        noLessonsFound = false
        pendingNewLessons = nil
        showUpdateAlert = false
    }
    
    private func applyNewData(_ newLessons: [Lesson], palette: [String], selectedYear: String, matricola: String) {
        self.lessons = newLessons
        self.organizeData(selectedYear: selectedYear, matricola: matricola)
        
        let cacheObject = ResponseAPI(celle: newLessons, colori: palette)
        CacheManager.shared.save(cacheObject, fileName: cacheKey)
    }
    
    private func assignColors(to lessons: inout [Lesson], palette: [String]) {
        var colorMap: [String: String] = [:]
        var paletteIndex = 0
        
        for lesson in lessons where !lesson.color.isEmpty && lesson.color != "CCCCCC" && lesson.color != "A0A0A0" {
            colorMap[lesson.codiceInsegnamento] = lesson.color
        }
        
        for i in lessons.indices {
            let code = lessons[i].codiceInsegnamento
            
            if lessons[i].annullato == "1" {
                lessons[i].color = "#FFFFFF"
            } else if lessons[i].tipo == "chiusura_type" {
                lessons[i].color = "#BDF2F2"
            } else if !lessons[i].colorIndex.isEmpty {
               print("Trovato uno")
            } else if let existingColor = colorMap[code] {
                lessons[i].color = existingColor
            } else {
                if let existingColor = colorMap[code] {
                    lessons[i].color = existingColor
                } else {
                    let newColor = (paletteIndex < palette.count) ? palette[paletteIndex] : "#CCCCCC"
                    colorMap[code] = newColor
                    lessons[i].color = newColor
                    
                    paletteIndex += 1
                }
            }
        }
    }
    
    public func organizeData(selectedYear: String, matricola: String) {
        guard let annoInt = Int(selectedYear) else { return }
        
        let lessonsSnapshot = self.lessons
        let currentCache = self.cachedStructure
        
        Task.detached(priority: .userInitiated) {
            let yearStructure: YearStructure
            
            if let cache = currentCache, cache.year == annoInt {
                yearStructure = cache
            } else {
                yearStructure = CalendarViewModel.generateYearStructure(year: annoInt)
            }
            
            let resultDays = CalendarViewModel.mapLessons(
                lessons: lessonsSnapshot,
                structure: yearStructure,
                matricola: matricola
            )
            
            await MainActor.run {
                if self.cachedStructure?.year != annoInt {
                    self.cachedStructure = yearStructure
                }
                
                self.daysString = yearStructure.days
                self.days = resultDays
                self.loading = false
            }
        }
    }
    
    nonisolated private static func generateYearStructure(year: Int) -> YearStructure {
        var dateStringhe: [String] = []
        var dateObj: [Date] = []
        
        dateStringhe.reserveCapacity(366)
        dateObj.reserveCapacity(366)
        
        let endYear = year + 1
        
        var currentMonth = 10
        var currentYear = year
        var currentDay = 1
        
        while !(currentYear == endYear && currentMonth == 10) {
            let dayStr = currentDay < 10 ? "0\(currentDay)" : "\(currentDay)"
            let monthStr = currentMonth < 10 ? "0\(currentMonth)" : "\(currentMonth)"
            let datekey = "\(dayStr)-\(monthStr)-\(currentYear)"
            
            dateStringhe.append(datekey)
            dateObj.append(Date(year: currentYear, month: currentMonth, day: currentDay))
            
            currentDay += 1
            
            let daysInMonth = Calendars.calendar.range(of: .day, in: .month, for: dateObj.last!)!.count
            
            if currentDay > daysInMonth {
                currentDay = 1
                currentMonth += 1
                if currentMonth > 12 {
                    currentMonth = 1
                    currentYear += 1
                }
            }
        }
        
        return YearStructure(year: year, days: dateStringhe, dates: dateObj)
    }
    
    nonisolated private static func mapLessons(lessons: [Lesson], structure: YearStructure, matricola: String) -> [[Lesson]] {
        let lessonsByDate = Dictionary(grouping: lessons, by: { $0.data })
        
        var newDaysStructure: [[Lesson]] = []
        newDaysStructure.reserveCapacity(structure.days.count)
        
        let filtroUtente: Lesson.GruppoMatricola = (matricola == "pari") ? .pari : .dispari
        
        for dayString in structure.days {
            guard let lessonsForDay = lessonsByDate[dayString] else {
                newDaysStructure.append([])
                continue
            }
            
            var filtered = lessonsForDay.filter { lesson in
                if lesson.tipo == "chiusura_type" { return false }
                
                if lesson.gruppo == .tutti { return true }
                
                return lesson.gruppo == filtroUtente
            }
            
            if filtered.isEmpty {
                newDaysStructure.append([])
                continue
            }
            
            if filtered.count > 1 {
                filtered.sort(by: { $0.orario < $1.orario })
            }
            
            var processedDay = filtered
            var added = 0
            
            for i in 0..<filtered.count - 1 {
                let endString = filtered[i].orario.suffix(5)
                let startString = filtered[i + 1].orario.prefix(5)
                
                if endString < startString {
                    processedDay.insert(Lesson(
                        data: dayString,
                        orario: "\(endString)-\(startString)",
                        tipo: "pause"
                    ), at: i + added + 1)
                    added += 1
                }
            }
            newDaysStructure.append(processedDay)
        }
        
        return newDaysStructure
    }
}
