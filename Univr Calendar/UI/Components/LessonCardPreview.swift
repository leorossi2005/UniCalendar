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

struct LessonCardPreview: View {
    let lesson: Lesson
    
    private var backgroundColor: Color {
        Color(hex: lesson.color) ?? Color(.systemGray6)
    }
    
    private var date: Date {
        lesson.data.toDateModern() ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.cleanName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if !lesson.tags.isEmpty {
                    HStack {
                        ForEach(lesson.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(lesson.annullato ? Color(.systemBackground) : backgroundColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay {
                                    if lesson.annullato {
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
                    text: "\(date.getCurrentWeekdaySymbol(length: .wide)), \(date.day) \(date.getCurrentMonthSymbol(length: .wide)) \(date.yearSymbol)",
                    icon: "calendar"
                )
                rowLabel(
                    text: "\(lesson.orario) (\(lesson.durationCalculated))",
                    icon: "clock.fill"
                )
                rowLabel(
                    text: lesson.docente.isEmpty ? "Non specificato" : LocalizedStringKey(lesson.docente),
                    icon: lesson.docente.contains(",") ? "person.2.fill" : "person.fill"
                )
                rowLabel(
                    text: "\(lesson.formattedClassroom) \(lesson.capacity.map { "(\($0) \(String(localized: "posti")))" } ?? "")",
                    icon: "mappin"
                )
            }
            
            //Divider()
            //    .padding(.vertical, 4)
            //
            //Button {} label: {
            //    Text("Visualizza dettagli completi")
            //        .frame(maxWidth: .infinity)
            //        .foregroundStyle(.black)
            //        .fontWeight(.semibold)
            //        .padding(12)
            //}
            //.glassProminentIfAvailable()
            //.tint(backgroundColor)
        }
        .padding(24)
        .frame(width: UIApplication.shared.screenSize.width, alignment: .leading)
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
