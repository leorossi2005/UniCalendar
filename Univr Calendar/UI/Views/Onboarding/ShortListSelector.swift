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
    let items: [Item]
    @Binding var selectedItem: String
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                let isSelected = selectedItem == item.id

                Button {
                    Haptics.play(.selection)
                    selectedItem = item.id
                } label: {
                    HStack {
                        if item is SelectableOption {
                            Text(LocalizedStringKey(item.label))
                                .fontWeight(isSelected ? .semibold : .regular)
                        } else {
                            Text(item.label)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary.opacity(0.35))
                            .symbolReplace()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(
                        isSelected ? Color(.secondarySystemFill) : Color(.tertiarySystemFill),
                        in: .rect(cornerRadius: 24, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.snappy(duration: 0.25), value: selectedItem)
        .padding(.top, 16)
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
