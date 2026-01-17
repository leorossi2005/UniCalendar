//
//  DatePickerLogic.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//

import Foundation
#if canImport(Observation)
import Observation
#endif

public struct CalendarCell: Identifiable, Equatable, Sendable {
    public var id: Date { date }
    public let dayNumber: String
    public let isCurrentMonth: Bool
    public var hasActivity: Bool
    public var activityQuantity: Double
    public let date: Date
}

public struct FractionDay: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let dayNumber: String
    public let weekdayString: String
    public let isOutOfBounds: Bool
    public let date: Date
}

@MainActor
#if canImport(Observation)
@Observable
#endif
public class DatePickerCache {
    public static let shared = DatePickerCache()
    
    private init() {}
    
    public var monthGrids: [String: [CalendarCell]] = [:]
    public var academicWeeks: [[FractionDay]] = []
    public var additionalWeek: [FractionDay] = []
    public var currentYear: String = ""
    
    private var activeDatesCache: [String: Double] = [:]
    
    public func updateActivities(dates: [String: Double]) {
        self.activeDatesCache = dates
        print("🔄 Updating Activities in Cache: \(dates.count) items") // DEBUG
        
        for (monthKey, cells) in monthGrids {
            monthGrids[monthKey] = cells.map { cell in
                var newCell = cell
                let dateKey = cell.date.formatUnivrStyle()
                
                if let quantity = dates[dateKey] {
                    newCell.hasActivity = true
                    newCell.activityQuantity = quantity
                } else {
                    newCell.hasActivity = false
                    newCell.activityQuantity = 0.0
                }
                
                return newCell
            }
        }
    }
    
    public func generateMonthGrid(for date: Date, monthName: String) async {
        guard monthGrids["\(monthName)-\(date.yearSymbol)"] == nil else { return }
        
        let cells: [CalendarCell] = await Task.detached(priority: .userInitiated) { [activeDatesCache] in
            var newGrid: [CalendarCell] = []
            let calendar = Calendar.autoupdatingCurrent
            
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return newGrid }
            
            let numDays = range.count
            
            let firstWeekday = calendar.component(.weekday, from: startOfMonth)
            let startOffset = (firstWeekday + 5) % 7
            
            let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: startOfMonth)
            let prevMonthRange = prevMonthDate.flatMap { calendar.range(of: .day, in: .month, for: $0) }
            let prevMonthDays = prevMonthRange?.count ?? 30
            
            for i in 0..<42 {
                let cellDate: Date
                let dayValue: Int
                let isCurrentMonth: Bool
                
                if i < startOffset {
                    dayValue = prevMonthDays - (startOffset - i - 1)
                    isCurrentMonth = false
                    cellDate = calendar.date(byAdding: .day, value: -(startOffset - i), to: startOfMonth) ?? date
                } else if i >= startOffset + numDays {
                    dayValue = i - (startOffset + numDays) + 1
                    isCurrentMonth = false
                    
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) {
                        cellDate = calendar.date(byAdding: .day, value: dayValue - 1, to: nextMonth) ?? date
                    } else {
                        cellDate = date
                    }
                } else {
                    dayValue = i - startOffset + 1
                    isCurrentMonth = true
                    cellDate = calendar.date(byAdding: .day, value: dayValue - 1, to: startOfMonth) ?? date
                }
                
                let dateKey = cellDate.formatUnivrStyle()
                
                newGrid.append(CalendarCell(
                    dayNumber: "\(dayValue)",
                    isCurrentMonth: isCurrentMonth,
                    hasActivity: activeDatesCache[dateKey] != nil,
                    activityQuantity: activeDatesCache[dateKey] ?? 0,
                    date: cellDate
                ))
            }
            return newGrid
        }.value
        
        self.monthGrids["\(monthName)-\(date.yearSymbol)"] = cells
    }
    
    public func generateAcademicWeeks(selectedYear: String) async {
        guard currentYear != selectedYear else { return }
        guard let yearInt = Int(selectedYear) else { return }
        
        (self.academicWeeks, self.additionalWeek) = await Task.detached(priority: .userInitiated) {
            let startAcademicYear = Date(year: yearInt, month: 10, day: 1)
            let endAcademicYear = Date(year: yearInt + 1, month: 9, day: 30)
            
            guard var currentWeekStart = startAcademicYear.startOfWeek() else { return ([[FractionDay]](), [FractionDay]()) }
            
            var allWeeks: [[FractionDay]] = []
            
            while currentWeekStart <= endAcademicYear {
                var weekOfDays: [FractionDay] = []
                let weekDates = currentWeekStart.weekDates()
                
                for date in weekDates {
                    let stableID = date.formatUnivrStyle()
                    
                    weekOfDays.append(FractionDay(
                        id: stableID,
                        dayNumber: "\(date.day)",
                        weekdayString: date.getCurrentWeekdaySymbol(length: .abbreviated),
                        isOutOfBounds: date.isOutOfAcademicBounds(for: yearInt),
                        date: date
                    ))
                }
                
                allWeeks.append(weekOfDays)
                currentWeekStart = currentWeekStart.add(type: .weekOfYear, value: 1)
            }
            
            var weekOfDays: [FractionDay] = []
            let weekDates = currentWeekStart.weekDates()
            
            for date in weekDates {
                let stableID = date.formatUnivrStyle()
                
                weekOfDays.append(FractionDay(
                    id: stableID,
                    dayNumber: "\(date.day)",
                    weekdayString: date.getCurrentWeekdaySymbol(length: .abbreviated),
                    isOutOfBounds: date.isOutOfAcademicBounds(for: yearInt),
                    date: date
                ))
            }
            
            return (allWeeks, weekOfDays)
        }.value
        
        self.currentYear = selectedYear
    }
}

