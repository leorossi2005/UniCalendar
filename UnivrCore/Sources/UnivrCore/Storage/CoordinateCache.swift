//
//  CoordinateCache.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

public struct Coordinate: Sendable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public actor CoordinateCache {
    public static let shared = CoordinateCache()
    
    private var cache: [String: Coordinate] = [:]
    
    public func coordinate(for address: String) -> Coordinate? {
        cache[address]
    }
    
    public func save(_ coordinate: Coordinate, for address: String) {
        cache[address] = coordinate
    }
}
