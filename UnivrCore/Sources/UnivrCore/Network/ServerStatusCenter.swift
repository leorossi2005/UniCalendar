//
//  ServerStatusCenter.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

enum TickContext: Sendable {
    @TaskLocal static var isHandler: Bool = false
}

@MainActor
@Observable
public final class ServerStatusCenter {
    public static let shared = ServerStatusCenter()
    
    public private(set) var isUnreachable: Bool = false
    public private(set) var isRetrying: Bool = false
    public private(set) var isUniVROffline: Bool = false
    public private(set) var isUniVRRetrying: Bool = false
    private var univrWaiters: Set<AnyHashable> = []
    private let univrAutoRetry = AutoRetry()
    private var isTickInProgress: Bool = false
    
    private var hadFailureInCurrentTick: Bool = false
    private var hadSuccessInCurrentTick: Bool = false
    private var blockedDuringTick: Bool = false
    private var lastSuccessAt: Date?
    private var handlers: [AnyHashable: @MainActor @Sendable () async -> Void] = [:]
    private let autoRetry = AutoRetry()
    
    private init() {}
    
    public func shouldBlockRequest(insideHandler: Bool) -> Bool {
        isUnreachable && !(isTickInProgress && insideHandler)
    }
    
    public func noteBlockedRequest() {
        if isTickInProgress {
            blockedDuringTick = true
        }
    }
    
    public func register(id: AnyHashable, handler: @escaping @MainActor @Sendable () async -> Void) {
        handlers[id] = handler
    }
    
    public func unregister(id: AnyHashable) {
        handlers.removeValue(forKey: id)
    }
    
    public func reportSuccess() {
        lastSuccessAt = Date()
        if isTickInProgress {
            hadSuccessInCurrentTick = true
        } else {
            isUnreachable = false
            autoRetry.cancel()
        }
    }

    public func reportUniVROffline() {
        guard !isUniVROffline else { return }
        isUniVROffline = true
    }

    public func reportUniVROnline() {
        guard isUniVROffline else { return }
        isUniVROffline = false
        if !univrWaiters.isEmpty && !isUniVRRetrying {
            Task { await self.performUniVRPass(onlyWaiters: true) }
        }
    }
    
    // MARK: - UniVR offline (indipendente da isUnreachable: non blocca mai le richieste)
    
    /// Registra/rimuove una risorsa che al momento è in `.univrOffline` e va ricaricata appena UniVR torna raggiungibile.
    public func setUniVRWaiting(id: AnyHashable, _ waiting: Bool) {
        if waiting {
            univrWaiters.insert(id)
            startUniVRLoopIfNeeded()
        } else {
            univrWaiters.remove(id)
            if univrWaiters.isEmpty {
                univrAutoRetry.cancel()
            }
        }
    }
    
    /// Retry manuale: esegue tutti gli handler registrati (come `retryNow`) senza toccare `isUnreachable`.
    public func retryUniVRNow() async {
        guard NetworkStatusMonitor.shared.status != .disconnected, !isUniVRRetrying else { return }
        univrAutoRetry.cancel()
        await performUniVRPass(onlyWaiters: false)
        if !univrWaiters.isEmpty {
            startUniVRLoopIfNeeded()
        }
    }
    
    private func performUniVRPass(onlyWaiters: Bool) async {
        guard !isUniVRRetrying else { return }
        isUniVRRetrying = true
        let ids = onlyWaiters ? Array(univrWaiters) : Array(handlers.keys)
        let currentHandlers = ids.compactMap { handlers[$0] }
        await withTaskGroup(of: Void.self) { group in
            for handler in currentHandlers {
                group.addTask {
                    await TickContext.$isHandler.withValue(true) {
                        await handler()
                    }
                }
            }
            await group.waitForAll()
        }
        isUniVRRetrying = false
    }
    
    private func startUniVRLoopIfNeeded() {
        univrAutoRetry.startIfNeeded(
            while: { [weak self] in
                guard let self else { return false }
                return !self.univrWaiters.isEmpty
                    && !self.isUnreachable
                    && NetworkStatusMonitor.shared.status != .disconnected
            },
            attempt: { [weak self] in
                await self?.performUniVRPass(onlyWaiters: true)
            }
        )
    }
    
    public func reportServerFailure(startedAt: Date = Date()) {
        if isTickInProgress {
            hadFailureInCurrentTick = true
            isUnreachable = true
        } else {
            if let lastSuccessAt, lastSuccessAt > startedAt {
                return
            }
            isUnreachable = true
            startLoopIfNeeded()
        }
    }
    
    public func networkDidReconnect() async {
        NetworkService.resetConnections()
        if isUnreachable {
            await retryNow()
        } else {
            await executeHandlersOnce()
        }
    }
    
    public func retryAfterForeground() async {
        NetworkService.resetConnections()
        await retryNow()
    }
    
    public func retryNow() async {
        guard NetworkStatusMonitor.shared.status != .disconnected else { return }
        guard !isTickInProgress else { return }
        autoRetry.cancel()
        await performTick()
        if isUnreachable {
            startLoop()
        }
    }
    
    public func executeHandlersOnce() async {
        guard !isTickInProgress else { return }
        let currentHandlers = Array(handlers.values)
        guard !currentHandlers.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for handler in currentHandlers {
                group.addTask {
                    await TickContext.$isHandler.withValue(true) {
                        await handler()
                    }
                }
            }
            await group.waitForAll()
        }
    }
    
    private func performTick() async {
        guard !isTickInProgress else { return }
        isTickInProgress = true
        isRetrying = true
        hadFailureInCurrentTick = false
        hadSuccessInCurrentTick = false
        blockedDuringTick = false
        
        let currentHandlers = Array(handlers.values)
        if !currentHandlers.isEmpty {
            await withTaskGroup(of: Void.self) { group in
                for handler in currentHandlers {
                    group.addTask {
                        await TickContext.$isHandler.withValue(true) {
                            await handler()
                        }
                    }
                }
                await group.waitForAll()
            }
        }
        
        if !hadFailureInCurrentTick && !hadSuccessInCurrentTick && isUnreachable {
            await TickContext.$isHandler.withValue(true) {
                _ = try? await NetworkService().getLocations()
            }
        }
        
        isRetrying = false
        isTickInProgress = false
        
        if hadFailureInCurrentTick {
            isUnreachable = true
        } else if hadSuccessInCurrentTick {
            isUnreachable = false
        }
        
        if !isUnreachable && blockedDuringTick {
            Task {
                await self.executeHandlersOnce()
            }
        }
    }
    
    private func startLoopIfNeeded() {
        autoRetry.startIfNeeded(
            while: { [weak self] in
                self?.isUnreachable == true && NetworkStatusMonitor.shared.status != .disconnected
            },
            attempt: { [weak self] in
                await self?.performTick()
            }
        )
    }
    
    private func startLoop() {
        autoRetry.start(
            while: { [weak self] in
                self?.isUnreachable == true && NetworkStatusMonitor.shared.status != .disconnected
            },
            attempt: { [weak self] in
                await self?.performTick()
            }
        )
    }
}
