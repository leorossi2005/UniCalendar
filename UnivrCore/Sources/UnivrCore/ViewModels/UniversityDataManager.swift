//
//  UniversityDataManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 19/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class UniversityDataManager {
    private let service: NetworkService = .init()
    private let cacheManager: CacheManager = .shared
    
    private let yearsResource: CachedResource<[AcademicYear]> = CachedResource(cacheFileName: .years, cacheManager: .shared)
    private var coursesResource: CachedResource<[Corso]>?
    private var currentCoursesYear: String = ""
    private var activeResource: Resource = .years

    private enum Resource {
        case years
        case courses
    }
    
    public var years: [AcademicYear] { yearsResource.value ?? [] }
    public var courses: [Corso] { coursesResource?.value ?? [] }
    public var academicYears: [AcademicYear] = []
    
    public var isOffline: Bool { NetworkStatusMonitor.shared.status == .disconnected }
    public var errorMessage: String? {
        let phase = switch activeResource {
        case .years: yearsResource.phase
        case .courses: coursesResource?.phase ?? .idle
        }

        guard case .error(let message) = phase else { return nil }
        return message
    }
    
    public init() {}
    
    public func resetCourses() {
        currentCoursesYear = ""
        coursesResource = nil
    }
    
    public func loadYears() async throws {
        activeResource = .years
        try await yearsResource.refreshStaleWhileRevalidate(fetch: { try await self.service.getYears() })
    }
    
    public func loadCourses(year: String) async throws {
        activeResource = .courses
        if year != currentCoursesYear || coursesResource == nil {
            currentCoursesYear = year
            coursesResource = CachedResource(cacheFileName: .courses(year: year), cacheManager: cacheManager)
        }
        
        try await coursesResource?.refreshStaleWhileRevalidate(fetch: { try await self.service.getCourses(year: year) })
    }
    
    public func updateAcademicYears(for courseValue: String) {
        self.academicYears = courses.first(where: { $0.id == courseValue })?.years ?? []
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        return academicYears.first(where: { $0.id == academicYearValue })?.hasGroup ?? false
    }
    
}
