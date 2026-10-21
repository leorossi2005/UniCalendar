//
//  AutoRetry.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
final class AutoRetry {
    private var task: Task<Void, Never>?
    private var generation: Int = 0
    private(set) var isRunning: Bool = false
    private let backoffDelays: [Double] = [5, 10, 20, 40, 60]
    
    init() {}
    
    func startIfNeeded(
        while condition: @escaping @MainActor () -> Bool,
        attempt: @escaping @MainActor () async -> Void
    ) {
        guard !isRunning else { return }
        start(while: condition, attempt: attempt)
    }
    
    func start(
        while condition: @escaping @MainActor () -> Bool,
        attempt: @escaping @MainActor () async -> Void
    ) {
        cancel()
        generation += 1
        let currentGen = generation
        isRunning = true
        task = Task { [weak self] in
            defer {
                if let self, self.generation == currentGen {
                    self.isRunning = false
                }
            }
            guard let self else { return }
            var attemptIndex = 0
            while !Task.isCancelled && condition() {
                let baseDelay = attemptIndex < self.backoffDelays.count ? self.backoffDelays[attemptIndex] : 60.0
                let jitter = Double.random(in: 0.0...1.0)
                let totalDelay = baseDelay + jitter
                
                try? await Task.sleep(for: .seconds(totalDelay))
                guard !Task.isCancelled, condition() else { return }
                
                await attempt()
                attemptIndex += 1
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        isRunning = false
    }
}
