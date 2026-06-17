//
//  DatePicker.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct DatePicker: View, Equatable {
    @Environment(UserSettings.self) var settings
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.calendar) var calendar
    
    var viewModel = DatePickerCache.shared
    @Binding var selection: Date
    let date: Date
    
    private let cellSize: CGFloat = 40
    private let spacing: CGFloat = 8
    
    private var monthName: String { date.getCurrentMonthSymbol(length: .wide) }
    private let columns = Array(repeating: GridItem(.fixed(40), spacing: 8), count: 7)
    
    static func == (lhs: DatePicker, rhs: DatePicker) -> Bool {
        guard lhs.date == rhs.date else { return false }
        let cal = Calendar.current
        let lhsActive = cal.isDate(lhs.selection, equalTo: lhs.date, toGranularity: .month)
        let rhsActive = cal.isDate(rhs.selection, equalTo: rhs.date, toGranularity: .month)
        return (!lhsActive && !rhsActive) ? true : lhs.selection == rhs.selection
    }
    
    var body: some View {
        VStack(spacing: 10) {
            headerView
            
            HStack(spacing: spacing) {
                ForEach(date.getWeekdaySymbols(length: .short), id: \.self) { day in
                    Text(day.capitalized)
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .opacity(isEnabled ? 1 : 0.3)
            
            LazyVGrid(columns: columns, spacing: spacing) {
                if let monthCell = viewModel.monthGrids["\(monthName)-\(date.yearSymbol)"] {
                    ForEach(monthCell, id: \.date) { cell in
                        DayCellView(
                            cell: cell,
                            isSelected: calendar.isDate(selection, inSameDayAs: cell.date),
                            isToday: calendar.isDateInToday(cell.date),
                            isOutsideBounds: cell.date.isOutOfAcademicBounds(for: Int(settings.selectedYear) ?? 0)
                        ) {
                            if selection != cell.date && !cell.date.isOutOfAcademicBounds(for: Int(settings.selectedYear) ?? 0) {
                                selection = cell.date
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 328, maxHeight: .infinity)
        .ignoresSafeArea()
        .task(id: date) {
            await viewModel.generateMonthGrid(for: date, monthName: monthName)
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack {
                Text(monthName).fontWeight(.bold)
                Text("•")
                Text(date.yearSymbol)
            }
            .opacity(isEnabled ? 1 : 0.3)
            
            Spacer()
            
            if Date().isInAcademicYear(for: settings.selectedYear) {
                Button("Oggi") {
                    let today = Calendar.current.startOfDay(for: Date())
                    if !Calendar.current.isDate(selection, inSameDayAs: today) {
                        Haptics.play(.impact(weight: .medium), state: "selection")
                        selection = today
                    }
                }
                .glassIfAvailable()
                .hoverEffect()
            }
        }
        .frame(height: 30)
    }
}

struct DatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    @Binding var selectedWeek: Date
    @State private var internalIndex: Int = 0
    
    var body: some View {
        let year = Int(settings.selectedYear) ?? selectedWeek.year
        
        TabView(selection: $internalIndex) {
            ForEach(0..<12, id: \.self) { index in
                DatePicker(selection: $selectedWeek, date: Date(year: year, month: 10, day: 1).add(type: .month, value: index))
                    .equatable()
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: CustomSheetDetent.medium.value)
        // Matematica pura al posto dell'array: Ottobre(10) -> 0, Gennaio(1) -> 3, ecc.
        .onAppear { internalIndex = (selectedWeek.month + 2) % 12 }
        .onChange(of: selectedWeek) { _, new in internalIndex = (new.month + 2) % 12 }
        .onChange(of: internalIndex) {
            if GlobalHaptics.shared.state != "selection" {
                Haptics.play(.selection)
            } else {
                GlobalHaptics.shared.state = ""
            }
        }
    }
}

// MARK: - Subviews
private struct DayCellView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    let cell: CalendarCell
    let isSelected, isToday, isOutsideBounds: Bool
    let action: () -> Void
    
    var progressColor: Color {
        switch cell.activityQuantity {
        case 8...: return .red
        case 5..<8: return .orange
        case 3..<5: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        Text(cell.dayNumber)
            .frame(width: 40, height: 40)
            .fontWeight(isToday && !isSelected ? .black : .regular)
            .foregroundStyle(!isSelected ? Color.primary : colorScheme == .light ? .white : .black)
            .background {
                if isSelected { Circle().fill(colorScheme == .light ? .black : .white) }
            }
            .overlay(alignment: .bottom) {
                if cell.hasActivity && isEnabled {
                    RoundedRectangle(cornerRadius: 2, style: .continuous).fill(progressColor).opacity(0.2).frame(width: 15, height: 4)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(progressColor)
                                .frame(width: (min(8, cell.activityQuantity) * 15) / 8, height: 4)
                        }
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(colorScheme == .dark ? .black : .white)
                                    .opacity(progressColor != .yellow ? 0.1 : 0.05)
                            }
                        }
                        .padding(.bottom, 4)
                }
            }
            .opacity(isEnabled ? (cell.isCurrentMonth ? 1 : 0.3) : (cell.isCurrentMonth ? 0.3 : 0.1))
            .contentShape(.rect)
            .clipShape(.circle)
            .if(!isOutsideBounds) { view in
                view.contentShape(.hoverEffect, .circle).hoverEffect(isSelected ? .lift : .highlight)
            }
            .onTapGesture(perform: action)
    }
}

#Preview {
    @Previewable @State var selectedWeek: Date = Date()
    DatePickerContainer(selectedWeek: $selectedWeek)
        .environment(UserSettings.shared)
}
