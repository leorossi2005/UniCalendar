//
//  LessonCardView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

struct LessonCardView: View {
    let lesson: Lesson
    @State private var cleanText: String = ""
    @State private var tags: [String] = []
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(Color(hex: lesson.color) ?? .black)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.orario.split(separator: " - ").first!)
                        .foregroundStyle(.black)
                        .font(.system(size: 40))
                    Label(lesson.durationCalculated, systemImage: "clock")
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Color.black
                                .opacity(0.1)
                        }
                        .cornerRadius(10)
                    Spacer()
                }
                
                Spacer(minLength: 20)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(cleanText)
                        .foregroundStyle(.black)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    Text(lesson.formattedClassroom)
                        .foregroundStyle(Color(white: 0.3))
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                    
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .foregroundStyle(.black)
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background {
                                ZStack {
                                    Color.black
                                        .opacity(0.5)
                                    Color(hex: lesson.color)
                                        .opacity(0.5)
                                }
                                .opacity(0.2)
                            }
                            .cornerRadius(7)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .padding(.horizontal, 15)
        .onAppear {
            if cleanText.isEmpty {
                let result = LessonNameFormatter.format(lesson.nomeInsegnamento)
                cleanText = result.cleanText
                tags = result.tags
            }
        }
        .drawingGroup()
    }
}

#Preview {
    ScrollView {
        LessonCardView(lesson: Lesson.sample)
            .environment(UserSettings.shared)
    }
}
