//
//  DatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var selection: Date
    
    @State var date: Date
    @State var actual: Bool
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    
    var daysString: [String] {
        generaDateAnnoAccademico(annoInizio: Int(selectedYear)!)
    }
    
    var days: [String] {
        Date().getWeekdaySymbols(length: .short)
    }
    
    var currentDay: Int {
        date.day
    }
    
    var lastDayN: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30 // Fallback a 30 se fallisce
    }
    
    var firstDayName: String {
        date.startWeekdaySymbolOfMonth(length: .short)
    }
    
    var monthName: String {
        date.getCurrentMonthSymbol(length: .full)
    }
    
    var year: String {
        date.yearSymbol
    }
    
    var rows: Int {
        6
    }
    
    var calculatedRows: Int {
        var row = 1
        var dayNumber: Int = 1
        while dayNumber < lastDayN {
            dayNumber += 7
            if dayNumber <= lastDayN {
                row += 1
            } else if days.firstIndex(of: firstDayName)! - (dayNumber - lastDayN) >= 0 {
                row += 1
            }
        }
        
        return row
    }
    
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    HStack {
                        Text(monthName)
                            .fontWeight(.bold)
                        Text("•")
                        Text(year)
                    }
                    Spacer()
                    if daysString.contains(Date().getString(format: "dd-MM-yyyy")) {
                        Button("Oggi") {
                            if date.month != Date().month {
                                actual = false
                            } else {
                                date = date.set(type: .day, value: Date().day)
                            }
                            
                            selection = Date()
                        }
                        .glassIfAvailable()
                    }
                }
                HStack {
                    ForEach(days, id: \.self) { day in
                        Text("\(day)")
                            .frame(width: 40, height: 40)
                        if day != days.last {
                            Spacer()
                        }
                    }
                }
                let startOffset = days.firstIndex(of: firstDayName) ?? 0

                ForEach(0..<rows, id: \.self) { row in
                    HStack {
                        ForEach(0..<days.count, id: \.self) { col in
                            let dayIndex = row * days.count + col - startOffset + 1
                            if dayIndex < 1 {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                    let calendar = Calendar.current
                                    let range = calendar.range(of: .day, in: .month, for: date.remove(type: .month, value: 1))
                                    let final = range?.count ?? 30 // Fallback a 30 se fallisce
                                    Text("\(final + dayIndex)")
                                        .opacity(0.3)
                                        .onTapGesture {
                                            if date.month - 1 != 9 {
                                                actual = false
                                                date = date.set(type: .day, value: 1)
                                                var newDate = date.remove(type: .month, value: 1)
                                                newDate = newDate.set(type: .day, value: final + dayIndex)
                                                selection = newDate
                                            }
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else if dayIndex > lastDayN /*&& calculatedRows == row + 1*/ {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                    Text("\(dayIndex - lastDayN)")
                                        .opacity(0.3)
                                        .onTapGesture {
                                            if date.month + 1 != 10 {
                                                actual = false
                                                date = date.set(type: .day, value: 1)
                                                var newDate = date.add(type: .month, value: 1)
                                                newDate = newDate.set(type: .day, value: dayIndex - lastDayN)
                                                selection = newDate
                                            }
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else if dayIndex <= lastDayN {
                                ZStack {
                                    Circle()
                                        .fill(dayIndex == currentDay && actual ? .blue : .clear)
                                        .frame(width: 40, height: 40)
                                        .opacity(0.3)
                                    Text("\(dayIndex)")
                                        .if((dayIndex != currentDay || !actual) && Date().day == dayIndex && Date().getCurrentMonthSymbol(length: .full) == monthName  && Date().yearSymbol == year) { view in
                                            view
                                                .foregroundStyle(.blue)
                                                .fontWeight(.bold)
                                        }
                                        .onTapGesture {
                                            actual = true
                                            date = date.set(type: .day, value: dayIndex)
                                            selection = date
                                        }
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 40, height: 40)
                                }
                                if col < days.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, (screenSize.width / 100) * 8)
    }
    
    func generaDateAnnoAccademico(annoInizio: Int) -> [String] {
        var dateStringhe: [String] = []
        
        // Setup Calendario e Formatter
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Formato richiesto
        formatter.locale = Locale(identifier: "it_IT") // Opzionale: forza locale italiano
        
        // Data Inizio: 1 Ottobre [annoInizio]
        var startComponents = DateComponents()
        startComponents.year = annoInizio
        startComponents.month = 10
        startComponents.day = 1
        
        // Data Fine: 30 Settembre [annoInizio + 1]
        var endComponents = DateComponents()
        endComponents.year = annoInizio + 1
        endComponents.month = 9
        endComponents.day = 30
        
        // Controllo validità date
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        // Ciclo per generare le date
        var currentDate = startDate
        
        while currentDate <= endDate {
            // 1. Aggiungi la stringa formattata all'array
            dateStringhe.append(formatter.string(from: currentDate))
            
            // 2. Incrementa di 1 giorno
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break // Sicurezza per evitare loop infiniti in caso di errore
            }
        }
        
        return dateStringhe
    }
}

struct DatePickerContainer: View {
    @Binding var  selectedMonth: Int
    @Binding var selectedWeek: Date
    
    @AppStorage("selectedYear") var selectedYear: String = "2025"
    
    var body: some View {
        TabView(selection: $selectedMonth) {
            ForEach(0..<12) { n in
                let date = Date(year: Int(selectedYear)!, month: 10, day: 1).add(type: .month, value: n)
                if selectedWeek.month == date.month {
                    DatePickerView(selection: $selectedWeek, date: selectedWeek, actual: true).tag(date.month)
                } else {
                    DatePickerView(selection: $selectedWeek, date: date, actual: false).tag(date.month)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

#Preview {
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    
    DatePickerContainer(selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
}
