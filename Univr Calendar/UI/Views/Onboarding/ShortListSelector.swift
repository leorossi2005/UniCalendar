//
//  ShortListSelector.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct ShortListSelector<Item: SelectableItem>: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    let items: [Item]
    var lang: String? = nil
    var inputLabelsProvider: ((Item) -> [String])? = nil
    @Binding var selectedItem: String
    
    @State private var listHeight: CGFloat?

    var body: some View {
        ScrollView {
            list
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { listHeight = $0 + 24 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: listHeight ?? .infinity)
        .clipped()
        .animation(.snappy(duration: 0.25), value: selectedItem)
        .padding(.top, 16)
    }
    
    private var list: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                let isSelected = selectedItem == item.id

                Button {
                    Haptics.play(.selection)
                    selectedItem = item.id
                } label: {
                    HStack {
                        Group {
                            if item is SelectableOption {
                                Text(LocalizedStringKey(item.label))
                            } else {
                                Text(item.label)
                            }
                        }
                        .fontWeight(isSelected ? .semibold : .regular)
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary.opacity(0.3))
                            .symbolReplace()
                    }
                    .padding(16)
                    .background(
                        isSelected ? Color(.secondarySystemFill) : Color(.tertiarySystemFill),
                        in: .rect(cornerRadius: 24, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5)
                    }
                    .accessibilityHidden(voiceOverEnabled)
                    .overlay {
                        if voiceOverEnabled {
                            SpeechLanguageLabel(
                                lang != nil ? .it(item.label) : .system(item.label),
                                traits: isSelected ? [.button, .selected] : .button,
                                onActivate: {
                                    Haptics.play(.selection)
                                    selectedItem = item.id
                                }
                            )
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    .contentShape(.rect(cornerRadius: 24, style: .continuous))
                    .accessibilityInputLabels(inputLabels(for: item))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func inputLabels(for item: Item) -> [String] {
        if let custom = inputLabelsProvider?(item), !custom.isEmpty {
            return custom
        }
        
        let raw = item.label
        
        if raw.contains("/") {
            if let first = raw.components(separatedBy: "/").first?.trimmingCharacters(in: .whitespaces), !first.isEmpty {
                return [first]
            }
        }
        
        if item is SelectableOption {
            let localized = String(localized: String.LocalizationValue(raw))
            return [localized, raw]
        }
        
        var labels: [String] = [raw]
        
        if let firstChar = raw.first, firstChar.isNumber {
            labels.insert(String(firstChar), at: 0)
        }
        return labels
    }
}

#Preview {
    @Previewable @State var selected = "even"
    ShortListSelector<SelectableOption>(
        items: [.even, .odd],
        selectedItem: $selected
    )
    .padding()
}
