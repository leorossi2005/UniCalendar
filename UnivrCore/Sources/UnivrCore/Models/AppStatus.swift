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
    public let startsAt: Date?
    public let endsAt: Date?
    
    func effectiveLevel(appVersion: AppVersion, osVersion: AppVersion, now: Date) -> NoticeLevel? {
        if let startsAt, now < startsAt { return nil }
        if let endsAt, now > endsAt { return nil }
        if let minVersion, appVersion < AppVersion(minVersion) { return nil }
        if let maxVersion, appVersion > AppVersion(maxVersion) { return nil }
        
        guard level == .blocking else { return level }
        
        guard maxVersion != nil else { return nil }
        
        if let updateRequiresOS, osVersion < AppVersion(updateRequiresOS) { return .warning }
        
        return .blocking
    }
}

public struct EvaluatedNotice: Equatable, Sendable, Identifiable {
    public let id: String
    public let level: NoticeLevel
    public let title: String
    public let message: String
    public let buttonText: String?
    public let actionURL: URL?
}

// MARK: - Helpers
struct AppVersion: Comparable {
    private let parts: [Int]
    
    init(_ string: String) {
        parts = string.split(separator: ".").map { Int($0) ?? 0 }
    }
    
    init(_ os: OperatingSystemVersion) {
        parts = [os.majorVersion, os.minorVersion, os.patchVersion]
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<max(lhs.parts.count, rhs.parts.count) {
            let a = i < lhs.parts.count ? lhs.parts[i] : 0
            let b = i < rhs.parts.count ? rhs.parts[i] : 0
            if a != b { return a < b }
        }
        return false
    }
}

extension Dictionary where Key == String, Value == String {
    func localized(for language: String) -> String {
        self[language] ?? self["en"] ?? values.first ?? ""
    }
}
