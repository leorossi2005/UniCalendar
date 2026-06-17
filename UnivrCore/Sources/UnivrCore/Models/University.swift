//
//  University.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

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
