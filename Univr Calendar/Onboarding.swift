//
//  Onboarding.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 14/10/25.
//

import SwiftUI

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
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    @AppStorage("selectedCourse") var selectedCourse: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYear: String = "0"
    @AppStorage("foundMatricola") var foundMatricola: Bool = false
    @AppStorage("matricola") var matricola: String = "Pari"
    
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @State private var index: Int = 0
    @State private var nextIndex: Int = 0
    
    @State private var searchText: String = ""
    @FocusState private var searchTextFieldFocus: Bool
    
    @Binding var years: [Year]
    @Binding var courses: [Corso]
    @Binding var academicYears: [Anno]
    @Binding var selectedTab: Int
    
    private let safeAreas = UIApplication.shared.safeAreas
    
    var body: some View {
        TabView(selection: $index) {
            VStack {
                if !years.isEmpty {
                    Spacer()
                    Text("Benvenuto!")
                        .font(.title)
                        .bold()
                    Text("Cambia anno se desideri o procedi alla scelta del corso")
                    
                    Picker(selection: $selectedYear, content: {
                        ForEach(years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                    Spacer()
                    Button(action: {
                        withAnimation {
                            courses = []
                            selectedCourse = "0"

                            nextIndex = 1
                            getCourses(year: selectedYear) { result in
                                courses = result
                                
                                withAnimation {
                                    index = nextIndex
                                }
                            }
                        }
                    }) {
                        if nextIndex != 1 {
                            Text("Continua")
                                .frame(maxWidth: .infinity)
                        } else {
                            RotatingSemicircleLoader()
                        }
                    }
                    .padding(.horizontal, safeAreas.bottom)
                    .controlSize(.large)
                    .buttonStyle(.glassProminent)
                    .disabled(nextIndex == 1)
                }
            }
            .multilineTextAlignment(.center)
            .tag(0)
            .onAppear {
                getYears { result in
                    years = result
                }
            }
            VStack {
                Spacer()
                Text("Bene! Ora scegli un corso")
                    .font(.title)
                    .bold()
                Text("Sono mostrati i corsi per l'anno \(years.filter{$0.valore == selectedYear}.first?.label ?? "")")
                
                TextField("Cerca un corso", text: $searchText)
                    .focused($searchTextFieldFocus)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    .padding()
                if searchText == "" && !searchTextFieldFocus {
                    Menu(content: {
                        Button(action: {
                            selectedCourse = "0"
                        }) {
                            HStack {
                                if selectedCourse == "0" {
                                    Image(systemName: "checkmark")
                                        .frame(width: 40)
                                }
                                Text("Scegli un corso")
                            }
                        }
                        ForEach(courses, id: \.valore) { course in
                            Button(action: {
                                selectedCourse = course.valore
                            }) {
                                HStack {
                                    if selectedCourse == course.valore {
                                        Image(systemName: "checkmark")
                                            .frame(width: 40)
                                    }
                                    Text(course.label).tag(course.valore)
                                }
                            }
                        }
                    }) {
                        Text(courses.filter{$0.valore == selectedCourse}.first?.label ?? "Scegli un corso")
                            .foregroundStyle(colorScheme == .light ? .black : .white)
                            .padding()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(30)
                            .padding(.horizontal)
                    }
                    .disabled(courses.isEmpty)
                } else {
                    List {
                        let filteredCourses = courses.filter { (searchText != "" ? $0.label.localizedCaseInsensitiveContains(searchText) : true) }
                        if !filteredCourses.isEmpty {
                            ForEach(filteredCourses, id: \.valore) { course in
                                Button(action: {
                                    searchText = ""
                                    searchTextFieldFocus = false
                                    
                                    selectedCourse = course.valore
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark")
                                            .frame(width: 40)
                                            .opacity(selectedCourse == course.valore ? 1 : 0)
                                        Text(course.label).tag(course.valore)
                                    }
                                    .foregroundStyle(colorScheme == .light ? .black : .white)
                                }
                            }
                            .if(colorScheme == .light) { view in
                                view
                                    .listRowBackground(Color.gray.opacity(0.2))
                            }
                        } else {
                            Text("Nessun corso trovato")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.top, -35)
                    .scrollContentBackground(.hidden)
                }
                Spacer()
                Button(action: {
                    searchTextFieldFocus = false
                    nextIndex = 2
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            academicYears = []
                            foundMatricola = false
                            
                            academicYears = courses.first(where: { $0.valore == selectedCourse })!.elenco_anni
                            
                            selectedAcademicYear = academicYears.first!.valore
                            
                            let filtered: Anno = academicYears.first(where: { $0.valore == selectedAcademicYear })!
                            
                            for insegnamento in filtered.elenco_insegnamenti {
                                if insegnamento.label.contains("Matricole dispari") || insegnamento.label.contains("Matricole pari") {
                                    foundMatricola = true
                                }
                            }
                            
                            index = 2
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
                .buttonStyle(.glassProminent)
                .disabled(selectedCourse == "0" || nextIndex == 2)
                .keyboardPadding(10)
            }
            .multilineTextAlignment(.center)
            .tag(1)
            VStack {
                Spacer()
                Text("Che anno frequenti?")
                    .font(.title)
                    .bold()
                Text("Se vedi solo un anno allora lascia così, non puoi sbagliare!")
                
                Picker(selection: $selectedAcademicYear, content: {
                    ForEach(academicYears, id: \.valore) { year in
                        Text(year.label).tag(year.valore)
                    }
                }) {}
                    .pickerStyle(.segmented)
                    .padding()
                    .disabled(courses.isEmpty)
                    .onChange(of: selectedAcademicYear) { oldValue, newValue in
                        foundMatricola = false
                        
                        if !academicYears.isEmpty {
                            let filtered: Anno = academicYears.first(where: { $0.valore == newValue })!
                            
                            for insegnamento in filtered.elenco_insegnamenti {
                                if insegnamento.label.contains("Matricole dispari") || insegnamento.label.contains("Matricole pari") {
                                    foundMatricola = true
                                }
                            }
                        }
                    }
                Spacer()
                Button(action: {
                    if foundMatricola {
                        nextIndex = 3
                        withAnimation {
                            index = 3
                        }
                    } else {
                        onboardingCompleted = true
                        
                        selectedTab = 0
                    }
                }) {
                    Text(foundMatricola ? "Continua" : "Comincia!")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, safeAreas.bottom)
                .controlSize(.large)
                .buttonStyle(.glassProminent)
            }
            .multilineTextAlignment(.center)
            .tag(2)
            VStack {
                Spacer()
                Text("Sei matricola pari o dispari?")
                    .font(.title)
                    .bold()
                Text("O il tuo amico, ovvio")
                
                Picker(selection: $matricola, content: {
                    Text("Pari").tag("pari")
                    Text("Dispari").tag("dispari")
                }) {}
                    .pickerStyle(.segmented)
                    .padding()
                Spacer()
                Button(action: {
                    withAnimation {
                        onboardingCompleted = true
                        
                        selectedTab = 0
                    }
                }) {
                    Text("Comincia!")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, safeAreas.bottom)
                .controlSize(.large)
                .buttonStyle(.glassProminent)
            }
            .multilineTextAlignment(.center)
            .tag(3)
        }
        .onAppear {
            index = 0
            nextIndex = 0
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .highPriorityGesture(DragGesture())
    }
}

#Preview {
    Onboarding(years: .constant([]), courses: .constant([]), academicYears: .constant([]), selectedTab: .constant(0))
}
