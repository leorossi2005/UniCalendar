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


struct CalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    @Environment(AppStatusManager.self) var statusManager
  
    @State private var sheetRouter: CalendarSheetRouter = .init()
    @State private var coordinator = CalendarCoordinator()
    @State private var viewModel = CalendarViewModel()
    
    private var selectedWeekBinding: Binding<Date> {
        Binding(
            get: { coordinator.selectedWeek },
            set: { coordinator.selectDate($0) }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if coordinator.page == .classrooms {
                    ClassroomAvailabilityView(coordinator: coordinator, sheetRouter: sheetRouter)
                        .transition(.identity)
                } else {
                    mainView
                        .transition(.identity)
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
            .onChange(of: statusManager.activeNotices) { _, _ in
                checkPendingNotices()
            }
            .onAppear {
                inizializeData()
                checkPendingNotificationTap()
            }
            .onChange(of: NotificationManager.shared.itemToOpen) { _, _ in
                checkPendingNotificationTap()
            }
            .onChange(of: viewModel.state == .loading) { _, isLoading in
                Haptics.play(isLoading ? .start : .success)
            }
            .modifier(SelectionFeedback(coordinator: coordinator, sheetRouter: sheetRouter))
            .animation(.default, value: viewModel.checkingUpdates)
            .animation(.default, value: viewModel.updateAvailable)
        }
        .customSheet(isPresented: .constant(true), manager: sheetRouter.manager, detents: sheetRouter.detents) {
            CalendarSheetContent(
                router: sheetRouter,
                selectedWeek: selectedWeekBinding
            )
        }
        .environment(sheetRouter.manager)
    }
    
    // MARK: - MainView
    @ViewBuilder
    private var mainView: some View {
        let hasCourse = settings.selectedCourse != "0"
        switch viewModel.state {
        case .idle, .loading:
            loadingStateOverlay(hasCourse: hasCourse)
        case .loaded:
            calendarScrollView
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
        }
    }
    
    private var calendarScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.academicYearDays, id: \.self) { date in
                        CalendarViewDay(date: date, viewModel: viewModel, sheetRouter: sheetRouter)
                            .containerRelativeFrame(.horizontal)
                            .id(date)
                    }
                }
                .scrollTargetLayout()
            }
            .transaction { $0.animation = nil }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: Binding<Date?>(
                get: { coordinator.selectedWeek },
                set: { if let d = $0 { coordinator.selectDate(d) } }
            ), anchor: .center)
            .modify { view in
                if #available(iOS 18, *) { view } else {
                    view.onAppear {
                        let target = coordinator.selectedWeek
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
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
                        CardItemContainer(item: .lesson(.sample), sheetRouter: sheetRouter)
                            .shimmeringPlaceholder(opacity: colorScheme == .light ? 0.5 : 0.7)
                    }
                }
            }
            .contentMargins(.top, 15, for: .scrollContent)
            .contentMargins(.top, 15, for: .scrollIndicators)
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
                SelectedDayLabel(coordinator: coordinator)
                
                Image(systemName: "wifi.slash")
                    .symbolEffect(.appear.up.byLayer, isActive: !viewModel.isOffline)
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
        
        if coordinator.page == .main {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Aggiungi", systemImage: "plus") {
                    Haptics.play(.impact(weight: .light))
                    sheetRouter.routeToAddPersonalEvent()
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Cambia pagina", systemImage: coordinator.page == .main ? "calendar" : "clock") {
                withAnimation {
                    coordinator.page = coordinator.page == .main ? .classrooms : .main
                }
            }
            .symbolReplace()
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Impostazioni", systemImage: "gearshape.fill", action: openSettingsAction)
        }
    }
    
    // MARK: - Logic Methods
    private func checkPendingNotices() {
        guard !sheetRouter.openSettings,
              !sheetRouter.openWhatsNew,
              !sheetRouter.openAddPersonalEvent,
              sheetRouter.openAppNotices == nil,
              sheetRouter.selectedItem == nil,
              sheetRouter.selectedRoom == nil,
              sheetRouter.manager.selectedDetent != .large else { return }
              
        let validNotices = statusManager.activeNotices.filter { notice in
            notice.level != .blocking && !statusManager.shownThisSessionIDs.contains(notice.id)
        }
        
        guard !validNotices.isEmpty else { return }

        for notice in validNotices {
            statusManager.markAsShownThisSession(id: notice.id)
        }
        sheetRouter.routeToAppNotices(validNotices)
    }
    
    private func openSettingsAction() {
        Haptics.play(.impact(weight: .light))
        sheetRouter.tempSettings.sync(with: settings)
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
            } else {
                checkPendingNotices()
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
    
    private func checkPendingNotificationTap() {
        guard let item = NotificationManager.shared.itemToOpen else { return }
        NotificationManager.shared.itemToOpen = nil
        guard !sheetRouter.openSettings,
              !sheetRouter.openWhatsNew,
              !sheetRouter.openAddPersonalEvent else { return }
        sheetRouter.routeToItem(item)
    }
    
    private func handleDetentChange(oldValue: CustomSheetDetent, newValue: CustomSheetDetent) {
        if newValue != .large {
            if sheetRouter.openSettings {
                let hasChanged = sheetRouter.tempSettings.hasChanged(from: settings)
                
                if hasChanged {
                    coordinator.page = .main
                    viewModel.state = .loading
                    sheetRouter.tempSettings.apply(to: settings)
                    
                    if settings.selectedCourse != "0" {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            updateDate()
                        }
                        
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
                } else if let notices = sheetRouter.openAppNotices {
                    for notice in notices {
                        statusManager.dismissNotice(id: notice.id)
                    }
                }
            }
            
            sheetRouter.resetToCalendar()
            
            if oldValue == .large {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.3))
                    checkPendingNotices()
                }
            }
        }
    }
}

