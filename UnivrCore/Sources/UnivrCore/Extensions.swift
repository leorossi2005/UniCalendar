//
//  Extensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/10/25.
//

import Foundation

public enum CalendarSymbolLength: String {
    case full
    case short
    case veryShort
}

public enum NewDateComponents: String {
    case day
    case month
    case year
}

extension Date {
    public nonisolated init(year: Int, month: Int, day: Int) {
        let timeInterval: TimeInterval = Calendars.calendar.date(from: DateComponents(year: year, month: month, day: day))?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        
        self.init(timeIntervalSince1970: timeInterval)
    }
    
    // Restituisce la data del primo giorno della settimana (esempio: lunedì)
    public func startOfWeek(using calendar: Foundation.Calendar = .current) -> Date? {
        let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: comp)
    }
    
    public func startWeekdaySymbolOfMonth(length: CalendarSymbolLength) -> String {
        Date(year: year, month: month, day: 1).getCurrentWeekdaySymbol(length: length)
    }

    // Restituisce l'array dei 7 giorni della settimana
    public func weekDates(using calendar: Foundation.Calendar = .current) -> [Date] {
        guard let start = startOfWeek(using: calendar) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
    
    public func getString(format: String) -> String {
        if format == "dd-MM-yyyy" {
            return Formatters.displayDate.string(from: self)
        } else if format == "HH:mm" {
            return Formatters.hourMinute.string(from: self)
        }
        
        let formatter = FormatterCache.getFormatter(for: format)
        return formatter.string(from: self)
    }
    
    public func getCurrentMonthSymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Calendars.calendar.monthSymbols[month - 1].capitalized
            case .short:
                Calendars.calendar.shortMonthSymbols[month - 1].capitalized
            case .veryShort:
                Calendars.calendar.veryShortMonthSymbols[month - 1].capitalized
        }
    }
    
    public func getCurrentWeekdaySymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Calendars.calendar.weekdaySymbols[weekday - 1].capitalized
            case .short:
                Calendars.calendar.shortWeekdaySymbols[weekday - 1].capitalized
            case .veryShort:
                Calendars.calendar.veryShortWeekdaySymbols[weekday - 1].capitalized
        }
    }
    
    public func getWeekdaySymbols(length: CalendarSymbolLength) -> [String] {
        switch length {
            case .full:
                var weekdaySymbols: [String] = Calendars.calendar.weekdaySymbols
                weekdaySymbols.append(weekdaySymbols.remove(at: weekdaySymbols.startIndex))
                return weekdaySymbols
            case .short:
                var shortWeekdaySymbols: [String] = Calendars.calendar.shortWeekdaySymbols
                shortWeekdaySymbols.append(shortWeekdaySymbols.remove(at: shortWeekdaySymbols.startIndex))
                return shortWeekdaySymbols
            case .veryShort:
                var verySortWeekdaySymbols: [String] = Calendars.calendar.veryShortWeekdaySymbols
                verySortWeekdaySymbols.append(verySortWeekdaySymbols.remove(at: verySortWeekdaySymbols.startIndex))
                return verySortWeekdaySymbols
        }
        
    }
    
    public func set(type: NewDateComponents, value: Int) -> Date {
        switch type {
            case .day:
                Date(year: year, month: month, day: value)
            case .month:
                Date(year: year, month: value, day: day)
            case .year:
                Date(year: value, month: month, day: day)
        }
    }
    
    public func add(type: Calendar.Component, value: Int) -> Date {
        Calendars.calendar.date(byAdding: type, value: value, to: self) ?? self
    }
    
    public func remove(type: Calendar.Component, value: Int) -> Date {
        Calendars.calendar.date(byAdding: type, value: -value, to: self) ?? self
    }
    
    public var minute: Int {
        Calendars.calendar.component(.minute, from: self)
    }
    
    public var hour: Int {
        Calendars.calendar.component(.hour, from: self)
    }
    
    public nonisolated var day: Int {
        Calendars.calendar.component(.day, from: self)
    }
    
    public nonisolated var month: Int {
        Calendars.calendar.component(.month, from: self)
    }
    
    public nonisolated var year: Int {
        Calendars.calendar.component(.year, from: self)
    }
    
    public var yearSymbol: String {
        String(year)
    }
    
    public var weekday: Int {
        Calendars.calendar.component(.weekday, from: self)
    }
}

extension String {
    public nonisolated func date(format: String) -> Date? {
        if format == "dd-MM-yyyy" {
            return Formatters.displayDate.date(from: self)
        } else if format == "HH:mm" {
            return Formatters.hourMinute.date(from: self)
        }
        
        // Fallback
        let formatter = FormatterCache.getFormatter(for: format)
        return formatter.date(from: self)
    }
}
