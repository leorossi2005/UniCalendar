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
    
    @Binding var tempSettings: TempSettingsState
    
    var body: some View {
        List {
            Section {
                Picker(selection: $tempSettings.selectedYear) {
                    ForEach(viewModel.years) { year in
                        Text(year.label).tag(year.id)
                    }
                } label: {
                    Label("Anno", systemImage: "calendar")
                        .foregroundStyle(.primary)
                        .environment(\.isEnabled, true)
                }
                .onChange(of: tempSettings.selectedYear) {
                    handleYearChange()
                }
                NavigationLink {
                    LongListSelectorSettings(
                        title: "Corso",
                        prompt: "Cerca un corso",
                        items: viewModel.courses,
                        selectedItem: $tempSettings.selectedCourse
                    )
                } label: {
                    HStack(spacing: 12) {
                        Label("Corso", systemImage: "graduationcap")
                            .foregroundStyle(.primary)
                            .environment(\.isEnabled, true)
                            .layoutPriority(1)
                        Spacer(minLength: 8)
                        if viewModel.courses.isEmpty {
                            ProgressView()
                        } else {
                            Text(viewModel.courses.first { $0.id == tempSettings.selectedCourse }?.label ?? String(localized: "Scegli un corso"))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                .disabled(viewModel.courses.isEmpty)
                .onChange(of: tempSettings.selectedCourse) {
                    handleCourseChange()
                }
                if tempSettings.selectedCourse != "0" {
                    Group {
                        if viewModel.academicYears.count <= 5 {
                            Picker(selection: $tempSettings.selectedAcademicYear) {
                                ForEach(viewModel.academicYears) { year in
                                    Text(year.label).tag(year.id)
                                }
                            } label: {
                                Label("Anno di Corso", systemImage: "calendar.badge.clock")
                                    .foregroundStyle(.primary)
                                    .environment(\.isEnabled, true)
                            }
                        } else {
                            NavigationLink {
                                LongListSelectorSettings(
                                    title: "Anno di Corso",
                                    prompt: "Cerca un anno di corso",
                                    items: viewModel.academicYears,
                                    selectedItem: $tempSettings.selectedAcademicYear
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    Label("Anno di Corso", systemImage: "calendar.badge.clock")
                                        .foregroundStyle(.primary)
                                        .environment(\.isEnabled, true)
                                        .layoutPriority(1)
                                    Spacer(minLength: 8)
                                    Text(viewModel.academicYears.first { $0.id == tempSettings.selectedAcademicYear }?.label ?? String(localized: "Scegli un anno"))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    .onChange(of: tempSettings.selectedAcademicYear) {
                        if tempSettings.selectedAcademicYear != "0" {
                            sheetManager.setLock(false)
                            if let yearLabel = viewModel.academicYears.first(where: { $0.id == tempSettings.selectedAcademicYear })?.label {
                                settings.selectedAcademicYearName = yearLabel
                            }
                            settings.foundMatricola = viewModel.checkForMatricola(in: tempSettings.selectedAcademicYear)
                        } else {
                            sheetManager.setLock(true)
                        }
                    }
                }
                if settings.foundMatricola {
                    HStack {
                        Label("Matricola", systemImage: "person.text.rectangle")
                            .foregroundStyle(.primary)
                            .environment(\.isEnabled, true)
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
                    } else if ServerStatusCenter.shared.isUnreachable && ServerStatusCenter.shared.isRetrying {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Sto provando a contattare il server...")
                                .foregroundStyle(.orange)
                        }
                    } else if ServerStatusCenter.shared.isUnreachable {
                        HStack {
                            Text("Server non raggiungibile, riprova più tardi.")
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("Riprova") {
                                Haptics.play(.impact(weight: .medium))
                                Task { await viewModel.retry(year: tempSettings.selectedYear) }
                            }
                            .disabled(ServerStatusCenter.shared.isRetrying)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(.orange)
                            .environment(\.isEnabled, true)
                        }
                    } else if ServerStatusCenter.shared.isUniVROffline && ServerStatusCenter.shared.isUniVRRetrying {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Sto provando a contattare l'università...")
                                .foregroundStyle(.blue)
                        }
                    } else if ServerStatusCenter.shared.isUniVROffline {
                        HStack {
                            Text("I dati potrebbero non essere aggiornati.")
                                .foregroundStyle(.blue)
                            Spacer()
                            Button("Riprova") {
                                Haptics.play(.impact(weight: .medium))
                                Task { await ServerStatusCenter.shared.retryUniVRNow() }
                            }
                            .disabled(ServerStatusCenter.shared.isUniVRRetrying)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(.blue)
                            .environment(\.isEnabled, true)
                        }
                    } else if viewModel.isLoading {
                        Text("Aggiornamento dei dati in corso...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(viewModel.isOffline || viewModel.isServerUnreachable || viewModel.isLoading)
            Section {
                NavigationLink(destination: NotificationsView()) {
                    Label("Notifiche Programmate", systemImage: "bell.badge")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: PersonalCommitmentsList()) {
                    Label("Impegni Personali", systemImage: .personalCommitmentsDynamic)
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("Area Personale")
            } footer: {
                Text("Questa sezione include tutto ciò che ti rigurda, accessibile in un unico posto senza dover cercare in giro per l'app.")
            }
            Section("Informazioni Generali") {
                NavigationLink(destination: AppNoticesListView()) {
                    Label("Avvisi di Sistema", systemImage: "megaphone")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: WhatsNewView()) {
                    Label("Novità", systemImage: "sparkles")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: DeveloperProfileView()) {
                    Label("Lo Sviluppatore", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: FeedbackView()) {
                    Label("Invia un Feedback", systemImage: "text.bubble")
                        .foregroundStyle(.primary)
                }
                NavigationLink(destination: AboutView()) {
                    Label("Informazioni", systemImage: .infoPageDynamic)
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
        .onAppear {
            viewModel.activate()
            loadInitialData()
        }
        .onDisappear {
            viewModel.cancelAll()
        }
    }
    
    // MARK: - Logic Methods
    private func handleYearChange() {
        guard tempSettings.selectedYear != "0" && !tempSettings.selectedYear.isEmpty else { return }
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
            
            if viewModel.academicYears.count <= 5, let firstYear = viewModel.academicYears.first {
                tempSettings.selectedAcademicYear = firstYear.id
                settings.selectedAcademicYearName = firstYear.label
                sheetManager.setLock(false)
                if tempSettings.selectedAcademicYear != "0" {
                    settings.foundMatricola = viewModel.checkForMatricola(in: tempSettings.selectedAcademicYear)
                }
            } else {
                tempSettings.selectedAcademicYear = "0"
                settings.selectedAcademicYearName = ""
                settings.foundMatricola = false
                sheetManager.setLock(true)
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
        
        Task(priority: .background) {
            await NotificationManager.shared.removeAllNotifications()
            await CommitmentsManager.shared.deleteAllEvents()
            await CacheManager.shared.clear(file: .calendarSchedule)
            settings.reset()
            tempSettings.sync(with: settings)
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
        
        if viewModel.courses.isEmpty, tempSettings.selectedYear != "0", !tempSettings.selectedYear.isEmpty {
            Task {
                do {
                    try await viewModel.loadCourses(year: tempSettings.selectedYear)
                    
                    await MainActor.run {
                        if tempSettings.matricola.isEmpty || !["even", "odd"].contains(tempSettings.matricola) {
                            tempSettings.matricola = "even"
                        }
                        
                        if tempSettings.selectedYear == "0", let lastYear = viewModel.years.first {
                            tempSettings.selectedYear = lastYear.id
                        }
                        
                        if tempSettings.selectedCourse != "0" {
                            if let course = viewModel.courses.first(where: { $0.id == tempSettings.selectedCourse }) {
                                tempSettings.selectedCourseName = course.label
                                viewModel.academicYears = course.years
                                
                                if tempSettings.selectedAcademicYear == "0" {
                                    if viewModel.academicYears.count <= 5, let firstAcademicYear = viewModel.academicYears.first {
                                        tempSettings.selectedAcademicYear = firstAcademicYear.id
                                    } else {
                                        sheetManager.setLock(true)
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
