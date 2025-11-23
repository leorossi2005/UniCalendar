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
                    Text(formatName(name: lesson.nomeInsegnamento))
                        .foregroundStyle(.black)
                        .font(.custom("", size: 20)) // Considera di usare .title3 o .headline
                        .multilineTextAlignment(.leading)
                    
                    Text(formatClassroom(classroom: lesson.aula))
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
                
                Text(LessonCardView.getDuration(orario: lesson.orario))
                    .foregroundStyle(.black)
                    .font(.system(size: 60))
                    .padding(.trailing, 45)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Helpers
    private func formatName(name: String) -> String {
        return name.replacingOccurrences(of: "Matricole pari", with: "")
                   .replacingOccurrences(of: "Matricole dispari", with: "")
    }
    
    private func formatClassroom(classroom: String) -> String {
        guard let bracketIndex = classroom.firstIndex(of: "[") else {
            return classroom
        }
        let index = classroom.index(bracketIndex, offsetBy: -2, limitedBy: classroom.startIndex) ?? classroom.startIndex
        return String(classroom[...index])
    }
    
    static func getDuration(orario: String) -> String {
        let parti = orario.components(separatedBy: " - ")
        guard parti.count == 2 else { return "" }
        
        // Usiamo i formatters ottimizzati creati nella Fase 1
        let formatter = Formatters.hourMinute

        if let inizio = formatter.date(from: parti[0]),
           let fine = formatter.date(from: parti[1]) {
            
            let diff = fine.timeIntervalSince(inizio)
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            
            if hours >= 1 && minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else if hours >= 1 {
                return "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        }
        return ""
    }
}

#Preview {
    //LessonCardView(lesson: <#Lesson#>)
    //    .environment(UserSettings.shared)
}
