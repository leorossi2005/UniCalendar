//
//  AppStatusManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 05/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class AppStatusManager {
    public private(set) var activeNotices: [AppNotice] = []
    public private(set) var allNotices: [AppNotice] = []
    public private(set) var isResolved = false
    public private(set) var shownThisSessionIDs: Set<String> = []
    
    private let service = NetworkService()
    private let resource = CachedResource<[AppNotice]>(cacheFileName: .appStatus, cacheManager: .shared)
    
    private var notices: [AppNotice] = []
    private var closedIDs: Set<String>
    private var isFetching = false
    private var lastCheck = Date.distantPast
    public private(set) var lastAttemptFailed = false
    
    private static let closedKey = "appStatus_closedIDs"
    
    public init() {
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
        if let notice = activeNotices.first(where: { $0.id == id }), notice.level != .blocking {
            closedIDs.insert(id)
            saveClosedIDs()
            evaluateCurrentState()
        }
    }
    
    public func dismissAllNonBlocking() {
        let nonBlocking = activeNotices.filter { $0.level != .blocking }
        guard !nonBlocking.isEmpty else { return }
        for notice in nonBlocking {
            closedIDs.insert(notice.id)
        }
        saveClosedIDs()
        evaluateCurrentState()
    }
    
    public func refreshIfNeeded() async {
        let hasBlocking = activeNotices.contains(where: { $0.level == .blocking })
        let interval: TimeInterval = if hasBlocking {
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
        
        let appVer = Bundle.main.clearAppVersion
        let osVer = Device.os.version
        
        do {
            notices = try await resource.refresh {
                try await self.service.getAppStatus(appVersion: appVer, osVersion: osVer)
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
        let active = notices.filter { !$0.isExpired }
        allNotices = active
        activeNotices = active.filter { notice in
            notice.level == .blocking || !closedIDs.contains(notice.id)
        }
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
}
