//
//  CalendarViewModel.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 22/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public class CalendarViewModel {
    public var schedule: [DailySchedule] = []
    public var academicYearDays: [Date] = []
    
    public var state: ResourcePhase = .loading
    public var updateAvailable: Bool = false
    public var checkingUpdates: Bool = false
    public var isOffline: Bool { NetworkStatusMonitor.shared.status == .disconnected }
    
    private var pendingNewLessons: [DailySchedule]? = nil
    private let service: NetworkService = .init()
    private let resource: CachedResource<[DailySchedule]> = CachedResource(cacheFileName: .calendarSchedule, cacheManager: .shared)
    private var lastMatricola: String = ""
    
    public init() {
        observeResource()
        observeNetworkStatus()
    }
    
    private func observeResource() {
        withObservationTracking {
            _ = resource.phase
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.reactToResourceChange()
                self.observeResource()
            }
        }
    }
    
    private func reactToResourceChange() {
        switch resource.phase {
        case .loaded:
            if let fetched = resource.value {
                handleNewData(fetched, matricola: lastMatricola, update: false)
            }
        case .offline:
            if schedule.isEmpty { state = .offline }
        case .error(let message):
            if schedule.isEmpty { state = .error(message) }
        case .loading:
            if schedule.isEmpty { state = .loading }
        case .idle, .empty:
            break
        }
    }
    
    private func observeNetworkStatus() {
        withObservationTracking {
            _ = NetworkStatusMonitor.shared.status
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let offline = NetworkStatusMonitor.shared.status == .disconnected
                if offline, self.schedule.isEmpty, self.resource.value == nil {
                    self.state = .offline
                } else if !offline, self.state == .offline, self.resource.value == nil, self.schedule.isEmpty, !self.resource.hasLastFetch {
                    self.state = .empty
                }
                self.observeNetworkStatus()
            }
        }
    }
    
    public func loadLessons(corso: String, anno: String, selYear: String, matricola: String, updating: Bool) async {
        lastMatricola = matricola
        guard corso != "0" else {
            await clearAll(state: NetworkStatusMonitor.shared.status == .disconnected ? .offline : .empty)
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
        switch resource.phase {
        case .offline:
            if schedule.isEmpty { state = .offline }
        case .error(let message):
            if schedule.isEmpty { state = .error(message) }
        case .idle, .loading, .loaded, .empty:
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
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1))
            self.state = result.processed.isEmpty ? .empty : .loaded
        }
        
        DatePickerCache.shared.updateActivities(dates: result.activities)
    }
    
    // MARK: - Helpers & Cache
    public func loadFromCache(matricola: String) async {
        await resource.loadFromDisk()
        if let cached = resource.value {
            processAndSave(cached, matricola: matricola)
        }
    }
    
    public func clearAll(state: ResourcePhase = .empty) async {
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
    
    public func events(for date: Date) -> [CalendarItem]? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let lessons = schedule.first(where: { $0.date == normalizedDate })?.events ?? []
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? startOfDay
        
        let dailyPersonalEvents = CommitmentsManager.shared.personalEvents.filter { 
            $0.startTime >= startOfDay && $0.startTime <= endOfDay 
        }
        
        if lessons.isEmpty && dailyPersonalEvents.isEmpty {
            return nil
        }
        
        var combinedItems: [CalendarItem] = []
        for lesson in lessons {
            combinedItems.append(.lesson(lesson))
        }
        for event in dailyPersonalEvents {
            combinedItems.append(.personal(event))
        }
        
        let sortedItems = combinedItems.sorted(by: { $0.startTime < $1.startTime })
        // If BFF takes over remove the function and change to "return sortedItems"
        return processPausesWithPersonalEvents(items: sortedItems)
    }
    
    private func processPausesWithPersonalEvents(items: [CalendarItem]) -> [CalendarItem] {
        var pauses: [Lesson] = []
        var realLessons: [Lesson] = []
        var personalEvents: [PersonalEvent] = []
        
        for item in items {
            switch item {
            case .lesson(let l):
                if l.type == .pause { pauses.append(l) } else { realLessons.append(l) }
            case .personal(let p):
                personalEvents.append(p)
            }
        }
        
        var adjustedPauses: [Lesson] = []
        
        for pause in pauses {
            var currentPieces = [pause]
            for pe in personalEvents {
                var nextPieces: [Lesson] = []
                for p in currentPieces {
                    if pe.startTime < p.endTime && pe.endTime > p.startTime {
                        if p.startTime < pe.startTime {
                            let dur = Calendar.current.dateComponents([.minute], from: p.startTime, to: pe.startTime).minute ?? 0
                            if dur > 0 {
                                nextPieces.append(Lesson(id: p.id + "_pre", code: p.code, type: p.type, name: p.name, cleanName: p.cleanName, tags: p.tags, group: p.group, startTime: p.startTime, endTime: pe.startTime, durationMinutes: dur, isCanceled: p.isCanceled, color: p.color, teachers: p.teachers, location: p.location))
                            }
                        }
                        if p.endTime > pe.endTime {
                            let dur = Calendar.current.dateComponents([.minute], from: pe.endTime, to: p.endTime).minute ?? 0
                            if dur > 0 {
                                nextPieces.append(Lesson(id: p.id + "_post", code: p.code, type: p.type, name: p.name, cleanName: p.cleanName, tags: p.tags, group: p.group, startTime: pe.endTime, endTime: p.endTime, durationMinutes: dur, isCanceled: p.isCanceled, color: p.color, teachers: p.teachers, location: p.location))
                            }
                        }
                    } else {
                        nextPieces.append(p)
                    }
                }
                currentPieces = nextPieces
            }
            adjustedPauses.append(contentsOf: currentPieces)
        }
        
        var allEvents: [CalendarItem] = []
        allEvents.append(contentsOf: realLessons.map { .lesson($0) })
        allEvents.append(contentsOf: personalEvents.map { .personal($0) })
        allEvents.append(contentsOf: adjustedPauses.map { .lesson($0) })
        
        allEvents.sort { $0.startTime < $1.startTime }
        
        var finalItems: [CalendarItem] = []
        if allEvents.isEmpty { return [] }
        
        var currentEndTime = allEvents.first!.startTime
        
        for item in allEvents {
            if currentEndTime < item.startTime {
                let dur = Calendar.current.dateComponents([.minute], from: currentEndTime, to: item.startTime).minute ?? 0
                if dur > 0 {
                    let newPause = Lesson(
                        id: "pause-\(Int(currentEndTime.timeIntervalSince1970))",
                        code: nil,
                        type: .pause,
                        name: "Pausa",
                        cleanName: "Pausa",
                        tags: [],
                        group: .all,
                        startTime: currentEndTime,
                        endTime: item.startTime,
                        durationMinutes: dur,
                        isCanceled: false,
                        color: "#FFFFFF",
                        teachers: [],
                        location: nil
                    )
                    finalItems.append(.lesson(newPause))
                }
            }
            
            finalItems.append(item)
            
            let itemEndTime: Date
            switch item {
            case .lesson(let l): itemEndTime = l.endTime
            case .personal(let p): itemEndTime = p.endTime
            }
            
            if itemEndTime > currentEndTime {
                currentEndTime = itemEndTime
            }
        }
        
        return finalItems
    }
}
