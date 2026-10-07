//
//  AppStatusManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class AppStatusManager {
    public private(set) var activeNotice: EvaluatedNotice?
    public private(set) var isResolved = false
    public private(set) var shownThisSessionIDs: Set<String> = []
    
    private let service = NetworkService()
    private let resource = CachedResource<[AppNotice]>(cacheFileName: .appStatus, cacheManager: .shared)
    
    private var notices: [AppNotice] = []
    private var closedIDs: Set<String>
    private var isFetching = false
    private var lastCheck = Date.distantPast
    private var lastAttemptFailed = false
    
    private static let closedKey = "appStatus_closedIDs"
    private static let fallbackStoreURL = URL(string: "https://apps.apple.com/app/id6756148883")
    
    public init() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: Self.closedKey)
        #endif
        closedIDs = Set(UserDefaults.standard.stringArray(forKey: Self.closedKey) ?? [])
        
        Task {
            await loadCache()
            evaluateCurrentState()
        }
    }
    
    // MARK: - Public
    public func markAsShownThisSession(id: String) {
        shownThisSessionIDs.insert(id)
    }
    
    public func dismissNotice(id: String) {
        closedIDs.insert(id)
        saveClosedIDs()
        evaluateCurrentState()
    }
    
    public func refreshIfNeeded() async {
        let interval: TimeInterval = if activeNotice?.level == .blocking {
            30
        } else if lastAttemptFailed {
            300
        } else {
            3600
        }
        
        if Date.now.timeIntervalSince(lastCheck) >= interval {
            await refresh()
        }
    }
    
    public func refresh() async {
        guard !isFetching else { return }
        isFetching = true
        lastCheck = .now
        defer {
            isFetching = false
            isResolved = true
        }
        
        await loadCache()
        
        do {
            notices = try await resource.refresh {
                try await self.service.getAppStatus()
            }
            closedIDs.formIntersection(notices.map(\.id))
            saveClosedIDs()
            lastAttemptFailed = false
        } catch {
            print("AppStatusManager: errore nel recupero dello stato dell'app: \(error)")
            lastAttemptFailed = true
        }
        
        evaluateCurrentState()
    }
    
    public func evaluateCurrentState() {
        let app = AppVersion(Bundle.main.clearAppVersion)
        let os = AppVersion(ProcessInfo.processInfo.operatingSystemVersion)
        let now = Date.now
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        
        let candidates = notices.compactMap { notice -> (notice: AppNotice, level: NoticeLevel)? in
            guard let level = notice.effectiveLevel(appVersion: app, osVersion: os, now: now) else { return nil }
            if level != .blocking && closedIDs.contains(notice.id) { return nil }
            return (notice, level)
        }
        
        guard let (notice, level) = candidates.max(by: {
            ($0.level, $0.notice.startsAt ?? Date.distantPast) < ($1.level, $1.notice.startsAt ?? Date.distantPast)
        }) else {
            activeNotice = nil
            return
        }
        
        let downgraded = level != notice.level
        let message = downgraded ? (notice.messageUnsupportedOS ?? notice.message) : notice.message
        let url: URL? = downgraded ? nil : Self.storeURL(from: notice.url) ?? (level == .blocking ? Self.fallbackStoreURL : nil)
        
        activeNotice = EvaluatedNotice(
            id: notice.id,
            level: level,
            title: notice.title.localized(for: language),
            message: message.localized(for: language),
            buttonText: notice.buttonText?.localized(for: language),
            actionURL: url
        )
    }
    
    // MARK: - Private
    private func loadCache() async {
        guard resource.value == nil else { return }
        await resource.loadFromDisk()
        notices = resource.value ?? []
    }
    
    private func saveClosedIDs() {
        UserDefaults.standard.set(Array(closedIDs), forKey: Self.closedKey)
    }
    
    private static func storeURL(from string: String?) -> URL? {
        guard let string, let url = URL(string: string) else { return nil }
        let allowedSchemes = ["https", "itms-apps"]
        return allowedSchemes.contains(url.scheme?.lowercased() ?? "") ? url : nil
    }
}

// MARK: - Regole di validità
extension AppNotice {
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

struct AppVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    
    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init(_ string: String) {
        let n = string.split(separator: ".").map { Int($0) ?? 0 } + [0, 0, 0]
        self.init(n[0], n[1], n[2])
    }
    
    init(_ os: OperatingSystemVersion) {
        self.init(os.majorVersion, os.minorVersion, os.patchVersion)
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

extension Dictionary where Key == String, Value == String {
    func localized(for language: String) -> String {
        self[language] ?? self["en"] ?? values.first ?? ""
    }
}
