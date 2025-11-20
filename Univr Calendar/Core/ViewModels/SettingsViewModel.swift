//
//  SettingsViewModel.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

@Observable
class SettingsViewModel {
    var years: [Year] = []
    var courses: [Corso] = []
    var academicYears: [Anno] = []
    
    var loading: Bool = false
    var errorMessage: String? = nil
    
    private let networkService: NetworkService
    
    init(service: NetworkService = NetworkService()){
        self.networkService = service
    }
    
    @MainActor
    func loadYears() async {
        guard years.isEmpty else { return }
        
        do {
            self.years = try await networkService.getYears()
        } catch {
            self.errorMessage = "Errore caricamento anni: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadCourses(year: String) async {
        self.loading = true
        do {
            self.courses = try await networkService.getCourses(year: year)
        } catch {
            self.errorMessage = "Errore caricamento corsi: \(error.localizedDescription)"
        }
        self.loading = false
    }
    
    func updateAcademicYears(for courseValue: String) {
        guard let selectedCorso = courses.first(where: { $0.valore == courseValue }) else {
            self.academicYears = []
            return
        }
        self.academicYears = selectedCorso.elenco_anni
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
