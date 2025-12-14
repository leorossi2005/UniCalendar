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
    @State private var currentSourceID: String = "calendar"
    
    @State private var selectedDetent: PresentationDetent = .fraction(0.15)
    @State private var detents: Set<PresentationDetent> = [.fraction(0.15), UIDevice.isIpad ? .fraction(0.75) : .medium]
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
        NavigationStack {
            Group {
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 40) {
                        mainScrollView
                            .overlay(alignment: .bottom) {
                                if openCalendar {
                                    FractionDatePickerContainer(
                                        selectedWeek: $selectedWeek,
                                        loading: $viewModel.loading,
                                        selectionFraction: $selectionFraction,
                                        selectedDetent: $selectedDetent
                                    )
                                    .frame(height: screenSize.height * 0.2)
                                    .glassEffect(.regular.interactive(), in: sheetShape)
                                    .glassEffectID("calendar", in: transition)
                                    .glassEffectTransition(.matchedGeometry)
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                                    .id(colorScheme)
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
                } else {
                    mainScrollView
                        .safeAreaInset(edge: .bottom) {
                            if openCalendar {
                                ZStack {
                                    sheetShape
                                    .fill(.clear)
                                    
                                    FractionDatePickerContainer(
                                        selectedWeek: $selectedWeek,
                                        loading: $viewModel.loading,
                                        selectionFraction: $selectionFraction,
                                        selectedDetent: $selectedDetent
                                    )
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: screenSize.height * 0.2)
                            }
                        }
                }
            }
                .ignoresSafeArea(edges: .bottom)
                .background(WindowAccessor { window in
                    positionObserver.startObserving(window: window)
                })
                .onChange(of: positionObserver.edges) { _, newEdges in
                    withAnimation {
                        if UIDevice.isIpad {
                            sheetShape = UnevenRoundedRectangle(
                                topLeadingRadius: 32 - 8,
                                bottomLeadingRadius: (newEdges.bottomLeftSquare && openCalendar ? 18 : 32) - 8,
                                bottomTrailingRadius: (newEdges.bottomRightSquare && openCalendar ? 18 : 32) - 8,
                                topTrailingRadius: 32 - 8
                            )
                        } else {
                            sheetShape = UnevenRoundedRectangle(
                                topLeadingRadius: .deviceCornerRadius - 8,
                                bottomLeadingRadius: .deviceCornerRadius - 8,
                                bottomTrailingRadius: .deviceCornerRadius - 8,
                                topTrailingRadius: .deviceCornerRadius - 8
                            )
                        }
                    }
                }
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
                //    .sheetDesign(transition, sourceID: currentSourceID, detent: $selectedDetent)
                //}
                //.background {
                //    if #available(iOS 26, *) {
                //        Color.clear
                //            .frame(width: 1, height: 1)
                //            .matchedTransitionSource(id: "safe_anchor", in: transition)
                //    }
                //}
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
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background {
                        currentSourceID = "safe_anchor"
                    } else if newPhase == .active {
                        currentSourceID = "calendar"
                    }
                }
                //.overlay(alignment: .bottomTrailing) { // Allinea in basso a destra per controllo totale
                //    if #available(iOS 26, *) {
                //        HStack(spacing: 0) { // Spacing 0 per calcoli precisi
                //
                //            // IL BOTTONE
                //            Button {
                //                withAnimation {
                //                    selectedLesson = nil
                //                    openCalendar = true
                //                    detents = defaultDetents
                //                }
                //            } label: {
                //                HStack(spacing: 8) {
                //                    Image(systemName: "calendar")
                //                        .font(.title2)
                //                    Text("Calendario")
                //                }
                //                .padding(.vertical, 5.2)
                //                .padding(.horizontal, -2)
                //            }
                //            .buttonStyle(.glass)
                //
                //            .padding(.trailing, 28)
                //            .matchedTransitionSource(id: "calendar", in: transition)
                //        }
                //        .padding(.bottom, 28)
                //        .background(Color.clear)
                //    }
                //}
                //.ignoresSafeArea(edges: .bottom)
                .removeTopSafeArea()
                .animation(.default, value: viewModel.checkingUpdates)
                .animation(.default, value: viewModel.showUpdateAlert)
        }
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
                            detents: $detents,
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
                detents = defaultDetents
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
        detents = detentsWithLarge
        selectedDetent = .large
    }
    
    private func inizializeData() {
        selectedDetent = .fraction(0.15)
        detents = defaultDetents
        
        updateDate()
        
        tempSettings.sync(with: settings)
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
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
                        
                        if selectedDetent != .fraction(0.15) {
                            selectedDetent = .fraction(0.15)
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
    
    private func handleDetentChange(oldValue: PresentationDetent, newValue: PresentationDetent) {
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
            detents = defaultDetents
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
            detents = defaultDetents
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            openCalendar = toOpen
        }
    }
    
    private func setSheetShape(isOpen: Bool) {
        if UIDevice.isIpad {
            sheetShape = UnevenRoundedRectangle(
                topLeadingRadius: 32 - 8,
                bottomLeadingRadius: (positionObserver.edges.bottomLeftSquare && isOpen ? 18 : 32) - 8,
                bottomTrailingRadius: (positionObserver.edges.bottomRightSquare && isOpen ? 18 : 32) - 8,
                topTrailingRadius: 32 - 8
            )
        } else {
            sheetShape = UnevenRoundedRectangle(
                topLeadingRadius: .deviceCornerRadius - 8,
                bottomLeadingRadius: .deviceCornerRadius - 8,
                bottomTrailingRadius: .deviceCornerRadius - 8,
                topTrailingRadius: .deviceCornerRadius - 8
            )
        }
    }
}