// MARK: - Subviews
struct CalendarViewDay: View {
    let date: Date
    let viewModel: CalendarViewModel
    var sheetRouter: CalendarSheetRouter
    
    var body: some View {
        let items = viewModel.events(for: date) ?? []
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "Giornata Libera",
                    systemImage: "moon.zzz",
                    description: Text("Non ci sono lezioni o impegni in programma per oggi.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(items) { item in
                            CardItemContainer(item: item, sheetRouter: sheetRouter)
                        }
                    }
                }
                .contentMargins(.top, 15, for: .scrollContent)
                .contentMargins(.top, 15, for: .scrollIndicators)
                .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
                .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
            }
        }
    }
}

private struct SelectedDayLabel: View {
    let coordinator: CalendarCoordinator

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Mercoledì").font(.headline)
                Text("00 Settembre").font(.subheadline)
            }
            .opacity(0)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(coordinator.selectedWeek.getCurrentWeekdaySymbol(length: .wide))
                    .font(.headline)
                Text("\(coordinator.selectedWeek.day) \(coordinator.selectedWeek.getCurrentMonthSymbol(length: .wide))")
                    .font(.subheadline)
            }
            .contentTransition(.numericText())
            .animation(.default, value: coordinator.selectedWeek)
        }
    }
}

private struct SelectionFeedback: ViewModifier {
    let coordinator: CalendarCoordinator
    let sheetRouter: CalendarSheetRouter

    func body(content: Content) -> some View {
        content.onChange(of: coordinator.selectedWeek) { oldValue, newValue in
            guard !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
            Haptics.play(.selection, state: "selection")
            if !sheetRouter.openSettings { sheetRouter.manager.setDetent(.small) }
            Task {
                try? await Task.sleep(for: .seconds(0.2))
                GlobalHaptics.shared.state = ""
            }
        }
    }
}

#Preview {
    CalendarView()
        .environment(UserSettings.shared)
        .environment(AppStatusManager())
}
