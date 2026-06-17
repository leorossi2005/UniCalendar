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
    public var years: [AcademicYear] = []
    public var courses: [Corso] = []
    public var academicYears: [AcademicYear] = []
    
    public var loading: Bool = false
    public var errorMessage: String?
    
    private let service = NetworkService()
    private let cacheKey = "network_cache.json"
    
    public init() {}
    
    public func loadFromCache() async {
        if let cacheResponse = await CacheManager.shared.load(fileName: cacheKey, type: NetworkCacheData.self) {
            NetworkCache.shared.update(from: cacheResponse)
            self.years = NetworkCache.shared.years
        }
    }
    
    public func clearCalendarCache() async {
        await CacheManager.shared.clear(fileName: "calendar_cache.json")
    }
    
    public func loadYears() async throws {
        try await fetchAndRefresh(
            currentData: NetworkCache.shared.years,
            fetchOperation: { try await self.service.getYears() },
            updateState: { [weak self] newYears in
                NetworkCache.shared.years = newYears
                self?.years = newYears
            }
        )
    }
    
    public func loadCourses(year: String) async throws {
        self.loading = true
        defer { self.loading = false }
        
        try await fetchAndRefresh(
            currentData: NetworkCache.shared.courses[year] ?? [],
            fetchOperation: { try await self.service.getCourses(year: year) },
            updateState: { [weak self] newCourses in
                NetworkCache.shared.courses[year] = newCourses
                self?.courses = newCourses
            }
        )
    }
    
    public func updateAcademicYears(for courseValue: String) {
        self.academicYears = courses.first(where: { $0.id == courseValue })?.years ?? []
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        return academicYears.first(where: { $0.id == academicYearValue })?.hasGroup ?? false
    }
    
    private func fetchAndRefresh<T: Collection & Equatable & Sendable >(
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
        let data = NetworkCache.shared.toData()
        await CacheManager.shared.save(data, fileName: cacheKey)
    }
}
