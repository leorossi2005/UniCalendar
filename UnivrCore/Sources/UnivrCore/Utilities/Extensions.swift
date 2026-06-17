//
//  Extensions.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum CalendarSymbolLength: String, Sendable {
    case full, short, veryShort
}

extension Date {
    private var calendar: Calendar { .autoupdatingCurrent }
    
    public init(year: Int, month: Int, day: Int) {
        self = Calendar.autoupdatingCurrent.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
    
    public func startOfWeek() -> Date? {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }
    
    public func weekDates() -> [Date] {
        guard let start = startOfWeek() else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
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
    
    public func getCurrentWeekdaySymbol(length: Date.FormatStyle.Symbol.Weekday) -> String {
        self.formatted(.dateTime.weekday(length)).capitalized
    }
    
    public func getWeekdaySymbols(length: CalendarSymbolLength) -> [String] {
        let symbols = switch length {
            case .full: calendar.weekdaySymbols
            case .short: calendar.shortWeekdaySymbols
            case .veryShort: calendar.veryShortWeekdaySymbols
        }
        
        let firstWeekdayIndex = calendar.firstWeekday - 1
        let shiftedSymbols = Array(symbols[firstWeekdayIndex...] + symbols[0..<firstWeekdayIndex])
        
        return shiftedSymbols.map { $0.capitalized }
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
    
    public var day: Int { calendar.component(.day, from: self) }
    public var month: Int { calendar.component(.month, from: self) }
    public var year: Int { calendar.component(.year, from: self) }
    public var yearSymbol: String { String(year) }
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
