//
//  DatePickerLogic.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct CalendarCell: Identifiable, Equatable, Sendable {
    public var id: Date { date }
    public let dayNumber: String
    public let isCurrentMonth: Bool
    public var hasActivity: Bool
    public var activityQuantity: Double
    public let date: Date
}

public struct FractionDay: Identifiable, Equatable, Hashable, Sendable {
    public var id: Date { date }
    public let dayNumber: String
    public let weekdayString: String
    public let isOutOfBounds: Bool
    public let date: Date
}

@MainActor
@Observable
public class DatePickerCache {
    public static let shared = DatePickerCache()
    
    private init() {}
    
    public var monthGrids: [String: [CalendarCell]] = [:]
    public var academicWeeks: [[FractionDay]] = []
    public var additionalWeek: [FractionDay] = []
    public var currentYear: String = ""
    
    private var activeDatesCache: [Date: Double] = [:]
    
    public func updateActivities(dates: [Date: Double]) {
        self.activeDatesCache = dates
        print("🔄 Updating Activities in Cache: \(dates.count) items") // DEBUG
        
        let calendar = Calendar.current
        
        for monthKey in monthGrids.keys {
            guard var cells = monthGrids[monthKey] else { continue }
            
            for i in 0..<cells.count {
                let cellNormalizedDate = calendar.startOfDay(for: cells[i].date)
                
                if let quantity = dates[cellNormalizedDate] {
                    cells[i].hasActivity = true
                    cells[i].activityQuantity = quantity
                } else {
                    cells[i].hasActivity = false
                    cells[i].activityQuantity = 0.0
                }
            }
            
            monthGrids[monthKey] = cells
        }
    }
    
    public func generateMonthGrid(for date: Date, monthName: String) async {
        let cacheKey = "\(monthName)-\(date.yearSymbol)"
        guard monthGrids[cacheKey] == nil else { return }
        
        let cells: [CalendarCell] = await Task.detached(priority: .userInitiated) { [activeDatesCache] in
            let calendar = Calendar.autoupdatingCurrent
            
            guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
            let startOfMonth = monthInterval.start
            
            let firstWeekday = calendar.component(.weekday, from: startOfMonth)
            let startOffset = (firstWeekday + 5) % 7
            
            let startDate = calendar.date(byAdding: .day, value: -startOffset, to: startOfMonth) ?? startOfMonth
            
            return (0..<42).compactMap { offset -> CalendarCell? in
                guard let cellDate = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
                
                let normalizedDate = calendar.startOfDay(for: cellDate)
                let isCurrentMonth = calendar.isDate(cellDate, equalTo: startOfMonth, toGranularity: .month)
                let dayValue = calendar.component(.day, from: cellDate)
                
                return CalendarCell(
                    dayNumber: "\(dayValue)",
                    isCurrentMonth: isCurrentMonth,
                    hasActivity: activeDatesCache[normalizedDate] != nil,
                    activityQuantity: activeDatesCache[normalizedDate] ?? 0,
                    date: cellDate
                )
            }
        }.value
        
        self.monthGrids[cacheKey] = cells
    }
    
    public func generateAcademicWeeks(selectedYear: String) async {
        guard currentYear != selectedYear, let yearInt = Int(selectedYear) else { return }
        
        (self.academicWeeks, self.additionalWeek) = await Task.detached(priority: .userInitiated) {
            let startAcademicYear = Date(year: yearInt, month: 10, day: 1)
            let endAcademicYear = Date(year: yearInt + 1, month: 9, day: 30)
            
            guard let initialWeekStart = startAcademicYear.startOfWeek() else { return ([], []) }
            
            var weekStarts = Array(sequence(first: initialWeekStart) { current in
                let next = current.add(type: .weekOfYear, value: 1)
                return next <= endAcademicYear ? next : nil
            })
            
            if let lastStart = weekStarts.last {
                weekStarts.append(lastStart.add(type: .weekOfYear, value: 1))
            }
            
            var allWeeks = weekStarts.map { weekStart -> [FractionDay] in
                weekStart.weekDates().map { date in
                    FractionDay(
                        dayNumber: "\(date.day)",
                        weekdayString: date.getCurrentWeekdaySymbol(length: .abbreviated),
                        isOutOfBounds: date.isOutOfAcademicBounds(for: yearInt),
                        date: date
                    )
                }
            }
            
            let extraWeek = allWeeks.popLast() ?? []
            return (allWeeks, extraWeek)
        }.value
        
        self.currentYear = selectedYear
    }
}

