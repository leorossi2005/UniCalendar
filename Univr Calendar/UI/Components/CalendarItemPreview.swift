//
//  CalendarItemPreview.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct CalendarItemPreview: View {
    @Environment(\.colorScheme) var colorScheme
    
    let item: CalendarItem
    let internalItem: any CalendarDisplayable
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(internalItem.displayTitle)
                    .font(.headline.weight(.bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !internalItem.tagsItems.isEmpty {
                    HStack {
                        ForEach(internalItem.tagsItems.prefix(3)) { tag in
                            Text(tag.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(internalItem.isCanceled ? Color(.systemBackground) : badgeColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay {
                                    if internalItem.isCanceled {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(Color(white: 0.35), lineWidth: 0.5)
                                    }
                                }
                        }
                        if internalItem.tagsItems.count > 3 {
                            Text("+\(internalItem.tagsItems.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                rowLabel(
                    text: "\(internalItem.startTime.getCurrentWeekdaySymbol(length: .wide)), \(internalItem.startTime.day) \(internalItem.startTime.getCurrentMonthSymbol(length: .wide)) \(internalItem.startTime.yearSymbol)",
                    icon: "calendar"
                )
                rowLabel(
                    text: "\(internalItem.startTime.formatted(.dateTime.hour().minute())) - \(internalItem.endTime.formatted(.dateTime.hour().minute())) (\(Duration.seconds(internalItem.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))))",
                    icon: "clock.fill"
                )
                switch item {
                case .lesson(let lesson):
                    rowLabel(
                        text: lesson.teachers.isEmpty ? "Non specificato" : LocalizedStringKey(lesson.teachers.joined(separator: ", ")),
                        icon: !lesson.teachers.isEmpty && lesson.teachers.count > 1 ? "person.2.fill" : "person.fill"
                    )
                    rowLabel(
                        text: "\(lesson.location?.classroom ?? "") \(lesson.location?.capacity.map { "(\($0) \(String(localized: "posti")))" } ?? "")",
                        icon: "mappin"
                    )
                case .personal:
                    if let loc = internalItem.displayLocation, !loc.isEmpty {
                        rowLabel(
                            text: LocalizedStringKey(loc),
                            icon: "mappin"
                        )
                    }
                }
            }
            
            if case .personal(let personalEvent) = item, let notes = personalEvent.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Note")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.leading)
                    Text(notes)
                        .font(.body)
                        .lineLimit(4)
                        .truncationMode(.tail)
                        .foregroundColor(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            badgeColor.opacity(0.2),
                            in: RoundedRectangle(cornerRadius: .deviceCornerRadius - 16)
                        )
                }
            }
        }
        .padding(24)
        .frame(width: UIDevice.isIpad ? 320 : UIScreen.main.bounds.width - 32, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            switch item {
            case .lesson: EmptyView()
            case .personal:
                CustomMeshGradient(
                    width: BaseGradient.width,
                    height: BaseGradient.height,
                    points: BaseGradient.points,
                    colors: BaseGradient.colors,
                    background: BaseGradient.background,
                    smoothsColors: BaseGradient.smoothsColors
                )
                .opacity(colorScheme == .dark ? 0.15 : 0.4)
            }
        }
    }
    
    private func rowLabel(text: LocalizedStringKey, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .lineLimit(1)
    }
    
    private var badgeColor: Color {
        switch item {
        case .lesson(let lesson): return lesson.uiColor
        case .personal: return Color(white: colorScheme == .dark ? 0.5 : 1)
        }
    }
}
