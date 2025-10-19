//
//  Settings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/25.
//

import SwiftUI

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @AppStorage("selectedYear") var selectedYearStorage: String = "2025"
    @AppStorage("selectedCourse") var selectedCourseStorage: String = "0"
    @AppStorage("selectedAcademicYear") var selectedAcademicYearStorage: String = "0"
    @AppStorage("foundMatricola") var foundMatricola: Bool = false
    @AppStorage("matricola") var matricolaStorage: String = "pari"
    
    @Binding var years: [Year]
    @Binding var courses: [Corso]
    @Binding var academicYears: [Anno]
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var openSettings: Bool
    @Binding var openCalendar: Bool
    @Binding var selectedTab: Int
    @Binding var selectedDetent: PresentationDetent
    
    @Binding var selectedYear: String
    @Binding var selectedCourse: String
    @Binding var selectedAcademicYear: String
    @Binding var matricola: String
    
    @State private var searchText: String = ""
    @FocusState private var searchTextFieldFocus: Bool
    
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
                VStack {
                    TextField("Cerca un corso", text: $searchText)
                                .focused($searchTextFieldFocus)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                                .padding(.horizontal)
                                .padding(.top)
                                .listRowSeparator(.hidden)
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
                                .padding(.bottom)
                        }
                        .disabled(courses.isEmpty)
                    } else {
                        let filteredCourses = courses.filter { (searchText != "" ? $0.label.localizedCaseInsensitiveContains(searchText) : true) }
                        
                        if !filteredCourses.isEmpty {
                            VStack {
                                ForEach(filteredCourses, id: \.valore) { course in
                                    if course.valore != filteredCourses.first?.valore {
                                        Divider()
                                    }
                                    Button(action: {
                                        searchText = ""
                                        searchTextFieldFocus = false
                                        
                                        selectedCourse = course.valore
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark")
                                                .frame(width: 40)
                                                .opacity(selectedCourse == course.valore ? 1 : 0)
                                            Text(course.label)
                                                .padding(.vertical)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .foregroundStyle(colorScheme == .light ? .black : .white)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(30)
                            .padding(.horizontal)
                            .padding(.bottom)
                        } else {
                            Text("Nessun corso trovato")
                                .padding(.vertical)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                }
                .onChange(of: selectedCourse) {
                    if selectedCourse != "0" {
                        foundMatricola = false
                        
                        detents = [.fraction(0.15), .medium, .large]
                        
                        academicYears = []
                        
                        academicYears = courses.filter { $0.valore == selectedCourse }.first!.elenco_anni
                        
                        selectedAcademicYear = academicYears.first!.valore
                        
                        let filtered: Anno = academicYears.first(where: { $0.valore == selectedAcademicYear })!
                        
                        for insegnamento in filtered.elenco_insegnamenti {
                            if insegnamento.label.contains("Matricole dispari") || insegnamento.label.contains("Matricole pari") {
                                foundMatricola = true
                            }
                        }
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
                        .onChange(of: selectedAcademicYear) {
                            foundMatricola = false
                            
                            if selectedAcademicYear != "0" {
                                let filtered: Anno = academicYears.first(where: { $0.valore == selectedAcademicYear })!
                                
                                for insegnamento in filtered.elenco_insegnamenti {
                                    if insegnamento.label.contains("Matricole dispari") || insegnamento.label.contains("Matricole pari") {
                                        foundMatricola = true
                                    }
                                }
                            }
                        }
                }
                if foundMatricola {
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
            }
            Section {
                Button("Resetta l'app") {
                    selectedDetent = .fraction(0.15)
                    detents = [.fraction(0.15), .medium]
                    
                    onboardingCompleted = false
                    selectedYearStorage = "2025"
                    selectedCourseStorage = "0"
                    selectedAcademicYearStorage = "0"
                    foundMatricola = false
                    matricolaStorage = "pari"
                    
                    years = []
                    courses = []
                    academicYears = []
                    
                    selectedTab = 1
                    openCalendar = false
                    openSettings = false
                }
            }
        }
        .onAppear {
            if years.isEmpty {
                getYears { result in
                    years = result
                }
            }
            
            if courses.isEmpty {
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
}

#Preview {
    Settings(years: .constant([]), courses: .constant([]), academicYears: .constant([]), detents: .constant([]), openSettings: .constant(true), openCalendar: .constant(true), selectedTab: .constant(0), selectedDetent: .constant(.large), selectedYear: .constant(""), selectedCourse: .constant(""), selectedAcademicYear: .constant(""), matricola: .constant(""))
}
