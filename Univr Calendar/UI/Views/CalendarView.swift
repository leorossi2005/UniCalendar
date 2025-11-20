//
//  CalendarView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/25.
//

import SwiftUI

var isIpad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

struct CalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Namespace var transition
    
    @State var viewModel = CalendarViewModel()
    
    @State var selectedDetent: PresentationDetent = .fraction(0.15)
    
    @State var selectedWeek: Date = Date()
    
    @State var detents: Set<PresentationDetent> = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium]
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
    private let safeAreas = UIApplication.shared.safeAreas
    
    @State var selectedMonth: Int = Date().month
    @State private var selection: String? = ""
    @State private var selectionFraction: String? = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if viewModel.loading {
                       if selectedCourse != "0" {
                           ScrollView {
                               if #available(iOS 17, *) {
                                   if #unavailable(iOS 18.0) {
                                       Spacer()
                                           .frame(height: safeAreas.top * 1.9)
                                   }
                               }
                               VStack(spacing: 10) {
                                   ForEach(0..<5, id: \.self) { _ in
                                       LessonCardView(lesson: .sample)
                                           .redacted(reason: .placeholder) // Questo fa la magia: trasforma tutto in blocchi grigi
                                           .shimmeringPlaceholder() // (Opzionale: vedi sotto se vuoi l'animazione)
                                   }
                               }
                               .scrollViewTopPadding()
                               Spacer()
                                   .frame(height: screenSize.height * 0.10)
                           }
                           .containerRelativeFrame(.horizontal)
                       } else {
                           Text("Devi scegliere un corso")
                               .bold()
                               .font(.title2)
                               .containerRelativeFrame(.horizontal)
                       }
                   } else {
                       ForEach(viewModel.days.indices, id: \.self) { i in
                           if viewModel.days[i].count != 0 {
                               CalendarViewDay(filteredLessons: viewModel.days[i], detents: $detents, selectedLesson: $selectedLesson, openCalendar: $openCalendar, selectedDetent: $selectedDetent)
                                   .id(viewModel.daysString[i])
                                   .containerRelativeFrame(.horizontal)
                           } else {
                               Text("Oggi non hai lezioni!")
                                   .bold()
                                   .font(.title2)
                                   .id(viewModel.daysString[i])
                                   .containerRelativeFrame(.horizontal)
                           }
                       }
                   }
                }
                .scrollTargetLayout()
            }
            .id(selectedCourse + selectedYear + selectedAcademicYear + matricola)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection)
            .sheet(isPresented: $openCalendar) {
                NavigationStack {
                    sheetContent
                }
                .presentationDetents(detents, selection: $selectedDetent)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: isIpad ? .fraction(0.75) : isIpad ? .fraction(0.75) : .medium))
                .disabled(viewModel.loading && !openSettings)
                .onChange(of: selectedDetent) { oldValue, newValue in
                    if newValue != .fraction(0.15) {
                        selectionFraction = nil
                    }
                    
                    if newValue != .large {
                        if openSettings {
                            if tempSelectedCourse != selectedCourse || tempSelectedAcademicYear != selectedAcademicYear || tempSelectedYear != selectedYear {
                                selectedYear = tempSelectedYear
                                selectedCourse = tempSelectedCourse
                                selectedAcademicYear = tempSelectedAcademicYear
                                matricola = tempMatricola
                                
                                openCalendar = true
                                viewModel.loading = true
                                viewModel.lessons = []
                                if selectedCourse != "0" {
                                    updateDate()
                                    
                                    Task {
                                        await viewModel.loadLessons(
                                            corso: selectedCourse,
                                            anno: selectedAcademicYear,
                                            selYear: selectedYear,
                                            matricola: matricola
                                        )
                                    }
                                }
                            } else if tempMatricola != matricola {
                                matricola = tempMatricola
                                
                                openCalendar = true
                                viewModel.loading = true
                                viewModel.organizeData(selectedYear: selectedYear, matricola: matricola)
                                viewModel.loading = false
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
                        
                        detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium]
                    }
                }
                .onChange(of: selectedWeek) { oldDate, newDate in
                    if newDate.getString(format: "dd-MM-yyyy") != selection && !viewModel.loading {
                        selection = newDate.getString(format: "dd-MM-yyyy")
                    }
                }
                .onChange(of: selection) {
                    if let date = selection?.date(format: "dd-MM-yyyy") {
                        if selectedWeek.getString(format: "dd-MM-yyyy") != selection {
                            selectedWeek = date
                        }
                        // capire la “settimana” di newDate e aggiornare selectedWeek base
                        selectedMonth = selectedWeek.month
                        
                        selectedDetent = .fraction(0.15)
                    }
                }
                .onChange(of: selectionFraction) {
                    if selectionFraction != nil && selectionFraction != selectedWeek.weekDates().first?.getString(format: "dd-MM-yyyy") {
                        let newDate = selectionFraction?.date(format: "dd-MM-yyyy")!
                        let isLeftOutOfBounds = newDate!.month == 9 && newDate!.year == Int(selectedYear)
                        let isRightOutOfBounds = (newDate!.month == 10 && newDate!.year == Int(selectedYear)! + 1)
                        if isLeftOutOfBounds {
                            selectedWeek = "01-10-\(selectedYear)".date(format: "dd-MM-yyyy")!
                        } else if isRightOutOfBounds {
                            selectedWeek = "30-09-\(Int(selectedYear)! + 1)".date(format: "dd-MM-yyyy")!
                        } else {
                            selectedWeek = newDate!
                        }
                    }
                }
                .sheetDesign(transition)
            }
            .onAppear {
                updateDate()
                
                tempSelectedYear = selectedYear
                tempSelectedCourse = selectedCourse
                tempSelectedAcademicYear = selectedAcademicYear
                tempMatricola = matricola
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    openCalendar = true
                    oldOpenCalendar = true
                }
                
                if selectedCourse != "0" {
                    Task {
                        await viewModel.loadLessons(
                            corso: selectedCourse,
                            anno: selectedAcademicYear,
                            selYear: selectedYear,
                            matricola: matricola
                        )
                    }
                }
            }
            .onChange(of: viewModel.loading) { oldValue, isLoading in
                if !isLoading {
                    let today = Date().getString(format: "dd-MM-yyyy")
                    
                    if viewModel.daysString.contains(today) {
                        selection = today
                    } else {
                        selection = viewModel.daysString.first
                    }
                } else {
                    selection = nil
                }
            }
            .onChange(of: openCalendar) {
                if selectedTab == 0 {
                    if !openCalendar {
                        selectionFraction = nil
                    }
                } else {
                    openCalendar = false
                }
            }
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem {
                        Button(action: {
                            openCalendar = true
                            openSettings = true
                    
                            detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium, .large]
                            selectedDetent = .large
                        }) {
                            Label("", systemImage: "gearshape.fill")
                        }
                    }
                } else {
                    ToolbarItem {
                        Button(action: {
                            openCalendar = true
                            openSettings = true
                            
                            detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium, .large]
                            selectedDetent = .large
                        }) {
                            Label("", systemImage: "gearshape.fill")
                                .font(Font.system(size: 25))
                                .padding(3)
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
                        .overlay(Circle().stroke(colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), lineWidth: 2))
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            withAnimation {
                                selectedLesson = nil
                                openCalendar = true
                                
                                detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium]
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
            .removeTopSafeArea()
        }
        .hideTabBarCompatible()
    }
    
    @ViewBuilder
    var sheetContent: some View {
        ZStack {
            if selectedDetent == .fraction(0.15) {
                temp(selectedWeek: $selectedWeek, loading: $viewModel.loading, selectionFraction: $selectionFraction, selectedDetent: $selectedDetent)
            }
            
            // 2. DATE PICKER CONTAINER (Visibile solo su medium)
            if selectedDetent == (isIpad ? .fraction(0.75) : .medium) {
                DatePickerContainer(selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
                    .transition(.opacity) // Opzionale: per una transizione più fluida
            }
            
            // 3. SETTINGS O INFO (Visibile solo su large)
            if selectedDetent == .large { // Assumo che il terzo stato sia .large
                if openSettings {
                    Settings(detents: $detents, openSettings: $openSettings, openCalendar: $openCalendar, selectedTab: $selectedTab, selectedDetent: $selectedDetent, selectedYear: $tempSelectedYear, selectedCourse: $tempSelectedCourse, selectedAcademicYear: $tempSelectedAcademicYear, matricola: $tempMatricola)
                        .navigationTitle("Impostazioni")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    VStack {
                        Text("Informazioni sulla lezione (WIP)")
                            .font(.title2)
                            .bold()
                        Spacer()
                            .frame(height: 20)
                        Text(selectedLesson!.nomeInsegnamento)
                        Spacer()
                            .frame(height: 10)
                        Text(selectedLesson!.nameOriginal)
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
    }
    
    private func updateDate() {
        selectedWeek = Date(year: Int(selectedYear)!, month: Date().month, day: Date().day)
    }
}

struct temp: View {
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    @AppStorage("selectedCourse") var selectedCourse: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYear: String = "0"
    @AppStorage("matricola") var matricola: String = "pari"
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    @Binding var selectionFraction: String?
    @Binding var selectedDetent: PresentationDetent
    
    @State var opacity: Double = 0
    
    @State private var academicWeeks: [[Date]] = []
    
    var body: some View {
        // 1. LA TUA SCROLLVIEW (Sempre presente, ma nascosta se non è la detent giusta)
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(academicWeeks, id: \.self) { week in
                    FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: week)
                        .id(week.first?.getString(format: "dd-MM-yyyy"))
                        .containerRelativeFrame(.horizontal)
                        .overlay {
                            if #available(iOS 17, *) {
                                if #unavailable(iOS 18.0) {
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onChange(of: proxy.frame(in: .named("scrollFractionSpace")).minX) { oldValue, newValue in
                                                // Se l'elemento è vicino a 0 (centro schermo nel container relativo), è quello selezionato
                                                if abs(newValue) < 20 {
                                                    let currentId = week.first?.getString(format: "dd-MM-yyyy")
                                                    if selectionFraction != currentId {
                                                        selectionFraction = currentId
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                        }
                }
            }
            .scrollTargetLayout()
        }
        .onAppear {
            if academicWeeks.isEmpty {
                academicWeeks = generateAcademicWeeks(selectedYear: selectedYear)
            }
        }
        .onChange(of: selectedYear) { _, newYear in
            academicWeeks = generateAcademicWeeks(selectedYear: newYear)
        }
        .id(selectedCourse + selectedYear + selectedAcademicYear + matricola)
        .task(id: selectedWeek) {// Calcoliamo l'ID target
            let targetId = selectedWeek.weekDates().first?.getString(format: "dd-MM-yyyy")
            
            var transaction = Transaction()
            transaction.disablesAnimations = true
            
            withTransaction(transaction) {
                selectionFraction = targetId
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 secondi
            
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never, axes: .horizontal)
        .scrollPosition(id: $selectionFraction)
        .opacity(opacity)
        .allowsHitTesting(selectedDetent == .fraction(0.15))
    }
    
    func generateAcademicWeeks(selectedYear: String) -> [[Date]] {
        guard let yearInt = Int(selectedYear) else { return [] }
        
        let startAcademicYear = Date(year: yearInt, month: 10, day: 1)
        let endAcademicYear = Date(year: yearInt + 1, month: 9, day: 30)
        
        guard var currentWeekStart = startAcademicYear.startOfWeek() else { return [] }
        
        var allWeeks: [[Date]] = []
        
        while currentWeekStart <= endAcademicYear {
            let weekOfDates = currentWeekStart.weekDates()
            allWeeks.append(weekOfDates)
            
            currentWeekStart = currentWeekStart.add(type: .weekOfYear, value: 1)
        }
        
        return allWeeks
    }
}

struct CalendarViewDay: View {
    @Environment(\.colorScheme) var colorScheme
    
    let filteredLessons: [Lesson]
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var selectedLesson: Lesson?
    @Binding var openCalendar: Bool
    @Binding var selectedDetent: PresentationDetent
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    private let safeAreas = UIApplication.shared.safeAreas
    
    var body: some View {
        ScrollView {
            if #available(iOS 17, *) {
                if #unavailable(iOS 18.0) {
                    Spacer()
                        .frame(height: safeAreas.top * 1.9)
                }
            }
            VStack(spacing: 10) {
                ForEach(filteredLessons) { lesson in
                    if lesson.tipo != "pause" && lesson.tipo != "chiusura_type" {
                        LessonCardView(lesson: lesson)
                            .onTapGesture {
                                openCalendar = true
                                selectedLesson = lesson
                                
                                detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium, .large]
                                selectedDetent = .large
                            }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 45, style: .continuous)
                                .fill(LinearGradient(stops: [.init(color: Color(white: 0, opacity: 0), location: 0), .init(color: Color(white: colorScheme == .light ? 0 : 1, opacity: colorScheme == .light ? 0.1 : 0.2), location: 0.5), .init(color: Color(white: 0, opacity: 0), location: 1)], startPoint: .leading, endPoint: .trailing))
                                .padding(.vertical, -5)
                                .padding(.horizontal, 15)
                            Text("---- Pausa di " + LessonCardView.getDuration(orario: lesson.orario) + " ----")
                        }
                    }
                }
            }
            .scrollViewTopPadding()
            Spacer()
                .frame(height: screenSize.height * 0.10)
        }
        .onScrollGeometry(openCalendar: $openCalendar, selectedDetent: $selectedDetent)
    }
}

#Preview {
    @Previewable @State var years: [Year] = []
    @Previewable @State var courses: [Corso] = []
    @Previewable @State var academicYears: [Anno] = []
    @Previewable @State var selectedTab: Int = 0
    
    CalendarView(years: $years, courses: $courses, academicYears: $academicYears, selectedTab: $selectedTab)
}

