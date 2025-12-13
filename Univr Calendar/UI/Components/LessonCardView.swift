//
//  LessonCardView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI
import UnivrCore

struct LessonCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let lesson: Lesson
    
    private var backgroundColor: Color { Color(hex: lesson.color) ?? .black }
    private var isWhiteCard: Bool { backgroundColor == .white && colorScheme == .light }
    
    var body: some View {
        ZStack {
            backgroundLayer
            HStack(spacing: 20) {
                timeInfo
                lessonInfo
            }
            .padding()
            .opacity(lesson.annullato == "1" ? 0.5 : 1.0)
        }
        .padding(.horizontal, 15)
    }
    
    // MARK: - Components
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .fill(backgroundColor)
            .overlay {
                if isWhiteCard {
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .strokeBorder(Color(white: 0.35), lineWidth: 0.5)
                }
            }
        
    }
    
    private var timeInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.startTime)
                .font(.system(size: 40).monospacedDigit())
                .fontWeight(.medium)
            Label(lesson.durationCalculated, systemImage: "clock")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Spacer()
        }
        .foregroundStyle(.black)
    }
    
    private var lessonInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.cleanName)
                .foregroundStyle(.black)
                .font(.headline)
                .multilineTextAlignment(.leading)
            
            Text(lesson.formattedClassroom)
                .foregroundStyle(Color(white: 0.3))
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            if !lesson.tags.isEmpty {
                tagsList
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
                LessonCardView(lesson: lesson)
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
