//
//  CalendarViewModel.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 22/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import Observation

public enum CalendarViewState: Equatable, Sendable {
    case loading, loaded, empty, offline, error(String)
}

@MainActor
@Observable
public class CalendarViewModel {
    public var schedule: [DailySchedule] = []
    public var academicYearDays: [Date] = []
    
    public var state: CalendarViewState = .loading
    public var updateAvailable: Bool = false
    public var checkingUpdates: Bool = false
    
    private var pendingNewLessons: [DailySchedule]? = nil
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
        
        if !updating {
            if schedule.isEmpty {
                await loadFromCache(selYear: selYear, matricola: matricola)
            }
            checkingUpdates = !schedule.isEmpty
        } else {
            if schedule.isEmpty {
                await clearAll(state: .loading)
            }
        }
        
        do {
            let response = try await service.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            await handleNewData(response, selectedYear: selYear, matricola: matricola, update: updating)
        } catch {
            self.handleError(error)
        }
        
        checkingUpdates = false
    }
    
    // MARK: - Data Handling
    private func handleNewData(_ fetched: [DailySchedule], selectedYear: String, matricola: String, update: Bool) async {
        if fetched.isEmpty {
            if update || schedule.isEmpty {
                state = .empty
                schedule.removeAll()
            }
            return
        }
        
        if schedule.isEmpty || update {
            await processAndSave(fetched, selectedYear: selectedYear, matricola: matricola)
        } else {
            let fetchedFiltered = processRawLessons(fetched, matricola: matricola).processed
            
            if schedule != fetchedFiltered {
                pendingNewLessons = fetched
                updateAvailable = true
            }
        }
    }
    
    public func confirmUpdate(selectedYear: String, matricola: String) async {
        guard let newLessons = pendingNewLessons else { return }
        await processAndSave(newLessons, selectedYear: selectedYear, matricola: matricola)
        clearPendingUpdate()
    }
    
    private func processRawLessons(_ rawSchedule: [DailySchedule], matricola: String) -> (processed: [DailySchedule], activities: [Date: Double]) {
        let userFilter: Lesson.TargetGroup = (matricola == "even") ? .even : .odd
        
        var activeActivities: [Date: Double] = [:]
        
        let processedSchedule = rawSchedule.compactMap { daily -> DailySchedule? in
            let validEvents = daily.events.filter { lesson in
                lesson.type != .closure && (lesson.group == .all || lesson.group == userFilter)
            }
            
            guard !validEvents.isEmpty else { return nil }
            
            let activeMinutes = validEvents.reduce(0) { total, lesson in
                (lesson.isCanceled || lesson.type == .pause) ? total : total + lesson.durationMinutes
            }
            
            if activeMinutes > 0 {
                activeActivities[daily.date] = Double(activeMinutes) / 60.0
            }
            
            return DailySchedule(date: daily.date, events: validEvents)
        }
        
        return (processedSchedule, activeActivities)
    }
    
    // MARK: - Data Processing
    private func processAndSave(_ rawLessons: [DailySchedule], selectedYear: String, matricola: String) async {
        let result = processRawLessons(rawLessons, matricola: matricola)
        
        self.schedule = result.processed
        self.state = result.processed.isEmpty ? .empty : .loaded
        
        await CacheManager.shared.save(rawLessons, fileName: cacheKey)
        DatePickerCache.shared.updateActivities(dates: result.activities)
    }
    
    // MARK: - Helpers & Cache
    public func loadFromCache(selYear: String, matricola: String) async {
        if let cached = await CacheManager.shared.load(fileName: cacheKey, type: [DailySchedule].self) {
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
        schedule.removeAll()
        clearPendingUpdate()
    }
    
    public func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        updateAvailable = false
    }
    
    private func handleError(_ error: Error) {
        if let netError = error as? NetworkError, case .offline = netError {
            if schedule.isEmpty { state = .offline }
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
    
    public func events(for date: Date) -> [Lesson]? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return schedule.first(where: { $0.date == normalizedDate })?.events
    }
}
