//
//  Utilities.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

public struct LessonNameFormatter: Sendable {
    nonisolated(unsafe) private static let keywordsRegex = /(?:laboratorio|teoria|esercitazioni)\s*[^A-Za-zÀ-ÖØ-Þa-zà-öø-þ]*/.ignoresCase()
    nonisolated(unsafe) private static let parenthesisRegex = /\((.*?)\)/
    nonisolated(unsafe) private static let upperCaseRegex = /\b[A-ZÀ-ÖØ-Þ]+(?:[A-ZÀ-ÖØ-Þ\s]+)*\b/
    nonisolated(unsafe) private static let multipleSpacesRegex = /\s+/
    
    public static func format(_ text: String) -> (cleanText: String, tags: [String]) {
        var formattedTxt = text
            .replacingOccurrences(of: "Matricole pari", with: "")
            .replacingOccurrences(of: "Matricole dispari", with: "")
        
        var tags: [String] = []
        
        if let match = formattedTxt.firstMatch(of: keywordsRegex) {
            let matchedString = String(formattedTxt[match.range]).trimmingCharacters(in: .whitespacesAndNewlines)
            tags.append(matchedString.capitalized)
            formattedTxt.removeSubrange(match.range)
        }
        
        for match in formattedTxt.matches(of: parenthesisRegex).reversed() {
            let content = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if formattedTxt.contains("??"), let fixedName = fixLiterature(content: content) {
                formattedTxt = fixedName
            } else {
                formattedTxt.removeSubrange(match.range)
                tags.append(content)
            }
        }
        
        if !formattedTxt.contains("??") {
            for match in formattedTxt.matches(of: upperCaseRegex).reversed() {
                let range = match.range
                let upperPart = String(formattedTxt[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if upperPart.count >= 5 {
                    let checkEnd = formattedTxt.index(range.upperBound, offsetBy: 3, limitedBy: formattedTxt.endIndex) ?? formattedTxt.endIndex
                    let nextChars = formattedTxt[range.upperBound..<checkEnd]
                    
                    if nextChars.contains(":") {
                        let extendRange = range.lowerBound..<checkEnd
                        formattedTxt.removeSubrange(extendRange)
                    } else {
                        formattedTxt.removeSubrange(range)
                    }
                    tags.append(upperPart)
                }
            }
        }
        
        formattedTxt.replace(multipleSpacesRegex, with: " ")
        
        return (formattedTxt.trimmingCharacters(in: .whitespacesAndNewlines), tags)
    }
    
    private static func fixLiterature(content: String) -> String? {
        guard let lastChar = content.last, lastChar.isNumber else { return nil }
        let isCulture = content.contains("cultura")
        
        if content.contains("Letteratura russa") {
            let prefix = isCulture ? "Русская литература и культура" : "Русская литература"
            return "\(prefix) \(lastChar) (\(content))"
        } else if content.contains("Letteratura cinese") {
            let prefix = isCulture ? "中国文学与文化" : "中国文学"
            return "\(prefix) \(lastChar) (\(content))"
        }
        
        return nil
    }
}

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

public struct Stopwatch: Sendable {
    private var startTime: UInt64?
    
    public init() {}
    
    public mutating func start() {
        startTime = DispatchTime.now().uptimeNanoseconds
    }
    
    public mutating func stop() -> Double {
        guard let start = startTime else { return 0 }
        let now = DispatchTime.now().uptimeNanoseconds
        self.startTime = nil
        return Double(now - start) / 1_000_000_000.0
    }
}
