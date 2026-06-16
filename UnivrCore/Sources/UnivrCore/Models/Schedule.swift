//
//  Schedule.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct Coordinates: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
}

public struct LocationInfo: Codable, Equatable, Sendable {
    public let classroom: String
    // periphery:ignore
    public let building: String?
    public let address: String?
    public let capacity: Int?
    public let coordinates: Coordinates?
}

public struct Lesson: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    // periphery:ignore
    public let code: String?
    public let type: EventType
    public let name: String?
    public let cleanName: String?
    public let tags: [String]
    public let group: TargetGroup
    public let startTime: Date
    public let endTime: Date
    public let durationMinutes: Int
    public let isCanceled: Bool
    public let color: String
    public let teachers: [String]
    public let location: LocationInfo?
    
    public enum TargetGroup: String, Codable, Sendable {
        case even, odd, all
    }
    
    public enum EventType: String, Codable, Sendable {
        case lesson, closure, pause, unknown
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            
            self = EventType(rawValue: rawValue) ?? .unknown
        }
    }
}

public struct DailySchedule: Codable, Equatable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let events: [Lesson]
}
