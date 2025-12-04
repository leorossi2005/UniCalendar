//
//  Onboarding.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 14/10/25.
//

import SwiftUI
import UnivrCore

struct RotatingSemicircleLoader: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var rotation: Double = 0
    @State private var width: CGFloat = .infinity
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(colorScheme == .light ? .black : .white, lineWidth: 4)
            .frame(height: 20)
            .frame(maxWidth: width, alignment: .center)
            .scaleEffect(1)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation {
                    width = 20
                }
            }
    }
}

struct Onboarding: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = OnboardingViewModel()
    
    @State private var index: Int? = 0
    @State private var nextIndex: Int = 0
    
    @State private var searchText: String = ""
    @FocusState private var searchTextFieldFocus: Bool
    
    @Binding var selectedTab: Int
    
    @State var animation: Namespace.ID
    @Binding var showSplash: Bool
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    @State var safeAreas: UIEdgeInsets = .zero
    
    var body: some View {
        @Bindable var settings = settings
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                VStack {
                    Spacer()
                    if !showSplash {
                        Image("InternalIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 100 * 0.225, style: .continuous))
                            .matchedGeometryEffect(id: "appIcon", in: animation)
                            .frame(width: 100, height: 100)
                    }
                    Text("Benvenuto!")
                        .font(.title)
                        .bold()
                    Text("Non capisci mai che lezioni hai? Non hai voglia di aprire il sito ogni volta o usare app obsolete? Ora puoi fare tutto qui!")
                        .padding(.horizontal)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            nextIndex = 1
                            Task {
                                await viewModel.loadYears()
                                
                                await MainActor.run {
                                    withAnimation {
                                        index = nextIndex
                                    }
                                }
                            }
                        }
                    }) {
                        if nextIndex < 1 {
                            Text("Continua")
                                .frame(maxWidth: .infinity)
                        } else {
                            RotatingSemicircleLoader()
                        }
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                    .disabled(nextIndex == 1)
                }
                .containerRelativeFrame(.horizontal)
                .multilineTextAlignment(.center)
                .id(0)
                VStack {
                    Spacer()
                    Text("Scegli un anno")
                        .font(.title)
                        .bold()
                    Text("Seleziona un anno precedente per vedere l'archivio, sennò procedi pure con l'ultimo ;)")
                        .padding(.horizontal)
                    
                    Picker(selection: $settings.selectedYear, content: {
                        ForEach(viewModel.years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                    Spacer()
                    Button(action: {
                        withAnimation {
                            viewModel.courses = []
                            settings.selectedCourse = "0"
                            
                            nextIndex = 2
                            Task {
                                await viewModel.loadCourses(year: settings.selectedYear)
                                
                                await MainActor.run {
                                    withAnimation {
                                        index = nextIndex
                                    }
                                }
                            }
                        }
                    }) {
                        if nextIndex < 2 {
                            Text("Continua")
                                .frame(maxWidth: .infinity)
                        } else {
                            RotatingSemicircleLoader()
                        }
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                    .disabled(nextIndex == 2)
                }
                .containerRelativeFrame(.horizontal)
                .multilineTextAlignment(.center)
                .id(1)
                VStack {
                    Spacer()
                    Text("Bene! Ora scegli un corso")
                        .font(.title)
                        .bold()
                    Text("Sono mostrati i corsi per l'anno \(viewModel.years.filter{$0.valore == settings.selectedYear}.first?.label ?? "")")
                        .padding(.horizontal)
                    
                    HStack {
                        TextField("Cerca un corso", text: $searchText)
                            .focused($searchTextFieldFocus)
                            .frame(height: 50)
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(25)
                        if searchTextFieldFocus {
                            Button(action: {
                                withAnimation(nil) {
                                    searchTextFieldFocus = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(25)
                            }
                            .tint(.primary)
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                    if searchText == "" && !searchTextFieldFocus {
                        Menu(content: {
                            Button(action: {
                                settings.selectedCourse = "0"
                            }) {
                                HStack {
                                    if settings.selectedCourse == "0" {
                                        Image(systemName: "checkmark")
                                            .frame(width: 40)
                                    }
                                    Text("Scegli un corso")
                                }
                            }
                            ForEach(viewModel.courses, id: \.valore) { course in
                                Button(action: {
                                    settings.selectedCourse = course.valore
                                }) {
                                    HStack {
                                        if settings.selectedCourse == course.valore {
                                            Image(systemName: "checkmark")
                                                .frame(width: 40)
                                        }
                                        Text(course.label).tag(course.valore)
                                    }
                                }
                            }
                        }) {
                            Text(viewModel.courses.filter{$0.valore == settings.selectedCourse}.first?.label ?? String(localized: "Scegli un corso"))
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                                .padding()
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(25)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        .disabled(viewModel.courses.isEmpty)
                    } else {
                        let filteredCourses = viewModel.courses.filter { (searchText != "" ? $0.label.localizedCaseInsensitiveContains(searchText) : true) }
                        
                        if !filteredCourses.isEmpty {
                            ScrollView {
                                VStack {
                                    ForEach(filteredCourses, id: \.valore) { course in
                                        if course.valore != filteredCourses.first?.valore {
                                            Divider()
                                        }
                                        Button(action: {
                                            searchText = ""
                                            searchTextFieldFocus = false
                                            
                                            settings.selectedCourse = course.valore
                                        }) {
                                            HStack {
                                                Image(systemName: "checkmark")
                                                    .frame(width: 40)
                                                    .opacity(settings.selectedCourse == course.valore ? 1 : 0)
                                                Text(course.label)
                                                    .padding(.vertical)
                                                    .padding(.trailing)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            .foregroundStyle(colorScheme == .light ? .black : .white)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                            .background(Color.gray.opacity(0.2))
                            .frame(height: screenSize.height * 0.23)
                            .cornerRadius(25)
                            .padding(.bottom)
                            .padding(.horizontal)
                        } else {
                            Text("Nessun corso trovato")
                                .padding(.vertical)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(25)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                    Spacer()
                    Button(action: {
                        searchTextFieldFocus = false
                        nextIndex = 3
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                viewModel.academicYears = []
                                settings.foundMatricola = false
                                
                                viewModel.updateAcademicYears(for: settings.selectedCourse, year: settings.selectedYear)
                                
                                settings.selectedAcademicYear = viewModel.academicYears.first!.valore
                                
                                settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                                
                                index = nextIndex
                            }
                        }
                    }) {
                        if nextIndex < 3 {
                            Text("Continua")
                                .frame(maxWidth: .infinity)
                        } else {
                            RotatingSemicircleLoader()
                        }
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                    .disabled(settings.selectedCourse == "0" || nextIndex == 3)
                    .keyboardPadding(10)
                }
                .containerRelativeFrame(.horizontal)
                .multilineTextAlignment(.center)
                .id(2)
                VStack {
                    Spacer()
                    Text("Che anno frequenti?")
                        .font(.title)
                        .bold()
                    Text("Se vedi solo un anno allora lascia così, non puoi sbagliare!")
                        .padding(.horizontal)
                    
                    Picker(selection: $settings.selectedAcademicYear, content: {
                        ForEach(viewModel.academicYears, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                        .disabled(viewModel.courses.isEmpty)
                        .onChange(of: settings.selectedAcademicYear) { oldValue, newValue in
                            settings.foundMatricola = viewModel.checkForMatricola(in: settings.selectedAcademicYear)
                        }
                    Spacer()
                    Button(action: {
                        if settings.foundMatricola {
                            nextIndex = 4
                            withAnimation {
                                index = nextIndex
                            }
                        } else {
                            settings.onboardingCompleted = true
                            
                            selectedTab = 0
                        }
                    }) {
                        Text(settings.foundMatricola ? String(localized: "Continua") : String(localized: "Comincia!"))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                }
                .containerRelativeFrame(.horizontal)
                .multilineTextAlignment(.center)
                .id(3)
                VStack {
                    Spacer()
                    Text("Sei matricola pari o dispari?")
                        .font(.title)
                        .bold()
                    Text("O il tuo amico, ovvio")
                        .padding(.horizontal)
                    
                    Picker(selection: $settings.matricola, content: {
                        Text("Pari").tag("pari")
                        Text("Dispari").tag("dispari")
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                    Spacer()
                    Button(action: {
                        withAnimation {
                            settings.onboardingCompleted = true
                            
                            selectedTab = 0
                        }
                    }) {
                        Text("Comincia!")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                }
                .containerRelativeFrame(.horizontal)
                .multilineTextAlignment(.center)
                .id(4)
            }
        }
        .onAppear {
            index = 0
            nextIndex = 0
            
            safeAreas = UIApplication.shared.safeAreas
            
            viewModel.loadFromCache()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never, axes: .horizontal)
        .scrollPosition(id: $index, anchor: .center)
        .scrollDisabled(true)
    }
}

#Preview {
    @Previewable @Namespace var animation: Namespace.ID
    @Previewable @State var showSplash: Bool = false
    
    Onboarding(selectedTab: .constant(0), animation: animation, showSplash: $showSplash)
        .environment(UserSettings.shared)
}
