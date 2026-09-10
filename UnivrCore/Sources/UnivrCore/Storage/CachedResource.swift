//
//  CachedResource.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 01/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum ResourcePhase: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case empty
    case offline
    case error(String)
}

public enum CacheFile: Equatable, Sendable {
    case years
    case courses(year: String)
    case calendarSchedule
    
    var fileName: String {
        switch self {
        case .years: return "years_cache.json"
        case .courses(let year): return "courses_\(year)_cache.json"
        case .calendarSchedule: return "calendar_cache.json"
        }
    }
}

@MainActor
@Observable
final class CachedResource<T: Codable & Equatable & Sendable> {
    private(set) var phase: ResourcePhase = .idle
    private(set) var value: T?
    var hasLastFetch: Bool { lastFetch != nil }

    private let cacheFileName: CacheFile?
    private let cacheManager: CacheManager
    private var lastFetch: (@Sendable () async throws -> T)?

    init(cacheFileName: CacheFile? = nil, cacheManager: CacheManager = .shared) {
        self.cacheFileName = cacheFileName
        self.cacheManager = cacheManager
        observeNetworkStatus()
    }

    // MARK: - Network reactivity
    private func observeNetworkStatus() {
        withObservationTracking {
            _ = NetworkStatusMonitor.shared.status
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleNetworkChange(NetworkStatusMonitor.shared.status)
                self.observeNetworkStatus()
            }
        }
    }

    private func handleNetworkChange(_ status: NetworkStatus) {
        switch status {
        case .disconnected:
            if value == nil { phase = .offline }
        case .connected:
            if let lastFetch {
                Task { try? await self.refresh(fetch: lastFetch) }
            }
        }
    }

    func loadFromDisk() async {
        guard let cacheFileName, value == nil,
              let cached = await cacheManager.load(file: cacheFileName, type: T.self) else { return }
        value = cached
        phase = .loaded
    }

    @discardableResult
    func refresh(fetch: @escaping @Sendable () async throws -> T) async throws -> T {
        lastFetch = fetch
        phase = .loading
        do {
            let fresh = try await fetch()
            try Task.checkCancellation()
            value = fresh
            phase = .loaded
            if let cacheFileName { await cacheManager.save(fresh, file: cacheFileName) }
            return fresh
        } catch {
            if error is CancellationError { throw error }
            if isOfflineFailure(error) {
                phase = .offline
            } else if let networkError = error as? NetworkError {
                phase = .error(networkError.errorDescription ?? String(localized: "Errore sconosciuto", bundle: .module))
            } else {
                phase = .error(String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module))
            }
            throw error
        }
    }
    
    private func isOfflineFailure(_ error: Error) -> Bool {
        if NetworkStatusMonitor.shared.status == .disconnected { return true }
        if case NetworkError.offline = error { return true }
        return false
    }
    
    @discardableResult
    func refreshStaleWhileRevalidate(fetch: @escaping @Sendable () async throws -> T) async throws -> T {
        if value == nil { await loadFromDisk() }
        
        if let currentValue = value {
            lastFetch = fetch
            Task { try? await self.refresh(fetch: fetch) }
            return currentValue
        }
        return try await refresh(fetch: fetch)
    }

    func clear() async {
        value = nil
        phase = .idle
        lastFetch = nil
        if let cacheFileName {
            await cacheManager.clear(file: cacheFileName)
        }
    }

}
