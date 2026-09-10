//
//  NetworkMonitor.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 20/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum NetworkStatus: Sendable, Equatable {
    case connected
    case disconnected
}

public struct NetworkProvider: Sendable {
    public var statusStream: @Sendable () -> AsyncStream<NetworkStatus>
    
    public init(statusStream: @escaping @Sendable () -> AsyncStream<NetworkStatus>) {
        self.statusStream = statusStream
    }
}

@MainActor
@Observable
public final class NetworkStatusMonitor {
    public static let shared = NetworkStatusMonitor()
    
    public private(set) var status: NetworkStatus = .connected
    private var listenTask: Task<Void, Never>?
    
    private init() {}
    
    public func start(provider: NetworkProvider) {
        listenTask?.cancel()
        listenTask = Task {
            for await newStatus in provider.statusStream() {
                self.status = newStatus
            }
        }
    }
}
