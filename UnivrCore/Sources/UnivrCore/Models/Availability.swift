//
//  Availability.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

struct Availability: Codable, Equatable, Sendable {
    let locations: [String: String]
    let events: [String: [String: Room]]
}

public struct Room: Codable, Equatable, Sendable {
    public let name: String
    public let events: [Event]
}

public struct Event: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let cleanName: String
    public let startTime: Date
    public let endTime: Date
}
