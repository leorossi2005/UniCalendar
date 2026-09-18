//
//  Commitments.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 18/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

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
    public var location: String?
    public var notes: String?
    
    public init(id: String, title: String, startTime: Date, endTime: Date, tags: [String] = [], location: String? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.tags = tags
        self.location = location
        self.notes = notes
    }
}
