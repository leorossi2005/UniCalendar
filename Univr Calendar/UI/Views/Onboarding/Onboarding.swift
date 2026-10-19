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

struct Onboarding: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = UniversityDataManager()
    
    @State private var currentIndex: Int? = 0
    @State private var nextIndexLoading: Int = -1
    @State private var errorText: String = "nope"
    
    @State private var searchTextFieldFocus: Bool = false
    @State private var academicYearSearchFocus: Bool = false
    
    var body: some View {
        @Bindable var settings = settings
        
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    WelcomeOnboardingPage(
                        title: "Benvenuto!",
                        subtitle: "Basta siti lenti o **app obsolete** per capire che **lezioni** hai.\n**Ora hai tutto in un unico posto.**",
                        errorMessage: $errorText,
                        bottomPadding: safeAreas.bottom,
                        buttonTitle: "Continua",
                        isLoading: nextIndexLoading > 0,
                        isButtonDisabled: viewModel.isOffline,
                        buttonAction: {
                            handlePageTransition(to: 1) {
                                try await viewModel.ensureYears()
                            }
                        }
                    )
                    .id(0)
                    OnboardingPage(
                        title: "Scegli un anno",
                        subtitle: "Seleziona un **anno precedente** per consultare l'archivio, oppure procedi con **l'ultimo disponibile**.",
                        isActive: currentIndex == 1,
                        errorMessage: $errorText,
                        isTopContent: false,
                        content: ShortListSelector(items: viewModel.years, selectedItem: $settings.selectedYear),
                        bottomPadding: safeAreas.bottom,
                        buttonTitle: "Continua",
                        isLoading: nextIndexLoading > 1,
                        isButtonDisabled: viewModel.isOffline,
                        buttonAction: {
                            handlePageTransition(to: 2) {
                                let year = settings.selectedYear
                                if year != viewModel.coursesYear { settings.selectedCourse = "0" }
                                try await viewModel.ensureCourses(year: year)
                            }
                        }
                    )
                    .id(1)
                    OnboardingPage(
                        title: "Bene! Ora scegli un corso",
                        subtitle: "Stai visualizzando i corsi per l'anno **\(viewModel.years.filter{$0.id == settings.selectedYear}.first?.label ?? "")**.",
                        isActive: currentIndex == 2,
                        isSearching: searchTextFieldFocus,
                        errorMessage: $errorText,
                        isTopContent: false,
                        content: {
                            LongListSelector(
                                isFocused: $searchTextFieldFocus,
                                selectedItem: $settings.selectedCourse,
                                items: viewModel.courses
                            )
                        },
                        bottomPadding: safeAreas.bottom,
                        buttonTitle: "Continua",
                        isLoading: nextIndexLoading > 2,
                        isButtonDisabled: settings.selectedCourse == "0",
                        buttonAction: {
                            searchTextFieldFocus = false
                            
                            viewModel.academicYears = []
                            settings.foundMatricola = false
                            
                            handlePageTransition(to: 3) {
                                viewModel.updateAcademicYears(for: settings.selectedCourse)
                                
                                await MainActor.run {
                                    if viewModel.academicYears.count <= 5, let firstYear = viewModel.academicYears.first {
                                        settings.selectedAcademicYear = firstYear.id
                                        settings.selectedAcademicYearName = firstYear.label
                                        settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                                    } else {
                                        settings.selectedAcademicYear = "0"
                                        settings.selectedAcademicYearName = ""
                                        settings.foundMatricola = false
                                    }
                                }
                            }
                        }
                    )
                    .id(2)
                    OnboardingPage(
                        title: "Che anno frequenti?",
                        subtitle: "Se è presente **un solo anno**, puoi procedere direttamente.",
                        isActive: currentIndex == 3,
                        isSearching: academicYearSearchFocus,
                        errorMessage: $errorText,
                        isTopContent: false,
                        content: {
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
                                        searchPrompt: "Cerca un anno di corso",
                                        defaultPrompt: "Scegli un anno"
                                    )
                                }
                            }
                            .disabled(viewModel.courses.isEmpty)
                            .onChange(of: settings.selectedAcademicYear) { oldValue, newValue in
                                if let yearLabel = viewModel.academicYears.first(where: { $0.id == newValue })?.label {
                                    settings.selectedAcademicYearName = yearLabel
                                }
                                settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                            }
                        },
                        bottomPadding: safeAreas.bottom,
                        buttonTitle: settings.foundMatricola ? "Continua" : "Comincia!",
                        isLoading: nextIndexLoading > 3,
                        isButtonDisabled: settings.selectedAcademicYear == "0" || settings.selectedAcademicYear.isEmpty,
                        buttonAction: {
                            academicYearSearchFocus = false
                            if settings.foundMatricola {
                                handlePageTransition(to: 4) {}
                            } else {
                                completeOnboarding()
                            }
                        }
                    )
                    .id(3)
                    OnboardingPage(
                        title: "Sei matricola pari o dispari?",
                        subtitle: "Serve per filtrare le lezioni divise per **gruppo pari o dispari**.",
                        isActive: currentIndex == 4,
                        errorMessage: $errorText,
                        isTopContent: false,
                        content: {
                            ShortListSelector<SelectableOption>(
                                items: [.even, .odd],
                                selectedItem: $settings.matricola
                            )
                        },
                        bottomPadding: safeAreas.bottom,
                        buttonTitle: "Comincia!",
                        isLoading: false,
                        isButtonDisabled: false,
                        buttonAction: {
                            completeOnboarding()
                        }
                    )
                    .id(4)
                }
                .scrollTargetLayout()
            }
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if let index = currentIndex, index > 0 {
                    ToolbarItem(placement: .navigation) {
                        Button {
                                searchTextFieldFocus = false
                                academicYearSearchFocus = false
                                currentIndex = index - 1
                                nextIndexLoading -= 1
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
                if #available(iOS 26, *) {
                    Text("Al momento sei offline.")
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                        }
                        .glassEffect(.regular.interactive().tint(.yellow.opacity(0.7)))
                        .blur(radius: viewModel.isOffline ? 0 : 20)
                        .offset(y: viewModel.isOffline ? safeAreas.top : safeAreas.top / 2)
                        .scaleEffect(viewModel.isOffline ? 1 : 0)
                        .animation(.bouncy(extraBounce: 0.1), value: viewModel.isOffline)
                        .ignoresSafeArea()
                } else {
                    Text("Al momento sei offline.")
                        .blur(radius: viewModel.isOffline ? 0 : 20)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(colorScheme == .light ? .yellow : Color(hex: "#CCAA00")!)
                                .strokeBorder(colorScheme == .light ? Color(hex: "#CCAA00")! : Color(hex: "#B39500")!, lineWidth: 2)
                        }
                        .blur(radius: viewModel.isOffline ? 0 : 20)
                        .offset(y: viewModel.isOffline ? safeAreas.top : safeAreas.top / 2)
                        .scaleEffect(viewModel.isOffline ? 1 : 0)
                        .animation(.bouncy(extraBounce: 0.1), value: viewModel.isOffline)
                        .ignoresSafeArea()
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $currentIndex, anchor: .center)
            .scrollDisabled(true)
            .animation(.snappy, value: currentIndex)
            .task(id: viewModel.isOffline) {
                if let year = await viewModel.prefetch(preferredYear: settings.selectedYear) {
                    settings.selectedYear = year
                }
            }
            .onDisappear { viewModel.cancelAll() }
        }
    }
    
    // MARK: - Helpers
    private func handlePageTransition(to targetIndex: Int, operation: @escaping () async throws -> Void) {
        withAnimation {
            nextIndexLoading = targetIndex
        }
        
        Task {
            do {
                try await operation()
                
                await MainActor.run {
                    withAnimation {
                        currentIndex = targetIndex
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                if let errorMessage = viewModel.errorMessage {
                    self.errorText = errorMessage
                }
                
                await MainActor.run {
                    withAnimation {
                        nextIndexLoading = currentIndex ?? 0
                    }
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
