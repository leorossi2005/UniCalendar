//
//  DatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

struct DatePickerView: View {
    @Environment(UserSettings.self) var settings
    @Environment(\.isEnabled) var isEnabled
    
    @Binding var selection: Date
    @Binding var selectedMonth: Int
    
    @State var date: Date
    @State var actual: Bool
    @State var currentDay: Int = 1
    
    var daysString: [String] {
        if let year = Int(settings.selectedYear) {
            return generaDateAnnoAccademico(annoInizio: year)
        } else { return [] }
    }
    
    var days: [String] {
        Date().getWeekdaySymbols(length: .short)
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
                    .opacity(isEnabled ? 1 : 0.3)
                    Spacer()
                    if daysString.contains(Date().getString(format: "dd-MM-yyyy")) {
                        Button("Oggi") {
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
                .opacity(isEnabled ? 1 : 0.3)
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
                                    let final = range?.count ?? 30
                                    Text("\(final + dayIndex)")
                                        .opacity(isEnabled ? 0.3 : 0.1)
                                        .onTapGesture {
                                            if date.month - 1 != 9 {
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
                                        .opacity(isEnabled ? 0.3 : 0.1)
                                        .onTapGesture {
                                            if date.month + 1 != 10 {
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
                                        .opacity(isEnabled ? 0.3 : 0.1)
                                    Text("\(dayIndex)")
                                        .opacity(isEnabled ? 1 : 0.3)
                                        .if((dayIndex != currentDay || !actual) && Date().day == dayIndex && Date().getCurrentMonthSymbol(length: .full) == monthName  && Date().yearSymbol == year) { view in
                                            view
                                                .foregroundStyle(.blue)
                                                .fontWeight(.bold)
                                        }
                                        .onTapGesture {
                                            selection = date.set(type: .day, value: dayIndex)
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
        .onAppear {
            currentDay = date.day
        }
        .onChange(of: selection) {
            if selection.month == date.month {
                actual = true
                selectedMonth = selection.month
                date = date.set(type: .day, value: selection.day)
            } else {
                actual = false
                date = date.set(type: .day, value: 1)
            }
            
            currentDay = date.day
        }
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
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedDetent: PresentationDetent
    @Binding var selectedMonth: Int
    @Binding var selectedWeek: Date
    
    var body: some View {
        GeometryReader { proxy in
            let currentHeight = proxy.size.height
            let screenHeight = UIScreen.main.bounds.height
            
            let BigHeight = screenHeight * 0.45
            let smallHeight = screenHeight * 0.55
            
            let fadeRange: CGFloat = screenHeight * 0.05
            
            let dynamicOpacity = 1.0 - ((currentHeight < smallHeight ? Double(BigHeight - currentHeight) : Double(currentHeight - smallHeight)) / Double(fadeRange))
            
            TabView(selection: $selectedMonth) {
                ForEach(0..<12) { n in
                    if let year = Int(settings.selectedYear) {
                        let date = Date(year: year, month: 10, day: 1).add(type: .month, value: n)
                        if selectedWeek.month == date.month {
                            DatePickerView(selection: $selectedWeek, selectedMonth: $selectedMonth, date: selectedWeek, actual: true).tag(date.month)
                        } else {
                            DatePickerView(selection: $selectedWeek, selectedMonth: $selectedMonth, date: date, actual: false).tag(date.month)
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .opacity(min(max(dynamicOpacity, 0), 1))
            .allowsHitTesting(selectedDetent == (isIpad ? .fraction(0.75) : .medium))
        }
    }
}

#Preview {
    @Previewable @State var selectedDetent: PresentationDetent = .medium
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    
    DatePickerContainer(selectedDetent: $selectedDetent, selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
        .environment(UserSettings.shared)
}
