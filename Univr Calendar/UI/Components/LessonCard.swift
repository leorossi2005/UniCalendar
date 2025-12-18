//
//  LessonCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI
import UnivrCore

struct LessonCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let lesson: Lesson
    
    private var backgroundColor: Color { Color(hex: lesson.color) ?? Color(.systemGray6) }
    
    var body: some View {
        HStack(spacing: 20) {
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
            .fill(lesson.annullato ? .clear : backgroundColor)
            .overlay {
                if lesson.annullato {
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .strokeBorder(.secondary, lineWidth: 0.5)
                }
            }
        
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
                    .background(Color.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            Spacer()
        }
        .foregroundStyle(lesson.annullato ? .primary : Color.black)
    }
    
    private var lessonInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.cleanName)
                .foregroundStyle(lesson.annullato ? .primary : Color.black)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .strikethrough(lesson.annullato)
            if !lesson.annullato {
                Text(lesson.formattedClassroom)
                    .foregroundStyle(Color(white: 0.3))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                if !lesson.tags.isEmpty {
                    tagsList
                }
            }
            Spacer()
        }
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
                    .background {
                        ZStack {
                            Color.black.opacity(0.1)
                            backgroundColor.opacity(0.3)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }
}

#Preview {
    ScrollView {
        ForEach([Lesson.sample, Lesson.pausaSample, Lesson.sample]) { lesson in
            if lesson.tipo != "pause" && lesson.tipo != "chiusura_type" {
                LessonCard(lesson: lesson)
            } else {
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
    }
    .environment(UserSettings.shared)
}
