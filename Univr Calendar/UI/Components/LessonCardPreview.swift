//
//  LessonCardPreview.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/01/26.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct LessonCardPreview: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.cleanName ?? "")
                    .font(.headline.weight(.bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(10)
                
                if !lesson.tags.isEmpty {
                    HStack {
                        ForEach(lesson.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(lesson.isCanceled ? Color(.systemBackground) : lesson.uiColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay {
                                    if lesson.isCanceled {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(Color(white: 0.35), lineWidth: 0.5)
                                    }
                                }
                        }
                        if lesson.tags.count > 2 {
                            Text("+\(lesson.tags.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                rowLabel(
                    text: "\(lesson.startTime.getCurrentWeekdaySymbol(length: .wide)), \(lesson.startTime.day) \(lesson.startTime.getCurrentMonthSymbol(length: .wide)) \(lesson.startTime.yearSymbol)",
                    icon: "calendar"
                )
                rowLabel(
                    text: "\(lesson.startTime.formatted(.dateTime.hour().minute())) - \(lesson.endTime.formatted(.dateTime.hour().minute())) (\(Duration.seconds(lesson.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))))",
                    icon: "clock.fill"
                )
                rowLabel(
                    text: lesson.teachers.isEmpty ? "Non specificato" : LocalizedStringKey(lesson.teachers.joined(separator: ", ")),
                    icon: !lesson.teachers.isEmpty && lesson.teachers.count > 1 ? "person.2.fill" : "person.fill"
                )
                rowLabel(
                    text: "\(lesson.location?.classroom ?? "") \(lesson.location?.capacity.map { "(\($0) \(String(localized: "posti")))" } ?? "")",
                    icon: "mappin"
                )
            }
        }
        .padding(24)
        .frame(width: UIDevice.isIpad ? 320 : UIScreen.main.bounds.width - 32, alignment: .leading)
    }
    
    private func rowLabel(text: LocalizedStringKey, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .lineLimit(1)
    }
}

#Preview {
    LessonCardPreview(lesson: .sample)
        .frame(width: 280, height: 300)
        .environment(UserSettings.shared)
}
