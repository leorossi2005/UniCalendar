//
//  AppStatus.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 05/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum NoticeLevel: String, Codable, Sendable {
    case info
    case warning
    case blocking
    
    public var systemImage: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .blocking: "xmark.octagon.fill"
        }
    }
}

public struct AppNotice: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let level: NoticeLevel
    public let title: [String: String]
    public let message: [String: String]
    public let buttonText: [String: String]?
    public let url: String?
    public let startsAt: Date
    public let endsAt: Date?
    
    private static let storeURL = URL(string: "https://apps.apple.com/app/id6756148883")
    
    public var isExpired: Bool {
        if let endsAt {
            return Date.now > endsAt
        }
        return false
    }
    
    public var localizedTitle: String {
        title.localized
    }
    
    public var localizedMessage: String {
        message.localized
    }
    
    public var localizedButtonText: String? {
        buttonText?.localized
    }
    
    public var actionURL: URL? {
        guard let url else {
            return level == .blocking ? Self.storeURL : nil
        }
        if url.lowercased() == "apple" { return Self.storeURL }
        guard let parsed = URL(string: url) else { return nil }
        let allowed = ["https", "itms-apps"]
        return allowed.contains(parsed.scheme?.lowercased() ?? "") ? parsed : nil
    }
    
    public var shareText: String {
        var lines: [String] = []
        
        let icon = switch level {
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .blocking: "🛑"
        }
        lines.append("\(icon) \(localizedTitle)")
        
        if let endsAt {
            lines.append("🗓️ \(startsAt.formatted(date: .abbreviated, time: .omitted)) – \(endsAt.formatted(date: .abbreviated, time: .omitted))")
        } else {
            lines.append("🗓️ \(startsAt.formatted(date: .abbreviated, time: .omitted))")
        }
        
        lines.append(localizedMessage)
        
        if let actionURL {
            let label = localizedButtonText ?? "Link"
            lines.append("🔗 \(label): \(actionURL.absoluteString)")
        }
        
        lines.append("📱 Univr Calendar")
        
        return lines.joined(separator: "\n\n")
    }
}

extension Dictionary where Key == String, Value == String {
    public var localized: String {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        return self[lang] ?? self["en"] ?? values.first ?? ""
    }
}
