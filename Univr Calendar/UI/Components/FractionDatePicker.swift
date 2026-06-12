//
//  FractionDatePicker.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.calendar) var calendar
    
    @Binding var selection: Date
    let week: [FractionDay]
    let width: CGFloat
        
    private var itemWidth: CGFloat {
        (min(width, 500) - 70) / 7
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(week) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selection)
                
                Button {
                    if !day.isOutOfBounds {
                        selection = day.date
                    }
                } label: {
                    dayContent(for: day, isSelected: isSelected)
                }
                .disabled(day.isOutOfBounds)
                .if(!day.isOutOfBounds) { view in
                    view
                        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                        .hoverEffect(.lift)
                }
            }
        }
        .frame(maxWidth: 500, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func dayContent(for day: FractionDay, isSelected: Bool) -> some View {
        let foreground: Color = isSelected ? (colorScheme == .light ? .white : .black) : .primary
        
        VStack(spacing: 3) {
            Text(day.dayNumber)
                .font(.system(size: itemWidth * 0.40))
                .bold()
                .foregroundStyle(foreground)
            Text(day.weekdayString)
                .font(.system(size: itemWidth * 0.35))
                .foregroundStyle(foreground)
        }
        .frame(width: itemWidth, height: itemWidth * 1.35)
        .background(Color.primary.opacity(isSelected ? 1 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
        .opacity(day.isOutOfBounds || !isEnabled ? 0.3 : 1)
    }
}

struct FractionDatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    var viewModel = DatePickerCache.shared
    
    @Binding var selectedWeek: Date
    
    // MARK: - Internal State
    @State private var internalIndex: Int = 0
    @State private var isDualMode: Bool = false
    var indexBinding: Binding<Int> {
        Binding { internalIndex } set: { newIndex in
            handleFractionSelectionChange(oldIndex: internalIndex, newIndex: newIndex)
            internalIndex = newIndex
        }

    }
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            TabView(selection: indexBinding) {
                if !isDualMode {
                    ForEach(0..<viewModel.academicWeeks.count, id: \.self) { index in
                        FractionDatePickerView(selection: $selectedWeek, week: viewModel.academicWeeks[index], width: width)
                            .tag(index)
                    }
                } else {
                    ForEach(0...viewModel.academicWeeks.count / 2, id: \.self) { index in
                        let isLast = index == viewModel.academicWeeks.count / 2
                        HStack {
                            Spacer()
                            FractionDatePickerView(selection: $selectedWeek, week: viewModel.academicWeeks[index * 2], width: width)
                            Spacer()
                            FractionDatePickerView(selection: $selectedWeek, week: isLast ? viewModel.additionalWeek : viewModel.academicWeeks[index * 2 + 1], width: width)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: CustomSheetDetent.small.value)
            .id(isDualMode)
            .task {
                await viewModel.generateAcademicWeeks(selectedYear: settings.selectedYear)
                internalIndex = calculateTargetIndex(for: selectedWeek, isDual: isDualMode)
            }
            .onChange(of: selectedWeek) { _, newSelection in
                let week = viewModel.academicWeeks[isDualMode ? internalIndex * 2 : internalIndex]
                let filtered = week.filter { $0.date.month == newSelection.month && $0.date.day == newSelection.day }
                if filtered.isEmpty {
                    internalIndex = calculateTargetIndex(for: newSelection, isDual: isDualMode)
                }
            }
            .onChange(of: width) {
                let newIsDualMode = width >= 1000
                if isDualMode != newIsDualMode {
                    if newIsDualMode {
                        internalIndex /= 2
                    } else {
                        let newIndex = calculateTargetIndex(for: selectedWeek, isDual: newIsDualMode)
                        if newIndex == internalIndex * 2 + 1 {
                            internalIndex = newIndex
                        } else {
                            internalIndex *= 2
                        }
                    }
                    isDualMode = newIsDualMode
                }
            }
        }
    }
    
    // MARK: - Logic
    private func handleFractionSelectionChange(oldIndex: Int, newIndex: Int) {
        guard let yearInt = Int(settings.selectedYear) else { return }
        
        let difference = abs(newIndex - oldIndex)
        let daysToShift = difference * (isDualMode ? 14 : 7)
        
        let newDate = oldIndex < newIndex
            ? selectedWeek.add(type: .day, value: daysToShift)
            : selectedWeek.remove(type: .day, value: daysToShift)
        
        let minDate = Date(year: yearInt, month: 10, day: 1)
        let maxDate = Date(year: yearInt + 1, month: 9, day: 30)
        
        let calendar = Calendar.current
        
        if newDate < minDate {
            if !calendar.isDate(selectedWeek, inSameDayAs: minDate) {
                selectedWeek = minDate
            }
        } else if newDate > maxDate {
            if !calendar.isDate(selectedWeek, inSameDayAs: maxDate) {
                selectedWeek = maxDate
            }
        } else {
            if !calendar.isDate(selectedWeek, inSameDayAs: newDate) {
                selectedWeek = newDate
            }
        }
    }
    
    private func calculateTargetIndex(for index: Date, isDual: Bool) -> Int {
        let newIndex = viewModel.academicWeeks.firstIndex(where: { week in
            return week.contains(where: { day in
                return day.date.year == index.year && day.date.month == index.month && day.date.day == index.day
            })
        }) ?? 0
        return isDual ? newIndex / 2 : newIndex
    }
}

#Preview {
    @Previewable @Namespace var transition
    @Previewable @State var selectedWeek: Date = Date()
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            FractionDatePickerContainer(selectedWeek: $selectedWeek)
                .presentationDetents([.fraction(0.15)])
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .environment(UserSettings.shared)
}
