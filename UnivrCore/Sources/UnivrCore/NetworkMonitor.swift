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
