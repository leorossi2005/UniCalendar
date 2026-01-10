//
//  Settings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    private let net: NetworkMonitor = .shared
    @State private var viewModel = UniversityDataManager()
    @State private var showDeleteAlert = false
    @State private var initialIsContentAtTop: Bool? = nil
    @State private var searchTextFieldFocus: Bool = false
    
    @Binding var selectedYear: String
    @Binding var selectedCourse: String
    @Binding var selectedAcademicYear: String
    @Binding var matricola: String
    @Binding var lockSheet: Bool
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Anno", systemImage: "calendar")
                        .foregroundStyle(.primary)
                        .padding(.trailing)
                    Picker(selection: $selectedYear) {
                        ForEach(viewModel.years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    } label: {}
                        .pickerStyle(.segmented)
                        .onChange(of: selectedYear) {
                            handleYearChange()
                        }
                }
                CourseSelector(
                    isFocused: $searchTextFieldFocus,
                    selectedCourse: $selectedCourse,
                    courses: viewModel.courses
                )
                .onChange(of: selectedCourse) {
                    handleCourseChange()
                }
                if selectedCourse != "0" {
                    Picker(selection: $selectedAcademicYear) {
                        ForEach(viewModel.academicYears, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    } label: {
                        Label("Anno di Corso", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.primary)
                    }
                    .onChange(of: selectedAcademicYear) {
                        if selectedAcademicYear != "0" {
                            settings.foundMatricola = viewModel.checkForMatricola(in: selectedAcademicYear)
                        }
                    }
                }
                if settings.foundMatricola {
                    HStack {
                        Label("Matricola", systemImage: "person.text.rectangle")
                            .foregroundStyle(.primary)
                            .padding(.trailing)
                        Picker("", selection: $matricola) {
                            Text("Pari").tag("pari")
                            Text("Dispari").tag("dispari")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Usa questa sezione per modificare le impostazioni dell'app, cambia pure l'anno, il corso, l'anno di corso o la matricola se presente.")
                    
                    if net.status != .connected {
                        Text("In modalità offline non puoi modificare queste opzioni.")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .disabled(net.status != .connected)
            Section {
                NavigationLink(destination: AboutView()) {
                    Label("Informazioni", systemImage: .infoPageDynamic)
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: DeveloperProfileView()) {
                    Label("Lo Sviluppatore", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.primary)
                }
            }
            Section("DANGER ZONE") {
                Button {
                    showDeleteAlert.toggle()
                } label: {
                    Label("Resetta l'app", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .alert("Vuoi resettare l'app?", isPresented: $showDeleteAlert) {
                    Button("Conferma", role: .destructive, action: performReset)
                    Button("Annulla", role: .cancel) {}
                } message: {
                    Text("Confermando cancellerai le impostazioni e tornerai al benvenuto iniziale.")
                }
            }
            Section {
                Text("Buono studio!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchTextFieldFocus) {
            if searchTextFieldFocus {
                lockSheet = true
            } else {
                lockSheet = false
            }
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Logic Methods
    private func handleYearChange() {
        lockSheet = true
        viewModel.courses = []
        selectedCourse = "0"
        viewModel.academicYears = []
        selectedAcademicYear = "0"
        
        Task {
            try await viewModel.loadCourses(year: selectedYear)
        }
    }
    
    private func handleCourseChange() {
        if selectedCourse != "0" {
            settings.foundMatricola = false
            lockSheet = false
            viewModel.academicYears = []
            selectedAcademicYear = "0"
            
            viewModel.updateAcademicYears(for: selectedCourse, year: selectedYear)
            
            if let firstYear = viewModel.academicYears.first {
                selectedAcademicYear = firstYear.valore
                if selectedAcademicYear != "0" {
                    settings.foundMatricola = viewModel.checkForMatricola(in: selectedAcademicYear)
                }
            }
        } else {
            lockSheet = true
            viewModel.academicYears = []
            selectedAcademicYear = "0"
            settings.foundMatricola = false
        }
    }
    
    private func performReset() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            await viewModel.clearCalendarCache()
            settings.reset()
        }
    }
    
    private func loadInitialData() {
        viewModel.loadFromCache()
        
        if viewModel.years.isEmpty {
            Task {
                try await viewModel.loadYears()
            }
        }
        
        if viewModel.courses.isEmpty {
            Task {
                try await viewModel.loadCourses(year: selectedYear)
                
                await MainActor.run {
                    if !["pari", "dispari"].contains(matricola) {
                        matricola = "pari"
                    }
                    
                    if !viewModel.years.contains(where: { $0.valore == selectedYear }) {
                        if let lastYear = viewModel.years.last {
                            selectedYear = lastYear.valore
                        }
                    }
                    
                    if selectedCourse != "0" {
                        if let course = viewModel.courses.first(where: { $0.valore == selectedCourse }) {
                            viewModel.academicYears = course.elenco_anni
                            
                            if !viewModel.academicYears.contains(where: { $0.valore == selectedAcademicYear }) {
                                if let firstAcademicYear = viewModel.academicYears.last {
                                    selectedAcademicYear = firstAcademicYear.valore
                                }
                            }
                            settings.foundMatricola = viewModel.checkForMatricola(in: selectedAcademicYear)
                        }
                    } else {
                        lockSheet = true
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var openSettings: Bool = true
    @Previewable @State var openCalendar: Bool = true
    @Previewable @State var selectedYear: String = "2025"
    @Previewable @State var selectedCourse: String = "0"
    @Previewable @State var selectedAcademicYear: String = "0"
    @Previewable @State var matricola: String = "pari"
    @Previewable @State var isFocused: Bool = false
    @Previewable @State var lockSheet: Bool = false
    
    NavigationStack {
        Settings(selectedYear: $selectedYear, selectedCourse: $selectedCourse, selectedAcademicYear: $selectedAcademicYear, matricola: $matricola, lockSheet: $lockSheet)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Impostazioni")
                    .font(.headline)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    .environment(UserSettings.shared)
}
