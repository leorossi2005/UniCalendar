//
//  LessonCardView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

struct LessonCardView: View {
    let lesson: Lesson
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 45, style: .continuous)
                .fill(LinearGradient(stops: [
                    .init(color: Color(hex: lesson.color) ?? .black, location: 0),
                    .init(color: Color(white: 0, opacity: 0.6), location: 2)
                ], startPoint: .leading, endPoint: .trailing))
                .padding(.horizontal, 15)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(lesson.formattedName)
                        .foregroundStyle(.black)
                        .font(.custom("", size: 20)) // Considera di usare .title3 o .headline
                        .multilineTextAlignment(.leading)
                    
                    Text(lesson.formattedClassroom)
                        .foregroundStyle(Color(white: 0.3))
                        .font(.custom("", size: 20))
                    
                    Spacer(minLength: 30)
                    
                    Text(lesson.orario)
                        .foregroundStyle(.black)
                        .font(.custom("", size: 20))
                }
                .padding(.vertical, 25)
                .padding(.leading, 45)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 20)
                
                Text(lesson.durationCalculated)
                    .foregroundStyle(.black)
                    .font(.system(size: 60))
                    .padding(.trailing, 45)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
        }
        .drawingGroup()
    }
}

#Preview {
    LessonCardView(lesson: Lesson.sample)
        .environment(UserSettings.shared)
}
