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
    
    @State private var searchText: String = ""
    @State private var isSettling: Bool = false
    @FocusState private var internalFocus: Bool
    
    private let cardShape = RoundedRectangle(cornerRadius: 24, style: .continuous)
    private let toggleAnimation: Animation = .snappy(duration: 0.35)
    
    private var filteredItems: [Item] { items.filtered(by: searchText) }
    private var selectedObject: Item? { items.first { $0.id == selectedItem } }
    private var showsCard: Bool { isFocused || selectedObject != nil }
    
    private var listTransition: AnyTransition {
        .asymmetric(
            insertion: AnyTransition.opacity.animation(.easeOut(duration: 0.25).delay(0.1)),
            removal: AnyTransition.opacity.animation(.easeOut(duration: 0.12))
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultsCard
        }
        .padding(.top, isFocused ? 4 : 16)
        .animation(toggleAnimation, value: isFocused)
        .animation(.snappy(duration: 0.25), value: selectedItem)
        .disabled(items.isEmpty)
        .onChange(of: internalFocus) { _, newValue in
            if newValue { open() }
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue {
                internalFocus = false
                searchText = ""
            }
        }
    }
    
    private func open() {
        if !isFocused {
            Haptics.play(.impact(weight: .light))
            withAnimation(toggleAnimation) { isFocused = true }
        }
        internalFocus = true
    }
    
    private func close() {
        withAnimation(toggleAnimation) {
            searchText = ""
            internalFocus = false
            isFocused = false
        }
    }
    
    private var searchBar: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.medium))
                
                TextField(searchPrompt, text: $searchText, prompt: Text(""))
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .focused($internalFocus)
                    .submitLabel(.done)
                    .multilineTextAlignment(.leading)
                    .overlay { placeholder }
                
                if !searchText.isEmpty {
                    Button {
                        Haptics.play(.impact(flexibility: .rigid, intensity: 1))
                        withAnimation(.snappy(duration: 0.25)) {
                            searchText = ""
                        }
                        internalFocus = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.75).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.tertiarySystemFill), in: cardShape)
            .contentShape(cardShape)
            .padding(.trailing, isFocused ? 62 : 0)
            .animation(.snappy(duration: 0.25), value: searchText.isEmpty)
            .onTapGesture { open() }
            
            Button {
                Haptics.play(.impact(flexibility: .solid, intensity: 1))
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.bold))
                    .frame(width: 52, height: 52)
                    .background(Color(.tertiarySystemFill), in: .circle)
            }
            .buttonStyle(.plain)
            .scaleEffect(isFocused ? 1.0 : 0.6)
            .offset(x: isFocused ? 0 : -20)
            .opacity(isFocused ? 1.0 : 0.0)
            .allowsHitTesting(isFocused)
        }
        .frame(height: 52)
    }
    
    private var placeholder: some View {
        Text(searchPrompt)
            .foregroundStyle(Color(.placeholderText))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: isFocused ? .leading : .center)
            .opacity(searchText.isEmpty ? 1 : 0)
            .allowsHitTesting(false)
    }
    
    private var resultsCard: some View {
        ZStack(alignment: .top) {
            Color.clear.frame(height: 0)
            selectedRow
        }
        .frame(maxWidth: .infinity, maxHeight: isFocused ? .infinity : nil, alignment: .top)
        .background(Color(.tertiarySystemFill), in: cardShape)
        .overlay {
            if isFocused {
                searchResultsList
                    .transition(listTransition)
            }
        }
        .clipShape(cardShape)
        .padding(.top, showsCard ? 12 : 0)
        .animation(.easeOut(duration: 0.15)) { content in
            content.opacity(showsCard ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private var selectedRow: some View {
        if let item = selectedObject {
            Button {
                open()
            } label: {
                rowContent(for: item, isSelected: true, query: "")
            }
            .buttonStyle(.plain)
            .opacity(isFocused ? 0 : 1)
            .allowsHitTesting(!isFocused)
        }
    }
    
    private var searchResultsList: some View {
        let results = filteredItems
        
        return ScrollViewReader { proxy in
            Group {
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("topListAnchor")
                            
                            ForEach(results, id: \.id) { item in
                                Button {
                                    Haptics.play(.selection)
                                    selectedItem = item.id
                                    close()
                                } label: {
                                    rowContent(for: item, isSelected: item.id == selectedItem, query: searchText)
                                }
                                .buttonStyle(.plain)
                                .id(item.id)
                                
                                if item.id != results.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if selectedItem != "0" {
                            proxy.scrollTo(selectedItem, anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: searchText) { _, newText in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    if newText.isEmpty, selectedItem != "0" {
                        proxy.scrollTo(selectedItem, anchor: .center)
                    } else {
                        proxy.scrollTo("topListAnchor", anchor: .top)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.height) { _, _ in
                            recenter(proxy)
                        }
                }
            }
            .task {
                isSettling = true
                try? await Task.sleep(for: .seconds(0.8))
                isSettling = false
            }
        }
    }
    
    private func recenter(_ proxy: ScrollViewProxy) {
        guard isSettling, searchText.isEmpty, selectedItem != "0" else { return }
        withAnimation(toggleAnimation) {
            proxy.scrollTo(selectedItem, anchor: .center)
        }
    }
    
    private func rowContent(for item: Item, isSelected: Bool, query: String) -> some View {
        HStack(spacing: 14) {
            Text(highlightedText(item.label, query: query))
                .font(.body.weight(isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                .symbolReplace()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(.rect)
    }
    
    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .primary
        
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
    @Previewable @State var selectedCourse: String = "0"
    @Previewable @State var isFocused: Bool = false
    let courses: [Course] = []
    
    LongListSelector(isFocused: $isFocused, selectedItem: $selectedCourse, items: courses)
        .environment(UserSettings.shared)
}
