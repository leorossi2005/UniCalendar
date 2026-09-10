//
//  NetworkMonitor.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import Network
import UnivrCore

final class IOSNetworkMonitor: Sendable {
    static func createProvider() -> NetworkProvider {
        return NetworkProvider {
            AsyncStream { continuation in
                let monitor = NWPathMonitor()
                let queue = DispatchQueue(label: "IOSNetworkMonitor.Queue")
                
                monitor.pathUpdateHandler = { path in
                    let status: NetworkStatus = (path.status == .satisfied) ? .connected : .disconnected
                    continuation.yield(status)
                }
                
                monitor.start(queue: queue)
                
                continuation.onTermination = { @Sendable _ in
                    monitor.cancel()
                }
            }
        }
    }
}
