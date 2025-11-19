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
    
    @State var selectedDetent: PresentationDetent = .fraction(0.15)
    
    @State var selectedWeek: Date = Date()
    @State var currentDay: Int = Date().day
    
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
    
    @State var selectedMonth: Int = Date().month
    @State var days: [[Lesson]] = []
    @State var daysString: [String] = []
    @State private var selection: String? = ""
    
    var body: some View {
        NavigationView {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if loading {
                       if selectedCourse != "0" {
                           Text("Caricamento lezioni in corso...")
                               .bold()
                               .font(.title2)
                               .containerRelativeFrame(.horizontal)
                       } else {
                           Text("Devi scegliere un corso")
                               .bold()
                               .font(.title2)
                               .containerRelativeFrame(.horizontal)
                       }
                   } else {
                       ForEach(days.indices, id: \.self) { i in
                           if days[i].count != 0 {
                               CalendarViewDay(filteredLessons: days[i], detents: $detents, selectedLesson: $selectedLesson, openCalendar: $openCalendar, selectedDetent: $selectedDetent)
                                   .id(daysString[i])
                                   .containerRelativeFrame(.horizontal)
                           } else {
                               Text("Oggi non hai lezioni!")
                                   .bold()
                                   .font(.title2)
                                   .id(daysString[i])
                                   .containerRelativeFrame(.horizontal)
                           }
                       }
                   }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection)
            .if(loading) { view in
                view
                    //.ignoresSafeArea()
                    //.disabled(true)
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
                                    
                                    Task {
                                        do {
                                            let fetchedLessons = try await fetchOrario(corso: selectedCourse, anno: selectedAcademicYear, selyear: selectedYear)
                                            
                                            await MainActor.run {
                                                lessons = fetchedLessons
                                                organizeData()
                                                loading = false
                                            }
                                        } catch {
                                            print("Failed to fetch time in CalendarView: \(error)")
                                            throw error
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
                        } else if oldValue == .large {
                            openCalendar = oldOpenCalendar
                        } else {
                            selectedMonth = selectedWeek.month
                        }
                        
                        selectedLesson = nil
                        openSettings = false
                        
                        detents = [.fraction(0.15), .medium]
                    }
                }
                .onChange(of: selectedWeek) { oldDate, newDate in
                    if newDate.getString(format: "dd-MM-yyyy") != selection {
                        selection = newDate.getString(format: "dd-MM-yyyy")
                    }
                }
                .onChange(of: selection) {
                    if selection?.date != nil {
                        selectedWeek = selection!.date(format: "dd-MM-yyyy")!
                        // aggiornare currentDay in base a newDate
                        currentDay = selectedWeek.day
                        // capire la “settimana” di newDate e aggiornare selectedWeek base
                        selectedMonth = selectedWeek.month
                        
                        selectedDetent = .fraction(0.15)
                    }
                }
                .navigationTransition(
                    .zoom(sourceID: "calendar", in: transition)
                )
            }
            .onChange(of: currentDay) {
                //organizeData()
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
                    Task {
                        do {
                            let fetchedLessons = try await fetchOrario(corso: selectedCourse, anno: selectedAcademicYear, selyear: selectedYear)
                            
                            await MainActor.run {
                                lessons = fetchedLessons
                                organizeData()
                                loading = false
                            }
                        } catch {
                            print("Failed to fetch time in CalendarView: \(error)")
                            throw error
                        }
                    }
                }
            }
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
                                currentDay = week.day
                            }
                        }) {
                            VStack {
                                Text("\(week.day)")
                                    .bold()
                                    .foregroundStyle(week.day == currentDay ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                                Text(week.getCurrentWeekdaySymbol(length: .short))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .foregroundStyle(week.day == currentDay ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                            }
                            .frame(height: 50)
                        }
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .buttonStyle(.glassProminent)
                        .tint(Color(white: colorScheme == .light ? 0 : 1, opacity: week.day == currentDay ? 1 : 0))
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
                .ignoresSafeArea()
                /*.gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onEnded { value in
                            let current: Date = selectedWeek.set(type: .day, value: currentDay)
                            var new: Date? = nil
                            
                            if value.predictedEndTranslation.width < -150 {
                                new = current.add(type: .day, value: 7)!
                            } else if value.predictedEndTranslation.width > 150 {
                                new = current.remove(type: .day, value: 7)!
                            }
                            
                            if let d = new {
                                currentDay = d.day
                                selectedWeek = d
                            }
                        }
                )*/
            } else if selectedDetent == .medium {
                DatePickerContainer(selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
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
    
    private func organizeData() {
        daysString = generaDateAnnoAccademico(annoInizio: Int(selectedYear)!)
        
        for day in daysString {
            var filtered = lessons.filter { $0.data == day && ($0.tipo == "Lezione" || $0.tipo == "Tutorato") && ($0.nome_insegnamento.contains("Matricole \(matricola)") || (!$0.nome_insegnamento.contains("Matricole pari") && !$0.nome_insegnamento.contains("Matricole dispari")))}
            filtered = filtered.sorted(by: { $0.orario < $1.orario })
            
            if filtered.count > 0 {
                var newFiltered = filtered
                var added = 0
                for i in filtered.indices {
                    if i + 1 != filtered.count {
                        let end: String = String(filtered[i].orario.split(separator: " - ").last!)
                        let start: String = String(filtered[i + 1].orario.split(separator: " - ").first!)
                        
                        if end != start && end.date(format: "HH:mm")?.timeIntervalSince1970 ?? 0 < start.date(format: "HH:mm")?.timeIntervalSince1970 ?? 0 {
                            newFiltered.insert(Lesson(
                               data: day,
                               orario: end + " - " + start,
                               tipo: "pause"
                            ), at: i + added + 1)
                            added += 1
                        }
                    }
                }
                
                days.append(newFiltered)
            } else {
                days.append(filtered)
            }
        }
        
        selection = Date().getString(format: "dd-MM-yyyy")
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
    
    private func updateDate() {
        selectedWeek = Date(year: Int(selectedYear)!, month: Date().month, day: Date().day)
    }
}

struct DatePickerView: View {
    @Binding var selection: Date
    
    @State var date: Date
    @State var actual: Bool
    
    var days: [String] {
        Date().getWeekdaySymbols(length: .short)
    }
    
    var currentDay: Int {
        date.day
    }
    
    var lastDayN: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30 // Fallback a 30 se fallisce
    }
    
    var firstDayName: String {
        date.startWeekdaySymbolOfMonth(length: .short)
    }
    
    var monthName: String {
        date.getCurrentMonthSymbol(length: .full)
    }
    
    var year: String {
        date.yearSymbol
    }
    
    var rows: Int {
        6
    }
    
    var calculatedRows: Int {
        var row = 1
        var dayNumber: Int = 1
        while dayNumber < lastDayN {
            dayNumber += 7
            if dayNumber <= lastDayN {
                row += 1
            } else if days.firstIndex(of: firstDayName)! - (dayNumber - lastDayN) >= 0 {
                row += 1
            }
        }
        
        return row
    }
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    HStack {
                        Text(monthName)
                            .fontWeight(.bold)
                        Text("•")
                        Text(year)
                    }
                    Spacer()
                    Button("Oggi") {
                        if date.month != Date().month {
                            actual = false
                        } else {
                            date = date.set(type: .day, value: Date().day)
                        }
                        
                        selection = Date()
                    }
                    .buttonStyle(.glass)
                }
                HStack {
                    ForEach(days, id: \.self) { day in
                        Text("\(day)")
                            .frame(width: 40, height: 40)
                        if day != days.last {
                            Spacer()
                        }
                    }
                }
                let startOffset = days.firstIndex(of: firstDayName) ?? 0

                ForEach(0..<rows, id: \.self) { row in
                    HStack {
                        ForEach(0..<days.count, id: \.self) { col in
                            let dayIndex = row * days.count + col - startOffset + 1
                            if dayIndex < 1 {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                    let calendar = Calendar.current
                                    let range = calendar.range(of: .day, in: .month, for: date.remove(type: .month, value: 1))
                                    let final = range?.count ?? 30 // Fallback a 30 se fallisce
                                    Text("\(final + dayIndex)")
                                        .opacity(0.3)
                                        .onTapGesture {
                                            if date.month - 1 != 9 {
                                                actual = false
                                                date = date.set(type: .day, value: 1)
                                                var newDate = date.remove(type: .month, value: 1)
                                                newDate = newDate.set(type: .day, value: final + dayIndex)
                                                selection = newDate
                                            }
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else if dayIndex > lastDayN /*&& calculatedRows == row + 1*/ {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                    Text("\(dayIndex - lastDayN)")
                                        .opacity(0.3)
                                        .onTapGesture {
                                            if date.month + 1 != 10 {
                                                actual = false
                                                date = date.set(type: .day, value: 1)
                                                var newDate = date.add(type: .month, value: 1)
                                                newDate = newDate.set(type: .day, value: dayIndex - lastDayN)
                                                selection = newDate
                                            }
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else if dayIndex <= lastDayN {
                                ZStack {
                                    Circle()
                                        .fill(dayIndex == currentDay && actual ? .blue : .clear)
                                        .frame(width: 40, height: 40)
                                        .opacity(0.3)
                                    Text("\(dayIndex)")
                                        .if((dayIndex != currentDay || !actual) && Date().day == dayIndex && Date().getCurrentMonthSymbol(length: .full) == monthName) { view in
                                            view
                                                .foregroundStyle(.blue)
                                                .fontWeight(.bold)
                                        }
                                        .onTapGesture {
                                            actual = true
                                            date = date.set(type: .day, value: dayIndex)
                                            selection = date
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, (screenSize.width / 100) * 8)
    }
}

struct DatePickerContainer: View {
    @Binding var  selectedMonth: Int
    @Binding var selectedWeek: Date
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    
    var body: some View {
        TabView(selection: $selectedMonth) {
            ForEach(0..<12) { n in
                let date = Date(year: Int(selectedYear)!, month: 10, day: 1).add(type: .month, value: n)
                if selectedWeek.month == date.month {
                    DatePickerView(selection: $selectedWeek, date: selectedWeek, actual: true).tag(date.month)
                } else {
                    DatePickerView(selection: $selectedWeek, date: date, actual: false).tag(date.month)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct CalendarViewDay: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var filteredLessons: [Lesson]
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var selectedLesson: Lesson?
    @Binding var openCalendar: Bool
    @Binding var selectedDetent: PresentationDetent
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        ScrollView {
            ForEach(filteredLessons) { lesson in
                if lesson.tipo != "pause" && lesson.tipo != "chiusura_type" {
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
                            Text(getDifference(orario: lesson.orario, type: lesson.tipo))
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
                        Text("---- Pausa di " + getDifference(orario: lesson.orario, type: lesson.tipo) + " ----")
                    }
                    .padding(.top, -2.5)
                }
            }
            Spacer()
                .frame(height: screenSize.height * 0.15)
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
    }
    
    private func formatName(name: String) -> String {
        return name.replacingOccurrences(of: "Matricole pari", with: "").replacingOccurrences(of: "Matricole dispari", with: "")
    }
    
    private func formatClassroom(classroom: String) -> String {
        guard let bracketIndex = classroom.firstIndex(of: "[") else {
            return classroom // fallback if "[" not found
        }
        
        let index = classroom.index(bracketIndex, offsetBy: -2, limitedBy: classroom.startIndex) ?? classroom.startIndex
        return String(classroom[...index])
    }
    
    private func getDifference(orario: String, type: String) -> String {
        let parti = orario.components(separatedBy: " - ")
        guard parti.count == 2 else { fatalError("Formato orario non valido") }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        var difference: String = ""
        if let inizio = formatter.date(from: parti[0]),
           let fine = formatter.date(from: parti[1]) {
            
            let differenza = fine.timeIntervalSince(inizio)
            
            if differenza / 3600 >= 1 && differenza.truncatingRemainder(dividingBy: 3600) > 0 {
                difference = "\(Int(differenza) / 3600)h \(Int(differenza.truncatingRemainder(dividingBy: 3600)) / 60)m"
            } else if differenza / 3600 >= 1 {
                difference = "\(Int(differenza) / 3600)h"
            } else {
                difference = "\(Int(differenza.truncatingRemainder(dividingBy: 3600)) / 60)m"
            }
        }
        
        return difference
    }
}

#Preview {
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    CalendarView(years: .constant([]), courses: .constant([]), academicYears: .constant([]), selectedTab: .constant(0))
    //DatePickerContainer(selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
}
