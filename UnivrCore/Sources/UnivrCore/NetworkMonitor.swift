//
//  NetworkMonitor.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 20/12/25.
//

import Foundation

#if canImport(Network)
import Network
#endif

#if canImport(Observation)
import Observation
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum NetworkStatus: Sendable, Equatable {
    case connected
    case disconnected
}

@MainActor
#if canImport(Observation)
@Observable
#endif
public final class NetworkMonitor: @unchecked Sendable {

    public static let shared = NetworkMonitor()

    public private(set) var status: NetworkStatus = .connected

    #if canImport(Network)
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor.NWPathMonitor")
    #else
    private var pollTimer: Timer?
    #endif

    private init() {
        #if canImport(Network)
        self.monitor = NWPathMonitor()
        startMonitoring()
        #else
        startAndroidPolling()
        #endif
    }

    deinit {
        #if canImport(Network)
        monitor.cancel()
        #else
        pollTimer?.invalidate()
        pollTimer = nil
        #endif
    }

    // MARK: - Apple platforms (NWPathMonitor)

    #if canImport(Network)
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                
                if path.status == .satisfied {
                    self.status = .connected
                } else {
                    self.status = .disconnected
                }
            }
        }

        monitor.start(queue: queue)
    }
    #endif

    // MARK: - Fallback (polling)

    #if !canImport(Network)
    private func startAndroidPolling() {
        Task { await checkConnection() }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { await self?.checkConnection() }
        }
    }

    private func checkConnection() async {
        guard let url = URL(string: "https://www.google.com") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                status = .connected
            } else {
                status = .disconnected
            }
        } catch {
            status = .disconnected
        }
    }
    #endif
}
