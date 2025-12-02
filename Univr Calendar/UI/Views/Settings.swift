//
//  Settings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/25.
//

import SwiftUI

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = SettingsViewModel()
    
    @Binding var detents: Set<PresentationDetent>
    @Binding var openSettings: Bool
    @Binding var openCalendar: Bool
    @Binding var selectedTab: Int
    @Binding var selectedDetent: PresentationDetent
    
    @Binding var selectedYear: String
    @Binding var selectedCourse: String
    @Binding var selectedAcademicYear: String
    @Binding var matricola: String
    var searchTextFieldFocus: FocusState<Bool>.Binding
    
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Anno")
                        .padding(.trailing)
                    Picker("Anno", selection: $selectedYear) {
                        ForEach(viewModel.years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedYear) {
                        detents = [.large]
                        
                        viewModel.courses = []
                        selectedCourse = "0"
                        
                        viewModel.academicYears = []
                        selectedAcademicYear = "0"
                        
                        Task {
                            await viewModel.loadCourses(year: selectedYear)
                        }
                    }
                }
                VStack {
                    TextField("Cerca un corso", text: $searchText)
                                .focused(searchTextFieldFocus)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                                .padding(.horizontal)
                                .padding(.top)
                                .listRowSeparator(.hidden)
                    if searchText == "" && !searchTextFieldFocus.wrappedValue {
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
                            ForEach(viewModel.courses, id: \.valore) { course in
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
                            Text(viewModel.courses.filter{$0.valore == selectedCourse}.first?.label ?? "Scegli un corso")
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                                .padding()
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        .disabled(viewModel.courses.isEmpty)
                    } else {
                        let filteredCourses = viewModel.courses.filter { (searchText != "" ? $0.label.localizedCaseInsensitiveContains(searchText) : true) }
                        
                        if !filteredCourses.isEmpty {
                            VStack {
                                ForEach(filteredCourses, id: \.valore) { course in
                                    if course.valore != filteredCourses.first?.valore {
                                        Divider()
                                    }
                                    Button(action: {
                                        searchText = ""
                                        searchTextFieldFocus.wrappedValue = false
                                        
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
                        settings.foundMatricola = false
                        
                        detents = [.fraction(0.15), .medium, .large]
                        
                        viewModel.academicYears = []
                        selectedAcademicYear = "0"
                        
                        viewModel.updateAcademicYears(for: selectedCourse, year: selectedYear)
                        
                        selectedAcademicYear = viewModel.academicYears.first!.valore
                    } else {
                        detents = [.large]
                        
                        viewModel.academicYears = []
                        selectedAcademicYear = "0"
                    }
                }
                HStack {
                    Text("Anno")
                        .padding(.trailing)
                    Picker(selection: $selectedAcademicYear, content: {
                        ForEach(viewModel.academicYears, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
                        .pickerStyle(.segmented)
                        .padding()
                        .disabled(viewModel.courses.isEmpty)
                        .onChange(of: selectedAcademicYear) {
                            settings.foundMatricola = viewModel.checkForMatricola(in: selectedAcademicYear)
                        }
                }
                if settings.foundMatricola {
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
                    
                    DispatchQueue.main.async {
                        settings.reset()
                        
                        selectedYear = settings.selectedYear
                        selectedCourse = settings.selectedCourse
                        selectedAcademicYear = settings.selectedAcademicYear
                        matricola = settings.matricola
                        
                        viewModel.years = []
                        viewModel.courses = []
                        viewModel.academicYears = []
                        
                        selectedTab = 1
                        openSettings = false
                        
                        openCalendar = false
                    }
                }
            }
        }
        .onChange(of: searchTextFieldFocus.wrappedValue) {
            if searchTextFieldFocus.wrappedValue {
                detents = [.large]
            } else {
                detents = [.fraction(0.15), .medium, .large]
            }
        }
        .onAppear {
            viewModel.loadFromCache()
            
            if viewModel.years.isEmpty {
                Task {
                    await viewModel.loadYears()
                }
            }
            
            if viewModel.courses.isEmpty {
                Task {
                    await viewModel.loadCourses(year: selectedYear)
                    
                    await MainActor.run {
                        if selectedCourse != "0" {
                            viewModel.academicYears = viewModel.courses.filter { $0.valore == selectedCourse }.first!.elenco_anni
                            
                            if !viewModel.academicYears.contains(where: { $0.valore == selectedAcademicYear }) {
                                selectedAcademicYear = viewModel.academicYears.first!.valore
                            }
                        } else if openSettings {
                            detents = [.large]
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @FocusState var isFocused: Bool
    
    Settings(detents: .constant([]), openSettings: .constant(true), openCalendar: .constant(true), selectedTab: .constant(0), selectedDetent: .constant(.large), selectedYear: .constant(""), selectedCourse: .constant(""), selectedAcademicYear: .constant(""), matricola: .constant(""), searchTextFieldFocus: $isFocused)
        .environment(UserSettings.shared)
}
