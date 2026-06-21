//
//  CalendarView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

enum Pages {
    case main
    case classrooms
}

struct CalendarView: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    @Environment(NetworkStateObserver.self) private var net
  
    @State private var sheetRouter: CalendarSheetRouter = .init()
    
    @State private var viewModel = CalendarViewModel()
    @State private var selectedWeek: Date = Calendar.current.startOfDay(for: Date())
    @State private var firstLoading: Bool = true
    @State private var showSheet: Bool = true
    
    @State var tempSettings: TempSettingsState = .init()
    
    @State var page: Pages = .main
    
    //TEMP
    @State private var availabilityManager = AvailabilityDataManager()
    @State private var room: Room?
    
    var body: some View {
        NavigationStack {
            Group {
                switch page {
                case .main:
                    mainView
                case .classrooms:
                    classroomView
                }
            }
            .toolbar {
                buildToolbar()
            }
            .modify { view in
                if #available(iOS 26, *) { view } else {
                    view
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }
            .onChange(of: sheetRouter.manager.selectedDetent) { oldValue, newValue in
                handleDetentChange(oldValue: oldValue, newValue: newValue)
            }
            .onAppear {
                inizializeData()
            }
            .onChange(of: viewModel.state == .loading) { _, isLoading in
                handleLoadingChange(isLoading)
            }
            .onChange(of: net.status) { _, newStatus in
                if newStatus == .connected {
                    Task {
                        await viewModel.loadLessons(
                            corso: settings.selectedCourse,
                            anno: settings.selectedAcademicYear,
                            selYear: settings.selectedYear,
                            matricola: settings.matricola,
                            updating: false
                        )
                    }
                }
            }
            .removeTopSafeArea()
            .animation(.default, value: viewModel.checkingUpdates)
            .animation(.default, value: viewModel.updateAvailable)
            .animation(.default, value: net.status)
        }
        .customSheet(isPresented: $showSheet, manager: sheetRouter.manager, detents: sheetRouter.detents) {
            CalendarSheetContent(
                selectedWeek: $selectedWeek,
                selectedLesson: $sheetRouter.selectedLesson,
                selectedRoom: $sheetRouter.selectedRoom,
                openAddToCalendar: $sheetRouter.openAddToCalendar,
                openSettings: $sheetRouter.openSettings,
                openWhatsNew: $sheetRouter.openWhatsNew,
                tempSettings: $tempSettings
            )
            .disabled((viewModel.state == .loading || viewModel.state == .empty || viewModel.schedule.isEmpty) && !sheetRouter.openSettings)
        }
        .environment(sheetRouter.manager)
    }
    
    // MARK: - MainView
    private var mainView: some View {
        ZStack {
            calendarScrollView
            
            if viewModel.state != .loaded || firstLoading {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                stateOverlays
            }
        }
    }
    
    private var calendarScrollView: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.academicYearDays, id: \.self) { date in
                    let dailyLessons = viewModel.events(for: date) ?? []
                    
                    Group {
                        if !dailyLessons.isEmpty {
                            CalendarViewDay(
                                filteredLessons: dailyLessons,
                                sheetRouter: sheetRouter
                            )
                        } else {
                            ContentUnavailableView(
                                "Giornata Libera",
                                systemImage: "moon.zzz",
                                description: Text("Non ci sono lezioni in programma per oggi.")
                            )
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(date)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never, axes: .horizontal)
        .scrollPosition(id: Binding<Date?>(
                get: { self.firstLoading ? nil : self.selectedWeek },
                set: { newValue in
                    if let validDate = newValue {
                        self.selectedWeek = validDate
                    }
                }
            ), anchor: .center)
        .onChange(of: selectedWeek) { oldValue, newValue in
            if !Calendar.current.isDate(oldValue, inSameDayAs: newValue) {
                Haptics.play(.selection, state: "selection")
                if !sheetRouter.openSettings { sheetRouter.manager.setDetent(.small) }
                Task {
                    try? await Task.sleep(for: .seconds(0.2))
                    GlobalHaptics.shared.state = ""
                }
            }
        }
    }
    
    @ViewBuilder
    private var stateOverlays: some View {
        let hasCourse = settings.selectedCourse != "0"
        
        if net.status != .connected && (viewModel.schedule.isEmpty || !hasCourse) {
            ContentUnavailableView(
                "Sei Offline",
                systemImage: "wifi.slash",
                description: Text(hasCourse ? "Connettiti a internet per scaricare le tue lezioni." : "Connettiti a internet per configurare il tuo corso.")
            )
        } else {
            switch viewModel.state {
            case .loading:
                loadingStateOverlay(hasCourse: hasCourse)
                
            case .empty:
                ContentUnavailableView(
                    "Nessuna Lezione",
                    systemImage: "graduationcap",
                    description: Text(hasCourse ? "Non è stata trovata nessuna lezione per questo corso." : "Scegli un corso dalle impostazioni per iniziare.")
                )
                
            case .offline:
                ContentUnavailableView(
                    "Sei Offline",
                    systemImage: "wifi.slash",
                    description: Text(hasCourse ? "Connettiti a internet per scaricare le tue lezioni." : "Connettiti a internet per configurare il tuo corso.")
                )
                
            case .error(let msg):
                ContentUnavailableView(
                    "Si è verificato un errore",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
                
            case .loaded:
                if firstLoading {
                    loadingStateOverlay(hasCourse: hasCourse)
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadingStateOverlay(hasCourse: Bool) -> some View {
        if hasCourse {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<10, id: \.self) { _ in
                        LessonCard(lesson: .sample)
                            .shimmeringPlaceholder(opacity: colorScheme == .light ? 0.5 : 0.7)
                    }
                }
            }
            .scrollViewTopPadding()
            .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
            .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
        } else {
            ContentUnavailableView(
                "Nessun corso",
                systemImage: "graduationcap",
                description: Text("Scegli un corso dalle impostazioni per iniziare.")
            )
        }
    }
    
    // MARK: - ClassRoomView
    private var classroomView: some View {
        ScrollView {
            VStack {
                if let room = room {
                    RoomCard(room: room)
                }
            }
            .onTapGesture {
                Haptics.play(.impact(weight: .light, intensity: 0.5))
                sheetRouter.routeToRoom("")
            }
        }
        .task {
            try? await availabilityManager.getAvailability(date: "18-06-2026")
            room = availabilityManager.room
        }
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
    }
    
    // MARK: - Toolbar Builder
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(selectedWeek.getCurrentWeekdaySymbol(length: .wide))
                        .font(.headline)
                    Text("\(selectedWeek.day) \(selectedWeek.getCurrentMonthSymbol(length: .wide))")
                        .font(.subheadline)
                }
                
                Image(systemName: "wifi.slash")
                    .symbolEffect(.appear.up.byLayer, isActive: net.status == .connected)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.yellow.opacity(0.8))
            }
            .fixedSize()
            .modify { view in
                if #available(iOS 26, *) { view } else {
                    view
                        .padding(.bottom, 8)
                }
            }
        }
        .toolbarBackgroundVisibility(.hidden)
        
        if viewModel.checkingUpdates {
            ToolbarItem(placement: .topBarTrailing) {
                ProgressView()
                    .controlSize(.small)
            }
        } else if viewModel.updateAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Aggiorna") {
                    Task { @MainActor in
                        await viewModel.confirmUpdate(matricola: settings.matricola)
                    }
                }
                .font(.caption)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                page = page == .main ? .classrooms : .main
            } label: {
                HStack {
                    Image(systemName: page == .main ? "calendar" : "clock")
                        .symbolReplace()
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: openSettingsAction) {
                Label("", systemImage: "gearshape.fill")
            }
        }
    }
    
    // MARK: - Logic Methods
    private func openSettingsAction() {
        Haptics.play(.impact(weight: .light))
        sheetRouter.routeToSettings()
    }
    
    private func inizializeData() {
        viewModel.generateAcademicYearDays(for: settings.selectedYear)
        updateDate()
        tempSettings.sync(with: settings)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            if !settings.latestVersion.isEmpty && settings.latestVersion != Bundle.main.clearAppVersion {
                try? await Task.sleep(for: .seconds(0.2))
                sheetRouter.routeToWhatsNew()
            }
        }
        
        Task {
            if settings.selectedCourse != "0" {
                await viewModel.loadNetworkFromCache()
                await viewModel.loadFromCache(matricola: settings.matricola)
            }
            
            await viewModel.loadLessons(
                corso: settings.selectedCourse,
                anno: settings.selectedAcademicYear,
                selYear: settings.selectedYear,
                matricola: settings.matricola,
                updating: false
            )
        }
    }
    
    private func updateDate() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let years = NetworkCache.shared.years.last,
           let currentYear = Int(years.id),
           let year = Int(settings.selectedYear),
           year != currentYear {
            let startAcademic = Date(year: year, month: 10, day: 1)
            if !Calendar.current.isDate(selectedWeek, inSameDayAs: startAcademic) {
                selectedWeek = startAcademic
            }
        } else {
            if !Calendar.current.isDate(selectedWeek, inSameDayAs: today) {
                selectedWeek = today
            }
        }
    }
    
    private func handleLoadingChange(_ isLoading: Bool) {
        if isLoading {
            Haptics.play(.start)
            firstLoading = true
        } else {
            Task { @MainActor in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    if let exactMatch = viewModel.academicYearDays.first(where: { Calendar.current.isDate($0, inSameDayAs: selectedWeek) }) {
                        selectedWeek = exactMatch
                    } else {
                        selectedWeek = viewModel.academicYearDays.first ?? Calendar.current.startOfDay(for: Date())
                    }
                    firstLoading = false
                    Haptics.play(.success)
                }
            }
        }
    }
    
    private func handleDetentChange(oldValue: CustomSheetDetent, newValue: CustomSheetDetent) {
        if newValue != .large {
            if sheetRouter.openSettings {
                let hasChanged = tempSettings.hasChanged(from: settings)
                
                if hasChanged {
                    viewModel.state = .loading
                    tempSettings.apply(to: settings)
                    
                    if settings.selectedCourse != "0" {
                        updateDate()
                        viewModel.clearPendingUpdate()
                        Task {
                            await viewModel.loadLessons(
                                corso: settings.selectedCourse,
                                anno: settings.selectedAcademicYear,
                                selYear: settings.selectedYear,
                                matricola: settings.matricola,
                                updating: true
                            )
                        }
                    } else {
                        Task {
                            await viewModel.clearAll()
                        }
                    }
                } else if tempSettings.matricola != settings.matricola {
                    settings.matricola = tempSettings.matricola
                    Task {
                        await viewModel.loadFromCache(matricola: settings.matricola)
                    }
                }
            } else if oldValue == .large {
                if sheetRouter.openWhatsNew {
                    settings.latestVersion = Bundle.main.clearAppVersion
                }
            }
            
            sheetRouter.resetToCalendar()
        }
    }
}

