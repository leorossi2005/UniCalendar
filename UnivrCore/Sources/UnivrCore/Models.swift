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
public struct Lesson: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public private(set) var name: String? = nil
    public private(set) var cleanName: String? = nil
    public private(set) var date: String? = nil
    public private(set) var time: String? = nil
    public private(set) var duration: String? = nil
    public private(set) var classroom: String? = nil
    public private(set) var location: String? = nil
    public private(set) var address: String? = nil
    public private(set) var teacher: String? = nil
    public private(set) var code: String? = nil
    public private(set) var color: String? = nil
    public private(set) var type: EventType = .unknown
    
    public private(set) var tags: [String] = []
    
    public private(set) var latitude: Double? = nil
    public private(set) var longitude: Double? = nil
    public private(set) var capacity: Int? = nil
    
    public private(set) var group: TargetGroup = .all
    public private(set) var isCanceled: Bool = false
    
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

// MARK: - UI Previews
extension Lesson {
    public static let sample = Lesson(
        id: "SAMPLE-123", name: "Insegnamento di prova", cleanName: "Insegnamento di prova",
        date: "01-01-2025", time: "08:30 - 10:30", duration: "2h", classroom: "Aula Gino Tessari",
        teacher: "Prof. Rossi", code: "XYZ", color: "#A0A0A0", type: .lesson
    )
    
    public static let pausaSample = Lesson(
        id: "PAUSA-123", name: nil, cleanName: nil, date: "01-01-2025", time: "08:30 - 10:30", duration: "2h", type: .pause
    )
}
