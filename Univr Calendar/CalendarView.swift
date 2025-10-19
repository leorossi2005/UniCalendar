//
//  CalendarView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/25.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Namespace var transition
    
    @State var lessons: [Lesson] = []
    @State var filteredLessons: [Lesson] = []
    @State var loading: Bool = true
    @State var noLessons: Bool = true
    
    @State var selectedDetent: PresentationDetent = .fraction(0.15)
    
    @State var selectedWeek: Date = Date()
    @State var currentDay: Int = Foundation.Calendar.current.component(.day, from: Date())
    
    @State var detents: Set<PresentationDetent> = [.fraction(0.15), .medium]
    @State var selectedLesson: Lesson? = nil
    
    @State var openSettings: Bool = false
    @State var oldOpenCalendar: Bool = false
    @State var openCalendar: Bool = false {
        didSet {
            oldOpenCalendar = oldValue
        }
    }
    
    @Binding var years: [Year]
    @Binding var courses: [Corso]
    @Binding var academicYears: [Anno]
    
    @Binding var selectedTab: Int
    
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    @AppStorage("selectedCourse") var selectedCourse: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYear: String = "0"
    @AppStorage("matricola") var matricola: String = "pari"
    
    @State var tempSelectedYear: String = ""
    @State var tempSelectedCourse: String = ""
    @State var tempSelectedAcademicYear: String = ""
    @State var tempMatricola: String = ""
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if !filteredLessons.isEmpty {
                    ForEach(filteredLessons, id: \.nome_insegnamento) { lesson in
                        if lesson.type != "pause" && lesson.type != "chiusura_type" {
                            ZStack {
                                RoundedRectangle(cornerRadius: 45, style: .continuous)
                                    .fill(LinearGradient(stops: [.init(color: Color(hex: lesson.color) ?? .black, location: 0), .init(color: Color(white: 0, opacity: 0.6), location: 2)], startPoint: .leading, endPoint: .trailing))
                                    .padding(.vertical, -5)
                                    .padding(.horizontal, 15)
                                HStack {
                                    VStack {
                                        Text(formatName(name: lesson.nome_insegnamento))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundStyle(.black)
                                            .font(.custom("", size: 20))
                                        Text(formatClassroom(classroom: lesson.aula))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundStyle(Color(white: 0.3))
                                            .font(.custom("", size: 20))
                                        Spacer(minLength: 30)
                                        Text(lesson.orario)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundStyle(.black)
                                            .font(.custom("", size: 20))
                                    }
                                    .padding(.vertical, 25)
                                    .padding(.leading, 45)
                                    Spacer(minLength: 20)
                                    Text(getDifference(orario: lesson.orario))
                                        .foregroundStyle(.black)
                                        .font(.custom("", size: 60))
                                        .padding(.trailing, 45)
                                }
                            }
                            .onTapGesture {
                                openCalendar = true
                                selectedLesson = lesson
                                
                                detents = [.fraction(0.15), .medium, .large]
                                selectedDetent = .large
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 45, style: .continuous)
                                    .fill(LinearGradient(stops: [.init(color: Color(white: 0, opacity: 0), location: 0), .init(color: Color(white: colorScheme == .light ? 0 : 1, opacity: colorScheme == .light ? 0.1 : 0.2), location: 0.5), .init(color: Color(white: 0, opacity: 0), location: 1)], startPoint: .leading, endPoint: .trailing))
                                    .padding(.vertical, -5)
                                    .padding(.horizontal, 15)
                                Text("---- Pausa di " + getDifference(orario: lesson.orario) + " ----")
                            }
                            .padding(.top, -2.5)
                        }
                    }
                    Spacer()
                        .frame(height: screenSize.height * 0.15)
                } else if loading {
                    if selectedCourse != "0" {
                        Text("Caricamento lezioni in corso...")
                            .bold()
                            .font(.title2)
                            .frame(height: screenSize.height)
                    } else {
                        Text("Devi scegliere un corso")
                            .bold()
                            .font(.title2)
                            .frame(height: screenSize.height)
                    }
                } else if noLessons {
                    Text("Oggi non hai lezioni!")
                        .bold()
                        .font(.title2)
                        .frame(height: screenSize.height)
                }
            }
            .onScrollGeometryChange(for: ScrollGeometry.self, of: { geometry in
                geometry
            }) { oldValue, newValue in
                withAnimation {
                    if (newValue.contentOffset.y + newValue.contentInsets.top) <= 0 {
                        openCalendar = true
                    } else {
                        if selectedDetent != .large {
                            openCalendar = false
                        }
                    }
                }
            }
            .if(loading || noLessons) { view in
                view
                    .ignoresSafeArea()
                    .disabled(true)
            }
            .sheet(isPresented: $openCalendar) {
                NavigationStack {
                    sheetContent
                }
                .presentationDetents(detents, selection: $selectedDetent)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .disabled(loading && !openSettings)
                .onChange(of: selectedDetent) { oldValue, newValue in
                    if newValue != .large {
                        if openSettings {
                            if tempSelectedCourse != selectedCourse || tempSelectedAcademicYear != selectedAcademicYear || tempSelectedYear != selectedYear {
                                selectedYear = tempSelectedYear
                                selectedCourse = tempSelectedCourse
                                selectedAcademicYear = tempSelectedAcademicYear
                                matricola = tempMatricola
                                
                                openCalendar = true
                                loading = true
                                lessons = []
                                filteredLessons = []
                                if selectedCourse != "0" {
                                    updateDate()
                                    
                                    fetchOrario(corso: selectedCourse, anno: selectedAcademicYear, selyear: selectedYear) { result in
                                        switch result {
                                            case .success(let lessons):
                                                self.lessons = lessons
                                                organizeData()
                                                loading = false
                                            case .failure:
                                                print("Completion error")
                                                return
                                        }
                                    }
                                }
                            } else if tempMatricola != matricola {
                                matricola = tempMatricola
                                
                                openCalendar = true
                                loading = true
                                organizeData()
                                loading = false
                            } else {
                                openCalendar = oldOpenCalendar
                            }
                        } else {
                            openCalendar = oldOpenCalendar
                        }
                        
                        selectedLesson = nil
                        openSettings = false
                        
                        detents = [.fraction(0.15), .medium]
                    }
                }
                .onChange(of: selectedWeek) { oldDate, newDate in
                    // aggiornare currentDay in base a newDate
                    let comp = Foundation.Calendar.current.dateComponents([.day], from: newDate)
                    if let d = comp.day {
                        currentDay = d
                    }
                    // capire la “settimana” di newDate e aggiornare selectedWeek base
                    selectedWeek = newDate
                    
                    selectedDetent = .fraction(0.15)
                }
                .navigationTransition(
                    .zoom(sourceID: "calendar", in: transition)
                )
            }
            .onChange(of: currentDay) {
                organizeData()
            }
            .onAppear {
                updateDate()
                
                tempSelectedYear = selectedYear
                tempSelectedCourse = selectedCourse
                tempSelectedAcademicYear = selectedAcademicYear
                tempMatricola = matricola
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    openCalendar = true
                }
                
                if selectedCourse != "0" {
                    fetchOrario(corso: selectedCourse, anno: selectedAcademicYear, selyear: selectedYear) { result in
                        switch result {
                            case .success(let lessons):
                                self.lessons = lessons
                                organizeData()
                                loading = false
                            case .failure:
                                print("Completion error")
                                return
                        }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onEnded { value in
                        let current: Date = Foundation.Calendar.current.date(bySetting: .day, value: currentDay, of: selectedWeek)!
                        var new: Date? = nil
                        
                        if value.predictedEndTranslation.width < -150 {
                            new = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: current)!
                            withAnimation {
                                openCalendar = true
                            }
                        } else if value.predictedEndTranslation.width > 150 {
                            new = Foundation.Calendar.current.date(byAdding: .day, value: -1, to: current)!
                            withAnimation {
                                openCalendar = true
                            }
                        }
                        
                        if new != nil {
                            let comp = Foundation.Calendar.current.dateComponents([.day], from: new!)
                            if let dayNum = comp.day {
                                currentDay = dayNum
                            }
                            
                            selectedWeek = new!
                        }
                    }
            )
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        openCalendar = true
                        openSettings = true
                        
                        detents = [.fraction(0.15), .medium, .large]
                        selectedDetent = .large
                    }) {
                        Label("", systemImage: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        withAnimation {
                            selectedLesson = nil
                            openCalendar = true
                            
                            detents = [.fraction(0.15), .medium]
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Calendario")
                        }
                    }
                    .opacity(openCalendar ? 0 : 1)
                }
                .matchedTransitionSource(id: "calendar", in: transition)
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
    }
    
    @ViewBuilder
        var sheetContent: some View {
            if selectedDetent == .fraction(0.15) {
                HStack {
                    ForEach(selectedWeek.weekDates(), id: \.self) { week in
                        Button(action: {
                            withAnimation {
                                selectedWeek = week
                                let comp = Foundation.Calendar.current.dateComponents([.day], from: week)
                                if let dayNum = comp.day {
                                    currentDay = dayNum
                                }
                            }
                        }) {
                            VStack {
                                Text("\(Foundation.Calendar.current.component(.day, from: week))")
                                    .bold()
                                    .foregroundStyle(Foundation.Calendar.current.component(.day, from: week) == currentDay ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                                let weekdayName = Foundation.Calendar.current.shortWeekdaySymbols[Foundation.Calendar.current.component(.weekday, from: week) - 1]
                                Text(weekdayName)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .foregroundStyle(Foundation.Calendar.current.component(.day, from: week) == currentDay ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                            }
                            .frame(height: 50)
                        }
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .buttonStyle(.glassProminent)
                        .tint(Color(white: colorScheme == .light ? 0 : 1, opacity: Foundation.Calendar.current.component(.day, from: week) == currentDay ? 1 : 0))
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
                .ignoresSafeArea()
                /*.gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onEnded { value in
                            let current: Date = Foundation.Calendar.current.date(bySetting: .day, value: currentDay, of: selectedWeek)!
                            var new: Date? = nil
                            
                            if value.predictedEndTranslation.width < -150 {
                                new = Foundation.Calendar.current.date(byAdding: .day, value: 7, to: current)!
                            } else if value.predictedEndTranslation.width > 150 {
                                new = Foundation.Calendar.current.date(byAdding: .day, value: -7, to: current)!
                            }
                            
                            if new != nil {
                                let comp = Foundation.Calendar.current.dateComponents([.day], from: new!)
                                if let dayNum = comp.day {
                                    currentDay = dayNum
                                }
                                
                                selectedWeek = new!
                            }
                        }
                )*/
            } else if selectedDetent == .medium {
                VStack {
                    Text("Scegli un giorno")
                        .font(.headline)
                        .padding()
                    // Un DatePicker, LazyVGrid, o qualunque UI calendario tu preferisca.
                    // Per esempio un semplice DatePicker inline:
                    DatePicker(
                        "",
                        selection: $selectedWeek,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    Spacer()
                }
                .padding()
            } else {
                if openSettings {
                    Settings(years: $years, courses: $courses, academicYears: $academicYears, detents: $detents, openSettings: $openSettings, openCalendar: $openCalendar, selectedTab: $selectedTab, selectedDetent: $selectedDetent, selectedYear: $tempSelectedYear, selectedCourse: $tempSelectedCourse, selectedAcademicYear: $tempSelectedAcademicYear, matricola: $tempMatricola)
                        .navigationTitle("Impostazioni")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    VStack {
                        Text("Informazioni sulla lezione (WIP)")
                            .font(.title2)
                            .bold()
                        Spacer()
                            .frame(height: 20)
                        Text(selectedLesson!.nome_insegnamento)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.name_original)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.orario)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.data)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.aula)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.docente)
                    }
                    .padding()
                    .multilineTextAlignment(.center)
                }
            }
        }
    
    private func getDifference(orario: String) -> String {
        let parti = orario.components(separatedBy: " - ")
        guard parti.count == 2 else { fatalError("Formato orario non valido") }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        var difference: String = ""
        if let inizio = formatter.date(from: parti[0]),
           let fine = formatter.date(from: parti[1]) {
            
            let differenza = fine.timeIntervalSince(inizio)
            
            difference = "\(Int(differenza) / 3600)h"
        }
        
        return difference
    }
    
    private func formatClassroom(classroom: String) -> String {
        guard let bracketIndex = classroom.firstIndex(of: "[") else {
            return classroom // fallback if "[" not found
        }
        
        let index = classroom.index(bracketIndex, offsetBy: -2, limitedBy: classroom.startIndex) ?? classroom.startIndex
        return String(classroom[...index])
    }
    
    private func formatName(name: String) -> String {
        return name.replacingOccurrences(of: "Matricole pari", with: "").replacingOccurrences(of: "Matricole dispari", with: "")
    }
    
    private func organizeData() {
        let day = String(format: "%02d", currentDay)
        let month = String(format: "%02d", Foundation.Calendar.current.component(.month, from: selectedWeek))
        let year = String(format: "%04d", Foundation.Calendar.current.component(.year, from: selectedWeek))
        
        let filtered = lessons.filter { $0.data == "\(day)-\(month)-\(year)" && $0.type == "Lezione" && ($0.nome_insegnamento.contains("Matricole \(matricola)") || (!$0.nome_insegnamento.contains("Matricole pari") && !$0.nome_insegnamento.contains("Matricole dispari")))}
        filteredLessons = filtered.sorted(by: { $0.orario < $1.orario })
        
        if filteredLessons.count > 0 {
            for index in 0..<filteredLessons.count - 1 {
                let end: String = String(filteredLessons[index].orario.split(separator: " - ").last!)
                let start: String = String(filteredLessons[index + 1].orario.split(separator: " - ").first!)
            
                if end != start {
                    filteredLessons.insert(.init(
                       nome_insegnamento: "",
                       name_original: "",
                       orario: end + " - " + start,
                       data: "\(day)-\(month)-\(year)",
                       aula: "",
                       docente: "",
                       color: "",
                       type: "pause"
                    ), at: index + 1)
                }
            }
            
            noLessons = false
        } else {
            noLessons = true
        }
    }
    
    private func updateDate() {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.month, .day], from: now)
        var newComponents = DateComponents()
        newComponents.year = Int(selectedYear)
        newComponents.month = components.month
        newComponents.day = components.day
        
        if let newDate = calendar.date(from: newComponents) {
            selectedWeek = newDate
        } else {
            newComponents.month = 10
            newComponents.day = 1
            
            selectedWeek = calendar.date(from: newComponents)!
        }
    }
}

#Preview {
    CalendarView(years: .constant([]), courses: .constant([]), academicYears: .constant([]), selectedTab: .constant(0))
}
