//
//  CourseSelector.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct CourseSelector: View {
    @Binding var isFocused: Bool
    @Binding var selectedCourse: String
    let courses: [Corso]
    
    @State private var sm = CourseSearchManager()
    @FocusState private var internalFocus: Bool
    
    private var isSearching: Bool { !sm.searchText.isEmpty || internalFocus }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                searchBar
                    .opacity(isSearching || selectedCourse == "0" ? 1 : 0)
                if !isSearching, selectedCourse != "0" {
                    Text(sm.labelForCourse(selectedCourse))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding()
                        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 25))
                        .onTapGesture { internalFocus = true }
                }
            }
            if isSearching {
                searchResults
            }
        }
        .disabled(courses.isEmpty)
        .onChange(of: courses) { sm.courses = $1 }
        .onAppear { sm.courses = courses }
        .onChange(of: internalFocus) { _, new in
            guard isFocused != new else { return }
            if new { Haptics.play(.impact(weight: .light)) }
            isFocused = new
        }
        .onChange(of: isFocused) { if internalFocus != $1 { internalFocus = $1 } }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack {
            TextField("Cerca un corso", text: $sm.searchText)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .focused($internalFocus)
                .frame(height: 50)
                .padding(.horizontal)
                .submitLabel(.done)
                .multilineTextAlignment(.leading)
                .background(Color(.tertiarySystemFill), in: .capsule)
                .overlay(alignment: .trailing) {
                    if !sm.searchText.isEmpty {
                        Button {
                            Haptics.play(.impact(flexibility: .rigid, intensity: 1))
                            withAnimation(nil) {
                                sm.clearSearch()
                                internalFocus = true
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                                .padding(.trailing, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            if internalFocus {
                Button {
                    Haptics.play(.impact(flexibility: .solid, intensity: 1))
                    withAnimation(nil) {
                        sm.clearSearch()
                        internalFocus = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color(.tertiarySystemFill), in: .circle)
                }
                .buttonStyle(.borderless)
                .tint(.primary)
            }
        }
    }
    
    private var searchResults: some View {
        let filtered = sm.filteredCourses
        return Group {
            if filtered.isEmpty {
                Text("Nessun corso trovato")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.valore) { index, course in
                            Button {
                                guard course.valore != selectedCourse else { return }
                                Haptics.play(.selection)
                                selectedCourse = course.valore
                                sm.clearSearch()
                                internalFocus = false
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark")
                                        .opacity(selectedCourse == course.valore ? 1 : 0)
                                    Text(course.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .tint(.primary)
                            
                            if index != filtered.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .frame(minHeight: 150, maxHeight: 250)
            }
        }
        .background(Color(.tertiarySystemFill))
        .clipShape(.rect(cornerRadius: 25))
    }
}

#Preview {
    @Previewable @State var selectedCourse: String = "0"
    @Previewable @State var isFocused: Bool = false
    
    CourseSelector(isFocused: $isFocused, selectedCourse: $selectedCourse, courses: [])
        .environment(UserSettings.shared)
}
