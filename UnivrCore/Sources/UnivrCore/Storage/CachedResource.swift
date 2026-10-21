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
    case serverUnreachable
    case error(String)
}

public enum CacheFile: Equatable, Sendable {
    case years
    case courses(year: String)
    case calendarSchedule
    case appStatus
    case locations
    
    var fileName: String {
        switch self {
        case .years: return "years_cache.json"
        case .courses(let year): return "courses_\(year)_cache.json"
        case .calendarSchedule: return "calendar_cache.json"
        case .appStatus: return "appStatus_cache.json"
        case .locations: return "locations_cache.json"
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
    private let autoSaveToDisk: Bool
    private var lastFetch: (@Sendable () async throws -> T)?
    private var generation = 0

    init(cacheFileName: CacheFile? = nil, cacheManager: CacheManager = .shared, autoSaveToDisk: Bool = true) {
        self.cacheFileName = cacheFileName
        self.cacheManager = cacheManager
        self.autoSaveToDisk = autoSaveToDisk
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
            break
        }
    }

    func loadFromDisk() async {
        guard let cacheFileName,
              let cached = await cacheManager.load(file: cacheFileName, type: T.self) else { return }
        value = cached
        phase = .loaded
    }

    func saveToDisk(_ data: T? = nil) async {
        guard let cacheFileName else { return }
        let target = data ?? value
        if let target {
            value = target
            await cacheManager.save(target, file: cacheFileName)
        }
    }

    @discardableResult
    func refresh(fetch: @escaping @Sendable () async throws -> T) async throws -> T {
        generation += 1
        let myGen = generation
        let previous = phase
        lastFetch = fetch
        phase = .loading
        do {
            let fresh = try await fetch()
            try Task.checkCancellation()
            if generation == myGen {
                value = fresh
                phase = .loaded
                if autoSaveToDisk, let cacheFileName { await cacheManager.save(fresh, file: cacheFileName) }
            }
            return fresh
        } catch {
            if error is CancellationError {
                if generation == myGen {
                    phase = previous == .loading ? (value == nil ? .idle : .loaded) : previous
                }
                throw error
            }
            if generation == myGen {
                if isOfflineFailure(error) {
                    phase = .offline
                } else if isServerUnreachableFailure(error) {
                    phase = .serverUnreachable
                } else if let networkError = error as? NetworkError {
                    phase = .error(networkError.errorDescription ?? String(localized: .unknownError))
                } else {
                    phase = .error(String(localized: .genericError(error.localizedDescription)))
                }
            }
            throw error
        }
    }
    
    private func isOfflineFailure(_ error: Error) -> Bool {
        if NetworkStatusMonitor.shared.status == .disconnected { return true }
        if case NetworkError.offline = error { return true }
        return false
    }
    
    private func isServerUnreachableFailure(_ error: Error) -> Bool {
        if case NetworkError.serverUnreachable = error { return true }
        if case NetworkError.timeout = error { return true }
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
        generation += 1
        value = nil
        phase = .idle
        lastFetch = nil
        if let cacheFileName {
            await cacheManager.clear(file: cacheFileName)
        }
    }

}
