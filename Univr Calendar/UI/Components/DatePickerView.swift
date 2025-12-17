//
//  DatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI
import UnivrCore

struct DatePickerView: View, Equatable {
    @Environment(UserSettings.self) var settings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.calendar) var calendar
    
    var viewModel = DatePickerCache.shared
    
    @Binding var selection: Date
    @Binding var selectedMonth: Int
    @Binding var blockTabSwipe: Bool
    
    let date: Date
    private let screenSize: CGRect = UIApplication.shared.screenSize

    private var monthName: String { date.getCurrentMonthSymbol(length: .wide) }
    private var year: String { date.yearSymbol }
    private var daysHeader: [String] { Date().getWeekdaySymbols(length: .short) }
    
    static func == (lhs: DatePickerView, rhs: DatePickerView) -> Bool {
        return lhs.date == rhs.date &&
               lhs.selection == rhs.selection &&
               lhs.selectedMonth == rhs.selectedMonth
    }
    
    var body: some View {
        VStack(spacing: 10) {
            headerView
            HStack(spacing: 8) {
                ForEach(daysHeader, id: \.self) { day in
                    Text(day.capitalized)
                        .frame(width: 40, height: 40)
                }
            }
            .opacity(isEnabled ? 1 : 0.3)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
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
                Text(year)
            }
            .opacity(isEnabled ? 1 : 0.3)
            Spacer()
            if today.isInAcademicYear(for: settings.selectedYear) {
                Button("Oggi") {
                    if selection != today && !blockTabSwipe {
                        selection = today
                    }
                }
                .glassIfAvailable()
                .hoverEffect()
            }
        }
        .frame(height: 30)
    }
    
    private func dayCell(for cell: CalendarCell) -> some View {
        let isSelected = calendar.isDate(selection, inSameDayAs: cell.date)
        let isToday = calendar.isDateInToday(cell.date)
        let showSelectionCircle = isSelected
        let isOutsideBounds = cell.date.isOutOfAcademicBounds(for: Int(settings.selectedYear) ?? 0)
        
        return ZStack {
            if showSelectionCircle {
                Circle()
                    .fill(colorScheme == .light ? .black : .white)
                    .frame(width: 40, height: 40)
                    .opacity(isEnabled ? (cell.isCurrentMonth ? 1 : 0.3) : (cell.isCurrentMonth ? 0.3 : 0.1))
            }
            Text(cell.dayNumber)
                .fontWeight(isToday && !showSelectionCircle ? .black : .regular)
                .foregroundStyle(isToday && !showSelectionCircle ? Color.primary : showSelectionCircle ? colorScheme == .light ? .white : .black : .primary)
                .opacity(isEnabled ? (cell.isCurrentMonth ? 1 : 0.3) : (cell.isCurrentMonth ? 0.3 : 0.1))
        }
        .frame(width: 40, height: 40)
        .contentShape(Rectangle())
        .if(!isOutsideBounds) { view in
            view
                .contentShape(.hoverEffect, .circle)
                .hoverEffect(showSelectionCircle ? .lift : .highlight)
        }
        .onTapGesture {
            guard let yearInt = Int(settings.selectedYear), !blockTabSwipe else { return }
            if selection != cell.date && !cell.date.isOutOfAcademicBounds(for: yearInt) {
                selection = cell.date
            }
        }
    }
}

struct DatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedMonth: Int
    @Binding var selectedWeek: Date
    @Binding var blockTabSwipe: Bool
    
    // MARK: - Internal State
    @State private var internalIndex: Int = 0
    @State private var isSyncing: Bool = false
    @State private var isDualMode: Bool = false
    
    @State private var isResizing: Bool = false
    
    private let academicMonths = [10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    var body: some View {
        GeometryReader { proxy in
            let year = Int(settings.selectedYear) ?? Date().year
            
            TabView(selection: $internalIndex) {
                if !isDualMode {
                    ForEach(0..<12, id: \.self) { index in
                        let date = dateForIndex(index, year: year)
                        DatePickerView(
                            selection: $selectedWeek,
                            selectedMonth: $selectedMonth,
                            blockTabSwipe: $blockTabSwipe,
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
                            DatePickerView(
                                selection: $selectedWeek,
                                selectedMonth: $selectedMonth,
                                blockTabSwipe: $blockTabSwipe,
                                date: dateLeft
                            )
                            .equatable()
                            Spacer()
                            DatePickerView(
                                selection: $selectedWeek,
                                selectedMonth: $selectedMonth,
                                blockTabSwipe: $blockTabSwipe,
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
            .onAppear {
                let width = proxy.size.width
                let shouldBeDual = width >= 700
                isDualMode = shouldBeDual
                internalIndex = calculateTargetIndex(for: selectedMonth, isDual: shouldBeDual)
            }
            .onChange(of: proxy.size.width) { _, newWidth in
                let shouldBeDual = newWidth >= 700
                if shouldBeDual != isDualMode {
                    // 1. Attiva il blocco: stiamo cambiando layout, ignora i segnali della TabView
                    isResizing = true
                    
                    // 2. Calcola e applica i nuovi stati
                    let newIndex = calculateTargetIndex(for: selectedMonth, isDual: shouldBeDual)
                    isDualMode = shouldBeDual
                    Task { @MainActor in
                        internalIndex = newIndex
                    }
                    
                    // 3. Rilascia il blocco dopo che la UI si è stabilizzata
                    Task {
                        // Un piccolo ritardo permette alla TabView di inizializzarsi all'indice giusto
                        // senza innescare cambi mese errati.
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                        isResizing = false
                        
                        // 4. Controllo finale: se la view è finita sull'indice sbagliato (race condition), forziamola
                        let correctIndex = calculateTargetIndex(for: selectedMonth, isDual: shouldBeDual)
                        if internalIndex != correctIndex {
                            internalIndex = correctIndex
                        }
                    }
                }
            }
            .onChange(of: internalIndex) { _, newIndex in
                // FIX: Se stiamo ridimensionando o sincronizzando dall'esterno, FERMI.
                guard !isSyncing, !isResizing else { return }
                
                if isDualMode {
                    // Logica Dual Mode: non cambiare mese se siamo già nella pagina giusta
                    let leftIndex = newIndex * 2
                    let rightIndex = leftIndex + 1
                    
                    let leftMonth = leftIndex < academicMonths.count ? academicMonths[leftIndex] : -1
                    let rightMonth = rightIndex < academicMonths.count ? academicMonths[rightIndex] : -1
                    
                    let isSelectionValid = (selectedMonth == leftMonth || selectedMonth == rightMonth)
                    
                    if !isSelectionValid {
                        if leftMonth != -1 {
                            selectedMonth = leftMonth
                        }
                    }
                } else {
                    // Logica Single Mode: corrispondenza diretta
                    if newIndex < academicMonths.count {
                        let newMonth = academicMonths[newIndex]
                        if selectedMonth != newMonth {
                            selectedMonth = newMonth
                        }
                    }
                }
            }
            .onChange(of: selectedMonth) { _, newMonth in
                let targetIndex = calculateTargetIndex(for: newMonth, isDual: isDualMode)
                if internalIndex != targetIndex {
                    isSyncing = true
                    withAnimation {
                        internalIndex = targetIndex
                    }
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        isSyncing = false
                    }
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

#Preview {
    @Previewable @State var selectedMonth: Int = 11
    @Previewable @State var selectedWeek: Date = Date()
    
    DatePickerContainer(selectedMonth: $selectedMonth, selectedWeek: $selectedWeek, blockTabSwipe: .constant(false))
        .environment(UserSettings.shared)
}
