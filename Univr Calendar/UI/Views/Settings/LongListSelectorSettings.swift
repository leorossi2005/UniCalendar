//
//  LongListSelectorSettings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 18/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct LongListSelectorSettings<Item: SelectableItem>: View {
    @Environment(GlobalSheetManager.self) private var sheetManager
    @Environment(\.dismiss) private var dismiss
    
    let title: LocalizedStringKey
    let prompt: LocalizedStringKey
    let items: [Item]
    @Binding var selectedItem: String
    
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    private var filteredItems: [Item] { items.filtered(by: searchText) }
    
    var body: some View {
        ScrollViewReader { proxy in
            Form {
                ForEach(filteredItems) { item in
                    let isSelected = item.id == selectedItem
                    
                    Button {
                        if !isSelected {
                            Haptics.play(.selection)
                            selectedItem = item.id
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(highlightedText(item.label, query: searchText, baseColor: .primary))
                                .font(.body.weight(isSelected ? .semibold : .regular))
                            
                            Spacer(minLength: 8)
                            
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                        }
                        .padding(.vertical, 2)
                        .contentShape(.rect)
                    }
                    .id(item.id)
                    .accessibilityLabel(item.label)
                    .environment(\.locale, Locale(identifier: "it"))
                }
            }
            .overlay {
                if filteredItems.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .accessibilityElement(children: .combine)
                }
            }
            .onAppear {
                if selectedItem != "0" {
                    proxy.scrollTo(selectedItem, anchor: .center)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            placement: .automaticPlacement,
            prompt: prompt
        )
        .modify { view in if #available(iOS 27, *) { view.searchPresentationToolbarBehavior(.avoidHidingContent) } else { view } }
        .onChange(of: isSearching) { _, active in
            sheetManager.setLock(active || selectedItem == "0")
        }
    }
    
    private func highlightedText(_ text: String, query: String, baseColor: Color) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = baseColor
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return attributed }
        
        var searchRange = attributed.startIndex..<attributed.endIndex
        while let matchRange = attributed[searchRange].range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributed[matchRange].foregroundColor = Color.accentColor
            attributed[matchRange].inlinePresentationIntent = .stronglyEmphasized
            searchRange = matchRange.upperBound..<attributed.endIndex
        }
        
        return attributed
    }
}

#Preview {
    @Previewable @State var selectedItem: String = ""
    @Previewable @State var viewModel = UniversityDataManager()
    
    NavigationStack {
        LongListSelectorSettings(title: "Corso", prompt: "Cerca un corso", items: viewModel.courses, selectedItem: $selectedItem)
    }
    .environment(GlobalSheetManager())
    .task {
        try? await viewModel.loadCourses(year: "2026")
    }
}
