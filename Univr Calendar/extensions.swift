//
//  extensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/10/25.
//

import SwiftUI

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

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        switch hexSanitized.count {
        case 6: // RGB (es. "FF5733")
            (r, g, b, a) = (
                Double((rgb >> 16) & 0xFF) / 255.0,
                Double((rgb >> 8) & 0xFF) / 255.0,
                Double(rgb & 0xFF) / 255.0,
                1.0
            )
        case 8: // RGBA (es. "FF5733FF")
            (r, g, b, a) = (
                Double((rgb >> 24) & 0xFF) / 255.0,
                Double((rgb >> 16) & 0xFF) / 255.0,
                Double((rgb >> 8) & 0xFF) / 255.0,
                Double(rgb & 0xFF) / 255.0
            )
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension Date {
    init(year: Int, month: Int, day: Int) {
        let timeInterval: TimeInterval = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        
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
        let formatter = DateFormatter()
        formatter.dateFormat = format // Formato richiesto
        formatter.locale = Locale(identifier: "it_IT") // Opzionale: forza locale italiano
        return formatter.string(from: self)
    }
    
    func getCurrentMonthSymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Foundation.Calendar.current.monthSymbols[month - 1]
            case .short:
                Foundation.Calendar.current.shortMonthSymbols[month - 1]
            case .veryShort:
                Foundation.Calendar.current.veryShortMonthSymbols[month - 1]
        }
    }
    
    func getCurrentWeekdaySymbol(length: CalendarSymbolLength) -> String {
        switch length {
            case .full:
                Foundation.Calendar.current.weekdaySymbols[weekday - 1]
            case .short:
                Foundation.Calendar.current.shortWeekdaySymbols[weekday - 1]
            case .veryShort:
                Foundation.Calendar.current.veryShortWeekdaySymbols[weekday - 1]
        }
    }
    
    func getWeekdaySymbols(length: CalendarSymbolLength) -> [String] {
        switch length {
            case .full:
                var weekdaySymbols: [String] = Foundation.Calendar.current.weekdaySymbols
                weekdaySymbols.append(weekdaySymbols.remove(at: weekdaySymbols.startIndex))
                return weekdaySymbols
            case .short:
                var shortWeekdaySymbols: [String] = Foundation.Calendar.current.shortWeekdaySymbols
                shortWeekdaySymbols.append(shortWeekdaySymbols.remove(at: shortWeekdaySymbols.startIndex))
                return shortWeekdaySymbols
            case .veryShort:
                var verySortWeekdaySymbols: [String] = Foundation.Calendar.current.veryShortWeekdaySymbols
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
        Foundation.Calendar.current.date(byAdding: type, value: value, to: self) ?? self
    }
    
    func remove(type: Calendar.Component, value: Int) -> Date {
        Foundation.Calendar.current.date(byAdding: type, value: -value, to: self) ?? self
    }
    
    var minute: Int {
        Foundation.Calendar.current.component(.minute, from: self)
    }
    
    var hour: Int {
        Foundation.Calendar.current.component(.hour, from: self)
    }
    
    var day: Int {
        Foundation.Calendar.current.component(.day, from: self)
    }
    
    var month: Int {
        Foundation.Calendar.current.component(.month, from: self)
    }
    
    var year: Int {
        Foundation.Calendar.current.component(.year, from: self)
    }
    
    var yearSymbol: String {
        String(year)
    }
    
    var weekday: Int {
        Foundation.Calendar.current.component(.weekday, from: self)
    }
}

extension String {
    func date(format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format // dd = giorno, MM = mese, yyyy = anno
        formatter.locale = Locale(identifier: "en_US_POSIX") // Importante per evitare bug con le impostazioni utente
        formatter.timeZone = .current // O TimeZone(secondsFromGMT: 0) se preferisci UTC

        return formatter.date(from: self)
    }
}

extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension UIApplication {
    /// Ritorna le dimensioni della safe area attuale (se disponibili)
    var safeAreas: UIEdgeInsets {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)
        else {
            return .zero
        }
        return window.safeAreaInsets
    }
    
    var screenSize: CGRect {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)
        else {
            return .init()
        }
        return window.screen.bounds
    }
}

extension View {
    func keyboardPadding(_ value: CGFloat) -> some View {
        self.safeAreaPadding(.bottom, value)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
