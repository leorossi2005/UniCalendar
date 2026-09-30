//
//  Commitments.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 18/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct EventLocation: Codable, Equatable, Sendable {
    public var name: String
    public var coordinates: Coordinates?
    
    public init(name: String, coordinates: Coordinates? = nil) {
        self.name = name
        self.coordinates = coordinates
    }
}

public struct PersonalEvent: Sendable, Codable, Identifiable, Equatable {
    public let id: String
    public var title: String
    public var startTime: Date
    public var endTime: Date
    public var durationMinutes: Int {
        let diff = endTime.timeIntervalSince(startTime)
        return Int(max(0, diff) / 60)
    }
    public let tags: [String]
    public var location: EventLocation?
    public var notes: String?
    
    public init(id: String, title: String, startTime: Date, endTime: Date, tags: [String] = [], location: EventLocation? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.tags = tags
        self.location = location
        self.notes = notes
    }
}

public protocol CalendarDisplayable: Identifiable where ID == String {
    var displayTitle: String { get }
    var startTime: Date { get }
    var endTime: Date { get }
    var durationMinutes: Int { get }
    var tags: [String] { get }
    var displayLocation: String? { get }
    var displayAddress: String? { get }
    var displayCoordinates: Coordinates? { get }
    var isCanceled: Bool { get }
}

extension Lesson: CalendarDisplayable {
    public var displayTitle: String { cleanName ?? "" }
    public var displayLocation: String? { location?.classroom }
    public var displayAddress: String? { location?.address ?? location?.classroom }
    public var displayCoordinates: Coordinates? { location?.coordinates }
}

extension PersonalEvent: CalendarDisplayable {
    public var displayTitle: String { title }
    public var displayLocation: String? { location?.name }
    public var displayAddress: String? { location?.name }
    public var displayCoordinates: Coordinates? { location?.coordinates }
    public var isCanceled: Bool { false }
}
