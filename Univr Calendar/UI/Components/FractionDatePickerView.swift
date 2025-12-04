//
//  FractionDatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
//

import SwiftUI
import UnivrCore

@Observable
class FractionDatePickerViewModel {
    static let shared = FractionDatePickerViewModel()
    
    var academicWeeks: [[FractionDay]] = []
    var currentYear: String = ""
}

struct FractionDay: Identifiable, Equatable, Hashable {
    let id: String // ID Stabile generato una volta sola
    let date: Date
    let dayNumber: String      // Es: "12" (Calcolato una volta)
    let weekdayString: String  // Es: "LUN" (Calcolato una volta)
    let isOutOfBounds: Bool    // Se il giorno è fuori dall'anno accademico (Calcolato una volta)
}

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    
    let week: [FractionDay]
    let width: CGFloat
    
    private var itemWidth: CGFloat {
        (width - 40 - 30) / 7
    }
    private var dayFontSize: CGFloat {
        itemWidth * 0.40
    }
    private var weekdayFontSize: CGFloat {
        itemWidth * 0.35
    }
    
    private let calendar = Calendars.calendar
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(week) { day in
                let isSelected = calendar.isDate(day.date, inSameDayAs: selectedWeek)
                
                Button(action: {
                    if !day.isOutOfBounds {
                        withAnimation {
                            selectedWeek = day.date
                        }
                    }
                }) {
                    VStack {
                        Text("\(day.dayNumber)")
                            .font(.system(size: dayFontSize))
                            .bold()
                            .foregroundStyle(isSelected ? (colorScheme == .light ? .white : .black) : (colorScheme == .light ? .black : .white))
                        Spacer().frame(height: 3)
                        Text(day.weekdayString)
                            .font(.system(size: weekdayFontSize))
                            .foregroundStyle(isSelected ? (colorScheme == .light ? .white : .black) : (colorScheme == .light ? .black : .white))
                    }
                    .frame(width: itemWidth, height: itemWidth * 1.35)
                    .background(Color(white: colorScheme == .light ? 0 : 1, opacity: isSelected ? 1 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                }
                .opacity(day.isOutOfBounds || loading ? 0.3 : 1)
                .disabled(day.isOutOfBounds)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(20)
        .ignoresSafeArea()
    }
}

struct FractionDatePickerContainer: View {
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    @Binding var selectionFraction: String?
    @Binding var selectedDetent: PresentationDetent
    
    @State var viewModel = FractionDatePickerViewModel.shared
    
    @State private var canUpdateSelection: Bool = false
    
    private var targetId: String {
        if let day = selectedWeek.weekDates().first {
            return day.getString(format: "dd-MM-yyyy")
        } else {
            return ""
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
        
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.academicWeeks, id: \.self) { week in
                        FractionDatePickerView(selectedWeek: $selectedWeek, loading: $loading, week: week, width: screenWidth)
                            .containerRelativeFrame(.horizontal)
                            .overlay {
                                if #available(iOS 17, *) {
                                    if #unavailable(iOS 18.0) {
                                        GeometryReader { proxy in
                                            Color.clear
                                                .onChange(of: proxy.frame(in: .named("scrollFractionSpace")).minX) { oldValue, newValue in
                                                    guard canUpdateSelection else { return }
                        
                                                    if abs(newValue) < 20 {
                                                        if let firstDay = week.first, selectionFraction != firstDay.id {
                                                            selectionFraction = firstDay.id
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .id(week.first?.id)
                    }
                }
                .scrollTargetLayout()
            }
            .coordinateSpace(name: "scrollFractionSpace")
            .onAppear {
                reloadWeeksAndSelection()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canUpdateSelection = true
                }
            }
            .onChange(of: selectedWeek) {
                if viewModel.currentYear != settings.selectedYear {
                    reloadWeeksAndSelection()
                } else if selectionFraction != targetId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        withAnimation(nil) {
                            selectionFraction = targetId
                        }
                    }
                }
            }
            .onChange(of: selectionFraction) {
                handleFractionSelectionChange()
            }
            .id(settings.selectedCourse + settings.selectedYear + settings.selectedAcademicYear + settings.matricola)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never, axes: .horizontal)
            .scrollPosition(id: $selectionFraction, anchor: .leading)
        }
    }
    
    func reloadWeeksAndSelection() {
        selectionFraction = nil
        
        if viewModel.academicWeeks.isEmpty || viewModel.currentYear != settings.selectedYear {
            let newWeeks = generateAcademicWeeks(selectedYear: settings.selectedYear)
            
            if viewModel.academicWeeks != newWeeks {
                viewModel.academicWeeks = newWeeks
                viewModel.currentYear = settings.selectedYear
            }
        }
        
        if selectionFraction != targetId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(nil) {
                    selectionFraction = targetId
                }
            }
        }
    }
    
    func generateAcademicWeeks(selectedYear: String) -> [[FractionDay]] {
        guard let yearInt = Int(selectedYear) else { return [] }
        
        let startAcademicYear = Date(year: yearInt, month: 10, day: 1)
        let endAcademicYear = Date(year: yearInt + 1, month: 9, day: 30)
        
        guard var currentWeekStart = startAcademicYear.startOfWeek() else { return [] }
        
        var allWeeks: [[FractionDay]] = []
        
        while currentWeekStart <= endAcademicYear {
            var weekOfDays: [FractionDay] = []
            let weekDates = currentWeekStart.weekDates()
            
            for date in weekDates {
                let isOutOfBounds = (date.month == 9 && date.year == yearInt) || (date.month == 10 && date.year == yearInt + 1)
                
                let stableID = date.getString(format: "dd-MM-yyyy")
                
                weekOfDays.append(FractionDay(
                    id: stableID,
                    date: date,
                    dayNumber: "\(date.day)",
                    weekdayString: date.getCurrentWeekdaySymbol(length: .short),
                    isOutOfBounds: isOutOfBounds
                ))
            }
            
            allWeeks.append(weekOfDays)
            currentWeekStart = currentWeekStart.add(type: .weekOfYear, value: 1)
        }
        
        return allWeeks
    }
    
    private func handleFractionSelectionChange() {
        guard let selectionFraction, let currentWeekStart = selectedWeek.weekDates().first?.getString(format: "dd-MM-yyyy") else { return }
        
        if selectionFraction != currentWeekStart {
            guard let newDate = selectionFraction.date(format: "dd-MM-yyyy"),
                  let yearInt = Int(settings.selectedYear) else { return }
            
            let isLeftOutOfBounds = newDate.month == 9 && newDate.year == yearInt
            let isRightOutOfBounds = (newDate.month == 10 && newDate.year == yearInt + 1)
            
            if isLeftOutOfBounds {
                if selectedWeek.getString(format: "dd-MM-yyyy") != "01-10-\(yearInt)" {
                    selectedWeek = "01-10-\(yearInt)".date(format: "dd-MM-yyyy") ?? newDate
                }
            } else if isRightOutOfBounds {
                if selectedWeek.getString(format: "dd-MM-yyyy") != "30-09-\(yearInt + 1)" {
                    selectedWeek = "30-09-\(yearInt + 1)".date(format: "dd-MM-yyyy") ?? newDate
                }
            } else {
                if selectedWeek.getString(format: "dd-MM-yyyy") != newDate.getString(format: "dd-MM-yyyy") {
                    selectedWeek = newDate
                }
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
                .sheetDesign(transition, detent: $selectedDetent)
        }
        .environment(UserSettings.shared)
}
