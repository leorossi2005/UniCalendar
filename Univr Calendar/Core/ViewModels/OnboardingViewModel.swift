//
//  OnboardingViewModel.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

@Observable
class OnboardingViewModel {
    var years: [Year] = []
    var courses: [Corso] = []
    var academicYears: [Anno] = []
    
    var loading: Bool = false
    var errorMessage: String? = nil
    
    private let cacheKey = "network_cache.json"
    
    private let networkService: NetworkService
    
    init(service: NetworkService = NetworkService()){
        self.networkService = service
    }
    
    func loadFromCache() {
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
    func loadYears() async {
        var newYears: [Year] = []
        if NetworkCache.shared.years.isEmpty {
            do {
                newYears = try await networkService.getYears()
            } catch {
                self.errorMessage = "Errore caricamento anni: \(error.localizedDescription)"
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
    func loadCourses(year: String) async {
        self.loading = true
        
        var newCourses: [Corso] = []
        if NetworkCache.shared.courses[year] == nil {
            do {
                newCourses = try await networkService.getCourses(year: year)
            } catch {
                self.errorMessage = "Errore caricamento corsi: \(error.localizedDescription)"
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
    
    func updateAcademicYears(for courseValue: String) {
        var newAcademicYears: [Anno] = []
        if NetworkCache.shared.academicYears[courseValue] == nil {
            guard let selectedCorso = courses.first(where: { $0.valore == courseValue }) else {
                return
            }
            
            newAcademicYears = selectedCorso.elenco_anni
        } else {
            newAcademicYears = NetworkCache.shared.academicYears[courseValue]!
        }
        
        let oldNetworkCache = NetworkCache.shared.academicYears[courseValue] ?? nil
        NetworkCache.shared.academicYears[courseValue] = newAcademicYears
        self.academicYears = newAcademicYears
        
        Task.detached { [self] in
            guard let selectedCorso = await courses.first(where: { $0.valore == courseValue }) else {
                return
            }
            
            if selectedCorso.elenco_anni != oldNetworkCache {
                NetworkCache.shared.academicYears[courseValue] = selectedCorso.elenco_anni
                
                updateCache()
                
                await MainActor.run {
                    self.academicYears = selectedCorso.elenco_anni
                }
            }
        }
    }
    
    func checkForMatricola(in academicYearValue: String) -> Bool {
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
