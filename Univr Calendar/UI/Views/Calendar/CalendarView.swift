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
    @Environment(\.scenePhase) private var scenePhase
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    if settings.selectedCourse != "0" && settings.selectedAcademicYear != "0" && !settings.selectedAcademicYear.isEmpty {
                        Task {
                            await viewModel.refreshIfNeeded(
                                corso: settings.selectedCourse,
                                anno: settings.selectedAcademicYear,
                                selYear: settings.selectedYear,
                                matricola: settings.matricola
                            )
                        }
                    }
                }
            }
            .onChange(of: NotificationManager.shared.itemToOpen) { _, _ in
                checkPendingNotificationTap()
            }
            .onChange(of: viewModel.state) { oldState, newState in
                if newState == .loading {
                    Haptics.play(.start)
                } else if newState == .loaded {
                    switch oldState {
                    case .loading, .serverUnreachable, .univrOffline, .offline, .error:
                        Haptics.play(.success)
                    case .idle, .loaded, .empty:
                        break
                    }
                }
            }
            .onDisappear {
                viewModel.unregisterFromServerStatus()
            }
            .modifier(SelectionFeedback(coordinator: coordinator, sheetRouter: sheetRouter))
            .animation(.default, value: viewModel.checkingUpdates)
            .animation(.default, value: viewModel.updateAvailable)
            .animation(.default, value: ServerStatusCenter.shared.isUnreachable)
            .animation(.default, value: ServerStatusCenter.shared.isRetrying)
            .animation(.default, value: ServerStatusCenter.shared.isUniVRRetrying)
            .animation(.default, value: viewModel.isUniVROffline)
            .animation(.default, value: viewModel.isOffline)
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
        if settings.selectedCourse == "0" {
            ContentUnavailableView(
                "Nessun corso",
                systemImage: "graduationcap",
                description: Text("Scegli un corso dalle impostazioni per iniziare.")
            )
        } else if settings.selectedAcademicYear == "0" || settings.selectedAcademicYear.isEmpty {
            ContentUnavailableView(
                "Nessun anno di corso",
                systemImage: "calendar.badge.clock",
                description: Text("Scegli un anno di corso dalle impostazioni per iniziare.")
            )
        } else {
            switch viewModel.state {
            case .idle, .loading:
                loadingStateOverlay
            case .loaded:
                calendarScrollView
            case .empty:
                ContentUnavailableView(
                    "Nessuna Lezione",
                    systemImage: "graduationcap",
                    description: Text("Non è stata trovata nessuna lezione per questo corso.")
                )
            case .offline:
                ContentUnavailableView(
                    "Sei Offline",
                    systemImage: "wifi.slash",
                    description: Text("Connettiti a internet per scaricare le tue lezioni.")
                )
            case .serverUnreachable:
                ContentUnavailableView {
                    Label("Server non raggiungibile", systemImage: "network.slash")
                } description: {
                    Text("Non riusciamo a contattare il server. Riprova più tardi.")
                }
            case .univrOffline:
                ContentUnavailableView {
                    Label("Università non raggiungibile", systemImage: UniVROfflineStyle.symbolName)
                } description: {
                    Text("Questo corso non è disponibile finché i server dell'università non tornano online. Riprova più tardi.")
                }
            case .error(let msg):
                ContentUnavailableView(
                    "Si è verificato un errore",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
            }
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
    private var loadingStateOverlay: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(0..<10, id: \.self) { _ in
                    CardItemContainer(item: .lesson(.sample), sheetRouter: sheetRouter)
                        .shimmeringPlaceholder(opacity: colorScheme == .light ? 0.5 : 0.7)
                }
            }
            .allowsHitTesting(false)
        }
        .contentMargins(.top, 15, for: .scrollContent)
        .contentMargins(.top, 15, for: .scrollIndicators)
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
        .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
    }
    
    // MARK: - Toolbar Builder
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 6) {
                SelectedDayLabel(coordinator: coordinator)
                ZStack {
                    Image(systemName: "wifi.slash")
                        .symbolEffect(.appear.up.byLayer, isActive: !viewModel.isOffline)
                        .foregroundStyle(.yellow.opacity(0.8))
                    Image(systemName: "network.slash")
                        .symbolEffect(.appear.up.byLayer, isActive: !viewModel.isServerUnreachable)
                        .foregroundStyle(.orange.opacity(0.8))
                    Image(systemName: UniVROfflineStyle.symbolName)
                        .symbolEffect(.appear.up.byLayer, isActive: !viewModel.isUniVROffline)
                        .foregroundStyle(Color.univrOffline.opacity(0.8))
                }
                .font(.system(size: 12, weight: .bold))
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
        
        if (ServerStatusCenter.shared.isUnreachable || ServerStatusCenter.shared.isUniVROffline) && !viewModel.isOffline {
            ToolbarItem(placement: .topBarTrailing) {
                statusRetryButton
            }
        } else if viewModel.checkingUpdates && !viewModel.isOffline {
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
            .modify { view in if #available(iOS 26, *) { view } else { view.symbolReplace() }}
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Impostazioni", systemImage: "gearshape.fill", action: openSettingsAction)
        }
        .modify { view in if #available(iOS 27, *) { view.visibilityPriority(.high) } else { view }}
    }
    
    private var statusRetryButton: some View {
        let serverDown = ServerStatusCenter.shared.isUnreachable
        let isRetrying = serverDown ? ServerStatusCenter.shared.isRetrying : ServerStatusCenter.shared.isUniVRRetrying
        return Button {
            Haptics.play(.impact(weight: .medium))
            Task {
                if serverDown {
                    await ServerStatusCenter.shared.retryNow()
                } else {
                    await ServerStatusCenter.shared.retryUniVRNow()
                }
            }
        } label: {
            if isRetrying {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Label("Riprova", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .allowsHitTesting(!isRetrying)
        .buttonStyle(.borderedProminent)
        .tint(serverDown ? .orange : Color.univrOffline)
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
            if settings.selectedCourse != "0" && settings.selectedAcademicYear != "0" && !settings.selectedAcademicYear.isEmpty {
                await viewModel.loadFromCache(matricola: settings.matricola)
                
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
                    
                    if settings.selectedCourse != "0" && settings.selectedAcademicYear != "0" && !settings.selectedAcademicYear.isEmpty {
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
            
            let isSystemSheetOpen = sheetRouter.openSettings || sheetRouter.openAppNotices != nil || sheetRouter.openWhatsNew
            if !isSystemSheetOpen { 
                sheetRouter.manager.setDetent(.small) 
            }
            
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
