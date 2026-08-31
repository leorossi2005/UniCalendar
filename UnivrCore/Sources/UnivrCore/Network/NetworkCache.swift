//
//  NetworkCache.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct NetworkCacheData: Codable, Sendable {
    public let years: [AcademicYear]
    public let courses: [String: [Corso]]
}

@MainActor
@Observable
public final class NetworkCache: Sendable {
    public static let shared = NetworkCache()
    
    public var years: [AcademicYear] = []
    public var courses: [String: [Corso]] = [:]
    
    private init() {}
    
    public func toData() -> NetworkCacheData {
        return NetworkCacheData(years: self.years, courses: self.courses)
    }
    
    public func update(from data: NetworkCacheData) {
        self.years = data.years
        self.courses = data.courses
    }
}
