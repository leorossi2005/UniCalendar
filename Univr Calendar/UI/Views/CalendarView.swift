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
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(UserSettings.self) var settings
    @Namespace var transition
    
    @State private var viewModel = CalendarViewModel()
    @State private var tempSettings = TempSettingsState()
    @State private var positionObserver = WindowPositionObserver()
    
    @State private var selectedDetent: CustomSheetDetent = .small
    @State private var openCalendar: Bool = false
    @State private var oldOpenCalendar: Bool = false
    
    @State private var selectedLesson: Lesson? = nil
    @State private var selectedWeek: Date = Date()
    @State private var selectedMonth: Int = Date().month
    @State private var selection: String? = ""
    @State private var selectionFraction: String? = ""
    
    @State private var firstLoading: Bool = true
    @State private var scrollUpdateTask: Task<Void, Never>?
    
    @State private var openSettings: Bool = false
    @State private var settingsSearchFocus: Bool = false
    
    @State private var sheetEnableBackground: Bool = false
    @State private var sheetOffset: CGFloat = 0
    @State private var sheetPadding: CGFloat = 8
    @State private var sheetShape = UnevenRoundedRectangle(
        topLeadingRadius: 24,
        bottomLeadingRadius: 24,
        bottomTrailingRadius: 24,
        topTrailingRadius: 24
    )
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    private var defaultDetents: Set<PresentationDetent> {
        [.fraction(0.15), UIDevice.isIpad ? .fraction(0.75) : .medium]
    }

    private var detentsWithLarge: Set<PresentationDetent> {
        [.fraction(0.15), UIDevice.isIpad ? .fraction(0.75) : .medium, .large]
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                Group {
                    if #available(iOS 26, *) {
                        mainScrollView
                    } else {
                        mainScrollView
                            .overlay(alignment: .bottom) {
                                CustomSheetView(
                                    selectedWeek: $selectedWeek,
                                    selectedMonth: $selectedMonth,
                                    selectedDetent: $selectedDetent,
                                    selectionFraction: $selectionFraction,
                                    loading: $viewModel.loading,
                                    sheetShape: $sheetShape,
                                    selectedLesson: $selectedLesson,
                                    openSettings: $openSettings,
                                    settingsSearchFocus: $settingsSearchFocus,
                                    tempSettings: $tempSettings,
                                    openCalendar: $openCalendar,
                                    offset: $sheetOffset,
                                    enableBackground: $sheetEnableBackground,
                                    sheetPadding: $sheetPadding,
                                    setSheetShape: setSheetShape
                                )
                            }
                    }
                }
                .background(WindowAccessor { window in
                    if UIDevice.isIpad {
                        positionObserver.startObserving(window: window)
                    }
                })
                .toolbar {
                    buildToolbar()
                }
                //.sheet(isPresented: $openCalendar) {
                //    DynamicSheetContent(
                //        selectedWeek: $selectedWeek,
                //        selectedMonth: $selectedMonth,
                //        selectedDetent: $selectedDetent,
                //        detents: $detents,
                //        selectedFraction: $selectionFraction,
                //        selectedLesson: $selectedLesson,
                //        openSettings: $openSettings,
                //        settingsSearchFocus: $settingsSearchFocus,
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
                .onChange(of: positionObserver.edges) {
                    setSheetShape(isOpen: openCalendar)
                }
                .onChange(of: viewModel.loading) { _, isLoading in
                    handleLoadingChange(isLoading)
                }
                .removeTopSafeArea()
                .animation(.default, value: viewModel.checkingUpdates)
                .animation(.default, value: viewModel.showUpdateAlert)
            }
            
            
            if #available(iOS 26, *) {
                GlassEffectContainer {
                    ZStack(alignment: .bottom) {
                        if sheetEnableBackground {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()
                        }
                        
                        if openCalendar {
                            CustomSheetView(
                                selectedWeek: $selectedWeek,
                                selectedMonth: $selectedMonth,
                                selectedDetent: $selectedDetent,
                                selectionFraction: $selectionFraction,
                                loading: $viewModel.loading,
                                sheetShape: $sheetShape,
                                selectedLesson: $selectedLesson,
                                openSettings: $openSettings,
                                settingsSearchFocus: $settingsSearchFocus,
                                tempSettings: $tempSettings,
                                openCalendar: $openCalendar,
                                offset: $sheetOffset,
                                enableBackground: $sheetEnableBackground,
                                sheetPadding: $sheetPadding,
                                setSheetShape: setSheetShape
                            )
                            .glassEffect(sheetEnableBackground ? .identity : .regular.interactive(), in: sheetShape)
                            .glassEffectID("calendar", in: transition)
                            .glassEffectTransition(.matchedGeometry)
                            .offset(y: -sheetOffset)
                            .padding(.horizontal, sheetPadding)
                            .padding(.bottom, sheetPadding)
                        } else {
                            Button {
                                changeOpenCalendar(true)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                    Text("Calendario")
                                }
                                .padding(.vertical, 12.2)
                                .padding(.horizontal, 10)
                            }
                            .contentShape(.capsule)
                            .contentShape(.hoverEffect, .capsule)
                            .hoverEffect(.highlight)
                            .buttonStyle(.plain)
                            .glassEffect(colorScheme == .dark ? .clear.interactive().tint(.black.opacity(0.7)) : .clear.interactive(), in: sheetShape)
                            .glassEffectID("calendar", in: transition)
                            .glassEffectTransition(.matchedGeometry)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 28)
                            .padding(.bottom, 28)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Main Content
    private var mainScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if viewModel.loading || firstLoading {
                        loadingPlaceholder
                    } else {
                        loadedContent
                    }
                }
                .multilineTextAlignment(.center)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selection, anchor: .center)
            .task(id: selectedWeek) {
                if !viewModel.loading && !firstLoading {
                    let newSelection = selectedWeek.formatUnivrStyle()
                    if newSelection != selection { selection = newSelection }
                    if selectedMonth != selectedWeek.month { selectedMonth = selectedWeek.month }
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
                    if #available(iOS 17, *) {
                        if #unavailable(iOS 18.0) {
                            Spacer().frame(height: safeAreas.top * 1.9)
                        }
                    }
                    VStack(spacing: 10) {
                        ForEach(0..<10, id: \.self) { _ in
                            LessonCardView(lesson: .sample)
                                .shimmeringPlaceholder(opacity: colorScheme == .light ? 0.5 : 0.7)
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
        .disabled(viewModel.loading && settings.selectedCourse != "0")
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
        .disabled(viewModel.loading && settings.selectedCourse != "0")
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
        updateDate()
        
        tempSettings.sync(with: settings)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            openCalendar = true
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
                        
                        selectedDetent = .small
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
            } else {
                selectedMonth = selectedWeek.month
            }
            
            selectedLesson = nil
            openSettings = false
        } else {
            oldOpenCalendar = openCalendar
        }
    }
    
    private func changeOpenCalendar(_ toOpen: Bool) {
        guard openCalendar != toOpen else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            setSheetShape(isOpen: toOpen)
        }

        if toOpen {
            selectedLesson = nil
            openSettings = false
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            openCalendar = toOpen
        }
    }
    
    private func setSheetShape(isOpen: Bool, sheetCornerRadius: CGFloat = -1) {
        withAnimation {
            if #available(iOS 26, *) {
                if UIDevice.isIpad {
                    sheetShape = UnevenRoundedRectangle(
                        topLeadingRadius: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius,
                        bottomLeadingRadius: (isOpen ? (positionObserver.edges.bottomLeftSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8,
                        bottomTrailingRadius: (isOpen ? (positionObserver.edges.bottomRightSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8,
                        topTrailingRadius: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius
                    )
                } else {
                    let radius: CGFloat = (isOpen ? .deviceCornerRadius : (47.4 / 2 + 8)) - 8
                    sheetShape = UnevenRoundedRectangle(
                        topLeadingRadius: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                        bottomLeadingRadius: radius,
                        bottomTrailingRadius: radius,
                        topTrailingRadius: sheetCornerRadius == -1 ? radius : sheetCornerRadius
                    )
                }
            } else {
                if UIDevice.isIpad {
                    sheetShape = UnevenRoundedRectangle(
                        topLeadingRadius: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: sheetCornerRadius == -1 ? 32 : sheetCornerRadius
                    )
                } else {
                    sheetShape = UnevenRoundedRectangle(
                        topLeadingRadius: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius
                    )
                }
            }
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

    private let screenSize: CGRect = UIApplication.shared.screenSize
    
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
                        .foregroundStyle(Color(white: 0.35))
                    }
                }
            }
            .scrollViewTopPadding()
            Spacer().frame(height: screenSize.height * 0.10)
        }
        .onScrollGeometry(
            openCalendar: $openCalendar,
            selectedDetent: $selectedDetent,
            firstLoading: $firstLoading,
            changeOpenCalendar: changeOpenCalendar
        )
    }
}

struct temp: View {
    @State private var show: Bool = true
    
    var body: some View {
        NavigationStack {
            Rectangle()
                .ignoresSafeArea()
                .frame(maxHeight: .infinity)
                .frame(width: 130)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) { Spacer() }
                    
                    if !show {
                        if #available(iOS 26, *) {
                            ToolbarItem(placement: .bottomBar) {
                                Button(action: {
                                }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                        Text("Calendario")
                                    }
                                }
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if show {
                        if #available(iOS 26, *) {
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    calendarButton
                                    Spacer()
                                        .frame(width: 28)
                                }
                                Spacer()
                                    .frame(height: 28)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
        }
    }
    
    @available(iOS 26.0, *)
    var calendarButton: some View {
        Button(action: {
        }) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title2)
                Text("Calendario")
            }
            .padding(.vertical, 12.2)
            .padding(.horizontal, 10)
        }
        .tint(.primary)
        .glassEffect(.clear.interactive(), in: .ellipse)
        .buttonBorderShape(.roundedRectangle(radius: 0))
    }
}

#Preview {
    temp()
        .environment(UserSettings.shared)
}
