//
//  ServerStatusCenter.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum TickContext: Sendable {
    @TaskLocal public static var isHandler: Bool = false
}

@MainActor
@Observable
public final class ServerStatusCenter {
    public static let shared = ServerStatusCenter()
    
    public private(set) var isUnreachable: Bool = false
    public private(set) var isRetrying: Bool = false
    public private(set) var isTickInProgress: Bool = false
    
    private var hadFailureInCurrentTick: Bool = false
    private var hadSuccessInCurrentTick: Bool = false
    private var blockedDuringTick: Bool = false
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
        if isTickInProgress {
            hadSuccessInCurrentTick = true
        } else {
            isUnreachable = false
            autoRetry.cancel()
        }
    }
    
    public func reportServerFailure() {
        if isTickInProgress {
            hadFailureInCurrentTick = true
            isUnreachable = true
        } else {
            isUnreachable = true
            startLoopIfNeeded()
        }
    }
    
    public func retryNow() async {
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
            await executeHandlersOnce()
        }
    }
    
    private func startLoopIfNeeded() {
        autoRetry.startIfNeeded(
            while: { [weak self] in self?.isUnreachable == true },
            attempt: { [weak self] in
                await self?.performTick()
            }
        )
    }
    
    private func startLoop() {
        autoRetry.start(
            while: { [weak self] in self?.isUnreachable == true },
            attempt: { [weak self] in
                await self?.performTick()
            }
        )
    }
}
