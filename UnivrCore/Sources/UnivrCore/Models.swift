//
//  Models.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 08/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct Year: Codable, Sendable, Equatable, Identifiable {
    public var id: String { value }
    public let label: String
    public let value: String
}

// MARK: - Schedule & Lessons
public struct ResponseAPI: Codable, Sendable, Equatable {
    var lessons: [Lesson]
}

public struct Lesson: Codable, Sendable, Hashable, Identifiable, Equatable {
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(date)
        hasher.combine(time)
        hasher.combine(teacher)
        return hasher.finalize()
    }

    public let name: String?
    public let cleanName: String?
    public let tags: [String]
    public let group: String

    public let date: String?
    public let time: String?
    public let startTime: String?
    public let endTime: String?
    public let duration: String?

    public let classroom: String?
    public let location: String?
    public let address: String?
    public let latitude: Double?
    public let longitude: Double?
    public let capacity: Int?

    public let teacher: String?
    public let type: String // Oppure il tuo enum LessonType se i valori combaciano esattamente
    public let canceled: Bool
    public let code: String?
    public let color: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.cleanName = try container.decodeIfPresent(String.self, forKey: .cleanName)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.group = try container.decodeIfPresent(String.self, forKey: .group) ?? "all"
        
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.time = try container.decodeIfPresent(String.self, forKey: .time)
        self.startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        self.duration = try container.decodeIfPresent(String.self, forKey: .duration)
        
        self.classroom = try container.decodeIfPresent(String.self, forKey: .classroom)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        
        self.teacher = try container.decodeIfPresent(String.self, forKey: .teacher)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "lesson"
        self.canceled = try container.decodeIfPresent(Bool.self, forKey: .canceled) ?? false
        self.code = try container.decodeIfPresent(String.self, forKey: .code)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
    }

    // Costruttore per i Sample (pause, preview)
    init(date: String?, time: String?, type: String, duration: String) {
        self.date = date
        self.time = time
        self.type = type
        self.startTime = time?.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces)
        self.endTime = time?.components(separatedBy: "-").last?.trimmingCharacters(in: .whitespaces)
        self.name = nil; self.cleanName = nil; self.tags = []; self.group = "all"
        self.duration = nil; self.classroom = nil; self.location = nil; self.address = nil
        self.latitude = nil; self.longitude = nil; self.capacity = nil
        self.teacher = nil; self.canceled = false; self.code = nil
        self.color = nil;
    }

    public enum GruppoMatricola: String, Codable, Sendable {
        case even = "even", odd = "odd", all = "all"
    }
}

// MARK: Struct corsi per il network
public struct Corso: Codable, Sendable, Equatable {
    public let label: String
    public let value: String
    public let years: [Anno]
    
    public static func filter(_ courses: [Corso], with searchText: String) -> [Corso] {
        guard !searchText.isEmpty else { return courses }
        return courses.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }
}

public struct Anno: Codable, Sendable, Equatable {
    public let label: String
    public let value: String
    public let hasGroup: Bool
}

extension Lesson {
    //public static let sample = Lesson(
    //    name: "Insegnamento di prova molto lungo Laboratorio",
    //    cleanName: "Insegnamento di prova molto lungo lungo lungo",
    //    date: "01-01-2025",
    //    classroom: "Aula Gino Tessari",
    //    time: "08:30 - 10:30",
    //    type: "Lezione",
    //    teacher: "Prof. Rossi",
    //    canceled: false,
    //    colorIndex: "",
    //    code: "XYZ",
    //    color: "#A0A0A0"
    //)
    
    public static let sample = Lesson(
        date: "01-01-2025",
        time: "08:30 - 10:30",
        type: "pause",
        duration: "2h"
    )
    
    public static let pausaSample = Lesson(
        date: "01-01-2025",
        time: "08:30 - 10:30",
        type: "pause",
        duration: "2h"
    )
}

