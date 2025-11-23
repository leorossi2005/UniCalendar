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
    @Environment(UserSettings.self) var settings
    @Namespace var transition
    
    @State var viewModel = CalendarViewModel()
    
    @State var selectedDetent: PresentationDetent = .fraction(0.15)
    
    @State var selectedWeek: Date = Date()
    
    @State var detents: Set<PresentationDetent> = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium]
    @State var selectedLesson: Lesson? = nil
    
    @State var openSettings: Bool = false
    @State var oldOpenCalendar: Bool = false
    @State var openCalendar: Bool = {
        if #available(iOS 26, *) {
            return false
        } else {
            return true
        }
    }()
    
    @Binding var years: [Year]
    @Binding var courses: [Corso]
    @Binding var academicYears: [Anno]
    
    @Binding var selectedTab: Int
    
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
                        if settings.selectedCourse != "0" {
                           ScrollView {
                               if #available(iOS 17, *) {
                                   if #unavailable(iOS 18.0) {
                                       Spacer().frame(height: safeAreas.top * 1.9)
                                   }
                               }
                               VStack(spacing: 10) {
                                   ForEach(0..<5, id: \.self) { _ in
                                       LessonCardView(lesson: .sample)
                                           .redacted(reason: .placeholder)
                                           .shimmeringPlaceholder()
                                   }
                               }
                               .scrollViewTopPadding()
                               Spacer().frame(height: screenSize.height * 0.10)
                           }
                           .containerRelativeFrame(.horizontal)
                       } else {
                           Text("Devi scegliere un corso")
                               .bold()
                               .font(.title2)
                               .containerRelativeFrame(.horizontal)
                       }
                   } else {
                       if !viewModel.noLessonsFound {
                           ForEach(viewModel.days.indices, id: \.self) { i in
                               if !viewModel.days[i].isEmpty {
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
                       } else {
                           Text("Nessuna lezione trovata per questo corso")
                               .bold()
                               .font(.title2)
                               .containerRelativeFrame(.horizontal)
                       }
                   }
                }
                .multilineTextAlignment(.center)
                .scrollTargetLayout()
            }
            .id(settings.selectedCourse + settings.selectedYear + settings.selectedAcademicYear + settings.matricola)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection)
            .task(id: selectedWeek) {
                if selectedWeek.getString(format: "dd-MM-yyyy") != selection && !viewModel.loading {
                    selection = selectedWeek.getString(format: "dd-MM-yyyy")
                }
            }
            .sheet(isPresented: $openCalendar) {
                sheetContent
                    .presentationDetents(detents, selection: $selectedDetent)
                    .interactiveDismissDisabled(true)
                    .presentationBackgroundInteraction(.enabled(upThrough: isIpad ? .fraction(0.75) : isIpad ? .fraction(0.75) : .medium))
                    .disabled((viewModel.loading || viewModel.noLessonsFound) && !openSettings)
                    .onChange(of: selectedDetent) { oldValue, newValue in
                        handleDetentChange(oldValue: oldValue, newValue: newValue)
                    }
                    .onChange(of: selection) {
                        if let date = selection?.date(format: "dd-MM-yyyy") {
                            if selectedWeek.getString(format: "dd-MM-yyyy") != selection {
                                selectedWeek = date
                            }
                            
                            selectedMonth = selectedWeek.month
                            selectedDetent = .fraction(0.15)
                        }
                    }
                    .sheetDesign(transition)
            }
            .onAppear {
                inizializeData()
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
            .onChange(of: openCalendar) { oldValue, newValue in
                oldOpenCalendar = oldValue
                
                if selectedTab == 0 {
                    if !newValue {
                        selectionFraction = nil
                    }
                } else {
                    openCalendar = false
                }
            }
            .toolbar {
                if viewModel.checkingUpdates || viewModel.showUpdateAlert {
                    if #available(iOS 26, *) {
                        ToolbarItem {
                            if viewModel.showUpdateAlert {
                                updateAvailable
                            } else {
                                checkingUpdate
                            }
                        }
                    } else {
                        ToolbarItem {
                            if viewModel.showUpdateAlert {
                                updateAvailableLegacy
                            } else {
                                checkingUpdateLegacy
                            }
                        }
                    }
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible)
                }
                
                if #available(iOS 26, *) {
                    ToolbarItem {
                        settingsButton
                    }
                } else {
                    ToolbarItem {
                        settingsButtonLegacy
                    }
                }
                
                ToolbarItem(placement: .bottomBar) { Spacer() }
                
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .bottomBar) {
                        calendarButton
                    }
                    .matchedTransitionSource(id: "calendar", in: transition)
                }
            }
            .animation(.default, value: viewModel.checkingUpdates)
            .animation(.default, value: viewModel.showUpdateAlert)
            .removeTopSafeArea()
        }
        .hideTabBarCompatible()
    }
    
    var settingsButton: some View {
        Button(action: openSettingsAction) {
            Label("", systemImage: "gearshape.fill")
        }
    }
    
    var settingsButtonLegacy: some View {
        Button(action: openSettingsAction) {
            Label("", systemImage: "gearshape.fill")
                .font(Font.system(size: 25))
                .padding(3)
                .foregroundStyle(colorScheme == .light ? .black : .white)
        }
        .frame(height: 45)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .overlay(Circle().stroke(colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), lineWidth: 2))
    }
    
    var updateAvailable: some View {
        HStack {
            Button(action: {
                DispatchQueue.main.async {
                    viewModel.confirmUpdate(selectedYear: settings.selectedYear, matricola: settings.matricola)
                }
            }) {
                Text("Aggiorna")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            Text("Ci sono novita!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }
    
    var checkingUpdate: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Controllo aggiornamenti...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }
    
    var updateAvailableLegacy: some View {
        HStack {
            Button(action: {
                DispatchQueue.main.async {
                    viewModel.confirmUpdate(selectedYear: settings.selectedYear, matricola: settings.matricola)
                }
            }) {
                Text("Aggiorna")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .font(Font.system(size: 25))
                    .padding(3)
                    .foregroundStyle(colorScheme == .light ? .black : .white)
            }
            Text("Ci sono novita!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 45)
        .padding(.horizontal, 12)
        .clipShape(.capsule)
        .background(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .overlay(Capsule().stroke(colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), lineWidth: 2))
    }
    
    var checkingUpdateLegacy: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Controllo aggiornamenti...")
                .font(.caption)
                .foregroundStyle(.secondary)
                .font(Font.system(size: 25))
                .padding(7)
                .foregroundStyle(colorScheme == .light ? .black : .white)
        }
        .frame(height: 45)
        .padding(.horizontal, 12)
        .clipShape(.capsule)
        .background(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .overlay(Capsule().stroke(colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), lineWidth: 2))
    }
    
    var calendarButton: some View {
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
    
    @ViewBuilder
    var sheetContent: some View {
        ZStack {
            FractionDatePickerContainer(selectedWeek: $selectedWeek, loading: $viewModel.loading, selectionFraction: $selectionFraction, selectedDetent: $selectedDetent)
            
            DatePickerContainer(selectedDetent: $selectedDetent, selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
            
            if selectedDetent == .large {
                GeometryReader { proxy in
                    let currentHeight = proxy.size.height
                    let screenHeight = UIScreen.main.bounds.height
                    
                    let bigHeight = screenHeight * 0.85
                    
                    let fadeRange: CGFloat = screenHeight * 0.05
                    
                    let dynamicOpacity = 1.0 - (Double(bigHeight - currentHeight) / Double(fadeRange))
                    
                    NavigationStack {
                        if openSettings {
                            Settings(
                                detents: $detents,
                                openSettings: $openSettings,
                                selectedTab: $selectedTab,
                                selectedDetent: $selectedDetent,
                                
                                selectedYear: $tempSelectedYear,
                                selectedCourse: $tempSelectedCourse,
                                selectedAcademicYear: $tempSelectedAcademicYear,
                                matricola: $tempMatricola
                            )
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text("Impostazioni")
                                        .font(.headline)
                                        .opacity(min(max(dynamicOpacity, 0), 1))
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
                        } else if let lesson = selectedLesson{
                            lessonDetailView(lesson: lesson)
                        }
                    }
                    .opacity(min(max(dynamicOpacity, 0), 1))
                    .allowsHitTesting(selectedDetent == .large)
                }
            }
        }
    }
    
    func lessonDetailView(lesson: Lesson) -> some View {
        VStack {
            Text("Informazioni sulla lezione (WIP)")
                .font(.title2)
                .bold()
            Spacer().frame(height: 20)
            Text(selectedLesson!.nomeInsegnamento)
            Spacer().frame(height: 10)
            Text(selectedLesson!.nameOriginal)
            Spacer().frame(height: 10)
            Text(selectedLesson!.orario)
            Spacer().frame(height: 10)
            Text(selectedLesson!.data)
            Spacer().frame(height: 10)
            Text(selectedLesson!.aula)
            Spacer().frame(height: 10)
            Text(selectedLesson!.docente)
        }
        .padding()
        .multilineTextAlignment(.center)
    }
    
    private func openSettingsAction() {
        openSettings = true
        openCalendar = true

        detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium, .large]
        selectedDetent = .large
    }
    
    private func updateDate() {
        if let year = Int(settings.selectedYear) {
            selectedWeek = Date(year: year, month: Date().month, day: Date().day)
        }
    }
    
    private func inizializeData() {
        updateDate()
        
        tempSelectedYear = settings.selectedYear
        tempSelectedCourse = settings.selectedCourse
        tempSelectedAcademicYear = settings.selectedAcademicYear
        tempMatricola = settings.matricola
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            openCalendar = true
            oldOpenCalendar = true
        }
        
        if settings.selectedCourse != "0" {
            viewModel.loadFromCache(selYear: settings.selectedYear, matricola: settings.matricola)
            
            Task {
                await viewModel.loadLessons(
                    corso: settings.selectedCourse,
                    anno: settings.selectedAcademicYear,
                    selYear: settings.selectedYear,
                    matricola: settings.matricola
                )
            }
        }
        
    }
    
    private func handleDetentChange(oldValue: PresentationDetent, newValue: PresentationDetent) {
        if newValue != .large {
            if openSettings {
                let hasChanged = tempSelectedCourse != settings.selectedCourse || tempSelectedAcademicYear != settings.selectedAcademicYear || tempSelectedYear != settings.selectedYear
                
                if hasChanged {
                    settings.selectedYear = tempSelectedYear
                    settings.selectedCourse = tempSelectedCourse
                    settings.selectedAcademicYear = tempSelectedAcademicYear
                    settings.matricola = tempMatricola
                    
                    openCalendar = true
                    viewModel.loading = true
                    viewModel.lessons = []
                    
                    if settings.selectedCourse != "0" {
                        updateDate()
                        
                        viewModel.clearPendingUpdate()
                        
                        Task {
                            await viewModel.loadLessons(
                                corso: settings.selectedCourse,
                                anno: settings.selectedAcademicYear,
                                selYear: settings.selectedYear,
                                matricola: settings.matricola
                            )
                        }
                    }
                } else if tempMatricola != settings.matricola {
                    settings.matricola = tempMatricola
                    
                    openCalendar = true
                    viewModel.loading = true
                    viewModel.organizeData(selectedYear: settings.selectedYear, matricola: settings.matricola)
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
        } else {
            oldOpenCalendar = openCalendar
        }
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
                    Spacer().frame(height: safeAreas.top * 1.9)
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
            Spacer().frame(height: screenSize.height * 0.10)
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
        .environment(UserSettings.shared)
}

