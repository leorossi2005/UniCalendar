//
//  FractionDatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
//

import SwiftUI
import UnivrCore

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.calendar) var calendar
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    
    let week: [FractionDay]
    let width: CGFloat
        
    private var itemWidth: CGFloat {
        (min(width, 500) - 70) / 7
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(week) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selectedWeek)
                
                Button {
                    if !day.isOutOfBounds {
                        withAnimation {
                            selectedWeek = day.date
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
        .opacity(day.isOutOfBounds || loading ? 0.3 : 1)
    }
}

struct FractionDatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    var viewModel = DatePickerCache.shared
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    @Binding var selectionFraction: String?

    @State private var isSyncingSelectionFraction: Bool = false
    @State private var lastIsDualMode: Bool? = nil
    
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        let screenWidth = containerWidth
        let isDualMode = screenWidth >= 1000
        
        TabView(selection: $selectionFraction) {
            if !isDualMode {
                ForEach(viewModel.academicWeeks, id: \.self) { week in
                    FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: week, width: screenWidth)
                        .tag(week.first?.id)
                }
            } else {
                ForEach(Array(stride(from: 0, to: viewModel.academicWeeks.count, by: 2)), id: \.self) { index in
                    let isLast = index != viewModel.academicWeeks.count - 1
                    HStack {
                        Spacer()
                        FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: viewModel.academicWeeks[index], width: screenWidth)
                        Spacer()
                        FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: isLast ? viewModel.academicWeeks[index + 1] : viewModel.additionalWeek, width: screenWidth)
                        Spacer()
                    }
                    .tag(viewModel.academicWeeks[index].first?.id)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) { _, newWidth in
                        
                        if containerWidth != newWidth {
                            containerWidth = newWidth
                        }
                    }
            }
        )
        .task(id: settings.selectedYear) {
            await reloadWeeksAndSelection(containerWidth: screenWidth)
        }
        .onAppear {
            if lastIsDualMode == nil {
                lastIsDualMode = isDualMode
            }
        }
        .onChange(of: screenWidth) { _, newWidth in
            let newIsDual = newWidth >= 1000
            let didCrossThreshold = (lastIsDualMode != nil && lastIsDualMode != newIsDual)
            lastIsDualMode = newIsDual
            
            guard didCrossThreshold else { return }
            guard !viewModel.academicWeeks.isEmpty else { return }
            
            let newTarget = targetId(containerWidth: screenWidth)
            if selectionFraction != newTarget {
                Task { @MainActor in
                    isSyncingSelectionFraction = true
                    withAnimation(nil) {
                        selectionFraction = newTarget
                    }
                    await Task.yield()
                    isSyncingSelectionFraction = false
                }
            }
        }
        .onChange(of: selectedWeek) {
            let newTarget = targetId(containerWidth: screenWidth)
            if selectionFraction != newTarget {
                Task { @MainActor in
                    isSyncingSelectionFraction = true
                    withAnimation(nil) {
                        selectionFraction = newTarget
                    }
                    await Task.yield()
                    isSyncingSelectionFraction = false
                }
            }
        }
        .onChange(of: selectionFraction) {
            guard !isSyncingSelectionFraction else { return }
            handleFractionSelectionChange(containerWidth: screenWidth)
        }
    }
    
    // MARK: - Logic
    
    func reloadWeeksAndSelection(containerWidth: CGFloat) async {
        await viewModel.generateAcademicWeeks(selectedYear: settings.selectedYear)
        
        let newTarget = targetId(containerWidth: containerWidth)
        guard selectionFraction != newTarget else { return }
        await MainActor.run {
            isSyncingSelectionFraction = true
            withAnimation(nil) {
                selectionFraction = newTarget
            }
        }
        await Task.yield()
        await MainActor.run { isSyncingSelectionFraction = false }
    }

    private func handleFractionSelectionChange(containerWidth: CGFloat) {
        guard let selectionFraction,
              let currentWeekStart = selectedWeek.weekDates().first?.formatUnivrStyle(),
              selectionFraction != currentWeekStart,
              let newDate = selectionFraction.toDateModern(),
              let yearInt = Int(settings.selectedYear) else { return }

        if containerWidth >= 1000,
           let baseIndex = viewModel.academicWeeks.firstIndex(where: { $0.first?.id == selectionFraction }) {
            let baseId = viewModel.academicWeeks[baseIndex].first?.id
            let nextId = (baseIndex + 1 < viewModel.academicWeeks.count)
                ? viewModel.academicWeeks[baseIndex + 1].first?.id
                : nil

            if currentWeekStart == baseId || currentWeekStart == nextId {
                return
            }
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
    
    private func targetId(containerWidth: CGFloat) -> String {
        let weekStartId = selectedWeek.weekDates().first?.formatUnivrStyle() ?? ""

        guard containerWidth >= 1000 else { return weekStartId }

        guard let index = viewModel.academicWeeks.firstIndex(where: { $0.first?.id == weekStartId }) else {
            return selectionFraction ?? viewModel.academicWeeks.first?.first?.id ?? weekStartId
        }

        let baseIndex = index - (index % 2)
        if baseIndex >= 0, baseIndex < viewModel.academicWeeks.count {
            return viewModel.academicWeeks[baseIndex].first?.id ?? weekStartId
        }

        return weekStartId
    }
}

#Preview {
    @Previewable @Namespace var transition
    @Previewable @State var selectedWeek: Date = Date()
    @Previewable @State var loading: Bool = false
    //@Previewable @State var selectedDetent: PresentationDetent = .fraction(0.15)
    @Previewable @State var selectionFraction: String? = ""
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            FractionDatePickerContainer(selectedWeek: $selectedWeek, loading: $loading, selectionFraction: $selectionFraction)
                .presentationDetents([.fraction(0.15)])
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                //.sheetDesign(transition, sourceID: "", detent: $selectedDetent)
        }
        .environment(UserSettings.shared)
}
