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
    
    var loading: Bool = true
    var checkingUpdates: Bool = false
    var showUpdateAlert: Bool = false
    var errorMessage: String? = nil
    var noLessonsFound: Bool = false
    
    private var pendingNewLessons: [Lesson]? = nil
    private var currentPalette: [String] = []
    private let cacheKey = "calendar_cache.json"
    
    private let networkService: NetworkServiceProtocol
    
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.networkService = service
    }
    
    func loadFromCache(selYear: String, matricola: String) {
        if let cacheResponse = CacheManager.shared.load(fileName: cacheKey, type: ResponseAPI.self) {
            self.lessons = cacheResponse.celle
            self.organizeData(selectedYear: selYear, matricola: matricola)
            
            DispatchQueue.main.async {
                self.loading = false
                if self.lessons.isEmpty {
                    self.noLessonsFound = true
                }
            }
        }
    }
    
    @MainActor
    func loadLessons(corso: String, anno: String, selYear: String, matricola: String) async {
        guard corso != "0" else { return }
        
        if !lessons.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.checkingUpdates = true
            }
        }
        self.errorMessage = nil
        
        do {
            let response = try await networkService.fetchOrario(corso: corso, anno: anno, selyear: selYear)
            
            var fetchedLessons = response.celle
            self.currentPalette = response.colori
            
            if fetchedLessons.isEmpty {
                noLessonsFound = true
                self.applyNewData(fetchedLessons, palette: self.currentPalette, selectedYear: selYear, matricola: matricola)
            } else {
                assignColors(to: &fetchedLessons, palette: self.currentPalette)
                
                noLessonsFound = false
                if self.lessons.isEmpty {
                    self.applyNewData(fetchedLessons, palette: self.currentPalette, selectedYear: selYear, matricola: matricola)
                } else {
                    if !self.lessons.elementsEqual(fetchedLessons, by: {
                        $0.orario == $1.orario &&
                        $0.tipo == $1.tipo &&
                        $0.color == $1.color &&
                        $0.aula == $1.aula &&
                        $0.nomeInsegnamento == $1.nomeInsegnamento &&
                        $0.data == $1.data &&
                        $0.docente == $1.docente &&
                        $0.codiceInsegnamento == $1.codiceInsegnamento &&
                        $0.annullato == $1.annullato &&
                        $0.colorIndex == $1.colorIndex &&
                        $0.nameOriginal == $1.nameOriginal
                    }) {
                        self.pendingNewLessons = fetchedLessons
                        self.showUpdateAlert = true
                    }
                }
            }
        } catch {
            if let netError = error as? NetworkError {
                self.errorMessage = netError.localizedDescription
            } else {
                self.errorMessage = "Errore Generico: \(error.localizedDescription)"
            }
            print("Debug Error: \(error)")
        }
        
        if self.loading {
            self.loading = false
        }
        self.checkingUpdates = false
    }
    
    func clearPendingUpdate() {
        pendingNewLessons = nil
        checkingUpdates = false
        showUpdateAlert = false
    }
    
    func confirmUpdate(selectedYear: String, matricola: String) {
        guard let newLessons = pendingNewLessons else { return }
        
        applyNewData(newLessons, palette: self.currentPalette, selectedYear: selectedYear, matricola: matricola)
        
        noLessonsFound = false
        pendingNewLessons = nil
        showUpdateAlert = false
    }
    
    private func applyNewData(_ newLessons: [Lesson], palette: [String], selectedYear: String, matricola: String) {
        self.lessons = newLessons
        self.organizeData(selectedYear: selectedYear, matricola: matricola)
        
        let cacheObject = ResponseAPI(celle: newLessons, colori: palette)
        CacheManager.shared.save(cacheObject, fileName: cacheKey)
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
        let calendar = Calendar.current
        
        let formatter = Formatters.displayDate
        
        var startComponents = DateComponents()
        startComponents.year = annoInizio
        startComponents.month = 10
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = annoInizio + 1
        endComponents.month = 9
        endComponents.day = 30
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            dateStringhe.append(formatter.string(from: currentDate))
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return dateStringhe
    }
}
