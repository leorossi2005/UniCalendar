//
//  Onboarding.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 14/10/25.
//

import SwiftUI
import UnivrCore

private struct OnboardingButton: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

struct Onboarding: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = UniversityDataManager()
    
    @State private var currentIndex: Int? = 0
    @State private var nextIndexLoading: Int = -1
    
    @State private var searchText: String = ""
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
                    isButtonDisabled: false,
                    buttonAction: {
                        handlePageTransition(to: 1) {
                            await viewModel.loadYears()
                        }
                    }
                )
                .id(0)
                OnboardingPage(
                    title: "Scegli un anno",
                    subtitle: "Seleziona un anno precedente per vedere l'archivio, sennò procedi pure con l'ultimo ;)",
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
                    isButtonDisabled: false,
                    buttonAction: {
                        viewModel.courses = []
                        settings.selectedCourse = "0"
                        
                        handlePageTransition(to: 2) {
                            await viewModel.loadCourses(year: settings.selectedYear)
                        }
                    }
                )
                .id(1)
                OnboardingPage(
                    title: "Bene! Ora scegli un corso",
                    subtitle: "Sono mostrati i corsi per l'anno \(viewModel.years.filter{$0.valore == settings.selectedYear}.first?.label ?? "")",
                    isTopContent: false,
                    content: {
                        CourseSelectionView(
                            searchText: $searchText,
                            isFocused: $searchTextFieldFocus,
                            selectedCourse: $settings.selectedCourse,
                            courses: viewModel.courses,
                            screenSize: screenSize
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
    private func handlePageTransition(to targetIndex: Int, operation: @escaping () async -> Void) {
        withAnimation {
            nextIndexLoading = targetIndex
        }
        
        Task {
            await operation()
            
            await MainActor.run {
                withAnimation {
                    currentIndex = targetIndex
                }
            }
        }
    }
    
    public func completeOnboarding() {
        settings.onboardingCompleted = true
    }
}

#Preview {
    @Previewable @Namespace var animation: Namespace.ID
    @Previewable @State var showSplash: Bool = false
    
    Onboarding(animation: animation, showSplash: $showSplash)
        .environment(UserSettings.shared)
}
