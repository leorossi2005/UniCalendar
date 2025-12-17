//
//  CalendarViewModel.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 22/10/25.
//

import Foundation
#if canImport(Observation)
import Observation
#endif

struct YearStructure: Sendable {
    let year: Int
    let days: [String]
    let dates: [Date]
}

@MainActor
#if canImport(Observation)
@Observable
#endif
public class CalendarViewModel {
    public var lessons: [Lesson] = []
    public var days: [[Lesson]] = []
    public var daysString: [String] = []
    
    public var loading: Bool = true
    public var checkingUpdates: Bool = false
    public var showUpdateAlert: Bool = false
    public var errorMessage: String? = nil
    public var noLessonsFound: Bool = false
    
    private var pendingNewLessons: [Lesson]? = nil
    private var currentPalette: [String] = []
    private var cachedStructure: YearStructure? = nil
    
    private let service = NetworkService()
    private let cacheKey = "calendar_cache.json"
    
    public init() {}
    
    public func loadFromCache(selYear: String, matricola: String) async {
        if let cacheResponse = await CacheManager.shared.load(fileName: cacheKey, type: ResponseAPI.self) {
            self.lessons = cacheResponse.celle
            self.currentPalette = cacheResponse.colori
            
            await self.organizeData(selectedYear: selYear, matricola: matricola)
            
            self.loading = false
            self.noLessonsFound = self.lessons.isEmpty
        }
    }
    
    public func loadNetworkFromCache() async {
        if let cacheResponse = await CacheManager.shared.load(fileName: "network_cache.json", type: NetworkCacheData.self) {
            NetworkCache.shared.update(from: cacheResponse)
        }
    }
    
    public func loadLessons(corso: String, anno: String, selYear: String, matricola: String, updating: Bool) async {
        guard corso != "0" else { return }
        
        if !updating && lessons.isEmpty {
            await loadFromCache(selYear: selYear, matricola: matricola)
        }
        
        if !updating && !lessons.isEmpty {
            self.checkingUpdates = true
        } else {
            self.loading = true
        }
        self.errorMessage = nil
        
        do {
            let response = try await service.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            self.currentPalette = response.colori
            
            var fetchedLessons = response.celle
            if !fetchedLessons.isEmpty {
                fetchedLessons = CalendarLogic.applyColors(to: fetchedLessons, palette: self.currentPalette)
            }
            
            try await handleNewData(fetchedLessons, selectedYear: selYear, matricola: matricola, update: updating)
        } catch {
            self.handleError(error)
        }
        
        self.loading = false
        self.checkingUpdates = false
    }
    
    public func confirmUpdate(selectedYear: String, matricola: String) {
        Task {
            guard let newLessons = pendingNewLessons else { return }
            
            try? await handleNewData(newLessons, selectedYear: selectedYear, matricola: matricola, update: true)
            
            noLessonsFound = false
            pendingNewLessons = nil
            showUpdateAlert = false
        }
    }
    
    public func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        showUpdateAlert = false
    }
    
    public func organizeData(selectedYear: String, matricola: String) async {
        guard let annoInt = Int(selectedYear) else { return }
        
        let lessonsSnapshot = self.lessons
        let currentCache = self.cachedStructure
        
        let (newStructure, organizedDays) = await CalendarLogic.processCalendarData(
            year: annoInt,
            matricola: matricola,
            lessons: lessonsSnapshot,
            cachedStructure: currentCache
        )
        
        if self.cachedStructure?.year != annoInt {
            self.cachedStructure = newStructure
        }
        self.daysString = newStructure.days
        self.days = organizedDays
    }
    
    private func handleNewData(_ fetchedLessons: [Lesson], selectedYear: String, matricola: String, update: Bool) async throws {
        if fetchedLessons.isEmpty {
            self.noLessonsFound = true
            await updateStateAndCache([], selectedYear: selectedYear, matricola: matricola)
            return
        }
        
        self.noLessonsFound = false
        
        if self.lessons.isEmpty || update {
            await updateStateAndCache(fetchedLessons, selectedYear: selectedYear, matricola: matricola)
            return
        }
        
        if self.lessons != fetchedLessons {
            self.pendingNewLessons = fetchedLessons
            self.showUpdateAlert = true
        }
    }
    
    private func updateStateAndCache(_ newLessons: [Lesson], selectedYear: String, matricola: String) async {
        self.lessons = newLessons
        
        let cacheObject = ResponseAPI(celle: newLessons, colori: self.currentPalette)
        await CacheManager.shared.save(cacheObject, fileName: cacheKey)
        
        await self.organizeData(selectedYear: selectedYear, matricola: matricola)
    }
    
    private func handleError(_ error: Error) {
        if let netError = error as? NetworkError {
            self.errorMessage = netError.localizedDescription
        } else {
            self.errorMessage = "Errore generico: \(error.localizedDescription)"
        }
        print("Debug Error: \(error)")
    }
}

