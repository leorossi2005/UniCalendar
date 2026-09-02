//
//  CachedResource.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 01/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

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
    public enum State: Equatable {
        case idle
        case loading
        case loaded(T)
        case offline
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var value: T?

    private let cacheFileName: CacheFile?
    private let cacheManager: CacheManager

    init(cacheFileName: CacheFile? = nil, cacheManager: CacheManager = .shared) {
        self.cacheFileName = cacheFileName
        self.cacheManager = cacheManager
    }

    func loadFromDisk() async {
        guard let cacheFileName, value == nil,
              let cached = await cacheManager.load(file: cacheFileName, type: T.self) else { return }
        value = cached
        state = .loaded(cached)
    }

    @discardableResult
    func refresh(fetch: @Sendable () async throws -> T) async throws -> T {
        state = .loading
        do {
            let fresh = try await fetch()
            try Task.checkCancellation()
            value = fresh
            state = .loaded(fresh)
            if let cacheFileName { await cacheManager.save(fresh, file: cacheFileName) }
            return fresh
        } catch let error as NetworkError {
            switch error {
            case .offline: state = .offline
            default: state = .error(error.errorDescription ?? String(localized: "Errore sconosciuto", bundle: .module))
            }
            throw error
        } catch {
            if error is CancellationError { throw error }
            state = .error(String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module))
            throw error
        }
    }
    
    @discardableResult
    func refreshStaleWhileRevalidate(fetch: @escaping @Sendable () async throws -> T) async throws -> T {
        if value == nil { await loadFromDisk() }
        
        if let currentValue = value {
            Task { try? await self.refresh(fetch: fetch) }
            return currentValue
        }
        return try await refresh(fetch: fetch)
    }

    func clear() async {
        value = nil
        state = .idle
        if let cacheFileName {
            await cacheManager.clear(file: cacheFileName)
        }
    }
}
