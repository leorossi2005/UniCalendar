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
public struct Lesson: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String?
    public let cleanName: String?
    public let date: String?
    public let time: String?
    public let duration: String?
    public let classroom: String?
    public let location: String?
    public let address: String?
    public let teacher: String?
    public let code: String?
    public let color: String?
    public let type: String?
    
    public let tags: [String]
    
    public let latitude: Double?
    public let longitude: Double?
    public let capacity: Int?
    
    public let group: TargetGroup
    public let isCanceled: Bool 
    
    public enum TargetGroup: String, Codable, Sendable {
        case even, odd, all
    }
}

// MARK: - O(1) Diffing per SwiftUI
extension Lesson: Hashable, Equatable {
    public static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#if DEBUG
// MARK: - UI Previews
extension Lesson {
    public static let sample = Lesson(
        id: "SAMPLE-123", name: "Insegnamento di prova", cleanName: "Insegnamento di prova",
        date: "01-01-2025", time: "08:30 - 10:30", duration: "2h", classroom: "Aula Gino Tessari",
        location: nil, address: nil, teacher: "Prof. Rossi", code: "XYZ", color: "#A0A0A0", type: "lesson",
        tags: [], latitude: nil, longitude: nil, capacity: nil,
        group: .all, isCanceled: false
    )
    
    public static let pausaSample = Lesson(
        id: "PAUSA-123", name: nil, cleanName: nil, date: "01-01-2025", time: "08:30 - 10:30", duration: "2h",
        classroom: nil, location: nil, address: nil, teacher: nil, code: nil, color: nil, type: "pause", tags: [],
        latitude: nil, longitude: nil, capacity: nil,
        group: .all, isCanceled: false
    )
}
#endif
