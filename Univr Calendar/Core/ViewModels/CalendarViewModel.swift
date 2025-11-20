//
//  CalendarViewModel.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 22/10/25.
//

import Foundation

@Observable
class CalendarViewModel {
    var lessons: [Lesson] = []
    var days: [[Lesson]] = []
    var daysString: [String] = []
    var loading: Bool = false
    var errorMessage: String? = nil
    
    private let networkService: NetworkServiceProtocol
    
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.networkService = service
    }
    
    @MainActor
    func loadLessons(corso: String, anno: String, selYear: String, matricola: String) async {
        guard corso != "0" else { return }
        
        self.loading = true
        self.errorMessage = nil
        
        do {
            let response = try await networkService.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            
            var fetchedLessons = response.celle
            let palette = response.colori
            
            assignColors(to: &fetchedLessons, palette: palette)
            
            self.lessons = fetchedLessons
            self.organizeData(selectedYear: selYear, matricola: matricola)
        } catch {
            self.errorMessage = "Errore: \(error.localizedDescription)"
            print("Errore fetch: \(error)")
        }
        
        self.loading = false
    }
    
    private func assignColors(to lessons: inout [Lesson], palette: [String]) {
        var colorMap: [String: String] = [:]
        var paletteIndex = 0
        
        for i in lessons.indices {
            if lessons[i].annullato == "1" {
                lessons[i].color = "#FFFFFF"
            } else if lessons[i].tipo == "chiusura_type" {
                lessons[i].color = "#BDF2F2"
            } else if !lessons[i].colorIndex.isEmpty {
               print("Trovato uno")
            } else if let existingColor = colorMap[lessons[i].codiceInsegnamento] {
                lessons[i].color = existingColor
            } else {
                let code = lessons[i].codiceInsegnamento
                
                if let existingColor = colorMap[code] {
                    lessons[i].color = existingColor
                } else {
                    let newColor = (paletteIndex < palette.count) ? palette[paletteIndex] : "#CCCCCC"
                    colorMap[code] = newColor
                    lessons[i].color = newColor
                    
                    paletteIndex += 1
                }
            }
        }
    }
    
    func organizeData(selectedYear: String, matricola: String) {
        guard let annoInt = Int(selectedYear) else { return }
        
        self.daysString = generaDateAnnoAccademico(annoInizio: annoInt)
        var newDays: [[Lesson]] = []
        
        for day in daysString {
            var filtered = lessons.filter { lesson in
                let isRightDay = lesson.data == day
                let isNotChiusura = (lesson.tipo != "chiusura_type")
                
                let nameCondition = lesson.nomeInsegnamento.contains("Matricole \(matricola)") || (!lesson.nomeInsegnamento.contains("Matricole pari") && !lesson.nomeInsegnamento.contains("Matricole dispari"))
                
                return isRightDay && isNotChiusura && nameCondition
            }
            
            filtered = filtered.sorted(by: { $0.orario < $1.orario })
            
            if !filtered.isEmpty {
                var processedDay = filtered
                var added = 0
                
                for i in filtered.indices {
                    if i + 1 < filtered.count {
                        let endString = String(filtered[i].orario.split(separator: " - ").last ?? "")
                        let startString = String(filtered[i + 1].orario.split(separator: " - ").first ?? "")
                        
                        let endDate = endString.date(format: "HH:mm")
                        let startDate = startString.date(format: "HH:mm")
                        
                        if let end = endDate, let start = startDate, end.timeIntervalSince1970 < start.timeIntervalSince1970 {
                            
                            processedDay.insert(Lesson(
                                data: day,
                                orario: endString + " - " + startString,
                                tipo: "pause"
                            ), at: i + added + 1)
                            added += 1
                        }
                    }
                }
                newDays.append(processedDay)
            } else {
                newDays.append(filtered)
            }
        }
        
        self.days = newDays
    }
    
    func generaDateAnnoAccademico(annoInizio: Int) -> [String] {
        var dateStringhe: [String] = []
        
        // Setup Calendario e Formatter
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Formato richiesto
        formatter.locale = Locale(identifier: "it_IT") // Opzionale: forza locale italiano
        
        // Data Inizio: 1 Ottobre [annoInizio]
        var startComponents = DateComponents()
        startComponents.year = annoInizio
        startComponents.month = 10
        startComponents.day = 1
        
        // Data Fine: 30 Settembre [annoInizio + 1]
        var endComponents = DateComponents()
        endComponents.year = annoInizio + 1
        endComponents.month = 9
        endComponents.day = 30
        
        // Controllo validità date
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        // Ciclo per generare le date
        var currentDate = startDate
        
        while currentDate <= endDate {
            // 1. Aggiungi la stringa formattata all'array
            dateStringhe.append(formatter.string(from: currentDate))
            
            // 2. Incrementa di 1 giorno
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break // Sicurezza per evitare loop infiniti in caso di errore
            }
        }
        
        return dateStringhe
    }
}
