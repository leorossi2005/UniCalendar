//
//  AppMetadata.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct Contributor: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let role: LocalizedStringResource
    public let url: URL?
    public let image: String
    
    public init(name: String, role: LocalizedStringResource, url: URL? = nil, image: String = "") {
        self.id = name
        self.name = name
        self.role = role
        self.url = url
        self.image = image
    }
}

public enum AppColor: String, Sendable {
    case blue, orange, purple, gray, green, red, teal, pink, yellow, indigo, mint, cyan, brown
}

public struct WhatsNewFeature: Identifiable, Sendable {
    public let id = UUID()
    public let icon: IconType
    public let accentColor: AppColor
    public let title: LocalizedStringResource
    public let shortDescription: LocalizedStringResource
    public let detailedDescription: LocalizedStringResource
    
    public enum IconType: Sendable, Equatable {
        case system(String)
        case asset(String)
    }
}

public struct WhatsNewVersion: Identifiable, Sendable {
    public let id = UUID()
    public let version: String
    public let date: Date
    public let headline: LocalizedStringResource
    public let features: [WhatsNewFeature]
}
