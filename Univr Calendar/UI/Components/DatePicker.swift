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
    private var daysHeader: [String] { date.getWeekdaySymbols(length: .short) }
    
    static func == (lhs: DatePicker, rhs: DatePicker) -> Bool {
        if lhs.date != rhs.date { return false }
        
        let lhsIsSelectedMonth = Calendar.current.isDate(lhs.selection, equalTo: lhs.date, toGranularity: .month)
        let rhsIsSelectedMonth = Calendar.current.isDate(rhs.selection, equalTo: rhs.date, toGranularity: .month)
        
        if !lhsIsSelectedMonth && !rhsIsSelectedMonth { return true }
        
        return lhs.selection == rhs.selection
    }
    
    var body: some View {
        VStack(spacing: 10) {
            headerView
            HStack(spacing: spacing) {
                ForEach(daysHeader, id: \.self) { day in
                    Text(day.capitalized)
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .opacity(isEnabled ? 1 : 0.3)
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                if let monthCell = viewModel.monthGrids["\(monthName)-\(date.yearSymbol)"] {
                    ForEach(0..<6, id: \.self) { row in
                        GridRow {
                            ForEach(0..<7, id: \.self) { column in
                                let index = (row * 7) + column
                                if index < monthCell.count {
                                    let cell = monthCell[index]
                                    DayCellView(
                                        cell: cell,
                                        isSelected: calendar.isDate(selection, inSameDayAs: cell.date),
                                        isToday: calendar.isDateInToday(cell.date),
                                        isOutsideBounds: cell.date.isOutOfAcademicBounds(for: Int(settings.selectedYear) ?? 0)
                                    ) {
                                        handleSelection(for: cell)
                                    }
                                }
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
            let today = Date()
            HStack {
                Text(monthName)
                    .fontWeight(.bold)
                Text("•")
                Text(date.yearSymbol)
            }
            .opacity(isEnabled ? 1 : 0.3)
            Spacer()
            if today.isInAcademicYear(for: settings.selectedYear) {
                Button("Oggi") {
                    if selection.formatUnivrStyle() != today.formatUnivrStyle() {
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
    
    private func handleSelection(for cell: CalendarCell) {
        guard let yearInt = Int(settings.selectedYear) else { return }
        if selection != cell.date && !cell.date.isOutOfAcademicBounds(for: yearInt) {
            selection = cell.date
        }
    }
}

struct DatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedWeek: Date
    
    // MARK: - Internal State
    @State private var internalIndex: Int = 0
    @State private var isDualMode: Bool = false
    
    private let academicMonths = [10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let year = Int(settings.selectedYear) ?? selectedWeek.year
            
            TabView(selection: $internalIndex) {
                if !isDualMode {
                    ForEach(0..<12, id: \.self) { index in
                        let date = dateForIndex(index, year: year)
                        DatePicker(
                            selection: $selectedWeek,
                            date: date
                        )
                        .equatable()
                        .tag(index)
                    }
                } else {
                    ForEach(0..<6, id: \.self) { index in
                        let dateLeft = dateForIndex(index * 2, year: year)
                        let dateRight = dateForIndex(index * 2 + 1, year: year)
                        
                        HStack(spacing: 0) {
                            Spacer()
                            DatePicker(
                                selection: $selectedWeek,
                                date: dateLeft
                            )
                            .equatable()
                            Spacer()
                            DatePicker(
                                selection: $selectedWeek,
                                date: dateRight
                            )
                            .equatable()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: CustomSheetDetent.medium.value)
            .id(isDualMode)
            .onAppear {
                isDualMode = width >= 700
                internalIndex = calculateTargetIndex(for: selectedWeek.month, isDual: isDualMode)
            }
            .onChange(of: selectedWeek) { _, newSelection in
                internalIndex = calculateTargetIndex(for: selectedWeek.month, isDual: isDualMode)
            }
            .onChange(of: width) {
                let newIsDualMode = width >= 700
                if isDualMode != newIsDualMode {
                    if newIsDualMode {
                        internalIndex /= 2
                    } else {
                        let newIndex = calculateTargetIndex(for: selectedWeek.month, isDual: newIsDualMode)
                        if newIndex == internalIndex * 2 + 1 {
                            internalIndex = newIndex
                        } else {
                            internalIndex *= 2
                        }
                    }
                    isDualMode = newIsDualMode
                }
            }
            .onChange(of: internalIndex) {
                if GlobalHaptics.shared.state != "selection" {
                    Haptics.play(.selection)
                } else {
                    GlobalHaptics.shared.state = ""
                }
            }
        }
    }
    
    // MARK: - Logic
    private func dateForIndex(_ index: Int, year: Int) -> Date {
        let baseDate = Date(year: year, month: 10, day: 1)
        return baseDate.add(type: .month, value: index)
    }
    
    private func calculateTargetIndex(for month: Int, isDual: Bool) -> Int {
        guard let academicIndex = academicMonths.firstIndex(of: month) else { return 0 }
        return isDual ? academicIndex / 2 : academicIndex
    }
}

// MARK: - Subviews
private struct DayCellView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    let cell: CalendarCell
    let isSelected: Bool
    let isToday: Bool
    let isOutsideBounds: Bool
    let action: () -> ()
    
    var body: some View {
        Text(cell.dayNumber)
            .frame(width: 40, height: 40)
            .fontWeight(fontWeight)
            .foregroundStyle(!isSelected ? Color.primary : colorScheme == .light ? .white : .black)
            .background {
                if isSelected {
                    Circle()
                        .fill(colorScheme == .light ? .black : .white)
                }
            }
            .overlay(alignment: .topTrailing) {
                if cell.hasActivity {
                    Circle()
                        .fill(.red)
                        .frame(width: 5, height: 5)
                }
            }
            .opacity(opacityLevel)
            .contentShape(.rect)
            .if(!isOutsideBounds) { view in
                view
                    .contentShape(.hoverEffect, .circle)
                    .hoverEffect(isSelected ? .lift : .highlight)
            }
            .onTapGesture(perform: action)
    }
    
    // MARK: - Computed Properties per pulizia
    private var opacityLevel: Double {
        if isEnabled { return cell.isCurrentMonth ? 1 : 0.3 }
        return cell.isCurrentMonth ? 0.3 : 0.1
    }
    
    private var fontWeight: Font.Weight {
        (isToday && !isSelected) ? .black : .regular
    }
    
    private var textColor: Color {
        if isToday && !isSelected { return .primary }
        if isSelected { return colorScheme == .light ? .white : .black }
        return .primary
    }
}

#Preview {
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    
    DatePickerContainer(selectedWeek: $selectedWeek)
        .environment(UserSettings.shared)
}
