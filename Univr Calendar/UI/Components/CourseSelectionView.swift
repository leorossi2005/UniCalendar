//
//  CourseSelectionView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/12/25.
//

import SwiftUI
import UnivrCore

struct CourseSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var searchText: String
    @Binding var isFocused: Bool
    @Binding var selectedCourse: String
    
    let courses: [Corso]
    let screenSize: CGRect
    
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
                    .padding(.bottom)
                    .padding(.horizontal)
            }
        }
        .onChange(of: internalFocus) { _, newValue in
            isFocused = newValue
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
            Text(courses.first{$0.valore == selectedCourse}?.label ?? String(localized: "Scegli un corso"))
                .foregroundStyle(colorScheme == .light ? .black : .white)
                .padding()
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .disabled(courses.isEmpty)
    }
    
    private var searchResultsList: some View {
        Group {
            if !filteredCourses.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredCourses, id: \.valore) { course in
                            Divider()
                                .if(course.valore == filteredCourses.first?.valore) { view in
                                    view
                                        .opacity(0)
                                }
                            Button(action: {
                                searchText = ""
                                internalFocus = false
                                selectedCourse = course.valore
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark")
                                        .opacity(selectedCourse == course.valore ? 1 : 0)
                                    Text(course.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                                .contentShape(.rect)
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                            }
                            .buttonStyle(.borderless)
                            if course.valore == filteredCourses.last?.valore {
                                Divider()
                                    .opacity(0)
                            }
                        }
                    }
                }
                .frame(height: screenSize.height * 0.23)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                Text("Nessun corso trovato")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
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
    @Previewable @State var searchText: String = ""
    @Previewable @State var isFocused: Bool = false
    let courses: [Corso] = []
    
    CourseSelectionView(searchText: $searchText, isFocused: $isFocused, selectedCourse: $selectedCourse, courses: courses, screenSize: UIApplication.shared.screenSize)
        .environment(UserSettings.shared)
}
