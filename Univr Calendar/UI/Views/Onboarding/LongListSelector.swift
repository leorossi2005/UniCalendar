//
//  LongListSelector.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct LongListSelector<Item: SelectableItem>: View {
    @Binding var isFocused: Bool
    @Binding var selectedItem: String
    
    let items: [Item]
    var searchPrompt: LocalizedStringKey = "Cerca un corso"
    var defaultPrompt: LocalizedStringKey = "Scegli un corso"
    var emptyPrompt: LocalizedStringKey = "Nessun elemento trovato"
    
    @State var searchText: String = ""
    @FocusState private var internalFocus: Bool
    
    private var filteredItems: [Item] { items.filtered(by: searchText) }
    private var isSearching: Bool { !searchText.isEmpty || internalFocus }
    
    var body: some View {
        VStack {
            searchBar
                .padding(.top)
            if !isSearching {
                defaultMenu
                    .padding(.bottom)
            } else {
                searchResultsList
                    .padding(.bottom)
            }
        }
        .disabled(items.isEmpty)
        .onChange(of: internalFocus) { _, newValue in
            if isFocused != newValue {
                if newValue == true {
                    Haptics.play(.impact(weight: .light))
                }
                isFocused = newValue
            }
        }
        .onChange(of: isFocused) { _, newValue in
            if internalFocus != newValue {
                internalFocus = newValue
            }
        }
    }
    
    // MARK: - Components
    private var searchBar: some View {
        HStack {
            TextField(searchPrompt, text: $searchText)
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
                            Haptics.play(.impact(flexibility: .rigid, intensity: 1))
                            withAnimation(nil) {
                                searchText = ""
                                internalFocus = true
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray))
                                    .frame(width: size, height: size)

                                Image(systemName: "xmark")
                                    .font(Font.system(size: size / 2).bold())
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
                    Haptics.play(.impact(flexibility: .solid, intensity: 1))
                    withAnimation(nil) {
                        searchText = ""
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
            itemButton(value: "0", label: defaultPrompt)
            ForEach(items) { item in
                itemButton(value: item.id, label: LocalizedStringKey(item.label))
            }
        } label: {
            ZStack {
                if items.isEmpty {
                    ProgressView()
                } else if let selected = items.first(where: { $0.id == selectedItem }) {
                    Text(selected.label)
                } else {
                    Text(defaultPrompt)
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
            if !filteredItems.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                if item.id != selectedItem {
                                    Haptics.play(.selection)
                                    searchText = ""
                                    internalFocus = false
                                    selectedItem = item.id
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark")
                                        .opacity(selectedItem == item.id ? 1 : 0)
                                    Text(item.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                            }
                            .buttonStyle(.borderless)
                            .tint(.primary)
                            if index < filteredItems.count - 1  {
                                Divider()
                            }
                        }
                    }
                }
                .frame(minHeight: 150)
                .frame(maxHeight: 250)
            } else {
                Text(emptyPrompt)
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
    private func itemButton(value: String, label: LocalizedStringKey) -> some View {
        Button {
            selectedItem = value
        } label: {
            HStack {
                if selectedItem == value {
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
    let courses: [Course] = []
    
    LongListSelector(isFocused: $isFocused, selectedItem: $selectedCourse, items: courses)
        .environment(UserSettings.shared)
}
