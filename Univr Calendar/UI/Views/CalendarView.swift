//
//  CalendarView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/25.
//

import SwiftUI
import UnivrCore

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
    @State var openCalendar: Bool = false
    
    @Binding var selectedTab: Int
    
    @State var tempSelectedYear: String = ""
    @State var tempSelectedCourse: String = ""
    @State var tempSelectedAcademicYear: String = ""
    @State var tempMatricola: String = ""
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    @State var safeAreas: UIEdgeInsets = .zero
    
    @State var selectedMonth: Int = Date().month
    @State private var selection: String? = ""
    @State private var selectionFraction: String? = ""
    
    @State private var scrollUpdateTask: Task<Void, Never>?
    @State private var firstLoading: Bool = true
    
    @FocusState var settingsSearchFocus: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if viewModel.loading || firstLoading {
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
                                   CalendarViewDay(filteredLessons: viewModel.days[i], detents: $detents, selectedLesson: $selectedLesson, openCalendar: $openCalendar, selectedDetent: $selectedDetent, firstLoading: $firstLoading)
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
            .id((firstLoading ? "ready" : "loading") + settings.selectedCourse + settings.selectedYear + settings.selectedAcademicYear + settings.matricola)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection, anchor: .center)
            .task(id: selectedWeek) {
                if !viewModel.loading && !firstLoading {
                    let newSelection = selectedWeek.getString(format: "dd-MM-yyyy")
                    if newSelection != selection {
                        selection = newSelection
                    }
                    
                    if selectedMonth != selectedWeek.month {
                        selectedMonth = selectedWeek.month
                    }
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
                    .sheetDesign(transition, detent: $selectedDetent)
            }
            .onAppear {
                inizializeData()
            }
            .onChange(of: selection) {
                scrollUpdateTask?.cancel()
                
                scrollUpdateTask = Task {
                    if !Task.isCancelled {
                        await MainActor.run {
                            if let date = selection?.date(format: "dd-MM-yyyy") {
                                if selectedWeek.getString(format: "dd-MM-yyyy") != selection {
                                    selectedWeek = date
                                }
                                
                                if selectedDetent != .fraction(0.15) {
                                    selectedDetent = .fraction(0.15)
                                }
                            }
                        }
                    }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(selectedWeek.getCurrentWeekdaySymbol(length: .full))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(selectedWeek.day) \(selectedWeek.getCurrentMonthSymbol(length: .full))")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .toolbarTitleShadow(colorScheme)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .toolbarBackgroundVisibility(.hidden)
                
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
                            .disabled(viewModel.loading)
                    }
                } else {
                    ToolbarItem {
                        settingsButtonLegacy
                            .disabled(viewModel.loading)
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
        .onAppear {
            safeAreas = UIApplication.shared.safeAreas
        }
        .onChange(of: viewModel.loading) { oldValue, isLoading in
            if isLoading {
                selection = nil
                firstLoading = true
            } else {
                let today = Date().getString(format: "dd-MM-yyyy")
                
                DispatchQueue.main.async {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    
                    withTransaction(transaction) {
                        if viewModel.daysString.contains(today) {
                            selection = today
                        } else {
                            selection = viewModel.daysString.first
                        }
                        
                        firstLoading = false
                    }
                }
            }
        }
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
        .clipShape(.circle)
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
        .background(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .clipShape(.capsule)
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
        .background(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .clipShape(.capsule)
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
            GeometryReader { proxy in
                let currentHeight = proxy.size.height
                let screenHeight = UIScreen.main.bounds.height
        
                let largeHeight = screenHeight * 0.85
                let mediumHeightHigh = screenHeight * 0.55
                let mediumHeightLow = screenHeight * 0.45
                let smallHeight = screenHeight * 0.15
        
                let fadeRange: CGFloat = screenHeight * 0.05
        
                let largeOpacity = 1.0 - (Double(largeHeight - currentHeight) / Double(fadeRange))
                let mediumOpacity = 1.0 - ((currentHeight < mediumHeightHigh ? Double(mediumHeightLow - currentHeight) : Double(currentHeight - mediumHeightHigh)) / Double(fadeRange))
                let smallOpacity = 1.0 - (Double(currentHeight - smallHeight) / Double(fadeRange))
        
                ZStack {
                    if currentHeight < screenHeight * 0.25 {
                        FractionDatePickerContainer(selectedWeek: $selectedWeek, loading: $viewModel.loading, selectionFraction: $selectionFraction, selectedDetent: $selectedDetent)
                            .opacity(settingsSearchFocus ? 0 : min(max(smallOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == .fraction(0.15))
                    }
        
                    if currentHeight > screenHeight * 0.35 && currentHeight < screenHeight * 0.65 && !settingsSearchFocus {
                        DatePickerContainer(selectedDetent: $selectedDetent, selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
                            .opacity(settingsSearchFocus ? 0 : min(max(mediumOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == (isIpad ? .fraction(0.75) : .medium))
                    }
        
                    if currentHeight > screenHeight * 0.75 || settingsSearchFocus {
                        if openSettings {
                            NavigationStack {
                                Settings(
                                    detents: $detents,
                                    openSettings: $openSettings,
                                    openCalendar: $openCalendar,
                                    selectedTab: $selectedTab,
                                    selectedDetent: $selectedDetent,
                        
                                    selectedYear: $tempSelectedYear,
                                    selectedCourse: $tempSelectedCourse,
                                    selectedAcademicYear: $tempSelectedAcademicYear,
                                    matricola: $tempMatricola,
                                    searchTextFieldFocus: $settingsSearchFocus
                                )
                                .toolbar {
                                    ToolbarItem(placement: .principal) {
                                        Text("Impostazioni")
                                            .font(.headline)
                                            .opacity(settingsSearchFocus ? 1 : min(max(largeOpacity, 0), 1))
                                    }
                                }
                                .navigationBarTitleDisplayMode(.inline)
                            }
                            .opacity(settingsSearchFocus ? 1 : min(max(largeOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == .large)
                        } else {
                            LessonDetailsView(selectedLesson: $selectedLesson, selectedDetent: $selectedDetent)
                                .opacity(settingsSearchFocus ? 0 : min(max(largeOpacity, 0), 1))
                                .allowsHitTesting(selectedDetent == .large)
                        }
                    }
                }
            }
        }
    }
    
    private func openSettingsAction() {
        openSettings = true
        openCalendar = true

        detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium, .large]
        selectedDetent = .large
    }
    
    private func updateDate() {
        let today: Date = .now
        if let year = Int(settings.selectedYear), let years = NetworkCache.shared.years.last, let currentYear = Int(years.valore) {
            if year != currentYear {
                if selectedWeek.getString(format: "dd-MM-yyyy") != "01-10-\(year)" {
                    selectedWeek = "01-10-\(year)".date(format: "dd-MM-yyyy") ?? Date(year: year, month: today.month, day: today.day)
                }
            } else {
                if selectedWeek.getString(format: "dd-MM-yyyy") != Date().getString(format: "dd-MM-yyyy") {
                    selectedWeek = Date(year: today.year, month: today.month, day: today.day)
                }
            }
        } else {
            if selectedWeek.getString(format: "dd-MM-yyyy") != Date().getString(format: "dd-MM-yyyy") {
                selectedWeek = Date(year: today.year, month: today.month, day: today.day)
            }
        }
    }
    
    private func inizializeData() {
        selectedDetent = .fraction(0.15)
        detents = [.fraction(0.15), isIpad ? .fraction(0.75) : .medium]
        
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
            viewModel.loadNetworkFromCache()
            
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
                    settings.selectedYear = ""
                    settings.selectedCourse = ""
                    settings.selectedAcademicYear = ""
                    settings.matricola = ""
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
                    settings.matricola = ""
                    settings.matricola = tempMatricola
                    
                    openCalendar = true
                    viewModel.loading = true
                    viewModel.organizeData(selectedYear: settings.selectedYear, matricola: settings.matricola)
                    viewModel.loading = false
                } else {
                    if selectedTab == 0 {
                        openCalendar = oldOpenCalendar
                    }
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
    @Binding var firstLoading: Bool

    private let screenSize: CGRect = UIApplication.shared.screenSize
    @State var safeAreas: UIEdgeInsets = .zero
    
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
                        HStack(alignment: .bottom) {
                            Image(systemName: "cup.and.heat.waves.fill")
                                .font(.system(size: 40))
                            Text(lesson.durationCalculated)
                                .font(.system(size: 30))
                                .italic()
                                .bold()
                        }
                        .foregroundStyle(Color(white: 0.35))
                    }
                }
            }
            .scrollViewTopPadding()
            Spacer().frame(height: screenSize.height * 0.10)
        }
        .onScrollGeometry(openCalendar: $openCalendar, selectedDetent: $selectedDetent, firstLoading: $firstLoading)
        .onAppear {
            safeAreas = UIApplication.shared.safeAreas
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: Int = 0
    
    CalendarView(selectedTab: $selectedTab)
        .environment(UserSettings.shared)
}

