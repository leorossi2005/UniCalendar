//
//  FractionDatePickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/11/25.
//

import SwiftUI

struct FractionDatePickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    @Binding var selectedWeek: Date
    @Binding var loading: Bool
    
    let week: [Date]
    
    let width: CGFloat
    
    var body: some View {
        let itemWidth = (width - 40 - 30) / 7
        
        let dayFontSize = itemWidth * 0.40
        let weekdayFontSize = itemWidth * 0.35
        
        HStack(spacing: 5) {
            ForEach(week, id: \.self) { day in
                if let year = Int(settings.selectedYear) {
                    let isOutOfBounds = (day.month == 9 && day.year == year) || (day.month == 10 && day.year == year + 1)
                    Button(action: {
                        if !isOutOfBounds {
                            withAnimation {
                                selectedWeek = day
                            }
                        }
                    }) {
                        VStack {
                            Text("\(day.day)")
                                .font(.system(size: dayFontSize))
                                .bold()
                                .foregroundStyle(day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                            Spacer().frame(height: 3)
                            Text(day.getCurrentWeekdaySymbol(length: .short))
                                .font(.system(size: weekdayFontSize))
                                .foregroundStyle(day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? colorScheme == .light ? .white : .black : colorScheme == .light ? .black : .white)
                        }
                        .frame(width: itemWidth, height: itemWidth * 1.35)
                        .background(Color(white: colorScheme == .light ? 0 : 1, opacity: day.getString(format: "dd-MM-yyyy") == selectedWeek.getString(format: "dd-MM-yyyy") ? 1 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: itemWidth / 2.5, style: .continuous))
                    }
                    .opacity(isOutOfBounds || loading ? 0.3 : 1)
                    .disabled(isOutOfBounds)
                }
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

    @State private var academicWeeks: [[Date]] = []
    
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
            
            let currentHeight = proxy.size.height
            let screenHeight = UIScreen.main.bounds.height
            
            let smallHeight = screenHeight * 0.15
            
            let fadeRange: CGFloat = screenHeight * 0.05
            
            let dynamicOpacity = 1.0 - (Double(currentHeight - smallHeight) / Double(fadeRange))
        
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(academicWeeks, id: \.self) { week in
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
                                                        if let currentId = week.first?.getString(format: "dd-MM-yyyy"), selectionFraction != currentId {
                                                            selectionFraction = currentId
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .id(week.first?.getString(format: "dd-MM-yyyy"))
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
            .onChange(of: settings.selectedYear) {
                reloadWeeksAndSelection()
            }
            .onChange(of: selectedWeek) {
                if selectionFraction != targetId {
                    withAnimation(.easeInOut(duration: 0)) {
                        selectionFraction = targetId
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
            .opacity(min(max(dynamicOpacity, 0), 1))
            .allowsHitTesting(selectedDetent == .fraction(0.15))
        }
    }
    
    func reloadWeeksAndSelection() {
        let newWeeks = generateAcademicWeeks(selectedYear: settings.selectedYear)
        
        if academicWeeks != newWeeks {
            academicWeeks = newWeeks
        }
        
        if selectionFraction != targetId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(nil) {
                    selectionFraction = targetId
                }
            }
        }
    }
    
    func generateAcademicWeeks(selectedYear: String) -> [[Date]] {
        guard let yearInt = Int(selectedYear) else { return [] }
        
        let startAcademicYear = Date(year: yearInt, month: 10, day: 1)
        let endAcademicYear = Date(year: yearInt + 1, month: 9, day: 30)
        
        guard var currentWeekStart = startAcademicYear.startOfWeek() else { return [] }
        
        var allWeeks: [[Date]] = []
        
        while currentWeekStart <= endAcademicYear {
            let weekOfDates = currentWeekStart.weekDates()
            allWeeks.append(weekOfDates)
            
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
        .environment(UserSettings.shared)
        .sheet(isPresented: .constant(true)) {
            FractionDatePickerContainer(selectedWeek: $selectedWeek, loading: $loading, selectionFraction: $selectionFraction, selectedDetent: $selectedDetent)
                .presentationDetents([.fraction(0.15)])
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .sheetDesign(transition)
        }
}
