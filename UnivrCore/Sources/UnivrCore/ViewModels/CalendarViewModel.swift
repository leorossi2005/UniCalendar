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
    public var lessons: [String: [Lesson]] = [:]
    public var days: [[Lesson]] = []
    public var daysString: [String] = []
    
    public var loading: Bool = true
    public var checkingUpdates: Bool = false
    public var showUpdateAlert: Bool = false
    public var errorMessage: String? = nil
    public var noLessonsFound: Bool = false
    public var isOffline: Bool = false
    
    private var pendingNewLessons: [String: [Lesson]]? = nil
    private var cachedStructure: YearStructure? = nil
    
    private let service = NetworkService()
    private let cacheKey = "calendar_cache.json"
    
    public init() {}
    
    public func loadFromCache(selYear: String, matricola: String) async {
        if let cacheResponse = await CacheManager.shared.load(fileName: cacheKey, type: [String: [Lesson]].self) {
            self.lessons = cacheResponse
            
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
        isOffline = false
        
        if !updating && lessons.isEmpty {
            await loadFromCache(selYear: selYear, matricola: matricola)
        }
        
        if !updating && !lessons.isEmpty {
            self.checkingUpdates = true
        } else {
            await clearAll()
            self.loading = true
        }
        self.errorMessage = nil
        
        do {
            let response = try await service.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            
            try await handleNewData(response, selectedYear: selYear, matricola: matricola, update: updating)
            
            self.loading = false
        } catch {
            self.handleError(error)
        }
        
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
        
        let activeActivities = organizedDays.indices.reduce(into: [String: Double]()) { dict, index in
            let date = newStructure.days[index]
            let dailyLessons = organizedDays[index]
            
            // Filtra: solo lezioni valide (non annullate e non pause)
            let validLessons = dailyLessons.filter { !$0.isCanceled && $0.type != "pause" }
            
            if !validLessons.isEmpty {
                let totalMinutes = validLessons.reduce(0) { sum, lesson in
                    guard let time = lesson.time else { return 0 }
                    
                    let times = time.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                    guard times.count == 2 else { return sum }
                    
                    func toMinutes(_ time: String) -> Int {
                        let parts = time.split(separator: ":")
                        guard parts.count == 2,
                              let h = Int(parts[0]),
                              let m = Int(parts[1]) else { return 0 }
                        return h * 60 + m
                    }
                    
                    let start = toMinutes(times[0])
                    let end = toMinutes(times[1])
                    
                    return sum + (end - start)
                }
                
                let hours = Double(totalMinutes) / 60.0
                if hours > 0 {
                    dict[date] = hours
                }
            }
        }
        
        await MainActor.run {
            DatePickerCache.shared.updateActivities(dates: activeActivities)
        }
    }
    
    private func handleNewData(_ fetchedLessons: [String: [Lesson]], selectedYear: String, matricola: String, update: Bool) async throws {
        if fetchedLessons.isEmpty {
            self.noLessonsFound = true
            await updateStateAndCache([:], selectedYear: selectedYear, matricola: matricola)
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
    
    private func updateStateAndCache(_ newLessons: [String: [Lesson]], selectedYear: String, matricola: String) async {
        self.lessons = newLessons
        
        let cacheObject = newLessons
        await CacheManager.shared.save(cacheObject, fileName: cacheKey)
        
        await self.organizeData(selectedYear: selectedYear, matricola: matricola)
    }
    
    private func clearCache() async {
        await CacheManager.shared.clear(fileName: cacheKey)
    }
    
    public func clearAll() async {
        self.loading = true
        await Task.yield()
        await clearCache()
        clearPendingUpdate()
        self.lessons.removeAll()
        self.days.removeAll()
    }
    
    private func handleError(_ error: Error) {
        if let netError = error as? NetworkError {
            if case .offline = netError {
                isOffline = lessons.isEmpty
            }
            
            self.errorMessage = netError.localizedDescription
        } else {
            self.errorMessage = NSLocalizedString("Errore generico: \(error.localizedDescription)", comment: "")
        }
        print("Debug Error: \(error)")
    }
}

struct CalendarLogic {
    static func processCalendarData(
        year: Int,
        matricola: String,
        lessons: [String: [Lesson]],
        cachedStructure: YearStructure?
    ) async -> (YearStructure, [[Lesson]]) {
        return await Task.detached(priority: .userInitiated) {
            let structure: YearStructure
            if let cache = cachedStructure, cache.year == year {
                structure = cache
            } else {
                structure = generateYearStructure(year: year)
            }
            
            let userFilter: Lesson.TargetGroup = (matricola == "pari") ? .even : .odd
            
            var organized: [[Lesson]] = []
            organized.reserveCapacity(structure.days.count)
            
            for dayString in structure.days {
                guard let dailyLessons = lessons[dayString] else {
                    organized.append([])
                    continue
                }
                
                let filtered = dailyLessons.filter { lesson in
                    lesson.type != "chiusura_type" &&
                    lesson.type != "closure" &&
                    (lesson.group == .all || lesson.group == userFilter)
                }
                
                organized.append(filtered)
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
}
