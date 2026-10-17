//
//  University.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

public protocol SelectableItem: Identifiable, Equatable {
    var id: String { get }
    var label: String { get }
}

public struct AcademicYear: Codable, Equatable, Sendable, Identifiable, SelectableItem {
    public let id: String
    public let label: String
    public let hasGroup: Bool?
}

public struct Course: Codable, Equatable, Sendable, Identifiable, SelectableItem {
    public let id: String
    public let label: String
    public let years: [AcademicYear]
}
