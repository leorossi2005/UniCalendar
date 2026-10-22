//
//  Onboarding.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 14/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

enum OnboardingStep: Int, CaseIterable, Comparable {
    case welcome, year, course, academicYear, matricola
    static func < (l: Self, r: Self) -> Bool { l.rawValue < r.rawValue }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
}

struct Onboarding: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = UniversityDataManager()
    
    @State private var step: OnboardingStep? = .welcome
    @State private var loadingStep: OnboardingStep? = nil
    @State private var transitionTask: Task<Void, Never>? = nil
    @State private var errorText: String?
    
    @State private var searchTextFieldFocus: Bool = false
    @State private var academicYearSearchFocus: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(OnboardingStep.allCases, id: \.self) { page(for: $0) }
                }
                .scrollTargetLayout()
            }
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if let current = step, current > .welcome {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            searchTextFieldFocus = false
                            academicYearSearchFocus = false
                            if let previous = current.previous {
                                step = previous
                                loadingStep = nil
                            }
                        } label: {
                            if #available(iOS 26, *) {
                                Image(systemName: "chevron.left")
                                    .fontWeight(.semibold)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .fontWeight(.semibold)
                                    Text("Indietro")
                                }
                            }
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $step, anchor: .center)
            .scrollDisabled(true)
            .animation(.snappy, value: step)
            .task(id: viewModel.isOffline || ServerStatusCenter.shared.isUnreachable) {
                guard !viewModel.isOffline && !ServerStatusCenter.shared.isUnreachable else { return }
                if let year = await viewModel.prefetch(preferredYear: settings.selectedYear) {
                    settings.selectedYear = year
                }
            }
            .onChange(of: ServerStatusCenter.shared.isUnreachable) { _, isUnreachable in
                if isUnreachable && loadingStep != nil {
                    transitionTask?.cancel()
                    transitionTask = nil
                    withAnimation {
                        loadingStep = nil
                    }
                }
            }
            .onDisappear { viewModel.cancelAll() }
        }
        .overlay(alignment: .top) {
            let isOffline = viewModel.isOffline
            let isUnreachable = ServerStatusCenter.shared.isUnreachable
            // UniVR giù: avviso non bloccante (il server proprio giù ha la precedenza)
            let isUniVROffline = !isOffline && !isUnreachable && ServerStatusCenter.shared.isUniVROffline
            let isRetrying = isUniVROffline ? ServerStatusCenter.shared.isUniVRRetrying : ServerStatusCenter.shared.isRetrying
            let isWarningVisible = isOffline || isUnreachable || isUniVROffline
            let tint: Color = isOffline ? .yellow : (isUniVROffline ? .blue : .orange)
            
            HStack(spacing: 8) {
                if isOffline {
                    Image(systemName: "wifi.slash")
                        .font(.subheadline.weight(.semibold))
                    Text("Al momento sei offline.")
                        .font(.subheadline.weight(.medium))
                } else if isRetrying {
                    ProgressView()
                        .controlSize(.small)
                        .tint(isUniVROffline ? .white : .black)
                    Text(isUniVROffline ? "Sto provando a contattare l'università..." : "Sto provando a contattare il server...")
                        .font(.subheadline.weight(.medium))
                } else if isUniVROffline {
                    Image(systemName: "building.columns")
                        .font(.subheadline.weight(.semibold))
                    Text("I dati potrebbero non essere aggiornati.")
                        .font(.subheadline.weight(.medium))
                } else {
                    Image(systemName: "network.slash")
                        .font(.subheadline.weight(.semibold))
                    Text("Server non raggiungibile, riprova più tardi.")
                        .font(.subheadline.weight(.medium))
                }
            }
            .foregroundStyle(isUniVROffline ? .white : .black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .modify { view in
                if #available(iOS 26, *) {
                    view.glassEffect(.regular.interactive().tint(tint), in: .capsule)
                } else {
                    view.background(tint, in: .capsule)
                }
            }
            .contentShape(Capsule())
            .padding(.top, safeAreas.bottom > 0 ? 0 : 8)
            .blur(radius: isWarningVisible ? 0 : 20)
            .offset(y: isWarningVisible ? safeAreas.top : safeAreas.top / 2)
            .scaleEffect(isWarningVisible ? 1 : 0)
            .animation(.bouncy(extraBounce: 0.1), value: isWarningVisible)
            .allowsHitTesting(isWarningVisible && !isRetrying)
            .ignoresSafeArea()
            .onTapGesture {
                Haptics.play(.impact(weight: .medium))
                Task {
                    if isUniVROffline {
                        await ServerStatusCenter.shared.retryUniVRNow()
                    } else {
                        await ServerStatusCenter.shared.retryNow()
                    }
                    if (settings.selectedYear.isEmpty || settings.selectedYear == "0"), let firstYear = viewModel.years.first {
                        settings.selectedYear = firstYear.id
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func page(for pageStep: OnboardingStep) -> some View {
        @Bindable var settings = settings
        
        switch pageStep {
        case .welcome: WelcomeOnboardingPage(
            title: "Benvenuto!",
            subtitle: "Basta siti lenti o **app obsolete** per capire che **lezioni** hai.\n**Ora hai tutto in un unico posto.**",
            errorMessage: $errorText,
            bottomPadding: safeAreas.bottom,
            buttonTitle: "Continua",
            isLoading: loadingStep == .year,
            isButtonDisabled: viewModel.isOffline || ServerStatusCenter.shared.isUnreachable || step != .welcome || loadingStep != nil,
            buttonAction: {
                guard step == .welcome, loadingStep == nil else { return }
                handlePageTransition(to: .year) {
                    try await viewModel.reloadYears()
                }
            }
        )
        case .year: OnboardingPage(
            title: "Scegli un anno",
            subtitle: "Seleziona un **anno precedente** per consultare l'archivio, oppure procedi con **l'ultimo disponibile**.",
            isActive: step == .year,
            errorMessage: $errorText,
            bottomPadding: safeAreas.bottom,
            buttonTitle: "Continua",
            isLoading: loadingStep == .course,
            isButtonDisabled: viewModel.isOffline || ServerStatusCenter.shared.isUnreachable || loadingStep != nil,
            buttonAction: {
                guard step == .year, loadingStep == nil else { return }
                handlePageTransition(to: .course) {
                    let year = settings.selectedYear
                    if year != viewModel.coursesYear { settings.selectedCourse = "0" }
                    try await viewModel.reloadCourses(year: year)
                }
            }
        ) { ShortListSelector(items: viewModel.years, selectedItem: $settings.selectedYear) }
        case .course: OnboardingPage(
            title: "Bene! Ora scegli un corso",
            subtitle: "Stai visualizzando i corsi per l'anno **\(viewModel.years.first { $0.id == settings.selectedYear }?.label ?? "")**.",
            isActive: step == .course,
            isSearching: searchTextFieldFocus,
            errorMessage: $errorText,
            bottomPadding: safeAreas.bottom,
            buttonTitle: "Continua",
            isLoading: false,
            isButtonDisabled: settings.selectedCourse == "0" || loadingStep != nil,
            textFieldFocus: searchTextFieldFocus,
            buttonAction: {
                guard step == .course else { return }
                searchTextFieldFocus = false
                viewModel.updateAcademicYears(for: settings.selectedCourse)
                
                if viewModel.academicYears.count <= 5, let firstYear = viewModel.academicYears.first {
                    settings.selectedAcademicYear = firstYear.id
                } else {
                    settings.selectedAcademicYear = "0"
                    settings.selectedAcademicYearName = ""
                    settings.foundMatricola = false
                }
                
                withAnimation {
                    step = .academicYear
                }
            }
        ) {
            LongListSelector(
                isFocused: $searchTextFieldFocus,
                selectedItem: $settings.selectedCourse,
                items: viewModel.courses
            )
        }
        case .academicYear: OnboardingPage(
            title: "Che anno frequenti?",
            subtitle: "Se è presente **un solo anno**, puoi procedere direttamente.",
            isActive: step == .academicYear,
            isSearching: academicYearSearchFocus,
            errorMessage: $errorText,
            bottomPadding: safeAreas.bottom,
            buttonTitle: settings.foundMatricola ? "Continua" : "Comincia!",
            isLoading: false,
            isButtonDisabled: settings.selectedAcademicYear == "0" || settings.selectedAcademicYear.isEmpty || loadingStep != nil,
            textFieldFocus: academicYearSearchFocus,
            buttonAction: {
                guard step == .academicYear else { return }
                academicYearSearchFocus = false
                if settings.foundMatricola {
                    withAnimation {
                        step = .matricola
                    }
                } else {
                    completeOnboarding()
                }
            }
        ) {
            Group {
                if viewModel.academicYears.count <= 5 {
                    ShortListSelector(
                        items: viewModel.academicYears,
                        selectedItem: $settings.selectedAcademicYear
                    )
                } else {
                    LongListSelector(
                        isFocused: $academicYearSearchFocus,
                        selectedItem: $settings.selectedAcademicYear,
                        items: viewModel.academicYears,
                        searchPrompt: "Cerca un anno di corso"
                    )
                }
            }
            .disabled(viewModel.courses.isEmpty)
            .onChange(of: settings.selectedAcademicYear) { _, newValue in
                if let yearLabel = viewModel.academicYears.first(where: { $0.id == newValue })?.label {
                    settings.selectedAcademicYearName = yearLabel
                }
                settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
            }
        }
        case .matricola: OnboardingPage(
            title: "Sei matricola pari o dispari?",
            subtitle: "Serve per filtrare le lezioni divise per **gruppo pari o dispari**.",
            isActive: step == .matricola,
            errorMessage: $errorText,
            bottomPadding: safeAreas.bottom,
            buttonTitle: "Comincia!",
            isLoading: false,
            isButtonDisabled: false,
            buttonAction: {
                completeOnboarding()
            }
        ) { ShortListSelector<SelectableOption>(items: [.even, .odd], selectedItem: $settings.matricola) }
        }
    }
    
    // MARK: - Helpers
    @MainActor
    private func handlePageTransition(to targetIndex: OnboardingStep, operation: @escaping () async throws -> Void) {
        guard loadingStep == nil else { return }
        withAnimation {
            loadingStep = targetIndex
        }
        
        transitionTask?.cancel()
        transitionTask = Task {
            defer { transitionTask = nil }
            do {
                try await operation()
                
                guard loadingStep == targetIndex else { return }
                
                withAnimation {
                    step = targetIndex
                    loadingStep = nil
                }
            } catch is CancellationError {
                withAnimation {
                    loadingStep = nil
                }
                return
            } catch {
                if let errorMessage = viewModel.errorMessage {
                    self.errorText = errorMessage
                }
                
                withAnimation {
                    loadingStep = nil
                }
            }
        }
    }
    
    func completeOnboarding() {
        settings.latestVersion = Bundle.main.clearAppVersion
        settings.onboardingCompleted = true
    }
}

#Preview {
    Onboarding()
        .environment(UserSettings.shared)
        .readSafeAreaInsets()
}
