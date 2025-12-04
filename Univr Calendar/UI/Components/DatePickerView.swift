//
//  DatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI
import UnivrCore

@Observable
class DatePickerViewModel {
    static let shared = DatePickerViewModel()
    
    var grid: [String: [CalendarCell]] = [:]
}

// Struttura dati leggera per la cella
struct CalendarCell: Identifiable, Equatable {
    let id = UUID()
    let dayNumber: String
    let dayValue: Int
    let isCurrentMonth: Bool
    let date: Date
}

struct DatePickerView: View {
    @Environment(UserSettings.self) var settings
    @Environment(\.isEnabled) var isEnabled
    
    @State var viewModel = DatePickerViewModel.shared
    
    @Binding var selection: Date
    @Binding var selectedMonth: Int
    
    let date: Date
    
    private let calendar = Calendars.calendar
    private let screenSize: CGRect = UIApplication.shared.screenSize
    
    var isSelectedMonth: Bool {
        calendar.isDate(selection, equalTo: date, toGranularity: .month)
    }
    
    var monthName: String {
        date.getCurrentMonthSymbol(length: .full)
    }
    
    var year: String {
        date.yearSymbol
    }
    
    var days: [String] {
        Date().getWeekdaySymbols(length: .short)
    }
    
    var isTodayInAcademicYear: Bool {
        guard let yearInt = Int(settings.selectedYear) else { return false }
        
        let today = Date()
        let startDate = Date(year: yearInt, month: 10, day: 1)
        let endDate = Date(year: yearInt + 1, month: 9, day: 30)
        
        return today >= startDate && today <= endDate
    }
    
    private func calculatedGrid() {
        var newGrid: [CalendarCell] = []
        
        // 1. Troviamo il primo giorno del mese
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else { return }
        
        // 2. Giorni nel mese corrente
        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }
        let numDays = range.count
        
        // 3. Offset per iniziare dal giorno corretto (Lunedi = 0)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let startOffset = (firstWeekday + 5) % 7
        
        // 4. Dati mese precedente
        guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
              let prevMonthRange = calendar.range(of: .day, in: .month, for: prevMonthDate) else { return }
        let prevMonthDays = prevMonthRange.count
        
        // 5. Ciclo unico per le 42 celle (6 righe * 7 colonne)
        for i in 0..<42 {
            let cellDate: Date
            let dayValue: Int
            let isCurrentMonth: Bool
            
            if i < startOffset {
                // Giorni mese precedente
                let day = prevMonthDays - (startOffset - i - 1)
                dayValue = day
                isCurrentMonth = false
                cellDate = calendar.date(byAdding: .day, value: -(startOffset - i), to: startOfMonth) ?? date
                
            } else if i >= startOffset + numDays {
                // Giorni mese successivo
                let day = i - (startOffset + numDays) + 1
                dayValue = day
                isCurrentMonth = false
                // Calcolo sicuro per il mese prossimo
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) {
                    cellDate = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) ?? date
                } else {
                    cellDate = date
                }
                
            } else {
                // Giorni mese corrente
                let day = i - startOffset + 1
                dayValue = day
                isCurrentMonth = true
                cellDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) ?? date
            }
            
            newGrid.append(CalendarCell(
                dayNumber: "\(dayValue)",
                dayValue: dayValue,
                isCurrentMonth: isCurrentMonth,
                date: cellDate
            ))
        }
        
        viewModel.grid[monthName] = newGrid
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack {
                    Text(monthName)
                        .fontWeight(.bold)
                    Text("•")
                    Text(year)
                }
                .opacity(isEnabled ? 1 : 0.3)
                Spacer()
                if isTodayInAcademicYear {
                    Button("Oggi") {
                        let today = Date()
                        if selection != today {
                            selection = today
                        }
                    }
                    .glassIfAvailable()
                }
            }
            HStack {
                ForEach(days, id: \.self) { day in
                    Text("\(day.capitalized)")
                        .frame(width: 40, height: 40)
                    if day != days.last {
                        Spacer()
                    }
                }
            }
            .opacity(isEnabled ? 1 : 0.3)
            Grid {
                if viewModel.grid[monthName] != nil {
                    let month = viewModel.grid[monthName]!
                    let today = Date()
                    ForEach(0..<6, id: \.self) { row in
                        GridRow {
                            ForEach(0..<7, id: \.self) { column in
                                if !month.isEmpty {
                                    let index = (row * 7) + column
                                    let isSelected = calendar.isDate(selection, inSameDayAs: month[index].date)
                                    let isToday = calendar.isDate(today, inSameDayAs: month[index].date)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(isSelected && isSelectedMonth ? .blue : .clear)
                                            .frame(width: 40, height: 40)
                                            .opacity(isEnabled ? (month[index].isCurrentMonth ? 0.3 : 0.1) : 0.1)
                                        Text(month[index].dayNumber)
                                            .opacity(isEnabled ? (month[index].isCurrentMonth ? 1 : 0.3) : 0.3)
                                            .fontWeight(isToday && (!isSelected || !isSelectedMonth) ? .bold : .regular)
                                            .foregroundStyle(isToday && (!isSelected || !isSelectedMonth) ? .blue : .primary)
                                    }
                                    .frame(height: 40)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let yearInt = Int(settings.selectedYear) {
                                            let isLeftOutOfBounds = month[index].date.month == 9 && month[index].date.year == yearInt
                                            let isRightOutOfBounds = (month[index].date.month == 10 && month[index].date.year == yearInt + 1)
                                            
                                            if selection != month[index].date && !isLeftOutOfBounds && !isRightOutOfBounds {
                                                selection = month[index].date
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, (screenSize.width / 100) * 8)
        .onChange(of: selection) {
            if calendar.isDate(selection, equalTo: date, toGranularity: .month) {
                selectedMonth = calendar.component(.month, from: selection)
            }
        }
        .onAppear {
            if viewModel.grid[monthName] == nil || viewModel.grid[monthName]!.isEmpty || viewModel.grid[monthName]?.first?.date.yearSymbol != year {
                calculatedGrid()
            }
        }
        .onChange(of: date) {
            calculatedGrid()
        }
    }
}

struct DatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedDetent: PresentationDetent
    @Binding var selectedMonth: Int
    @Binding var selectedWeek: Date
    
    var body: some View {
        TabView(selection: $selectedMonth) {
            ForEach(0..<12) { n in
                if let year = Int(settings.selectedYear) {
                    let date = Date(year: year, month: 10, day: 1).add(type: .month, value: n)
                    DatePickerView(
                        selection: $selectedWeek,
                        selectedMonth: $selectedMonth,
                        date: date
                    )
                    .tag(date.month)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

#Preview {
    @Previewable @State var selectedDetent: PresentationDetent = .medium
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    
    DatePickerContainer(selectedDetent: $selectedDetent, selectedMonth: $selectedMonth, selectedWeek: $selectedWeek)
        .environment(UserSettings.shared)
}
