//
//  AvailabilityManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 21/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class AvailabilityDataManager {
    public var locations: [String: String] = [:]
    public var rooms: [Room]?
    
    public var loading: Bool = false
    public var errorMessage: String?
    
    private let service = NetworkService()
    
    public init() {}
    
    public func getAvailability(locationKey: String, date: String) async throws {
        rooms = nil
        if !locationKey.isEmpty {
            try await fetchAndRefresh(
                fetchOperation: { try await self.service.getAvailability(date: date) },
                updateState: { [weak self] availability in
                    self?.locations = availability.locations
                    self?.rooms = availability.events[locationKey]
                }
            )
        }
    }
    
    private func fetchAndRefresh(
        fetchOperation: @escaping @Sendable () async throws -> Availability,
        updateState: @escaping @MainActor (Availability) -> Void
    ) async throws {
        do {
            let newData = try await fetchOperation()
            updateState(newData)
        } catch let error as NetworkError {
            self.errorMessage = error.errorDescription
            throw error
        } catch {
            self.errorMessage = String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module)
            throw error
        }
    }
}
