//
//  AppStatus.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum NoticeLevel: String, Codable, Sendable, Comparable {
    case info
    case warning
    case blocking
    
    private var rank: Int {
        switch self {
        case .info: 1
        case .warning: 2
        case .blocking: 3
        }
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
}

public struct AppNotice: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let level: NoticeLevel
    public let title: [String: String]
    public let message: [String: String]
    public let messageUnsupportedOS: [String: String]?
    public let buttonText: [String: String]?
    public let url: String?
    public let minVersion: String?
    public let maxVersion: String?
    public let updateRequiresOS: String?
    public let startsAt: Date
    public let endsAt: Date?
}

public struct EvaluatedNotice: Equatable, Sendable, Identifiable {
    public let id: String
    public let level: NoticeLevel
    public let title: String
    public let message: String
    public let buttonText: String?
    public let actionURL: URL?
    public let date: Date
}
