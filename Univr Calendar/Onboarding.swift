//
//  Onboarding.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 14/10/25.
//

import SwiftUI

struct RotatingSemicircleLoader: View {
    @State private var rotation: Double = 0
    @State private var width: CGFloat = .infinity
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(.white, lineWidth: 4)
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
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    @AppStorage("selectedCourse") var selectedCourse: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYear: String = "0"
    @AppStorage("matricola") var matricola: String = "Pari"
    
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @Binding var selectedTab: Int
    
    @State private var index: Int = 0
    @State private var nextIndex: Int = 0
    
    @State private var years: [Year] = []
    @State private var courses: [Corso] = []
    @State private var academicYears: [Anno] = []
    
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
                
                Menu(content: {
                    Button(action: {
                        selectedCourse = "0"
                    }) {
                        Text("Scegli un corso")
                    }
                    ForEach(courses, id: \.valore) { course in
                        Button(action: {
                            selectedCourse = course.valore
                        }) {
                            Text(course.label).tag(course.valore)
                        }
                    }
                }) {
                    Text(courses.filter{$0.valore == selectedCourse}.first?.label ?? "Scegli un corso")
                        .padding()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(30)
                        .padding()
                }
                .disabled(courses.isEmpty)
                Spacer()
                Button(action: {
                    withAnimation {
                        academicYears = []
                        
                        academicYears = courses.filter { $0.valore == selectedCourse }.first!.elenco_anni
                        
                        selectedAcademicYear = academicYears.first!.valore
                        
                        index = 2
                    }
                }) {
                    Text("Continua")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, safeAreas.bottom)
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .disabled(selectedCourse == "0")
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
                Spacer()
                Button(action: {
                    withAnimation {
                        index = 3
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
    Onboarding(selectedTab: .constant(0))
}
