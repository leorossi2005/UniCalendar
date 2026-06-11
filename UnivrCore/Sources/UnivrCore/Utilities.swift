//
//  Utilities.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 19/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct HexColorParser: Sendable {
    public struct RGBComponents: Sendable {
        public let red: Double
        public let green: Double
        public let blue: Double
        public let opacity: Double
        
        public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.opacity = opacity
        }
    }
    
    public static func parse(_ hex: String) -> RGBComponents? {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        guard let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        
        switch hexSanitized.count {
        case 6:
            return RGBComponents(
                red: Double((rgb >> 16) & 0xFF) / 255,
                green: Double((rgb >> 8) & 0xFF) / 255,
                blue: Double(rgb & 0xFF) / 255
            )
        case 8:
            return RGBComponents(
                red: Double((rgb >> 24) & 0xFF) / 255,
                green: Double((rgb >> 16) & 0xFF) / 255,
                blue: Double((rgb >> 8) & 0xFF) / 255,
                opacity: Double(rgb & 0xFF) / 255
            )
        default:
            return nil
        }
    }
}