// MARK: - Subviews
struct CalendarViewDay: View {
    @Environment(\.colorScheme) var colorScheme
    
    let filteredLessons: [Lesson]
    var sheetRouter: CalendarSheetRouter
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(filteredLessons) { lesson in
                    if lesson.type != .pause && lesson.type != .closure {
                        LessonCard(lesson: lesson)
                            .onTapGesture {
                                Haptics.play(.impact(weight: .light, intensity: 0.5))
                                sheetRouter.routeToLesson(lesson)
                            }
                            .contextMenu(
                                menuItems: {
                                    Button(action: {
                                        Haptics.play(.impact(weight: .light, intensity: 0.5))
                                        sheetRouter.routeToLesson(lesson, addToCalendar: true)

                                    }) {
                                        Label("Aggiungi al calendario", systemImage: "calendar.badge.plus")
                                    }
                                    Button(action: {
                                        Haptics.play(.impact(weight: .light, intensity: 0.5))
                                        sheetRouter.routeToLesson(lesson)
                                    }) {
                                        Label("Vedi più dettagli", systemImage: "ellipsis")
                                    }
                                },
                                preview: {
                                    LessonCardPreview(lesson: lesson)
                                }
                            )
                    } else {
                        HStack(alignment: .bottom) {
                            Image(systemName: .cupDynamic)
                                .font(.system(size: 40))
                            Text(Duration.seconds(lesson.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                                .font(.system(size: 30))
                                .italic()
                                .bold()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollViewTopPadding()
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
    }
}

#Preview {
    CalendarView()
        .environment(UserSettings.shared)
}
