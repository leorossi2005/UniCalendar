//
//  UniversityDataManager.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation
#if canImport(Observation)
import Observation
#endif

@MainActor
#if canImport(Observation)
@Observable
#endif
public final class UniversityDataManager {
    public var years: [Year] = []
    public var courses: [Corso] = []
    public var academicYears: [Anno] = []
    
    public var loading: Bool = false
    public var errorMessage: String?
    
    private let service = NetworkService()
    private let cacheKey = "network_cache.json"
    
    public init() {}
    
    public func loadFromCache() {
        Task {
            if let cacheResponse = await CacheManager.shared.load(fileName: cacheKey, type: NetworkCacheData.self) {
                NetworkCache.shared.update(from: cacheResponse)
                self.years = NetworkCache.shared.years
            }
        }
    }
    
    public func clearCalendarCache() async {
        await CacheManager.shared.clear(fileName: "calendar_cache.json")
    }
    
    public func loadYears() async {
        await fetchAndRefresh(
            currentData: NetworkCache.shared.years,
            fetchOperation: { try await self.service.getYears() },
            updateState: { [weak self] newYears in
                NetworkCache.shared.years = newYears
                self?.years = newYears
            }
        )
    }
    
    public func loadCourses(year: String) async {
        self.loading = true
        defer { self.loading = false }
        
        await fetchAndRefresh(
            currentData: NetworkCache.shared.courses[year],
            fetchOperation: { try await self.service.getCourses(year: year) },
            updateState: { [weak self] newCourses in
                NetworkCache.shared.courses[year] = newCourses
                self?.courses = newCourses
            }
        )
    }
    
    public func updateAcademicYears(for courseValue: String, year: String) {
        guard let selectedCourse = courses.first(where: { $0.valore == courseValue }) else { return }
        self.academicYears = selectedCourse.elenco_anni
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        guard let anno = academicYears.first(where: { $0.valore == academicYearValue }) else { return false }
        
        return anno.elenco_insegnamenti.contains { item in
            let label = item.label.lowercased()
            return label.contains("matricole dispari") || label.contains("matricole pari")
        }
    }
    
    private func fetchAndRefresh<T: Sendable & Equatable>(
        currentData: T?,
        fetchOperation: @escaping @Sendable () async throws -> T,
        updateState: @escaping @MainActor (T) -> Void
    ) async {
        if let currentData, (currentData as? [Any])?.isEmpty == false {
            updateState(currentData)
        }
        
        Task {
            do {
                let newData = try await fetchOperation()
                if currentData != newData {
                    updateState(newData)
                    await saveCache()
                }
            } catch {
                if currentData == nil || (currentData as? [Any])?.isEmpty == true {
                    self.errorMessage = "Errore generico: \(error.localizedDescription)"
                }
                print(error)
            }
        }
    }
    
    private func saveCache() async {
        let data = NetworkCache.shared.toData()
        await CacheManager.shared.save(data, fileName: cacheKey)
    }
}
