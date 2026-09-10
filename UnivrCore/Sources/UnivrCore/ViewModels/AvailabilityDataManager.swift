//
//  AvailabilityManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum RoomDailyStatus: Equatable {
    case pastDay
    case futureDay(event: Event, index: Int)
    case futureDayFree
    case freeAllDay
    case freeUntil(event: Event, index: Int)
    case occupiedUntil(event: Event, index: Int, freeAt: Date)
    case dayEnded
    
    public var statusText: String {
        switch self {
        case .pastDay:
            return String(localized: "Giornata conclusa")
        case .futureDay(let event, _):
            return String(localized: "Primo impegno alle \(event.startTime.formatted(.dateTime.hour().minute()))")
        case .futureDayFree:
            return String(localized: "Libera tutto il giorno")
        case .freeAllDay, .dayEnded:
            return String(localized: "Libera per il resto della giornata")
        case .freeUntil(let event, _):
            return String(localized: "Libera fino alle \(event.startTime.formatted(.dateTime.hour().minute()))")
        case .occupiedUntil(_, _, let freeAt):
            return String(localized: "Occupata fino alle \(freeAt.formatted(.dateTime.hour().minute()))")
        }
    }
    
    private static func freeTime(in events: [Event], after index: Int) -> Date {
        var endTime = events[index].endTime
        var i = index
        while i + 1 < events.count, events[i + 1].startTime == endTime {
            i += 1
            endTime = events[i].endTime
        }
        return endTime
    }
    
    public init(room: Room, selectedDate: Date, now: Date, calendar: Calendar = .current) {
            let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
            let startOfToday = calendar.startOfDay(for: now)
            
            if startOfSelectedDay < startOfToday {
                self = .pastDay
                return
            }
            
            if startOfSelectedDay > startOfToday {
                self = room.events.first.map { .futureDay(event: $0, index: 0) } ?? .futureDayFree
                return
            }
            
            if let index = room.events.firstIndex(where: { $0.startTime <= now && $0.endTime > now }) {
                let freeAt = Self.freeTime(in: room.events, after: index)
                self = .occupiedUntil(event: room.events[index], index: index, freeAt: freeAt)
                return
            }
            
            if let index = room.events.firstIndex(where: { $0.startTime > now }) {
                self = .freeUntil(event: room.events[index], index: index)
                return
            }
            
            self = (room.events.last?.endTime ?? now) < now ? .dayEnded : .freeAllDay
        }
}

@MainActor
@Observable
public final class AvailabilityDataManager {
    public var locations: [String: String] = [:]
    public var rooms: [Room]?
    
    public var state: ResourcePhase = .loading
    
    private let service = NetworkService()
    private let resource = CachedResource<Availability>()
    private var locationKey: String = ""
    private var loadedDate: String?
    
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
                self.applyResourceState()
                self.observeResource()
            }
        }
    }

    private func observeNetworkStatus() {
        withObservationTracking {
            _ = NetworkStatusMonitor.shared.status
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if NetworkStatusMonitor.shared.status == .disconnected {
                    self.rooms = nil
                    self.state = .offline
                }
                self.observeNetworkStatus()
            }
        }
    }

    private func applyResourceState() {
        state = resource.phase

        switch resource.phase {
        case .idle:
            break
        case .loading:
            break
        case .loaded:
            if let availability = resource.value {
                locations = availability.locations
                rooms = availability.rooms[locationKey]
            }
        case .empty:
            rooms = nil
        case .offline:
            rooms = nil
        case .error(let message):
            rooms = nil
            state = .error(message)
        }
    }
    
    public func getAvailability(locationKey: String, date: Date) async {
        let dateString = String(format: "%02d-%02d-%04d", date.day, date.month, date.year)
        self.locationKey = locationKey

        if loadedDate == dateString,
           NetworkStatusMonitor.shared.status == .connected,
           let availability = resource.value {
            locations = availability.locations
            rooms = availability.rooms[locationKey]
            state = .loaded
            return
        }

        loadedDate = dateString
        state = .loading
        rooms = nil
        do {
            let availability = try await resource.refresh {
                try await self.service.getAvailability(date: dateString)
            }
            try Task.checkCancellation()
            locations = availability.locations
            rooms = availability.rooms[locationKey]
            state = .loaded
        } catch is CancellationError {
        } catch {
            applyResourceState()
        }
    }
    
    public func reset() {
        state = .loading
        rooms = nil
    }
}
