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

public enum ClassroomViewState: Equatable, Sendable {
    case loading, loaded, offline, error(String)
}

@MainActor
@Observable
public final class AvailabilityDataManager {
    public var locations: [String: String] = [:]
    public var rooms: [Room]?
    
    public var state: ClassroomViewState = .loading
    
    private let service = NetworkService()
    private var lastFetch: Availability? = nil
    private var lastDate: String = ""
    
    public init() {}
    
    public func getAvailability(locationKey: String, date: Date) async {
        let dateString = String(format: "%02d-%02d-%04d", date.day, date.month, date.year)
        state = .loading
        rooms = nil
        do {
            if lastFetch == nil || lastDate != dateString {
                let availability = try await service.getAvailability(date: dateString)
                try Task.checkCancellation()
                lastDate = dateString
                lastFetch = availability
                locations = availability.locations
                rooms = availability.rooms[locationKey]
            } else {
                rooms = lastFetch?.rooms[locationKey]
            }
            state = .loaded
        } catch is CancellationError {
        } catch let error as NetworkError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error(String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module))
        }
    }
    
    public func reset() {
        state = .loading
        rooms = nil
    }
}