struct CalendarLogic {
    static func processCalendarData(
        year: Int,
        matricola: String,
        lessons: [Lesson],
        cachedStructure: YearStructure?
    ) async -> (YearStructure, [[Lesson]]) {
        return await Task.detached(priority: .userInitiated) {
            let structure: YearStructure
            if let cache = cachedStructure, cache.year == year {
                structure = cache
            } else {
                structure = generateYearStructure(year: year)
            }
            
            let lessonsByDate = Dictionary(grouping: lessons, by: { $0.data })
            let userFilter: Lesson.GruppoMatricola = (matricola == "pari") ? .pari : .dispari
            
            var organized: [[Lesson]] = []
            organized.reserveCapacity(structure.days.count)
            
            for dayString in structure.days {
                guard let dailyLessons = lessonsByDate[dayString] else {
                    organized.append([])
                    continue
                }
                
                let filtered = dailyLessons.filter { lesson in
                    lesson.tipo != "chiusura_type" &&
                    (lesson.gruppo == .tutti || lesson.gruppo == userFilter)
                }.sorted(by: { $0.orario < $1.orario })
                
                if filtered.isEmpty {
                    organized.append([])
                } else {
                    organized.append(insertPauses(in: filtered, date: dayString))
                }
            }
            
            return (structure, organized)
        }.value
    }
    
    static func generateYearStructure(year: Int) -> YearStructure {
        let startDate = Date(year: year, month: 10, day: 1)
        let endDate = Date(year: year + 1, month: 9, day: 30)
        
        var dateStrings: [String] = []
        var dateObj: [Date] = []
        dateStrings.reserveCapacity(366)
        dateObj.reserveCapacity(366)
        
        var currentDate = startDate
        while currentDate <= endDate {
            dateStrings.append(currentDate.formatUnivrStyle())
            dateObj.append(currentDate)
            currentDate = currentDate.add(type: .day, value: 1)
        }
        
        return YearStructure(year: year, days: dateStrings, dates: dateObj)
    }
    
    private static func insertPauses(in lessons: [Lesson], date: String) -> [Lesson] {
        var processedDay = lessons
        var offset = 0
        
        for i in 0..<lessons.count - 1 {
            let currentEnd = lessons[i].orario.suffix(5)
            let NextStart = lessons[i + 1].orario.prefix(5)
            
            if currentEnd < NextStart {
                let pauseLesson = Lesson(
                    data: date,
                    orario: "\(currentEnd)-\(NextStart)",
                    tipo: "pause"
                )
                
                processedDay.insert(pauseLesson, at: i + 1 + offset)
                offset += 1
            }
        }
        return processedDay
    }
    
    static func applyColors(to lessons: [Lesson], palette: [String]) -> [Lesson] {
        var processedLessons = lessons
        var colorMap: [String: String] = [:]
        var paletteIndex = 0
        
        for lesson in processedLessons where hasCustomColor(lesson) {
            colorMap[lesson.codiceInsegnamento] = lesson.color
        }
        
        for i in processedLessons.indices {
            if processedLessons[i].annullato {
                processedLessons[i].color = "#FFFFFF"
                continue
            }
            
            if processedLessons[i].tipo == "chiusura_type" {
                processedLessons[i].color = "#BDF2F2"
                continue
            }
            
            if !processedLessons[i].colorIndex.isEmpty {
                print("Trovato uno")
                continue
            }
            
            let code = lessons[i].codiceInsegnamento
            
            if let existingColor = colorMap[code] {
                processedLessons[i].color = existingColor
            } else {
                let newColor = (paletteIndex < palette.count) ? palette[paletteIndex] : "#CCCCCC"
                colorMap[code] = newColor
                processedLessons[i].color = newColor
                
                paletteIndex += 1
            }
        }
        return processedLessons
    }
    
    private static func hasCustomColor(_ lesson: Lesson) -> Bool {
        return !lesson.color.isEmpty && lesson.color != "CCCCCC" && lesson.color != "A0A0A0"
    }
}
