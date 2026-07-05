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
    private var lastFetch: Availability? = nil
    private var lastDate: String = ""
    
    public init() {}
    
    public func getAvailability(locationKey: String, date: Date) async throws {
        rooms = nil
        let dateString = String(format: "%02d-%02d-%04d", date.day, date.month, date.year)
        if !locationKey.isEmpty {
            if lastFetch == nil || lastDate != dateString {
                lastDate = dateString
                try await fetchAndRefresh(
                    fetchOperation: { try await self.service.getAvailability(date: dateString) },
                    updateState: { [weak self] availability in
                        self?.lastFetch = availability
                        self?.locations = availability.locations
                        self?.rooms = availability.events[locationKey]
                    }
                )
            } else if lastFetch != nil {
                rooms = lastFetch?.events[locationKey]
            }
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
