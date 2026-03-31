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

public enum CalendarViewState: Equatable, Sendable {
    case loading, loaded, empty, offline, error(String)
}

@MainActor
#if canImport(Observation)
@Observable
#endif
public class CalendarViewModel {
    public var lessons: [String: [Lesson]] = [:]
    public var academicYearDays: [Date] = []
    
    public var state: CalendarViewState = .loading
    public var updateAvailable: Bool = false
    public var checkingUpdates: Bool = false
    
    private var pendingNewLessons: [String: [Lesson]]? = nil
    private let service = NetworkService()
    private let cacheKey = "calendar_cache.json"
    
    public init() {}
    
    // MARK: - Core Loading
    public func loadLessons(corso: String, anno: String, selYear: String, matricola: String, updating: Bool) async {
        guard corso != "0" else {
            await clearAll()
            return
        }
        
        generateAcademicYearDays(for: selYear)
        
        if !updating && lessons.isEmpty {
            await loadFromCache(selYear: selYear, matricola: matricola)
        }
        
        if !updating && !lessons.isEmpty {
            self.checkingUpdates = true
        } else {
            await clearAll(state: .loading)
        }
        
        do {
            let response = try await service.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            try await handleNewData(response, selectedYear: selYear, matricola: matricola, update: updating)
        } catch {
            self.handleError(error)
        }
        
        checkingUpdates = false
    }
    
    // MARK: - Data Handling
    private func handleNewData(_ fetched: [String: [Lesson]], selectedYear: String, matricola: String, update: Bool) async {
        if fetched.isEmpty {
            if update || lessons.isEmpty {
                state = .empty
                lessons.removeAll()
            }
            return
        }
        
        if lessons.isEmpty || update {
            await processAndSave(fetched, selectedYear: selectedYear, matricola: matricola)
        } else {
            let fetchedFiltered = processRawLessons(fetched, matricola: matricola).processed
            
            if lessons != fetchedFiltered {
                pendingNewLessons = fetched
                updateAvailable = true
            }
        }
    }
    
    public func confirmUpdate(selectedYear: String, matricola: String) async {
        guard let newLessons = pendingNewLessons else { return }
        await processAndSave(newLessons, selectedYear: selectedYear, matricola: matricola)
        pendingNewLessons = nil
        updateAvailable = false
    }
    
    private func processRawLessons(_ rawLessons: [String: [Lesson]], matricola: String) -> (processed: [String: [Lesson]], activities: [String: Double]) {
        let userFilter: Lesson.TargetGroup = (matricola == "even") ? .even : .odd
        var processedLessons: [String: [Lesson]] = [:]
        var activeActivities: [String: Double] = [:]
        
        for (dateString, dailyLessons) in rawLessons {
            let filtered = dailyLessons.filter { lesson in
                lesson.type != .closure &&
                (lesson.group == .all || lesson.group == userFilter)
            }
            
            if !filtered.isEmpty {
                processedLessons[dateString] = filtered
                
                let valid = filtered.filter { !$0.isCanceled && $0.type != .pause }
                if !valid.isEmpty {
                    let totalMinutes = valid.reduce(0) { sum, lesson in
                        guard let t = lesson.time else { return sum }
                        return sum + calculateMinutes(from: t)
                    }
                    activeActivities[dateString] = Double(totalMinutes) / 60
                }
            }
        }
        
        return (processedLessons, activeActivities)
    }
    
    // MARK: - Data Processing
    private func processAndSave(_ rawLessons: [String: [Lesson]], selectedYear: String, matricola: String) async {
        let result = processRawLessons(rawLessons, matricola: matricola)
        
        self.lessons = result.processed
        self.state = result.processed.isEmpty ? .empty : .loaded
        
        await CacheManager.shared.save(rawLessons, fileName: cacheKey)
        DatePickerCache.shared.updateActivities(dates: result.activities)
    }
    
    // MARK: - Helpers & Cache
    public func loadFromCache(selYear: String, matricola: String) async {
        if let cached = await CacheManager.shared.load(fileName: cacheKey, type: [String: [Lesson]].self) {
            await processAndSave(cached, selectedYear: selYear, matricola: matricola)
        }
    }
    
    public func loadNetworkFromCache() async {
        if let cacheResponse = await CacheManager.shared.load(fileName: "network_cache.json", type: NetworkCacheData.self) {
            NetworkCache.shared.update(from: cacheResponse)
        }
    }
    
    public func clearAll(state: CalendarViewState = .empty) async {
        self.state = state
        await CacheManager.shared.clear(fileName: cacheKey)
        lessons.removeAll()
        pendingNewLessons = nil
        updateAvailable = false
    }
    
