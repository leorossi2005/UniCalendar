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
    
    private let net: NetworkMonitor = .shared
    @State private var viewModel = UniversityDataManager()
    
    @State private var currentIndex: Int? = 0
    @State private var nextIndexLoading: Int = -1
    @State private var errorText: String = "nope"
    
    @State private var offlineScale: CGFloat = 1
    @State private var offlineOffset: CGPoint = .zero
    
    @State private var searchTextFieldFocus: Bool = false
    
    let animation: Namespace.ID
    @Binding var showSplash: Bool
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        @Bindable var settings = settings
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                OnboardingPage(
                    title: "Benvenuto!",
                    subtitle: "Non capisci mai che lezioni hai? Non hai voglia di aprire il sito ogni volta o usare app obsolete? Ora puoi fare tutto qui!",
                    errorMessage: $errorText,
                    isTopContent: true,
                    content: {
                        if !showSplash {
                            Image("InternalIcon")
                                .resizable()
                                .clipShape(RoundedRectangle(cornerRadius: 100 * 0.225, style: .continuous))
                                .matchedGeometryEffect(id: "appIcon", in: animation, isSource: false)
                                .frame(width: 100, height: 100)
                        }
                    },
                    bottomPadding: safeAreas.bottom,
                    buttonTitle: "Continua",
                    isLoading: nextIndexLoading > 0,
                    isButtonDisabled: net.status != .connected,
                    buttonAction: {
                        handlePageTransition(to: 1) {
                            try await viewModel.loadYears()
                        }
                    }
                )
                .id(0)
                OnboardingPage(
                    title: "Scegli un anno",
                    subtitle: "Seleziona un anno precedente per vedere l'archivio, sennò procedi pure con l'ultimo ;)",
                    errorMessage: $errorText,
                    isTopContent: false,
                    content: {
                        Picker(selection: $settings.selectedYear) {
                            ForEach(viewModel.years, id: \.valore) { year in
                                Text(year.label).tag(year.valore)
                            }
                        } label: {}
                        .pickerStyle(.segmented)
                        .padding()
                    },
                    bottomPadding: safeAreas.bottom,
                    buttonTitle: "Continua",
                    isLoading: nextIndexLoading > 1,
                    isButtonDisabled: net.status != .connected,
                    buttonAction: {
                        viewModel.courses = []
                        settings.selectedCourse = "0"
                        
                        handlePageTransition(to: 2) {
                            try await viewModel.loadCourses(year: settings.selectedYear)
                        }
                    }
                )
                .id(1)
                OnboardingPage(
                    title: "Bene! Ora scegli un corso",
                    subtitle: "Sono mostrati i corsi per l'anno \(viewModel.years.filter{$0.valore == settings.selectedYear}.first?.label ?? "")",
                    errorMessage: $errorText,
                    isTopContent: false,
                    content: {
                        CourseSelector(
                            isFocused: $searchTextFieldFocus,
                            selectedCourse: $settings.selectedCourse,
                            courses: viewModel.courses
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
                            viewModel.updateAcademicYears(for: settings.selectedCourse, year: settings.selectedYear)
                            
                            if let firstYear = viewModel.academicYears.first {
                                await MainActor.run {
                                    settings.selectedAcademicYear = firstYear.valore
                                    settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                                }
                            }
                        }
                    }
                )
                .id(2)
                OnboardingPage(
                    title: "Che anno frequenti?",
                    subtitle: "Se vedi solo un anno allora lascia così, non puoi sbagliare!",
                    errorMessage: $errorText,
                    isTopContent: false,
                    content: {
                        Picker(selection: $settings.selectedAcademicYear) {
                            ForEach(viewModel.academicYears, id: \.valore) { year in
                                Text(year.label).tag(year.valore)
                            }
                        } label: {}
                        .pickerStyle(.segmented)
                        .padding()
                        .disabled(viewModel.courses.isEmpty)
                        .onChange(of: settings.selectedAcademicYear) { oldValue, newValue in
                            settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                        }
                    },
                    bottomPadding: safeAreas.bottom,
                    buttonTitle: settings.foundMatricola ? "Continua" : "Comincia!",
                    isLoading: nextIndexLoading > 3,
                    isButtonDisabled: false,
                    buttonAction: {
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
                    subtitle: "O il tuo amico, ovvio",
                    errorMessage: $errorText,
                    isTopContent: false,
                    content: {
                        Picker(selection: $settings.matricola) {
                            Text("Pari").tag("pari")
                            Text("Dispari").tag("dispari")
                        } label: {}
                        .pickerStyle(.segmented)
                        .padding()
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
                    .blur(radius: net.status != .connected ? 0 : 20)
                    .offset(y: net.status != .connected ? safeAreas.top : safeAreas.top / 2)
                    .scaleEffect(net.status != .connected ? 1 : 0)
                    .animation(.bouncy(extraBounce: 0.1), value: net.status)
                    .ignoresSafeArea()
            } else {
                Text("Al momento sei offline.")
                    .blur(radius: net.status != .connected ? 0 : 20)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(colorScheme == .light ? .yellow : Color(hex: "#CCAA00")!)
                            .strokeBorder(colorScheme == .light ? Color(hex: "#CCAA00")! : Color(hex: "#B39500")!, lineWidth: 2)
                    }
                    .blur(radius: net.status != .connected ? 0 : 20)
                    .offset(y: net.status != .connected ? safeAreas.top : safeAreas.top / 2)
                    .scaleEffect(net.status != .connected ? 1 : 0)
                    .animation(.bouncy(extraBounce: 0.1), value: net.status)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.loadFromCache()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never, axes: .horizontal)
        .scrollPosition(id: $currentIndex, anchor: .center)
        .scrollDisabled(true)
        .animation(.snappy, value: currentIndex)
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
    
    public func completeOnboarding() {
        settings.onboardingCompleted = true
    }
}

// MARK: - Subviews
private struct OnboardingButton: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            Haptics.play(.impact(weight: .medium))
            action()
        } label: {
            if isLoading {
                RotatingSemicircleLoader()
            } else {
                Text(title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .glassProminentIfAvailable()
        .disabled(isDisabled || isLoading)
        .keyboardPadding(10)
    }
}

private struct OnboardingPage<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var errorMessage: String
    let isTopContent: Bool
    @ViewBuilder let content: Content
    let bottomPadding: CGFloat
    
    let buttonTitle: LocalizedStringKey
    let isLoading: Bool
    let isButtonDisabled: Bool
    let buttonAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if isTopContent {
                content
                    .multilineTextAlignment(.center)
            }
            Text(title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if !isTopContent {
                content
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .opacity(errorMessage == "nope" ? 0 : 1)
                .task(id: errorMessage) {
                    do {
                        try await Task.sleep(for: .seconds(3))
                        
                        errorMessage = "nope"
                    } catch {}
                }
            OnboardingButton(
                title: buttonTitle,
                isLoading: isLoading,
                isDisabled: isButtonDisabled,
                action: buttonAction
            )
            .padding(.horizontal, bottomPadding)
        }
        .containerRelativeFrame(.horizontal)
    }
}

private struct RotatingSemicircleLoader: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(colorScheme == .light ? .black : .white, lineWidth: 4)
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    @Previewable @Namespace var animation: Namespace.ID
    @Previewable @State var showSplash: Bool = false
    
    Onboarding(animation: animation, showSplash: $showSplash)
        .environment(UserSettings.shared)
}
