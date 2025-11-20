//
//  Utilities.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

struct Formatters {
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