// MARK: - Subviews

struct DynamicSheetContent: View {
    @Binding var selectedWeek: Date
    @Binding var selectedMonth: Int
    @Binding var selectedDetent: PresentationDetent
    @Binding var detents: Set<PresentationDetent>
    @Binding var selectedFraction: String?
    @Binding var selectedLesson: Lesson?
    @Binding var openSettings: Bool
    @Binding var settingsSearchFocus: Bool
    @Binding var loading: Bool
    @Binding var tempSettings: TempSettingsState
    @Binding var openCalendar: Bool
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let currentHeight = proxy.size.height
                let screenHeight = UIApplication.shared.screenSize.height
        
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
                        FractionDatePickerContainer(
                            selectedWeek: $selectedWeek,
                            loading: $loading,
                            selectionFraction: $selectedFraction,
                            selectedDetent: $selectedDetent
                        )
                        .opacity(settingsSearchFocus ? 0 : min(max(smallOpacity, 0), 1))
                        .allowsHitTesting(selectedDetent == .fraction(0.15))
                    }
        
                    if currentHeight > screenHeight * 0.35 && currentHeight < screenHeight * 0.65 && !settingsSearchFocus {
                        DatePickerContainer(
                            selectedDetent: $selectedDetent,
                            selectedMonth: $selectedMonth,
                            selectedWeek: $selectedWeek
                        )
                        .opacity(settingsSearchFocus ? 0 : min(max(mediumOpacity, 0), 1))
                        .allowsHitTesting(selectedDetent == (UIDevice.isIpad ? .fraction(0.75) : .medium))
                    }
                    
                    if openSettings {
                        NavigationStack {
                            Settings(
                                detents: $detents,
                                selectedDetent: $selectedDetent,
                                selectedYear: $tempSettings.selectedYear,
                                selectedCourse: $tempSettings.selectedCourse,
                                selectedAcademicYear: $tempSettings.selectedAcademicYear,
                                matricola: $tempSettings.matricola,
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
                    } else if currentHeight > screenHeight * 0.75 {
                        LessonDetailsView(selectedLesson: $selectedLesson, selectedDetent: $selectedDetent)
                            .opacity(settingsSearchFocus ? 0 : min(max(largeOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == .large)
                    }
                }
            }
        }
    }
}

struct CalendarViewDay: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    let filteredLessons: [Lesson]
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var selectedLesson: Lesson?
    @Binding var openCalendar: Bool
    @Binding var selectedDetent: PresentationDetent
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
                                //selectedLesson = lesson
                                //detents = [.fraction(0.15), UIDevice.isIpad ? .fraction(0.75) : .medium, .large]
                                //selectedDetent = .large
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
