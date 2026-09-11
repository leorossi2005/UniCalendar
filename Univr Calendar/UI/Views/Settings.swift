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
import CustomSheet

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    @Environment(GlobalSheetManager.self) private var sheetManager
    
    @State private var viewModel = UniversityDataManager()
    @State private var showDeleteAlert = false
    @State private var searchTextFieldFocus: Bool = false
    
    @Binding var tempSettings: TempSettingsState
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Anno", systemImage: "calendar")
                        .foregroundStyle(.primary)
                        .padding(.trailing)
                    Picker(selection: $tempSettings.selectedYear) {
                        ForEach(viewModel.years) { year in
                            Text(year.label).tag(year.id)
                        }
                    } label: {}
                        .pickerStyle(.segmented)
                        .onChange(of: tempSettings.selectedYear) {
                            handleYearChange()
                        }
                }
                CourseSelector(
                    isFocused: $searchTextFieldFocus,
                    selectedCourse: $tempSettings.selectedCourse,
                    courses: viewModel.courses
                )
                .onChange(of: tempSettings.selectedCourse) {
                    handleCourseChange()
                }
                if tempSettings.selectedCourse != "0" {
                    Picker(selection: $tempSettings.selectedAcademicYear) {
                        ForEach(viewModel.academicYears) { year in
                            Text(year.label).tag(year.id)
                        }
                    } label: {
                        Label("Anno di Corso", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.primary)
                    }
                    .onChange(of: tempSettings.selectedAcademicYear) {
                        if tempSettings.selectedAcademicYear != "0" {
                            settings.foundMatricola = viewModel.checkForMatricola(in: tempSettings.selectedAcademicYear)
                        }
                    }
                }
                if settings.foundMatricola {
                    HStack {
                        Label("Matricola", systemImage: "person.text.rectangle")
                            .foregroundStyle(.primary)
                            .padding(.trailing)
                        Picker("", selection: $tempSettings.matricola) {
                            Text("Pari").tag("even")
                            Text("Dispari").tag("odd")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Usa questa sezione per modificare le impostazioni dell'app, cambia pure l'anno, il corso, l'anno di corso o la matricola se presente.")
                    
                    if viewModel.isOffline {
                        Text("In modalità offline non puoi modificare queste opzioni.")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .disabled(viewModel.isOffline)
            Section {
                NavigationLink(destination: NotificationsView()) {
                    Label("Notifiche Programmate", systemImage: "bell.badge")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: AboutView()) {
                    Label("Informazioni", systemImage: .infoPageDynamic)
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: DeveloperProfileView()) {
                    Label("Lo Sviluppatore", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: WhatsNewView()) {
                    Label("Novità", systemImage: "sparkles")
                        .foregroundStyle(.primary)
                }
            }
            Section("DANGER ZONE") {
                Button {
                    Haptics.play(.warning)
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
                sheetManager.setLock(true)
            } else if tempSettings.selectedCourse != "0" {
                sheetManager.setLock(false)
            }
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Logic Methods
    private func handleYearChange() {
        sheetManager.setLock(true)
        viewModel.resetCourses()
        tempSettings.selectedCourse = "0"
        viewModel.academicYears = []
        tempSettings.selectedAcademicYear = "0"
        
        Task {
            do {
                try await viewModel.loadCourses(year: tempSettings.selectedYear)
            } catch {}
        }
    }
    
    private func handleCourseChange() {
        if tempSettings.selectedCourse != "0" {
            if let courseName = viewModel.courses.first(where: { $0.id == tempSettings.selectedCourse })?.label {
                tempSettings.selectedCourseName = courseName
            }
            
            settings.foundMatricola = false
            sheetManager.setLock(false)
            viewModel.academicYears = []
            tempSettings.selectedAcademicYear = "0"
            
            viewModel.updateAcademicYears(for: tempSettings.selectedCourse)
            
            if let firstYear = viewModel.academicYears.first {
                tempSettings.selectedAcademicYear = firstYear.id
                if tempSettings.selectedAcademicYear != "0" {
                    settings.foundMatricola = viewModel.checkForMatricola(in: tempSettings.selectedAcademicYear)
                }
            }
        } else {
            sheetManager.setLock(true)
            viewModel.academicYears = []
            tempSettings.selectedAcademicYear = "0"
            settings.foundMatricola = false
        }
    }
    
    private func performReset() {
        Haptics.play(.impact(weight: .heavy))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            await CacheManager.shared.clear(file: .calendarSchedule)
            settings.reset()
            sheetManager.dismiss()
        }
    }
    
    private func loadInitialData() {
        if viewModel.years.isEmpty {
            Task {
                do {
                    try await viewModel.loadYears()
                } catch {}
            }
        }
        
        if viewModel.courses.isEmpty {
            Task {
                do {
                    try await viewModel.loadCourses(year: tempSettings.selectedYear)
                    
                    await MainActor.run {
                        if !["even", "odd"].contains(tempSettings.matricola) {
                            tempSettings.matricola = "even"
                        }
                        
                        if !viewModel.years.contains(where: { $0.id == tempSettings.selectedYear }) {
                            if let lastYear = viewModel.years.last {
                                tempSettings.selectedYear = lastYear.id
                            }
                        }
                        
                        if tempSettings.selectedCourse != "0" {
                            if let course = viewModel.courses.first(where: { $0.id == tempSettings.selectedCourse }) {
                                tempSettings.selectedCourseName = course.label
                                viewModel.academicYears = course.years
                                
                                if !viewModel.academicYears.contains(where: { $0.id == tempSettings.selectedAcademicYear }) {
                                    if let firstAcademicYear = viewModel.academicYears.last {
                                        tempSettings.selectedAcademicYear = firstAcademicYear.id
                                    }
                                }
                                settings.foundMatricola = viewModel.checkForMatricola(in: tempSettings.selectedAcademicYear)
                            }
                        } else {
                            sheetManager.setLock(true)
                        }
                    }
                } catch {}
            }
        }
    }
}

#Preview {
    @Previewable @State var temp = TempSettingsState()
    
    NavigationStack {
        Settings(tempSettings: $temp)
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
