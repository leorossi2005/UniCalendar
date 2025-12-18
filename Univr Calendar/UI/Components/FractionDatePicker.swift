//
//  FractionDatePicker.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
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
                        withAnimation {
                            selection = day.date
                        }
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
        .frame(maxHeight: .infinity)
        .frame(maxWidth: 500)
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
        let newDate: Date
        let difference = abs(newIndex - oldIndex)
        if oldIndex < newIndex {
            newDate = selectedWeek.add(type: .day, value: difference * (isDualMode ? 14 : 7))
        } else {
            newDate = selectedWeek.remove(type: .day, value: difference * (isDualMode ? 14 : 7))
        }
        
        let isLeftOutOfBounds = newDate.month == 9 && newDate.year == yearInt
        let isRightOutOfBounds = (newDate.month == 10 && newDate.year == yearInt + 1)
        
        if isLeftOutOfBounds {
            let limitDateStr = "01-10-\(yearInt)"
            if selectedWeek.formatUnivrStyle() != limitDateStr {
                selectedWeek = limitDateStr.toDateModern() ?? newDate
            }
        } else if isRightOutOfBounds {
            let limitDateStr = "30-09-\(yearInt + 1)"
            if selectedWeek.formatUnivrStyle() != limitDateStr {
                selectedWeek = limitDateStr.toDateModern() ?? newDate
            }
        } else {
            if selectedWeek.formatUnivrStyle() != newDate.formatUnivrStyle() {
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
                //.sheetDesign(transition, sourceID: "", detent: $selectedDetent)
        }
        .environment(UserSettings.shared)
}
