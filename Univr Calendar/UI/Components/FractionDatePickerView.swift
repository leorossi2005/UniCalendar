//
//  FractionDatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
//

import SwiftUI

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    
    let week: [Date]
    
    var body: some View {
        HStack {
            ForEach(week, id: \.self) { day in
                let isOutOfBounds = (day.month == 9 && day.year == Int(selectedYear)) || (day.month == 10 && day.year == Int(selectedYear)! + 1)
                Button(action: {
                    if !isOutOfBounds {
                        withAnimation {
                            selectedWeek = day
                        }
                    }
                }) {
                    VStack {
                        Text("\(day.day)")
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .bold()
                            .foregroundStyle(day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                        Text(day.getCurrentWeekdaySymbol(length: .short))
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .foregroundStyle(day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                    }
                    .frame(height: 50)
                }
                .buttonBorderShape(.roundedRectangle(radius: 20))
                .glassProminentIfAvailable()
                .tint(Color(white: colorScheme == .light ? 0 : 1, opacity: day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? 1 : 0.05))
                .opacity(isOutOfBounds || loading ? 0.3 : 1)
                .disabled(isOutOfBounds)
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
        .ignoresSafeArea()
        /*.gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onEnded { value in
                    let current: Date = selectedWeek.set(type: .day, value: currentDay)
                    var new: Date? = nil
                    
                    if value.predictedEndTranslation.width < -150 {
                        new = current.add(type: .day, value: 7)!
                    } else if value.predictedEndTranslation.width > 150 {
                        new = current.remove(type: .day, value: 7)!
                    }
                    
                    if let d = new {
                        currentDay = d.day
                        selectedWeek = d
                    }
                }
        )*/
    }
}

#Preview {
    @Previewable @State var selectedWeek: Date = Date()
    @Previewable @State var loading: Bool = false
    @Previewable @State var week: [Date] = [Date()]
    
    FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: week)
}
