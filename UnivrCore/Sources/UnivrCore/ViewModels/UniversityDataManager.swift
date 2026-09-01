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
    
    public var years: [AcademicYear] { yearsResource.value ?? [] }
    public var courses: [Corso] { coursesResource?.value ?? [] }
    public var academicYears: [AcademicYear] = []
    
    public var loading: Bool = false
    public var errorMessage: String?
    
    public init() {}
    
    public func resetCourses() {
        currentCoursesYear = ""
        coursesResource = nil
    }
    
    public func loadYears() async throws {
        do {
            try await yearsResource.refreshStaleWhileRevalidate(fetch: { try await self.service.getYears() })
        } catch {
            errorMessage = friendlyMessage(for: error)
            throw error
        }
    }
    
    public func loadCourses(year: String) async throws {
        if year != currentCoursesYear || coursesResource == nil {
            currentCoursesYear = year
            coursesResource = CachedResource(cacheFileName: .courses(year: year), cacheManager: cacheManager)
        }
        
        self.loading = true
        defer { self.loading = false }
        
        do {
            try await coursesResource?.refreshStaleWhileRevalidate(fetch: { try await self.service.getCourses(year: year) })
        } catch {
            errorMessage = friendlyMessage(for: error)
            throw error
        }
    }
    
    public func updateAcademicYears(for courseValue: String) {
        self.academicYears = courses.first(where: { $0.id == courseValue })?.years ?? []
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        return academicYears.first(where: { $0.id == academicYearValue })?.hasGroup ?? false
    }
    
    private func friendlyMessage(for error: Error) -> String {
        (error as? NetworkError)?.errorDescription ?? String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module)
    }
}
