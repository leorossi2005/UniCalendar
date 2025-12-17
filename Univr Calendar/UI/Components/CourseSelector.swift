//
//  CourseSelector.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/12/25.
//

import SwiftUI
import UnivrCore

struct CourseSelector: View {
    @Binding var isFocused: Bool
    @Binding var selectedCourse: String
    
    let courses: [Corso]
    
    @State var searchText: String = ""
    @FocusState private var internalFocus: Bool
    
    private var filteredCourses: [Corso] { Corso.filter(courses, with: searchText) }
    private var isSearching: Bool { !searchText.isEmpty || internalFocus }
    
    var body: some View {
        VStack {
            searchBar
                .padding(.top)
                .padding(.horizontal)
            if !isSearching {
                defaultMenu
                    .padding(.horizontal)
                    .padding(.bottom)
            } else {
                searchResultsList
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .disabled(courses.isEmpty)
        .onChange(of: internalFocus) { _, newValue in
            if isFocused != newValue {
                isFocused = newValue
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if internalFocus != newValue {
                internalFocus = newValue
            }
        }
    }
    
    // MARK: - Componets
    private var searchBar: some View {
        HStack {
            TextField("Cerca un corso", text: $searchText)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .focused($internalFocus)
                .frame(height: 50)
                .padding(.horizontal)
                .buttonStyle(.borderless)
                .submitLabel(.done)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(alignment: .trailing) {
                    if !searchText.isEmpty {
                        let size = 17.5
                        Button {
                            withAnimation(nil) {
                                searchText = ""
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray))
                                    .frame(width: size, height: size)

                                Image(systemName: "xmark")
                                    .font(Font.system(size: size / 2))
                                    .bold()
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, (50 - size) / 2)
                    }
                }
            if internalFocus {
                Button(action: {
                    withAnimation(nil) {
                        internalFocus = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .bold()
                        .frame(width: 50, height: 50)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .tint(.primary)
                .buttonStyle(.borderless)
            }
        }
        .multilineTextAlignment(.leading)
    }
    
    private var defaultMenu: some View {
        Menu {
            courseButton(value: "0", label: "Scegli un corso")
            ForEach(courses, id: \.valore) { course in
                courseButton(value: course.valore, label: LocalizedStringKey(course.label))
            }
        } label: {
            ZStack {
                if courses.isEmpty {
                    ProgressView()
                } else {
                    Text(courses.first{$0.valore == selectedCourse}?.label ?? String(localized: "Scegli un corso"))
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(.tertiarySystemFill))
            }
        }
        .tint(.primary)
    }
    
    private var searchResultsList: some View {
        Group {
            if !filteredCourses.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredCourses.enumerated()), id: \.element.valore) { index, course in
                            Button {
                                searchText = ""
                                internalFocus = false
                                selectedCourse = course.valore
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark")
                                        .opacity(selectedCourse == course.valore ? 1 : 0)
                                    Text(course.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                            }
                            .buttonStyle(.borderless)
                            .tint(.primary)
                            if index < filteredCourses.count - 1  {
                                Divider()
                            }
                        }
                    }
                }
                .frame(minHeight: 150)
                .frame(maxHeight: 250)
            } else {
                Text("Nessun corso trovato")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.tertiarySystemFill))
        }
    }
    
    // MARK: - Logic
    private func courseButton(value: String, label: LocalizedStringKey) -> some View {
        Button {
            selectedCourse = value
        } label: {
            HStack {
                if selectedCourse == value {
                    Image(systemName: "checkmark")
                }
                Text(label)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedCourse: String = "0"
    @Previewable @State var isFocused: Bool = false
    let courses: [Corso] = []
    
    CourseSelector(isFocused: $isFocused, selectedCourse: $selectedCourse, courses: courses)
        .environment(UserSettings.shared)
}
