//
//  Extensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/10/25.
//

import Foundation

enum CalendarSymbolLength: String {
    case full
    case short
    case veryShort
}

enum NewDateComponents: String {
    case day
    case month
    case year
}

extension Date {
    nonisolated init(year: Int, month: Int, day: Int) {
        let timeInterval: TimeInterval = Calendars.calendar.date(from: DateComponents(year: year, month: month, day: day))?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        
        self.init(timeIntervalSince1970: timeInterval)
    }
    
    // Restituisce la data del primo giorno della settimana (esempio: lunedì)
    func startOfWeek(using calendar: Foundation.Calendar = .current) -> Date? {
        let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: comp)
    }
    
    func startWeekdaySymbolOfMonth(length: CalendarSymbolLength) -> String {
        Date(year: year, month: month, day: 1).getCurrentWeekdaySymbol(length: length)
    }

    // Restituisce l'array dei 7 giorni della settimana
    func weekDates(using calendar: Foundation.Calendar = .current) -> [Date] {
        guard let start = startOfWeek(using: calendar) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
    
    func getString(format: String) -> String {
        if format == "dd-MM-yyyy" {
            return Formatters.displayDate.string(from: self)
        } else if format == "HH:mm" {
            return Formatters.hourMinute.string(from: self)
        }
        
        let formatter = FormatterCache.getFormatter(for: format)
        return formatter.string(from: self)
    }
    
    func getCurrentMonthSymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Calendars.calendar.monthSymbols[month - 1].capitalized
            case .short:
                Calendars.calendar.shortMonthSymbols[month - 1].capitalized
            case .veryShort:
                Calendars.calendar.veryShortMonthSymbols[month - 1].capitalized
        }
    }
    
    func getCurrentWeekdaySymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Calendars.calendar.weekdaySymbols[weekday - 1].capitalized
            case .short:
                Calendars.calendar.shortWeekdaySymbols[weekday - 1].capitalized
            case .veryShort:
                Calendars.calendar.veryShortWeekdaySymbols[weekday - 1].capitalized
        }
    }
    
    func getWeekdaySymbols(length: CalendarSymbolLength) -> [String] {
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
    
    func set(type: NewDateComponents, value: Int) -> Date {
        switch type {
            case .day:
                Date(year: year, month: month, day: value)
            case .month:
                Date(year: year, month: value, day: day)
            case .year:
                Date(year: value, month: month, day: day)
        }
    }
    
    func add(type: Calendar.Component, value: Int) -> Date {
        Calendars.calendar.date(byAdding: type, value: value, to: self) ?? self
    }
    
    func remove(type: Calendar.Component, value: Int) -> Date {
        Calendars.calendar.date(byAdding: type, value: -value, to: self) ?? self
    }
    
    var minute: Int {
        Calendars.calendar.component(.minute, from: self)
    }
    
    var hour: Int {
        Calendars.calendar.component(.hour, from: self)
    }
    
    nonisolated var day: Int {
        Calendars.calendar.component(.day, from: self)
    }
    
    nonisolated var month: Int {
        Calendars.calendar.component(.month, from: self)
    }
    
    nonisolated var year: Int {
        Calendars.calendar.component(.year, from: self)
    }
    
    var yearSymbol: String {
        String(year)
    }
    
    var weekday: Int {
        Calendars.calendar.component(.weekday, from: self)
    }
}

extension String {
    nonisolated func date(format: String) -> Date? {
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
