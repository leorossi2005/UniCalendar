//
//  DatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI
import UnivrCore

struct DatePickerView: View {
    @Environment(UserSettings.self) var settings
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.calendar) var calendar
    
    var viewModel = DatePickerCache.shared
    
    @Binding var selection: Date
    @Binding var selectedMonth: Int
    
    let date: Date
    private let screenSize: CGRect = UIApplication.shared.screenSize

    private var monthName: String { date.getCurrentMonthSymbol(length: .wide) }
    private var year: String { date.yearSymbol }
    private var daysHeader: [String] { Date().getWeekdaySymbols(length: .short) }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 10) {
            headerView
            HStack {
                ForEach(daysHeader, id: \.self) { day in
                    Text(day.capitalized)
                        .frame(width: 40, height: 40)
                    if day != daysHeader.last {
                        Spacer()
                    }
                }
            }
            .opacity(isEnabled ? 1 : 0.3)
            Grid {
                if let monthCell = viewModel.monthGrids["\(monthName)-\(date.yearSymbol)"] {
                    ForEach(0..<6, id: \.self) { row in
                        GridRow {
                            ForEach(0..<7, id: \.self) { column in
                                let index = (row * 7) + column
                                if index < monthCell.count {
                                    dayCell(for: monthCell[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, (screenSize.width / 100) * 8)
        .task(id: date) {
            await viewModel.generateMonthGrid(for: date, monthName: monthName)
        }
        .onChange(of: selection) {
            if calendar.isDate(selection, equalTo: date, toGranularity: .month) {
                selectedMonth = calendar.component(.month, from: selection)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            let today = Date()
            HStack {
                Text(monthName)
                    .fontWeight(.bold)
                Text("•")
                Text(year)
            }
            .opacity(isEnabled ? 1 : 0.3)
            Spacer()
            if today.isInAcademicYear(for: year) {
                Button("Oggi") {
                    if selection != today {
                        selection = today
                    }
                }
                .glassIfAvailable()
            }
        }
    }
    
    private func dayCell(for cell: CalendarCell) -> some View {
        let isSelected = calendar.isDate(selection, inSameDayAs: cell.date)
        let isSelectedMonth = calendar.isDate(selection, equalTo: date, toGranularity: .month)
        let isToday = calendar.isDateInToday(cell.date)
        let showSelectionCircle = isSelected && isSelectedMonth
        
        return ZStack {
            if showSelectionCircle {
                Circle()
                    .fill(.blue)
                    .frame(width: 40, height: 40)
                    .opacity(isEnabled ? (cell.isCurrentMonth ? 0.3 : 0.1) : 0.1)
            }
            Text(cell.dayNumber)
                .fontWeight(isToday && !showSelectionCircle ? .bold : .regular)
                .foregroundStyle(isToday && !showSelectionCircle ? .blue : .primary)
                .opacity(isEnabled ? (cell.isCurrentMonth ? 1 : 0.3) : (cell.isCurrentMonth ? 0.3 : 0.1))
        }
        .frame(width: 40, height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let yearInt = Int(settings.selectedYear) else { return }
            if selection != cell.date && cell.date.isOutOfAcademicBounds(for: yearInt) {
                selection = cell.date
            }
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
            if let year = Int(settings.selectedYear) {
                ForEach(0..<12) { n in
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
