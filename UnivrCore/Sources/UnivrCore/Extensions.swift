//
//  Extensions.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 10/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum CalendarSymbolLength: String, Sendable {
    case full, short, veryShort
}

extension Date.ParseStrategy {
    static var univrDate: Date.ParseStrategy {
        Date.ParseStrategy(
            format: "\(day: .twoDigits)-\(month: .twoDigits)-\(year: .extended())",
            timeZone: .autoupdatingCurrent
        )
    }
}

extension Date {
    private var calendar: Calendar { .autoupdatingCurrent }
    
    public init(year: Int, month: Int, day: Int) {
        self = Calendar.autoupdatingCurrent.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
    
    public func formatUnivrStyle() -> String {
        self.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.extended()))
            .replacingOccurrences(of: "/", with: "-")
    }
    
    public func startOfWeek() -> Date? {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }
    
    public func weekDates() -> [Date] {
        guard let start = startOfWeek() else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    
    public func set(type: Calendar.Component, value: Int) -> Date {
        calendar.date(bySetting: type, value: value, of: self) ?? self
    }
    
    public func add(type: Calendar.Component, value: Int) -> Date {
        calendar.date(byAdding: type, value: value, to: self) ?? self
    }
    
    public func remove(type: Calendar.Component, value: Int) -> Date {
        add(type: type, value: -value)
    }
    
    public func getCurrentMonthSymbol(length: Date.FormatStyle.Symbol.Month) -> String {
        self.formatted(.dateTime.month(length)).capitalized
    }
    
    public func startWeekdaySymbolOfMonth(length: Date.FormatStyle.Symbol.Weekday) -> String {
        guard let firstOfMonth = calendar.date(bySetting: .day, value: 1, of: self) else { return "" }
        return firstOfMonth.getCurrentWeekdaySymbol(length: length)
    }
    
    public func getCurrentWeekdaySymbol(length: Date.FormatStyle.Symbol.Weekday) -> String {
        self.formatted(.dateTime.weekday(length)).capitalized
    }
    
    public func getWeekdaySymbols(length: CalendarSymbolLength) -> [String] {
        var symbols = switch length {
            case .full: calendar.weekdaySymbols
            case .short: calendar.shortWeekdaySymbols
            case .veryShort: calendar.veryShortWeekdaySymbols
        }
        
        if let first = symbols.first {
            symbols.append(first)
            symbols.removeFirst()
        }
        
        return symbols.map { $0.capitalized }
    }
    
    public func isOutOfAcademicBounds(for academicYear: Int) -> Bool {
        (month == 9 && year == academicYear) || (month == 10 && year == academicYear + 1)
    }
    
    public func isInAcademicYear(for academicYear: String) -> Bool {
        guard let yearInt = Int(academicYear) else { return false }
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        
        if year == yearInt {
            return month >= 10
        } else if year == yearInt + 1 {
            return month <= 9
        }
        return false
    }
    
    public var minute: Int { calendar.component(.minute, from: self) }
    public var hour: Int { calendar.component(.hour, from: self) }
    public var day: Int { calendar.component(.day, from: self) }
    public var month: Int { calendar.component(.month, from: self) }
    public var year: Int { calendar.component(.year, from: self) }
    public var weekday: Int { calendar.component(.weekday, from: self) }
    public var yearSymbol: String { String(year) }
}

extension String {
    public func toDateModern() -> Date? {
        (try? Date(self, strategy: Date.ParseStrategy.univrDate)) ?? (try? Date(self, strategy: .iso8601))
    }
}

extension Bundle {
    public var appVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        return "v\(version) (\(build))"
    }
    
    public var clearAppVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        return version
    }
}
