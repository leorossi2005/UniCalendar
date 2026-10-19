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
    private var coursesResource: CachedResource<[Course]>?
    private var currentCoursesYear: String = ""
    private var activeResource: Resource = .years
    
    private var yearsTask: Task<Void, Error>?
    private var coursesTask: Task<Void, Error>?
    private var coursesTaskYear: String?
    private var locationsTask: Task<Void, Error>?

    private enum Resource {
        case years
        case courses
    }
    
    public var years: [AcademicYear] { yearsResource.value ?? [] }
    public var coursesYear: String { currentCoursesYear }
    public var courses: [Course] { coursesResource?.value ?? [] }
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
    
    @discardableResult
    public func prefetch(preferredYear: String?) async -> String? {
        guard !isOffline else { return nil }
        Task { await prefetchLocations() }
        do { try await ensureYears() } catch { return nil }

        let year = years.contains(where: { $0.id == preferredYear })
            ? preferredYear
            : years.first?.id
        guard let year, year != "0" else { return nil }

        Task { try? await ensureCourses(year: year) }
        return year
    }

    public func prefetchLocations() async {
        guard locationsTask == nil else { return }
        let task = Task {
            defer { locationsTask = nil }
            let locationsResource = CachedResource<[String: String]>(cacheFileName: .locations, cacheManager: cacheManager)
            try await locationsResource.refreshStaleWhileRevalidate {
                try await self.service.getLocations()
            }
        }
        locationsTask = task
        try? await task.value
    }
    
    public func ensureYears() async throws {
        if !years.isEmpty { return }
        if yearsTask == nil {
            yearsTask = Task {
                defer { yearsTask = nil }
                try await loadYears()
            }
        }
        try await yearsTask?.value
    }

    public func ensureCourses(year: String) async throws {
        if coursesTaskYear == year, let task = coursesTask {
            try await task.value
            return
        }
        
        if currentCoursesYear == year, !courses.isEmpty { return }

        coursesTask?.cancel()
        resetCourses()

        coursesTaskYear = year
        let task = Task {
            defer {
                if coursesTaskYear == year {
                    coursesTask = nil
                    coursesTaskYear = nil
                }
            }
            try await loadCourses(year: year)
        }
        coursesTask = task
        try await task.value
    }

    public func cancelAll() {
        yearsTask?.cancel(); yearsTask = nil
        coursesTask?.cancel(); coursesTask = nil
        coursesTaskYear = nil
        locationsTask?.cancel(); locationsTask = nil
    }
    
    public func resetCourses() {
        currentCoursesYear = ""
        coursesResource = nil
    }
    
    public func loadYears() async throws {
        activeResource = .years
        try await yearsResource.refreshStaleWhileRevalidate(fetch: { try await self.service.getYears() })
    }
    
    public func loadCourses(year: String) async throws {
        guard year != "0", !year.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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
