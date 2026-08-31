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
    private let cache: NetworkCache = .shared
    private let service: NetworkService = .init()
    private let cacheManager: CacheManager = .shared
    private let cacheFileName = "network_cache.json"
    
    private var currentCoursesYear: String = ""
    
    public var years: [AcademicYear] { cache.years }
    public var courses: [Corso] { cache.courses[currentCoursesYear] ?? [] }
    public var academicYears: [AcademicYear] = []
    
    public var loading: Bool = false
    public var errorMessage: String?
    
    public init() {}
    
    public func loadFromCache() async {
        if let cacheResponse = await cacheManager.load(fileName: cacheFileName, type: NetworkCacheData.self) {
            cache.update(from: cacheResponse)
        }
    }
    
    public func clearCalendarCache() async {
        await cacheManager.clear(fileName: "calendar_cache.json")
    }
    
    public func resetCourses() {
        currentCoursesYear = ""
    }
    
    public func loadYears() async throws {
        try await fetchAndRefresh(
            currentData: cache.years,
            fetchOperation: { try await self.service.getYears() },
            updateState: { [weak self] newYears in
                self?.cache.years = newYears
            }
        )
    }
    
    public func loadCourses(year: String) async throws {
        currentCoursesYear = year
        self.loading = true
        defer { self.loading = false }
        
        try await fetchAndRefresh(
            currentData: cache.courses[year] ?? [],
            fetchOperation: { try await self.service.getCourses(year: year) },
            updateState: { [weak self] newCourses in
                self?.cache.courses[year] = newCourses
            }
        )
    }
    
    public func updateAcademicYears(for courseValue: String) {
        self.academicYears = courses.first(where: { $0.id == courseValue })?.years ?? []
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        return academicYears.first(where: { $0.id == academicYearValue })?.hasGroup ?? false
    }
    
    private func fetchAndRefresh<T: Collection & Equatable & Sendable>(
        currentData: T,
        fetchOperation: @escaping @Sendable () async throws -> T,
        updateState: @escaping @MainActor (T) -> Void
    ) async throws {
        if !currentData.isEmpty {
            updateState(currentData)
            
            Task {
                guard let newData = try? await fetchOperation(), currentData != newData else { return }
                updateState(newData)
                await saveCache()
            }
            
            return
        }
        
        do {
            let newData = try await fetchOperation()
            updateState(newData)
            await saveCache()
        } catch let error as NetworkError {
            self.errorMessage = error.errorDescription
            throw error
        } catch {
            self.errorMessage = String(localized: "Errore generico: \(error.localizedDescription)", bundle: .module)
            throw error
        }
    }
    
    private func saveCache() async {
        let data = cache.toData()
        await cacheManager.save(data, fileName: cacheFileName)
    }
}
