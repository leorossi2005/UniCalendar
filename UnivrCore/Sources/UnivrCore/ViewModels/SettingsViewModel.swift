//
//  SettingsViewModel.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

@Observable
public class SettingsViewModel {
    public var years: [Year] = []
    public var courses: [Corso] = []
    public var academicYears: [Anno] = []
    
    var loading: Bool = false
    var errorMessage: String? = nil
    
    private let cacheKey = "network_cache.json"
    
    private let networkService: NetworkService
    
    public init(service: NetworkService = NetworkService()){
        self.networkService = service
    }
    
    public func loadFromCache() {
        if let cacheResponse = NetworkCacheManager.shared.load(fileName: cacheKey, type: NetworkCache.self) {
            NetworkCache.shared.years = cacheResponse.years
            NetworkCache.shared.courses = cacheResponse.courses
            NetworkCache.shared.academicYears = cacheResponse.academicYears
        }
    }
    
    nonisolated private func updateCache() {
        let cacheObject = NetworkCache.shared
        NetworkCacheManager.shared.save(cacheObject, fileName: cacheKey)
    }
    
    @MainActor
    public func loadYears() async {
        var newYears: [Year] = []
        if NetworkCache.shared.years.isEmpty {
            do {
                newYears = try await networkService.getYears()
            } catch {
                self.errorMessage = String(localized: "Errore caricamento anni: \(error.localizedDescription)")
            }
        } else {
            newYears = NetworkCache.shared.years
        }
        
        let oldNetworkCache = NetworkCache.shared.years
        NetworkCache.shared.years = newYears
        self.years = newYears
        
        Task.detached { [self] in
            do {
                let newYears = try await networkService.getYears()
                
                if newYears != oldNetworkCache {
                    NetworkCache.shared.years = newYears
                    
                    updateCache()
                    
                    await MainActor.run {
                        self.years = newYears
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    @MainActor
    public func loadCourses(year: String) async {
        self.loading = true
        
        var newCourses: [Corso] = []
        if NetworkCache.shared.courses[year] == nil {
            do {
                newCourses = try await networkService.getCourses(year: year)
            } catch {
                self.errorMessage = String(localized: "Errore caricamento corsi: \(error.localizedDescription)")
                print(error)
            }
        } else {
            newCourses = NetworkCache.shared.courses[year]!
        }
        
        let oldNetworkCache = NetworkCache.shared.courses[year] ?? nil
        NetworkCache.shared.courses[year] = newCourses
        self.courses = newCourses
        
        self.loading = false
        
        Task.detached { [self] in
            do {
                let newCourses = try await networkService.getCourses(year: year)
                
                if newCourses != oldNetworkCache {
                    NetworkCache.shared.courses[year] = newCourses
                    
                    updateCache()
                    
                    await MainActor.run {
                        self.courses = newCourses
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    public func updateAcademicYears(for courseValue: String, year: String) {
        var newAcademicYears: [Anno] = []
        if NetworkCache.shared.academicYears[year]?[courseValue] == nil {
            guard let selectedCorso = courses.first(where: { $0.valore == courseValue }) else {
                return
            }
            
            newAcademicYears = selectedCorso.elenco_anni
        } else {
            newAcademicYears = NetworkCache.shared.academicYears[year]![courseValue]!
        }
        
        let oldNetworkCache = NetworkCache.shared.academicYears[year]?[courseValue] ?? nil
        NetworkCache.shared.academicYears[year]?[courseValue] = newAcademicYears
        self.academicYears = newAcademicYears
        
        Task.detached { [self] in
            guard let selectedCorso = await courses.first(where: { $0.valore == courseValue }) else {
                return
            }
            
            if selectedCorso.elenco_anni != oldNetworkCache {
                NetworkCache.shared.academicYears[year]?[courseValue] = selectedCorso.elenco_anni
                
                updateCache()
                
                await MainActor.run {
                    self.academicYears = selectedCorso.elenco_anni
                }
            }
        }
    }
    
    public func checkForMatricola(in academicYearValue: String) -> Bool {
        guard let anno = academicYears.first(where: { $0.valore == academicYearValue }) else {
            return false
        }
        
        for insegnamento in anno.elenco_insegnamenti {
            if insegnamento.label.contains("Matricole dispari") || insegnamento.label.contains("Matricole pari") {
                return true
            }
        }
        return false
    }
}
