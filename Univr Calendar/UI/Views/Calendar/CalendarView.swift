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

private enum Pages {
    case main
    case classrooms
}

struct CalendarView: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    @Environment(NetworkStateObserver.self) private var net
  
    @State private var sheetRouter: CalendarSheetRouter = .init()
    @State private var coordinator = CalendarCoordinator()
    
    @State private var viewModel = CalendarViewModel()
    @State private var firstLoading: Bool = true
    @State private var showSheet: Bool = true
    
    @State private var page: Pages = .main
    
    private var selectedWeekBinding: Binding<Date> {
        Binding(
            get: { coordinator.selectedWeek },
            set: { coordinator.selectDate($0) }
        )
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch page {
                case .main:
                    mainView
                case .classrooms:
                    ClassroomAvailabilityView(coordinator: coordinator, sheetRouter: sheetRouter)
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
            .onChange(of: coordinator.selectedWeek) { oldValue, newValue in
                guard !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
                Haptics.play(.selection, state: "selection")
                if !sheetRouter.openSettings { sheetRouter.manager.setDetent(.small) }
                Task {
                    try? await Task.sleep(for: .seconds(0.2))
                    GlobalHaptics.shared.state = ""
                }
            }
            .removeTopSafeArea()
            .animation(.default, value: viewModel.checkingUpdates)
            .animation(.default, value: viewModel.updateAvailable)
            .animation(.default, value: net.status)
        }
        .customSheet(isPresented: $showSheet, manager: sheetRouter.manager, detents: sheetRouter.detents) {
            CalendarSheetContent(
                router: sheetRouter,
                selectedWeek: selectedWeekBinding
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
                get: { self.firstLoading ? nil : coordinator.selectedWeek },
                set: { newValue in
                    if let validDate = newValue {
                        coordinator.selectDate(validDate)
                    }
                }
            ), anchor: .center)
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
    
    // MARK: - Toolbar Builder
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(coordinator.selectedWeek.getCurrentWeekdaySymbol(length: .wide))
                        .font(.headline)
                    Text("\(coordinator.selectedWeek.day) \(coordinator.selectedWeek.getCurrentMonthSymbol(length: .wide))")
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
        sheetRouter.tempSettings.sync(with: settings)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            if !settings.latestVersion.isEmpty && settings.latestVersion != Bundle.main.clearAppVersion {
                try? await Task.sleep(for: .seconds(0.2))
                sheetRouter.routeToWhatsNew()
            }
        }
        
        Task {
            if settings.selectedCourse != "0" {
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
        guard let selectedYearInt = Int(settings.selectedYear) else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let currentAcademicYear = academicYearId(for: today)
        
        if selectedYearInt == currentAcademicYear {
            coordinator.selectDate(today)
        } else {
            coordinator.selectDate(Date(year: selectedYearInt, month: 10, day: 1))
        }
    }
    
    private func academicYearId(for date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        let year = comps.year ?? 0
        let month = comps.month ?? 1
        return month >= 10 ? year : year - 1
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
                    if let exactMatch = viewModel.academicYearDays.first(where: { Calendar.current.isDate($0, inSameDayAs: coordinator.selectedWeek) }) {
                        coordinator.selectDate(exactMatch)
                    } else {
                        coordinator.selectDate(viewModel.academicYearDays.first ?? Calendar.current.startOfDay(for: Date()))
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
                let hasChanged = sheetRouter.tempSettings.hasChanged(from: settings)
                
                if hasChanged {
                    viewModel.state = .loading
                    sheetRouter.tempSettings.apply(to: settings)
                    
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
                } else if sheetRouter.tempSettings.matricola != settings.matricola {
                    settings.matricola = sheetRouter.tempSettings.matricola
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
