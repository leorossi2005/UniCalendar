//
//  Settings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/25.
//

import SwiftUI
import UnivrCore

struct Settings: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @State private var viewModel = SettingsViewModel()
    @State private var showDeleteAlert = false
    
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
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Anno", systemImage: "calendar")
                        .foregroundStyle(.primary)
                        .padding(.trailing)
                    Picker(selection: $selectedYear, content: {
                        ForEach(viewModel.years, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {}
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
                    HStack {
                        TextField("Cerca un corso", text: $searchText)
                                    .focused(searchTextFieldFocus)
                                    .frame(height: 50)
                                    .padding(.horizontal)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(25)
                        if searchTextFieldFocus.wrappedValue {
                            Button(action: {
                                withAnimation(nil) {
                                    searchTextFieldFocus.wrappedValue = false
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
                            Text(viewModel.courses.filter{$0.valore == selectedCourse}.first?.label ?? String(localized: "Scegli un corso"))
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
                                            searchTextFieldFocus.wrappedValue = false
                                            
                                            selectedCourse = course.valore
                                        }) {
                                            HStack {
                                                Image(systemName: "checkmark")
                                                    .frame(width: 40)
                                                    .opacity(selectedCourse == course.valore ? 1 : 0)
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
                        
                        settings.foundMatricola = false
                    }
                }
                if selectedCourse != "0" {
                    Picker(selection: $selectedAcademicYear, content: {
                        ForEach(viewModel.academicYears, id: \.valore) { year in
                            Text(year.label).tag(year.valore)
                        }
                    }) {
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
                Text("Usa questa sezione per modificare le impostazioni dell'app, cambia pure l'anno, il corso, l'anno di corso o la matricola se presente.")
            }
            Section {
                //Link(destination: URL(string: "https://www.apple.com")!) {
                //    HStack {
                //        Label("Fammi un regalino", systemImage: "cup.and.saucer")
                //            .foregroundStyle(.primary)
                //        Spacer()
                //        Image(systemName: "arrow.up.forward.square")
                //            .foregroundStyle(.gray)
                //    }
                //}
                //.tint(.primary)
                NavigationLink(destination: AboutView()) {
                    Label("Informazioni", systemImage: "info.circle.text.page")
                        .foregroundStyle(.primary)
                }
            } footer: {
                //Text("Ps. Se non si fosse capito il regalino è una donazione, e ti ringrazio di cuore se mi darai un po' di sostegno per aver creato questa app.")
            }
            Section("DANGER ZONE") {
                Button(action: {
                    withAnimation(.spring()) {
                        showDeleteAlert.toggle()
                    }
                }) {
                    Label("Resetta l'app", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .alert("Vuoi resettare l'app?", isPresented: $showDeleteAlert) {
                    Button("Conferma", role: .destructive) {
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
                    
                    Button("Annulla", role: .cancel) {}
                } message: {
                    Text("Confermando cancellerai le impostazioni e tornerai al benvenuto iniziale.")
                }
            }
            Section {
                Text("Buono studio!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center) // Centra il testo
            }
            .listRowBackground(Color.clear)
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
                        if !["pari", "dispari"].contains(matricola) {
                            matricola = "pari"
                        }
                        
                        if !viewModel.years.contains(where: { $0.valore == selectedYear }) {
                            selectedYear = viewModel.years.last!.valore
                        }
                        
                        if selectedCourse != "0" {
                            if let course = viewModel.courses.first(where: { $0.valore == selectedCourse }) {
                                viewModel.academicYears = course.elenco_anni
                                
                                if !viewModel.academicYears.contains(where: { $0.valore == selectedAcademicYear }) {
                                    selectedAcademicYear = viewModel.academicYears.first!.valore
                                }
                                
                                settings.foundMatricola = viewModel.checkForMatricola(in: selectedAcademicYear)
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
    @Previewable @State var detents: Set<PresentationDetent> = []
    @Previewable @State var openSettings: Bool = true
    @Previewable @State var openCalendar: Bool = true
    @Previewable @State var selectedTab: Int = 0
    @Previewable @State var selectedDetent: PresentationDetent = .large
    @Previewable @State var selectedYear: String = "2025"
    @Previewable @State var selectedCourse: String = "0"
    @Previewable @State var selectedAcademicYear: String = "0"
    @Previewable @State var matricola: String = "pari"
    @FocusState var isFocused: Bool
    
    NavigationStack {
        Settings(detents: $detents, openSettings: $openSettings, openCalendar: $openCalendar, selectedTab: $selectedTab, selectedDetent: $selectedDetent, selectedYear: $selectedYear, selectedCourse: $selectedCourse, selectedAcademicYear: $selectedAcademicYear, matricola: $matricola, searchTextFieldFocus: $isFocused)
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
