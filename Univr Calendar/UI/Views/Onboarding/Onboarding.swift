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
            .overlay(alignment: .top) {
                Text("Al momento sei offline.")
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 25)
                                .glassEffect(.regular.interactive().tint(.yellow.opacity(0.7)))
                        } else {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(colorScheme == .light ? .yellow : Color(hex: "#CCAA00")!)
                                .strokeBorder(colorScheme == .light ? Color(hex: "#CCAA00")! : Color(hex: "#B39500")!, lineWidth: 2)
                        }
                    }
                    .blur(radius: viewModel.isOffline ? 0 : 20)
                    .offset(y: viewModel.isOffline ? safeAreas.top : safeAreas.top / 2)
                    .scaleEffect(viewModel.isOffline ? 1 : 0)
                    .animation(.bouncy(extraBounce: 0.1), value: viewModel.isOffline)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $step, anchor: .center)
            .scrollDisabled(true)
            .animation(.snappy, value: step)
            .task(id: viewModel.isOffline) {
                if let year = await viewModel.prefetch(preferredYear: settings.selectedYear) {
                    settings.selectedYear = year
                }
            }
            .onDisappear { viewModel.cancelAll() }
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
            isButtonDisabled: viewModel.isOffline || step != .welcome || loadingStep != nil,
            buttonAction: {
                guard step == .welcome, loadingStep == nil else { return }
                handlePageTransition(to: .year) {
                    try await viewModel.ensureYears()
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
            isButtonDisabled: viewModel.isOffline || loadingStep != nil,
            buttonAction: {
                guard step == .year, loadingStep == nil else { return }
                handlePageTransition(to: .course) {
                    let year = settings.selectedYear
                    if year != viewModel.coursesYear { settings.selectedCourse = "0" }
                    try await viewModel.ensureCourses(year: year)
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
        
        Task {
            do {
                try await operation()
                
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