    public func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        updateAvailable = false
    }
    
    private func handleError(_ error: Error) {
        if let netError = error as? NetworkError, case .offline = netError {
            if lessons.isEmpty { state = .offline }
        } else {
            state = .error(error.localizedDescription)
        }
        print("Debug Error: \(error)")
    }
    
    public func generateAcademicYearDays(for year: String) {
        guard let y = Int(year) else { return }
        if let first = academicYearDays.first, Calendar.current.component(.year, from: first) == y { return }
        
        let start = Date(year: y, month: 10, day: 1)
        let end = Date(year: y + 1, month: 9, day: 30)
        
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = current.add(type: .day, value: 1)
        }
        self.academicYearDays = dates
    }
    
    private func calculateMinutes(from timeString: String) -> Int {
        let parts = timeString.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return 0 }
        
        func toMins(_ str: String) -> Int {
            let p = str.split(separator: ":")
            guard p.count == 2, let h = Int(p[0]), let m = Int(p[1]) else { return 0 }
            return h * 60 + m
        }
        return toMins(parts[1]) - toMins(parts[0])
    }
    
    //public func organizeData(selectedYear: String, matricola: String) async {
    //    guard let annoInt = Int(selectedYear) else { return }
    //
    //    let lessonsSnapshot = self.lessons
    //    let currentCache = self.cachedStructure
    //
    //    let (newStructure, organizedDays) = await CalendarLogic.processCalendarData(
    //        year: annoInt,
    //        matricola: matricola,
    //        lessons: lessonsSnapshot,
    //        cachedStructure: currentCache
    //    )
    //
    //    if self.cachedStructure?.year != annoInt {
    //        self.cachedStructure = newStructure
    //    }
    //    self.daysString = newStructure.days
    //    self.days = organizedDays
    //
    //    let activeActivities = organizedDays.indices.reduce(into: [String: Double]()) { dict, index in
    //        let date = newStructure.days[index]
    //        let dailyLessons = organizedDays[index]
    //
    //        // Filtra: solo lezioni valide (non annullate e non pause)
    //        let validLessons = dailyLessons.filter { !$0.isCanceled && $0.type != "pause" }
    //
    //        if !validLessons.isEmpty {
    //            let totalMinutes = validLessons.reduce(0) { sum, lesson in
    //                guard let time = lesson.time else { return 0 }
    //
    //                let times = time.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
    //                guard times.count == 2 else { return sum }
    //
    //                func toMinutes(_ time: String) -> Int {
    //                    let parts = time.split(separator: ":")
    //                    guard parts.count == 2,
    //                          let h = Int(parts[0]),
    //                          let m = Int(parts[1]) else { return 0 }
    //                    return h * 60 + m
    //                }
    //
    //                let start = toMinutes(times[0])
    //                let end = toMinutes(times[1])
    //
    //                return sum + (end - start)
    //            }
    //
    //            let hours = Double(totalMinutes) / 60.0
    //            if hours > 0 {
    //                dict[date] = hours
    //            }
    //        }
    //    }
    //
    //    await MainActor.run {
    //        DatePickerCache.shared.updateActivities(dates: activeActivities)
    //    }
    //}
    //
    //private func updateStateAndCache(_ newLessons: [String: [Lesson]], selectedYear: String, matricola: String) async {
    //    self.lessons = newLessons
    //
    //    let cacheObject = newLessons
    //    await CacheManager.shared.save(cacheObject, fileName: cacheKey)
    //
    //    await self.organizeData(selectedYear: selectedYear, matricola: matricola)
    //}
    //
    //private func clearCache() async {
    //    await CacheManager.shared.clear(fileName: cacheKey)
    //}
}

//struct CalendarLogic {
//    static func processCalendarData(
//        year: Int,
//        matricola: String,
//        lessons: [String: [Lesson]],
//        cachedStructure: YearStructure?
//    ) async -> (YearStructure, [[Lesson]]) {
//        return await Task.detached(priority: .userInitiated) {
//            let structure: YearStructure
//            if let cache = cachedStructure, cache.year == year {
//                structure = cache
//            } else {
//                structure = generateYearStructure(year: year)
//            }
//
//            let userFilter: Lesson.TargetGroup = (matricola == "even") ? .even : .odd
//
//            var organized: [[Lesson]] = []
//            organized.reserveCapacity(structure.days.count)
//
//            for dayString in structure.days {
//                guard let dailyLessons = lessons[dayString] else {
//                    organized.append([])
//                    continue
//                }
//
//                let filtered = dailyLessons.filter { lesson in
//                    lesson.type != "chiusura_type" &&
//                    lesson.type != "closure" &&
//                    (lesson.group == .all || lesson.group == userFilter)
//                }
//
//                organized.append(filtered)
//            }
//
//            return (structure, organized)
//        }.value
//    }
//
//    static func generateYearStructure(year: Int) -> YearStructure {
//        let startDate = Date(year: year, month: 10, day: 1)
//        let endDate = Date(year: year + 1, month: 9, day: 30)
//
//        var dateStrings: [String] = []
//        var dateObj: [Date] = []
//        dateStrings.reserveCapacity(366)
//        dateObj.reserveCapacity(366)
//
//        var currentDate = startDate
//        while currentDate <= endDate {
//            dateStrings.append(currentDate.formatUnivrStyle())
//            dateObj.append(currentDate)
//            currentDate = currentDate.add(type: .day, value: 1)
//        }
//
//        return YearStructure(year: year, days: dateStrings, dates: dateObj)
//    }
//}
