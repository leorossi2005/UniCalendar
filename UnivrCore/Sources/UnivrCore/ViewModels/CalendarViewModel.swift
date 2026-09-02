//
//  CalendarViewModel.swift
//  UnivrCore
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
    private let service: NetworkService = .init()
    private let resource: CachedResource<[DailySchedule]> = CachedResource(cacheFileName: .calendarSchedule, cacheManager: .shared)
    
    public init() {}
    
    public func loadLessons(corso: String, anno: String, selYear: String, matricola: String, updating: Bool) async {
        guard corso != "0" else {
            await clearAll()
            return
        }
        
        generateAcademicYearDays(for: selYear)
        
        if !updating {
            if schedule.isEmpty {
                await loadFromCache(matricola: matricola)
            }
            checkingUpdates = !schedule.isEmpty
            if schedule.isEmpty {
                state = .loading
            }
        } else {
            await clearAll(state: .loading)
        }
        
        do {
            let fetched = try await resource.refresh { try await self.service.fetchOrario(corso: corso, anno: anno, selyear: selYear) }
            handleNewData(fetched, matricola: matricola, update: updating)
        } catch is CancellationError {
        } catch {
            handleFetchFailure()
        }
        
        checkingUpdates = false
    }
    
    // MARK: - Data Handling
    private func handleNewData(_ fetched: [DailySchedule], matricola: String, update: Bool) {
        if fetched.isEmpty {
            if update || schedule.isEmpty {
                state = .empty
                schedule.removeAll()
            }
            return
        }
        
        if schedule.isEmpty || update {
            processAndSave(fetched, matricola: matricola)
        } else {
            let fetchedFiltered = processRawLessons(fetched, matricola: matricola).processed
            
            if schedule != fetchedFiltered {
                pendingNewLessons = fetched
                updateAvailable = true
            }
        }
    }
    
    private func handleFetchFailure() {
        switch resource.state {
        case .offline:
            if schedule.isEmpty { state = .offline }
        case .error(let message):
            state = .error(message)
        case .idle, .loading, .loaded:
            break
        }
    }
    
    public func confirmUpdate(matricola: String) async {
        guard let newLessons = pendingNewLessons else { return }
        processAndSave(newLessons, matricola: matricola)
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
    private func processAndSave(_ rawLessons: [DailySchedule], matricola: String) {
        let result = processRawLessons(rawLessons, matricola: matricola)
        
        self.schedule = result.processed
        self.state = result.processed.isEmpty ? .empty : .loaded
        
        DatePickerCache.shared.updateActivities(dates: result.activities)
    }
    
    // MARK: - Helpers & Cache
    public func loadFromCache(matricola: String) async {
        await resource.loadFromDisk()
        if let cached = resource.value {
            processAndSave(cached, matricola: matricola)
        }
    }
    
    public func clearAll(state: CalendarViewState = .empty) async {
        self.state = state
        await resource.clear()
        schedule.removeAll()
        clearPendingUpdate()
    }
    
    public func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        updateAvailable = false
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
