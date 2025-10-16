//
//  Settings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/25.
//

import SwiftUI

struct Settings: View {
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @AppStorage("selectedYear") var selectedYearStorage: String = "2025"
    @AppStorage("selectedCourse") var selectedCourseStorage: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYearStorage: String = "0"
    @AppStorage("matricola") var matricolaStorage: String = "pari"
    
    @State private var years: [Year] = []
    @State private var courses: [Corso] = []
    @State private var academicYears: [Anno] = []
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var openSettings: Bool
    @Binding var openCalendar: Bool
    @Binding var selectedTab: Int
    @Binding var selectedDetent: PresentationDetent
    
    @Binding var selectedYear: String
    @Binding var selectedCourse: String
    @Binding var selectedAcademicYear: String
    @Binding var matricola: String
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Anno")
                        .padding(.trailing)
                    Picker("Anno", selection: $selectedYear) {
                        ForEach(years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedYear) {
                        detents = [.large]
                        
                        courses = []
                        selectedCourse = "0"
                        
                        academicYears = []
                        selectedAcademicYear = "0"
                        
                        getCourses(year: selectedYear) { result in
                            courses = result
                        }
                    }
                }
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
                .onChange(of: selectedCourse) {
                    if selectedCourse != "0" {
                        detents = [.fraction(0.15), .medium, .large]
                        
                        academicYears = []
                        
                        academicYears = courses.filter { $0.valore == selectedCourse }.first!.elenco_anni
                        
                        selectedAcademicYear = academicYears.first!.valore
                    } else {
                        detents = [.large]
                        
                        academicYears = []
                    }
                }
                HStack {
                    Text("Anno")
                        .padding(.trailing)
                    Picker(selection: $selectedAcademicYear, content: {
                        ForEach(academicYears, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                        .disabled(courses.isEmpty)
                }
                HStack {
                    Text("Matricola")
                        .padding(.trailing)
                    Picker("", selection: $matricola) {
                        Text("Pari").tag("pari")
                        Text("Dispari").tag("dispari")
                    }
                    .pickerStyle(.segmented)
                }
            }
            Section {
                Button("Resetta l'app") {
                    selectedDetent = .fraction(0.15)
                    detents = [.fraction(0.15), .medium]
                    
                    onboardingCompleted = false
                    selectedYearStorage = "2025"
                    selectedCourseStorage = "0"
                    selectedAcademicYearStorage = "0"
                    matricolaStorage = "pari"
                    
                    selectedTab = 1
                    openCalendar = false
                    openSettings = false
                }
            }
        }
        .onAppear {
            getYears { result in
                years = result
            }
            
            getCourses(year: selectedYear) { result in
                courses = result
                
                if selectedCourse != "0" {
                    academicYears = courses.filter { $0.valore == selectedCourse }.first!.elenco_anni
                } else if openSettings {
                    detents = [.large]
                }
            }
        }
    }
}

#Preview {
    Settings(detents: .constant([]), openSettings: .constant(true), openCalendar: .constant(true), selectedTab: .constant(0), selectedDetent: .constant(.large), selectedYear: .constant(""), selectedCourse: .constant(""), selectedAcademicYear: .constant(""), matricola: .constant(""))
}
