//
//  extensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/10/25.
//

import SwiftUI

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
    // Restituisce la data del primo giorno della settimana (esempio: lunedì)
    func startOfWeek(using calendar: Foundation.Calendar = .current) -> Date? {
        let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: comp)
    }

    // Restituisce l'array dei 7 giorni della settimana
    func weekDates(using calendar: Foundation.Calendar = .current) -> [Date] {
        guard let start = self.startOfWeek(using: calendar) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
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
}
