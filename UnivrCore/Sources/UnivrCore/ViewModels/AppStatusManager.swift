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
    
    private let service = NetworkService()
    private let resource = CachedResource<[AppNotice]>(cacheFileName: .appStatus, cacheManager: .shared)
    
    private var notices: [AppNotice] = []
    private var closedIDs: Set<String>
    private var isFetching = false
    private var lastCheck = Date.distantPast
    private var lastAttemptFailed = false
    
    private static let closedKey = "appStatus_closedIDs"
    private static let fallbackStoreURL = URL(string: "https://apps.apple.com/app/idXXXXXXXXX")
    
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
        let isWebStore = url.scheme == "https" && url.host() == "apps.apple.com"
        return (isWebStore || url.scheme == "itms-apps") ? url : nil
    }
}
