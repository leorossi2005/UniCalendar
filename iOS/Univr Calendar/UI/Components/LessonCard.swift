//
//  LessonCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct LessonCard: View {
    let lesson: Lesson
    
    private var backgroundColor: Color { lesson.annullato ? Color(.systemBackground) : Color(hex: lesson.color) ?? Color(.systemBackground) }
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            timeInfo
            lessonInfo
        }
        .padding()
        .opacity(lesson.annullato ? 0.5 : 1.0)
        .background(backgroundLayer)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect(.lift)
        .padding(.horizontal, 15)
    }
    
    // MARK: - Components
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .fill(backgroundColor)
            .strokeBorder(.secondary.opacity(lesson.annullato ? 1 : 0), lineWidth: 0.5)
    }
    
    private var timeInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.startTime)
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.medium)
            if !lesson.annullato {
                Label(lesson.durationCalculated, systemImage: "clock")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .foregroundStyle(lesson.annullato ? .primary : Color.black)
    }
    
    private var lessonInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.cleanName)
                .font(.headline)
                .strikethrough(lesson.annullato)
            if !lesson.annullato {
                Text(lesson.formattedClassroom)
                    .foregroundStyle(Color(white: 0.3))
                    .font(.subheadline)
                
                if !lesson.tags.isEmpty {
                    tagsList
                }
            }
        }
        .foregroundStyle(lesson.annullato ? .primary : Color.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(lesson.tags, id: \.self) { tag in
                Text(tag)
                    .foregroundStyle(.black)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(backgroundColor.opacity(0.3))
                    .background(.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }
}

struct BreakCard: View {
    let lesson: Lesson
    
    var body: some View {
        HStack(alignment: .bottom) {
            Image(systemName: .cupDynamic)
                .font(.system(size: 40))
            Text(lesson.durationCalculated)
                .font(.system(size: 30))
                .italic()
                .bold()
        }
        .foregroundStyle(Color(white: 0.35))
    }
}

struct ScheduleRow: View {
    let lesson: Lesson
    
    var body: some View {
        switch lesson.category {
        case .regular:
            LessonCard(lesson: lesson)
        case .pause:
            BreakCard(lesson: lesson)
        case .closure:
            EmptyView()
        }
    }
}

#Preview {
    ScrollView {
        ForEach([Lesson.sample, Lesson.pausaSample, Lesson.sample]) { lesson in
            ScheduleRow(lesson: lesson)
        }
    }
    .environment(UserSettings.shared)
}
