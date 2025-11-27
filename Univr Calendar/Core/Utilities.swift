//
//  Utilities.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

nonisolated struct Calendars {
    // Formatter per le date complete (es. 10-10-2025)
    static let calendar: Calendar = {
        return Calendar.current
    }()
}

nonisolated struct Formatters {
    // Formatter per le date complete (es. 10-10-2025)
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter
    }()
    
    // Formatter per orari (es. 14:30)
    static let hourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter
    }()
    
    // Formatter standard per il parsing API (se serve)
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        return formatter
    }()
}

nonisolated struct FormatterCache {
    private static var cache: [String: DateFormatter] = [:]
    
    static func getFormatter(for format: String) -> DateFormatter {
        if let formatter = cache[format] {
            return formatter
        }
        let newFormatter = DateFormatter()
        newFormatter.dateFormat = format
        newFormatter.locale = Locale(identifier: "it_IT")
        cache[format] = newFormatter
        return newFormatter
    }
}

struct Stopwatch {
    private var startTime: DispatchTime?
    
    mutating func start() {
        startTime = DispatchTime.now()
    }
    
    /// Ritorna i secondi trascorsi e resetta lo start
    mutating func stop() -> Double {
        guard let startTime else { return 0 }
        let end = DispatchTime.now()
        let nanos = end.uptimeNanoseconds &- startTime.uptimeNanoseconds
        self.startTime = nil
        return Double(nanos) / 1_000_000_000.0
    }
}
