//
//  CalendarView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/25.
//

import SwiftUI
import UnivrCore

struct CalendarView: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    @Namespace var transition
    
    private let positionObserver = WindowPositionObserver.shared
    private let net: NetworkMonitor = .shared
    @State private var viewModel = CalendarViewModel()
    @State private var tempSettings = TempSettingsState()
    
    @State private var selectedLesson: Lesson? = nil
    @State private var selectedWeek: Date = Date()
    @State private var selection: String? = ""
    
    @State private var firstLoading: Bool = true
    @State private var scrollUpdateTask: Task<Void, Never>?
    
    @State private var selectedDetent: CustomSheetDetent = .small
    @State private var openSettings: Bool = false
    @State private var openCalendar: Bool = false
    @State private var oldOpenCalendar: Bool = false
    
    @State private var sheetShape = UnevenRoundedRectangle()
    @State private var sheetShapeRadii: SheetCornerRadii = .init(tl: 0, tr: 0, bl: 0, br: 0)
    
    var body: some View {
        NavigationStack {
            mainScrollView
                .toolbar {
                    buildToolbar()
                }
                //.sheet(isPresented: $openCalendar) {
                //    DynamicSheetContent(
                //        selectedWeek: $selectedWeek,
                //        selectedDetent: $selectedDetent,
                //        detents: $detents,
                //        selectedLesson: $selectedLesson,
                //        openSettings: $openSettings,
                //        loading: $viewModel.loading,
                //        tempSettings: $tempSettings,
                //        openCalendar: $openCalendar
                //    )
                //    .presentationDetents(detents, selection: $selectedDetent)
                //    .interactiveDismissDisabled(true)
                //    .presentationBackgroundInteraction(.enabled(upThrough: UIDevice.isIpad ? .fraction(0.75) : .medium))
                //    .disabled((viewModel.loading || viewModel.noLessonsFound) && !openSettings)
                //    .onChange(of: selectedDetent) { oldValue, newValue in
                //        handleDetentChange(oldValue: oldValue, newValue: newValue)
                //    }
                //    .sheetDesign(transition, sourceID: "calendar", detent: $selectedDetent)
                //}
                .onChange(of: selectedDetent) { oldValue, newValue in
                    handleDetentChange(oldValue: oldValue, newValue: newValue)
                }
                .onAppear {
                    inizializeData()
                }
                .onChange(of: selection) {
                    handleSelectionChange()
                }
                .onChange(of: openCalendar) { oldValue, newValue in
                    oldOpenCalendar = oldValue
                }
                .onChange(of: viewModel.loading) { _, isLoading in
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
                .animation(.default, value: viewModel.showUpdateAlert)
                .animation(.default, value: net.status)
        }
        .overlay(alignment: .bottom) {
            CustomSheetView(
                transition: transition,
                openSettings: $openSettings,
                selectedDetent: $selectedDetent,
                sheetShape: $sheetShape,
                sheetShapeRadii: $sheetShapeRadii,
                selectedWeek: $selectedWeek,
                selectedLesson: $selectedLesson,
                tempSettings: $tempSettings,
                openCalendar: $openCalendar
            )
            .disabled((viewModel.loading || viewModel.noLessonsFound || viewModel.days.isEmpty) && !openSettings)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Main Content
    private var mainScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if net.status != .connected && viewModel.days.isEmpty {
                        offlineContent
                    } else if viewModel.loading || firstLoading {
                        loadingPlaceholder
                    } else {
                        loadedContent
                    }
                }
                .multilineTextAlignment(.center)
                .scrollTargetLayout()
                .id(viewModel.loading ? "loading-state" : "content-state")
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection, anchor: .center)
            .task(id: selectedWeek) {
                if !viewModel.loading && !firstLoading {
                    let newSelection = selectedWeek.formatUnivrStyle()
                    if newSelection != selection { selection = newSelection }
                }
            }
            .onChange(of: positionObserver.windowFrame.size.width) { _, _ in
                guard let currentSelection = selection else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    proxy.scrollTo(currentSelection, anchor: .center)
                }
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        Group {
            if settings.selectedCourse != "0" {
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
                .containerRelativeFrame(.horizontal)
            } else {
                Text("Devi scegliere un corso")
                    .bold()
                    .font(.title2)
                    .containerRelativeFrame(.horizontal)
            }
        }
    }
    
    private var loadedContent: some View {
        Group {
            if !viewModel.noLessonsFound {
                ForEach(viewModel.days.indices, id: \.self) { i in
                    if !viewModel.days[i].isEmpty {
                        CalendarViewDay(
                            filteredLessons: viewModel.days[i],
                            selectedLesson: $selectedLesson,
                            openCalendar: $openCalendar,
                            selectedDetent: $selectedDetent,
                            firstLoading: $firstLoading,
                            changeOpenCalendar: changeOpenCalendar
                        )
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
    
    private var offlineContent: some View {
        if settings.selectedCourse == "0" {
            Text("Connettiti a internet per scegliere un corso")
                .bold()
                .font(.title2)
                .containerRelativeFrame(.horizontal)
        } else {
            Text("Connettiti a internet per scaricare le lezioni")
                .bold()
                .font(.title2)
                .containerRelativeFrame(.horizontal)
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
        
        if viewModel.checkingUpdates || viewModel.showUpdateAlert {
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
        
        //if #available(iOS 26, *) {
        //    ToolbarItem(placement: .bottomBar) { Spacer() }
        //    ToolbarItem(id: "calendarButton", placement: .bottomBar) {
        //        calendarButton
        //            .matchedTransitionSource(id: "calendar", in: transition)
        //    }
        //}
    }
    
    // MARK: - Toolbar Components
    private var modernUpdateStatus: some View {
        Group {
            if viewModel.showUpdateAlert {
                HStack {
                    Button("Aggiorna") {
                        Task { @MainActor in
                            viewModel.confirmUpdate(selectedYear: settings.selectedYear, matricola: settings.matricola)
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
            if viewModel.showUpdateAlert {
                HStack {
                    Button("Aggiorna") {
                        Task { @MainActor in
                            viewModel.confirmUpdate(selectedYear: settings.selectedYear, matricola: settings.matricola)
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
    
    var calendarButton: some View {
        Button {
            withAnimation {
                selectedLesson = nil
                openCalendar = true
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text("Calendario")
            }
        }
    }
    
    // MARK: - Logic Methods
    private func openSettingsAction() {
        openSettings = true
        openCalendar = true
        selectedDetent = .large
    }
    
    private func inizializeData() {
        setSheetShape(isOpen: false)
        updateDate()
        
        tempSettings.sync(with: settings)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            changeOpenCalendar(true)
            oldOpenCalendar = true
        }
        
        if settings.selectedCourse != "0" {
            Task {
                await viewModel.loadNetworkFromCache()
                await viewModel.loadFromCache(selYear: settings.selectedYear, matricola: settings.matricola)
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
        let today: Date = .now
        
        if let years = NetworkCache.shared.years.last,
           let currentYear = Int(years.valore),
           let year = Int(settings.selectedYear),
           year != currentYear {
            let startAcademic = "01-10-\(year)"
            if selectedWeek.formatUnivrStyle() != startAcademic {
                selectedWeek = startAcademic.toDateModern() ?? Date(year: year, month: today.month, day: today.day)
            }
        } else {
            if selectedWeek.formatUnivrStyle() != today.formatUnivrStyle() {
                selectedWeek = Date(year: today.year, month: today.month, day: today.day)
            }
        }
    }
    
    private func handleSelectionChange() {
        scrollUpdateTask?.cancel()
        scrollUpdateTask = Task {
            if !Task.isCancelled {
                await MainActor.run {
                    if let date = selection?.toDateModern() {
                        if selectedWeek.formatUnivrStyle() != selection {
                            selectedWeek = date
                        }
                        
                        if !openSettings {
                            selectedDetent = .small
                        }
                    }
                }
            }
        }
    }
    
    private func handleLoadingChange(_ isLoading: Bool) {
        if isLoading {
            selection = nil
            firstLoading = true
        } else {
            let targetDate = selectedWeek.formatUnivrStyle()
            Task { @MainActor in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    if viewModel.daysString.contains(targetDate) {
                        selection = targetDate
                    } else {
                        selection = viewModel.daysString.first
                        if let first = viewModel.daysString.first, let date = first.toDateModern() {
                            selectedWeek = date
                        }
                    }
                    firstLoading = false
                }
            }
        }
    }
    
    // MARK: - Find a way to move
    private func handleDetentChange(oldValue: CustomSheetDetent, newValue: CustomSheetDetent) {
        if newValue != .large {
            if openSettings {
                let hasChanged = tempSettings.hasChanged(from: settings)
                
                if hasChanged {
                    tempSettings.apply(to: settings)
                    
                    openCalendar = true
                    
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
                    openCalendar = true
                    Task {
                        await viewModel.organizeData(selectedYear: settings.selectedYear, matricola: settings.matricola)
                    }
                } else {
                    openCalendar = oldOpenCalendar
                }
            } else if oldValue == .large {
                openCalendar = oldOpenCalendar
            }
            
            selectedLesson = nil
            openSettings = false
        } else {
            oldOpenCalendar = openCalendar
        }
    }
    
    // MARK: - To remove
    private func changeOpenCalendar(_ toOpen: Bool) {
        guard openCalendar != toOpen else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            setSheetShape(isOpen: toOpen)
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            openCalendar = toOpen
        }
    }
    
    private func setSheetShape(isOpen: Bool, sheetCornerRadius: CGFloat = -1) {
        withAnimation {
            if #available(iOS 26, *) {
                if UIDevice.isIpad {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius,
                        bl: (isOpen ? (positionObserver.edges.bottomLeftSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8,
                        br: (isOpen ? (positionObserver.edges.bottomRightSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8
                    )
                } else {
                    let radius: CGFloat = (isOpen ? .deviceCornerRadius : (47.4 / 2 + 8)) - 8
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                        bl: radius,
                        br: radius
                    )
                }
            } else {
                if UIDevice.isIpad {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                        bl: 0,
                        br: 0
                    )
                } else {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                        bl: 0,
                        br: 0
                    )
                }
            }
            sheetShape = UnevenRoundedRectangle(
                topLeadingRadius: sheetShapeRadii.tl,
                bottomLeadingRadius: sheetShapeRadii.bl,
                bottomTrailingRadius: sheetShapeRadii.br,
                topTrailingRadius: sheetShapeRadii.tr
            )
        }
    }
}

// MARK: - Subviews
struct CalendarViewDay: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    let filteredLessons: [Lesson]
    
    @Binding var selectedLesson: Lesson?
    @Binding var openCalendar: Bool
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var firstLoading: Bool

    var changeOpenCalendar: ((_ isOpen: Bool) -> Void)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(filteredLessons) { lesson in
                    if lesson.tipo != "pause" && lesson.tipo != "chiusura_type" {
                        LessonCard(lesson: lesson)
                            .onTapGesture {
                                changeOpenCalendar(true)
                                selectedLesson = lesson
                                selectedDetent = .large
                            }
                    } else {
                        HStack(alignment: .bottom) {
                            Image(systemName: .cupDynamic)
                                .font(.system(size: 40))
                            Text(lesson.durationCalculated)
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
        .onScrollGeometry(
            openCalendar: $openCalendar,
            selectedDetent: $selectedDetent,
            firstLoading: $firstLoading,
            changeOpenCalendar: changeOpenCalendar
        )
    }
}

#Preview {
    CalendarView()
        .environment(UserSettings.shared)
}
