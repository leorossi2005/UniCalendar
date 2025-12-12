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
        (width - 70) / 7
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
            }
        }
        .frame(maxHeight: .infinity)
        .padding(20)
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
    @Binding var selectedDetent: PresentationDetent
    
    @State private var canUpdateSelection: Bool = false
    
    private var targetId: String {
        selectedWeek.weekDates().first?.formatUnivrStyle() ?? ""
    }
    
    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
        
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.academicWeeks, id: \.self) { week in
                        FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: week, width: screenWidth)
                            .containerRelativeFrame(.horizontal)
                            .id(week.first?.id)
                            .overlay {
                                if #unavailable(iOS 18.0) {
                                    GeometryReader { geo in
                                        Color.clear
                                            .onChange(of: geo.frame(in: .named("scrollFractionSpace")).minX) { _, newValue in
                                                guard canUpdateSelection, abs(newValue) < 20 else { return }
                                                if let firstID = week.first?.id, selectionFraction != firstID {
                                                    selectionFraction = firstID
                                                }
                                            }
                                    }
                                }
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .coordinateSpace(name: "scrollFractionSpace")
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selectionFraction, anchor: .leading)
            .task(id: settings.selectedYear) {
                await reloadWeeksAndSelection()
            }
            .task {
                canUpdateSelection = true
            }
            .onChange(of: selectedWeek) {
                if selectionFraction != targetId {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.01))
                        withAnimation(nil) {
                            selectionFraction = targetId
                        }
                    }
                }
            }
            .onChange(of: selectionFraction) {
                handleFractionSelectionChange()
            }
        }
    }
    
    func reloadWeeksAndSelection() async {
        selectionFraction = nil
        await viewModel.generateAcademicWeeks(selectedYear: settings.selectedYear)
        
        if selectionFraction != targetId {
            try? await Task.sleep(for: .seconds(0.01))
            withAnimation(nil) {
                selectionFraction = targetId
            }
        }
    }
    
    private func handleFractionSelectionChange() {
        guard let selectionFraction,
              let currentWeekStart = selectedWeek.weekDates().first?.formatUnivrStyle(),
              selectionFraction != currentWeekStart,
              let newDate = selectionFraction.toDateModern(),
              let yearInt = Int(settings.selectedYear) else { return }
        
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
}

#Preview {
    @Previewable @Namespace var transition
    @Previewable @State var selectedWeek: Date = Date()
    @Previewable @State var loading: Bool = false
    @Previewable @State var selectedDetent: PresentationDetent = .fraction(0.15)
    @Previewable @State var selectionFraction: String? = ""
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            FractionDatePickerContainer(selectedWeek: $selectedWeek, loading: $loading, selectionFraction: $selectionFraction, selectedDetent: $selectedDetent)
                .presentationDetents([.fraction(0.15)])
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .sheetDesign(transition, sourceID: "", detent: $selectedDetent)
        }
        .environment(UserSettings.shared)
}
