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

@MainActor
@Observable
class CalendarSheetRouter {
    let manager: GlobalSheetManager
    
    var selectedLesson: Lesson? = nil
    var openSettings: Bool = false
    var openWhatsNew: Bool = false
    var openAddToCalendar: Bool = false
    
    var detents: [CustomSheetDetent] = [.small, .medium]
    
    init(selectedDetent: CustomSheetDetent? = nil) {
        if let detent = selectedDetent {
            manager = .init(initialDetent: detent)
        } else {
            manager = .init()
        }
    }
    
    // MARK: - Azioni di navigazione
    func routeToSettings() {
        openSettings = true
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToWhatsNew() {
        openWhatsNew = true
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToLesson(_ lesson: Lesson, addToCalendar: Bool = false) {
        selectedLesson = lesson
        openAddToCalendar = addToCalendar
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    // MARK: - Reset automatico
    func resetToCalendar() {
        selectedLesson = nil
        openSettings = false
        openWhatsNew = false
        openAddToCalendar = false
        detents = [.small, .medium]
    }
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
    
    @State var tempSettings: TempSettingsState = .init()
    
    var body: some View {
        NavigationStack {
            mainScrollView
                .toolbar {
                    buildToolbar()
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
        .customSheet(isPresented: .constant(true), manager: sheetRouter.manager, detents: sheetRouter.detents) {
            DynamicSheetContent(
                selectedWeek: $selectedWeek,
                selectedLesson: $sheetRouter.selectedLesson,
                openAddToCalendar: $sheetRouter.openAddToCalendar,
                openSettings: $sheetRouter.openSettings,
                openWhatsNew: $sheetRouter.openWhatsNew,
                tempSettings: $tempSettings
            )
            .disabled((viewModel.state == .loading || viewModel.state == .empty || viewModel.schedule.isEmpty) && !sheetRouter.openSettings)
        }
        .environment(sheetRouter.manager)
    }
    
    // MARK: - Main Content
    private var mainScrollView: some View {
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
    
    // MARK: - Toolbar Builder
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(selectedWeek.getCurrentWeekdaySymbol(length: .wide))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(selectedWeek.day) \(selectedWeek.getCurrentMonthSymbol(length: .wide))")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .toolbarTitleShadow(colorScheme)
            .fixedSize(horizontal: true, vertical: false)
        }
        .toolbarBackgroundVisibility(.hidden)
        
        if viewModel.checkingUpdates || viewModel.updateAvailable {
            ToolbarItem {
                if #available(iOS 26, *) {
                    modernUpdateStatus
                } else {
                    legacyUpdateStatus
                }
            }
        } else if net.status == .disconnected {
            ToolbarItem {
                if #available(iOS 26, *) {
                    Button {} label: {
                        Text("Modalità offline")
                            .foregroundStyle(.black)
                            .font(.caption)
                            .bold()
                    }
                    .tint(.yellow.opacity(0.7))
                    .buttonStyle(.glassProminent)
                } else {
                    Text("Modalità offline")
                        .blur(radius: net.status != .connected ? 0 : 20)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(colorScheme == .light ? .yellow : Color(hex: "#CCAA00")!)
                                .strokeBorder(colorScheme == .light ? Color(hex: "#CCAA00")! : Color(hex: "#B39500")!, lineWidth: 2)
                        }
                }
            }
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.flexible)
        }
        
        ToolbarItem {
            if #available(iOS 26, *) {
                modernSettingsButton
            } else {
                legacySettingsButton
            }
        }
    }
    
    // MARK: - Toolbar Components
    private var modernUpdateStatus: some View {
        Group {
            if viewModel.updateAvailable {
                HStack {
                    Button("Aggiorna") {
                        Task { @MainActor in
                            await viewModel.confirmUpdate(matricola: settings.matricola)
                        }
                    }
                    .font(.caption)
                    Text("Ci sono novita!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Controllo aggiornamenti...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
    }
    
    private var legacyUpdateStatus: some View {
        Group {
            if viewModel.updateAvailable {
                HStack {
                    Button("Aggiorna") {
                        Haptics.play(.start)
                        Task { @MainActor in
                            await viewModel.confirmUpdate(matricola: settings.matricola)
                        }
                    }
                    .font(.caption)
                    .padding(3)
                    .foregroundStyle(colorScheme == .light ? .black : .white)
                    Text("Ci sono novita!")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Controllo aggiornamenti...")
                        .font(.caption2)
                        .padding(7)
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                }
            }
        }
        .frame(height: 45)
        .padding(.horizontal, 12)
        .background(colorScheme == .light ? .white.opacity(0.7) : .black.opacity(0.7))
        .clipShape(.capsule)
        .overlay(Capsule().stroke(colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), lineWidth: 2))
    }
    
    var modernSettingsButton: some View {
        Button(action: openSettingsAction) {
            Label("", systemImage: "gearshape.fill")
        }
    }
    
    var legacySettingsButton: some View {
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
