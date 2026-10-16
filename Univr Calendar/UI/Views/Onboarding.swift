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
    
    var body: some View {
        @Bindable var settings = settings
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                WelcomeOnboardingPage(
                    title: "Benvenuto!",
                    subtitle: "Non capisci mai che lezioni hai? Non hai voglia di aprire il sito ogni volta o usare app obsolete? Ora puoi fare tutto qui!",
                    errorMessage: $errorText,
                    bottomPadding: safeAreas.bottom,
                    buttonTitle: "Continua",
                    isLoading: nextIndexLoading > 0,
                    isButtonDisabled: viewModel.isOffline,
                    buttonAction: {
                        handlePageTransition(to: 1) {
                            try await viewModel.loadYears()
                            
                            if settings.selectedYear == "0" || !viewModel.years.contains(where: { $0.id == settings.selectedYear }) {
                                if let lastYear = viewModel.years.last {
                                    await MainActor.run {
                                        settings.selectedYear = lastYear.id
                                    }
                                }
                            }
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
                            ForEach(viewModel.years) { year in
                                Text(year.label).tag(year.id)
                            }
                        } label: {}
                        .pickerStyle(.segmented)
                        .padding()
                    },
                    bottomPadding: safeAreas.bottom,
                    buttonTitle: "Continua",
                    isLoading: nextIndexLoading > 1,
                    isButtonDisabled: viewModel.isOffline,
                    buttonAction: {
                        viewModel.resetCourses()
                        settings.selectedCourse = "0"
                        
                        handlePageTransition(to: 2) {
                            try await viewModel.loadCourses(year: settings.selectedYear)
                        }
                    }
                )
                .id(1)
                OnboardingPage(
                    title: "Bene! Ora scegli un corso",
                    subtitle: "Sono mostrati i corsi per l'anno \(viewModel.years.filter{$0.id == settings.selectedYear}.first?.label ?? "")",
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
                            viewModel.updateAcademicYears(for: settings.selectedCourse)
                            
                            if let firstYear = viewModel.academicYears.first {
                                await MainActor.run {
                                    settings.selectedAcademicYear = firstYear.id
                                    settings.selectedAcademicYearName = firstYear.label
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
                            ForEach(viewModel.academicYears) { year in
                                Text(year.label).tag(year.id)
                            }
                        } label: {}
                        .pickerStyle(.segmented)
                        .padding()
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
                            Text("Pari").tag("even")
                            Text("Dispari").tag("odd")
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
            .scrollTargetLayout()
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
    
    func completeOnboarding() {
        settings.latestVersion = Bundle.main.clearAppVersion
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
        .glassIfAvailable(prominent: true)
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Welcome Onboarding Page (Solo Pagina 0)
private struct WelcomeOnboardingPage: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var errorMessage: String
    let bottomPadding: CGFloat
    
    let buttonTitle: LocalizedStringKey
    let isLoading: Bool
    let isButtonDisabled: Bool
    let buttonAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isExpanded: Bool = false
    @State private var isBlurred: Bool = false
    @State private var showText: Bool = false
    @State private var showButton: Bool = false
    
    @State private var zStackCenterY: CGFloat = 0
    
    private let initialSize: CGFloat = 200
    
    private var initialOffset: CGFloat {
        guard zStackCenterY > 0 else { return 0 }
        let screenCenterY = UIScreen.main.bounds.height / 2
        return screenCenterY - zStackCenterY
    }
    
    var body: some View {
        GeometryReader { proxy in
            let targetSize = max(proxy.size.width - 32, 200)
            let currentSize = isExpanded ? targetSize : initialSize
            let currentOffset = isExpanded ? -40 : initialOffset
            
            VStack(spacing: 12) {
                Spacer()
                
                ZStack {
                    // Icona che parte dal centro esatto dello schermo e sale a -40
                    iconView(size: currentSize)
                        .offset(y: currentOffset)
                    
                    // Testo centrato (rialzato) sopra la parte sfocata dell'icona
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 16)
                }
                .frame(maxWidth: .infinity)
                .background {
                    Color.clear
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .global).midY
                        } action: { midY in
                            zStackCenterY = midY
                        }
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
                .padding(.horizontal, max(bottomPadding, 16))
                .keyboardPadding(10)
                .opacity(showButton ? 1 : 0)
                .blur(radius: showButton ? 0 : 12)
                .allowsHitTesting(showButton)
            }
            .multilineTextAlignment(.center)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .containerRelativeFrame(.horizontal)
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private func iconView(size: CGFloat) -> some View {
        ZStack {
            // 1. Icona base nitida
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
            
            // 2. Overlay sfocato con maschera progressiva
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
                .blur(radius: isBlurred ? 28 : 0)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.08),
                            .init(color: .black, location: 0.40)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isBlurred ? 1 : 0)
            
            // 3. Velo del colore di sfondo in Light Mode (Idea 2: dissolve il contrasto residuo nel bianco)
            if colorScheme == .light {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.25),
                        .init(color: Color(.systemBackground).opacity(0.70), location: 0.72),
                        .init(color: Color(.systemBackground), location: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(isBlurred ? 1 : 0)
            }
        }
        .frame(width: size, height: size)
        .mask(
            LinearGradient(
                stops: opacityStops,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .mask {
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
        }
    }
    
    private var opacityStops: [Gradient.Stop] {
        if colorScheme == .light {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.10),
                .init(color: .black.opacity(isBlurred ? 0.70 : 1.0), location: 0.35),
                .init(color: .black.opacity(isBlurred ? 0.38 : 1.0), location: 0.52),
                .init(color: .black.opacity(isBlurred ? 0.15 : 1.0), location: 0.68),
                .init(color: .black.opacity(isBlurred ? 0.04 : 1.0), location: 0.78),
                .init(color: .black.opacity(isBlurred ? 0.008 : 1.0), location: 0.84),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 0.88),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 1.0)
            ]
        } else {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.12),
                .init(color: .black.opacity(isBlurred ? 0.08 : 1.0), location: 0.82),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 1.0)
            ]
        }
    }
    
    private func startAnimation() {
        guard !isExpanded else { return }
        
        Task { @MainActor in
            // Breve respiro per garantire il calcolo geometrico della posizione iniziale
            try? await Task.sleep(for: .milliseconds(50))
            guard !isExpanded else { return }
            
            // 1. Si allarga verso (schermo - 32) e si sposta in alto a -40 partendo dal centro schermo
            withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
                isExpanded = true
            }
            
            // 2. Blur dal basso + dissolvenza opacità
            withAnimation(.easeInOut(duration: 0.7).delay(0.35)) {
                isBlurred = true
            }
            
            // 3. Il testo compare centrato salendo leggermente
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.45)) {
                showText = true
            }
            
            // 4. Il pulsante si materializza sul posto con sfocatura e dissolvenza
            withAnimation(.easeInOut(duration: 0.6).delay(0.50)) {
                showButton = true
            }
        }
    }
}

// MARK: - Onboarding Page (Pagine 1, 2, 3...)
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
        VStack(spacing: 12) {
            Spacer()
            if isTopContent { content }
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
            if !isTopContent { content }
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
            .keyboardPadding(10)
        }
        .padding(.horizontal, bottomPadding)
        .multilineTextAlignment(.center)
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
    Onboarding()
        .environment(UserSettings.shared)
        .readSafeAreaInsets()
}
