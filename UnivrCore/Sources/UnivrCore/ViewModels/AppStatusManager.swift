//
//  AppStatusManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import SwiftUI

@MainActor
@Observable
public class AppStatusManager {
    public private(set) var activeNoticeAction: ActiveNoticeAction = .none
    public private(set) var isResolved: Bool = false
    public private(set) var closedNoticeIDs: Set<String> = []
    
    private let service = NetworkService()
    private let resource: CachedResource<[AppNotice]> = CachedResource(cacheFileName: .appStatus, cacheManager: .shared)
    private var notices: [AppNotice] = []
    
    private var isFetching = false
    private var lastNetworkCheck: Date = Date.distantPast
    private var lastAttemptFailed = false
    private let fallbackAppStoreURL = "https://apps.apple.com/app/idXXXXXXXXX"
    
    public init() {
        if let data = UserDefaults.standard.data(forKey: "appStatus_closedIDs"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.closedNoticeIDs = ids
        }
        
        #if DEBUG
        // Scommenta per testare gli avvisi a ogni avvio azzerando i popup già visti
        UserDefaults.standard.removeObject(forKey: "appStatus_closedIDs")
        #endif
        
        Task {
            await resource.loadFromDisk()
            self.notices = resource.value ?? []
            self.evaluateCurrentState()
        }
    }
    
    public func dismissNotice(id: String) {
        closedNoticeIDs.insert(id)
        if let data = try? JSONEncoder().encode(closedNoticeIDs) {
            UserDefaults.standard.set(data, forKey: "appStatus_closedIDs")
        }
        evaluateCurrentState()
    }
    
    public func refreshIfNeeded() async {
        let timeSinceLastCheck = Date().timeIntervalSince(lastNetworkCheck)
        
        var throttleInterval: TimeInterval = 3600
        if case .blocking = activeNoticeAction {
            throttleInterval = 30
        } else if lastAttemptFailed {
            throttleInterval = 300
        }
        
        if timeSinceLastCheck >= throttleInterval {
            await refresh()
        }
    }
    
    public func refresh() async {
        guard !isFetching else { return }
        isFetching = true
        lastNetworkCheck = Date()
        
        defer {
            isFetching = false
            isResolved = true
        }
        
        if resource.value == nil {
            await resource.loadFromDisk()
            if let val = resource.value {
                self.notices = val
            }
        }
        
        do {
            let fetchedNotices = try await resource.refresh {
                try await self.service.getAppStatus()
            }
            self.notices = fetchedNotices
            
            let validIds = Set(fetchedNotices.map { $0.id })
            closedNoticeIDs.formIntersection(validIds)
            if let data = try? JSONEncoder().encode(closedNoticeIDs) {
                UserDefaults.standard.set(data, forKey: "appStatus_closedIDs")
            }
            
            lastAttemptFailed = false
        } catch {
            print("AppStatusManager: errore nel recupero dello stato dell'app: \(error)")
            lastAttemptFailed = true
        }
        
        evaluateCurrentState()
    }
    
    public func evaluateCurrentState() {
        let appV = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osV = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let preferredLang = Bundle.main.preferredLocalizations.first ?? "en"
        let currentDate = Date()
        
        let appVersionNorm = normalizeVersion(appV)
        let currentOS = normalizeVersion(osV)
        
        let validNotices = notices.compactMap { notice -> (AppNotice, NoticeLevel)? in
            if let starts = notice.startsAt, currentDate < starts { return nil }
            if let ends = notice.endsAt, currentDate > ends { return nil }
            
            if let minV = notice.minVersion, appVersionNorm.compare(normalizeVersion(minV), options: .numeric) == .orderedAscending {
                return nil
            }
            if let maxV = notice.maxVersion, appVersionNorm.compare(normalizeVersion(maxV), options: .numeric) == .orderedDescending {
                return nil
            }
            
            if notice.level == .blocking && notice.maxVersion == nil {
                return nil
            }
            
            var effectiveLevel = notice.level
            
            if effectiveLevel == .blocking, let reqOS = notice.updateRequiresOS {
                let req = normalizeVersion(reqOS)
                if currentOS.compare(req, options: .numeric) == .orderedAscending {
                    effectiveLevel = .warning
                }
            }
            
            if effectiveLevel != .blocking && closedNoticeIDs.contains(notice.id) {
                return nil
            }
            
            return (notice, effectiveLevel)
        }
        
        let sorted = validNotices.sorted { t1, t2 in
            let w1 = weight(for: t1.1)
            let w2 = weight(for: t2.1)
            if w1 != w2 { return w1 > w2 }
            
            let d1 = t1.0.startsAt ?? Date.distantPast
            let d2 = t2.0.startsAt ?? Date.distantPast
            return d1 > d2
        }
        
        guard let (winner, finalLevel) = sorted.first else {
            self.activeNoticeAction = .none
            return
        }
        
        var localizedMessage = localizedText(for: winner.message, preferredLanguage: preferredLang)
        var actionURLString: String? = winner.url
        
        if finalLevel == .warning && winner.level == .blocking {
            if let unsupportedMessage = winner.messageUnsupportedOS {
                localizedMessage = localizedText(for: unsupportedMessage, preferredLanguage: preferredLang)
            }
            actionURLString = nil
        }
        
        var finalURL: URL? = nil
        if let urlStr = actionURLString, (urlStr.hasPrefix("https://apps.apple.com/") || urlStr.hasPrefix("itms-apps://")) {
            finalURL = URL(string: urlStr)
        } else if finalLevel == .blocking {
            finalURL = URL(string: fallbackAppStoreURL)
        }
        
        let evaluated = EvaluatedNotice(
            id: winner.id,
            level: finalLevel,
            title: localizedText(for: winner.title, preferredLanguage: preferredLang),
            message: localizedMessage,
            actionURL: finalURL
        )
        
        switch finalLevel {
        case .blocking:
            self.activeNoticeAction = .blocking(evaluated)
        case .warning:
            self.activeNoticeAction = .warning(evaluated)
        case .info:
            self.activeNoticeAction = .info(evaluated)
        }
    }
    
    private func localizedText(for dict: [String: String]?, preferredLanguage: String) -> String {
        guard let dict = dict else { return "" }
        return dict[preferredLanguage] ?? dict["en"] ?? dict.values.first ?? ""
    }
    
    private func normalizeVersion(_ v: String) -> String {
        var parts = v.split(separator: ".")
        while parts.count < 3 {
            parts.append("0")
        }
        return parts.joined(separator: ".")
    }
    
    private func weight(for level: NoticeLevel) -> Int {
        switch level {
        case .blocking: return 3
        case .warning: return 2
        case .info: return 1
        }
    }
}
