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
import CustomSheet

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.calendar) var calendar
    
    @Binding var selection: Date
    let week: [FractionDay]
    let width: CGFloat
    let index: Int
    var focus: AccessibilityFocusState<Int?>.Binding
    let goToNextWeek: () -> Void
    let goToPreviousWeek: () -> Void
    
    private var focusTargetID: FractionDay.ID? {
        week.first(where: { calendar.isDate($0.date, inSameDayAs: selection) && !$0.isOutOfBounds })?.id
            ?? week.first(where: { !$0.isOutOfBounds })?.id
    }
        
    private var itemWidth: CGFloat { (min(width, 500) - 70) / 7 }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(week) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selection)
                
                Button {
                    if !day.isOutOfBounds { selection = day.date }
                } label: {
                    VStack(spacing: 3) {
                        Text(day.dayNumber)
                            .font(.system(size: itemWidth * 0.40).bold())
                        Text(day.weekdayString)
                            .font(.system(size: itemWidth * 0.35))
                    }
                    .foregroundStyle(isSelected ? (colorScheme == .light ? .white : .black) : .primary)
                    .frame(width: itemWidth, height: itemWidth * 1.35)
                    .background(Color.primary.opacity(isSelected ? 1 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                    .opacity(day.isOutOfBounds || !isEnabled ? 0.3 : 1)
                }
                .disabled(day.isOutOfBounds)
                .if(!day.isOutOfBounds) { view in
                    view
                        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                        .hoverEffect(.lift)
                }
                .accessibilityElement(children: .combine)
                .accessibilityHidden(day.isOutOfBounds)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .if(day.id == focusTargetID) { view in
                    view.accessibilityFocused(focus, equals: index)
                }
                .accessibilityLabel(dayAccessibilityLabel(for: day.date))
                .accessibilityAction(named: "Settimana successiva") {
                    goToNextWeek()
                }
                .accessibilityAction(named: "Settimana precedente") {
                    goToPreviousWeek()
                }
            }
        }
        .frame(maxWidth: 500, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .ignoresSafeArea()
    }
    
    private func dayAccessibilityLabel(for date: Date) -> Text {
        let formattedDate = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        if calendar.isDateInToday(date) {
            return Text("Oggi, \(formattedDate)")
        } else {
            return Text(formattedDate)
        }
    }
}

struct FractionDatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    var viewModel = DatePickerCache.shared
    @Binding var selectedWeek: Date
    
    @State private var internalIndex: Int = 0
    
    @AccessibilityFocusState private var focusedPage: Int?
    
    var body: some View {
        GeometryReader { proxy in
            TabView(selection: Binding(
                get: { internalIndex },
                set: { newIndex in
                    shiftWeek(diff: newIndex - internalIndex)
                    internalIndex = newIndex
                }
            )) {
                ForEach(0..<viewModel.academicWeeks.count, id: \.self) { index in
                    FractionDatePickerView(selection: $selectedWeek, week: viewModel.academicWeeks[index], width: proxy.size.width, index: index, focus: $focusedPage, goToNextWeek: goToNextWeek, goToPreviousWeek: goToPreviousWeek)
                        .tag(index)
                        .accessibilitySortPriority(1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .task(id: settings.selectedYear) {
                await viewModel.generateAcademicWeeks(selectedYear: settings.selectedYear)
                internalIndex = targetIndex(for: selectedWeek)
            }
            .onChange(of: selectedWeek) { _, newSelection in
                if internalIndex < viewModel.academicWeeks.count,
                   !viewModel.academicWeeks[internalIndex].contains(where: { Calendar.current.isDate($0.date, inSameDayAs: newSelection) }) {
                    internalIndex = targetIndex(for: newSelection)
                }
            }
            // MARK: - Pulsanti accessibili in Overlay
            .overlay(alignment: .leading) {
                Button {
                    goToPreviousWeek()
                } label: {
                    Color.clear
                        .frame(width: 44, height: proxy.size.height)
                }
                .allowsHitTesting(false)
                .disabled(internalIndex == 0)
                .accessibilityLabel("Settimana precedente")
                .accessibilityHint(internalIndex > 0 ? "Tocca due volte per andare alla settimana precedente" : "")
                .accessibilitySortPriority(2)
            }
            .overlay(alignment: .trailing) {
                Button {
                    goToNextWeek()
                } label: {
                    Color.clear
                        .frame(width: 44, height: proxy.size.height)
                }
                .allowsHitTesting(false)
                .disabled(internalIndex >= viewModel.academicWeeks.count - 1)
                .accessibilityLabel("Settimana successiva")
                .accessibilityHint(internalIndex < viewModel.academicWeeks.count - 1 ? "Tocca due volte per andare alla settimana successiva" : "")
                .accessibilitySortPriority(0)
            }
        }
    }
    
    // MARK: - Helper di navigazione
    private func goToPreviousWeek() {
        guard internalIndex > 0 else { return }
        internalIndex -= 1
        moveAccessibilityFocus(to: internalIndex)
    }

    private func goToNextWeek() {
        guard internalIndex < viewModel.academicWeeks.count - 1 else { return }
        internalIndex += 1
        moveAccessibilityFocus(to: internalIndex)
    }

    private func moveAccessibilityFocus(to index: Int) {
        Task { @MainActor in
            focusedPage = nil
            try? await Task.sleep(for: .milliseconds(150))
            focusedPage = index
        }
    }
    
    private func shiftWeek(diff: Int) {
        guard diff != 0, let year = Int(settings.selectedYear) else { return }
        
        let shift = abs(diff) * 7
        let newDate = diff > 0 ? selectedWeek.add(type: .day, value: shift) : selectedWeek.remove(type: .day, value: shift)
        
        let minDate = Date(year: year, month: 10, day: 1)
        let maxDate = Date(year: year + 1, month: 9, day: 30)
        
        selectedWeek = max(minDate, min(newDate, maxDate))
    }
    
    private func targetIndex(for date: Date) -> Int {
        viewModel.academicWeeks.firstIndex { week in
            week.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
        } ?? 0
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
