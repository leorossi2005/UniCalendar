//
//  Models.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 08/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

// MARK: - Navigation Models
public struct AcademicYear: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let label: String
    public let hasGroup: Bool?
}

public struct Corso: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let label: String
    public let years: [AcademicYear]
}

// MARK: - Schedule Models
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

// MARK: - UI Previews
extension Lesson {
    public static let sample = Lesson(
        id: "SAMPLE-123",
        code: "XYZ",
        type: .lesson,
        name: "Insegnamento di prova",
        cleanName: "Insegnamento di prova",
        tags: ["Informatica", "Base"],
        group: .all,
        startTime: Date(),
        endTime: Date().addingTimeInterval(7200), // +2 ore
        durationMinutes: 120,
        isCanceled: false,
        color: "#A0A0A0",
        teachers: ["Prof. Rossi", "Prof. Verdi"],
        location: LocationInfo(
            classroom: "Aula Gino Tessari",
            building: "Borgo Roma - Ca' Vignal 2",
            address: "Strada Le Grazie, 15 - 37134 Verona",
            capacity: 236,
            coordinates: Coordinates(latitude: 45.4037, longitude: 10.9991)
        )
    )
    
    // periphery:ignore
    public static let pausaSample = Lesson(
        id: "PAUSA-123",
        code: nil,
        type: .pause,
        name: "Pausa",
        cleanName: "Pausa",
        tags: [],
        group: .all,
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        durationMinutes: 60,
        isCanceled: false,
        color: "#FFFFFF",
        teachers: [],
        location: nil
    )
}
