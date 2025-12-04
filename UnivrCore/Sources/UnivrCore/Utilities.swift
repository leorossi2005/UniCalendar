//
//  Utilities.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import Foundation

public nonisolated struct Calendars {
    static var deviceLocale: Locale {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferredIdentifier)
    }

    public static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.locale = deviceLocale
        return calendar
    }()
}

public nonisolated struct Formatters {
    // Formatter per le date complete (es. 10-10-2025)
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
    
    // Formatter per orari (es. 14:30)
    static let hourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
    
    // Formatter standard per il parsing API (se serve)
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

public nonisolated struct FormatterCache {
    private static var cache: [String: DateFormatter] = [:]
    
    static func getFormatter(for format: String) -> DateFormatter {
        if let formatter = cache[format] {
            return formatter
        }
        let newFormatter = DateFormatter()
        newFormatter.dateFormat = format
        newFormatter.locale = .autoupdatingCurrent
        cache[format] = newFormatter
        return newFormatter
    }
}

/// Gestisce la formattazione centralizzata dei nomi delle lezioni
public struct LessonNameFormatter {
    
    // Cache delle Regex per ottimizzare le performance (evita di ricrearle ad ogni chiamata)
    private static let keywordsRegex: NSRegularExpression? = {
        let keywords = ["laboratorio", "teoria", "esercitazioni"]
        // Pattern per trovare le keywords seguite da caratteri non alfabetici
        let pattern = "(?:" + keywords.joined(separator: "|") + ")" + "\\s*[^A-Za-zÀ-ÖØ-Þa-zà-öø-þ]*"
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()
    
    private static let parenthesisRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "\\((.*?)\\)")
    }()
    
    private static let upperCaseRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "\\b[A-ZÀ-ÖØ-Þ]+(?:\\s+[A-ZÀ-ÖØ-Þ]+)*\\b")
    }()
    
    private static let multipleSpacesRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "\\s+")
    }()

    /// Pulisce il nome della materia e estrae i tag rilevanti
    /// - Parameter text: Il nome originale della materia
    /// - Returns: Una tupla contenente il nome pulito e l'array di tag trovati
    public static func format(_ text: String) -> (cleanText: String, tags: [String]) {
        var formattedTxt = text
            .replacingOccurrences(of: "Matricole pari", with: "")
            .replacingOccurrences(of: "Matricole dispari", with: "")
        
        var tags: [String] = []
        
        // 1. Estrazione Keywords (Laboratorio, Teoria, ecc.)
        if let regex = keywordsRegex {
            let nsFormattedTxt = formattedTxt as NSString
            let fullRange = NSRange(location: 0, length: nsFormattedTxt.length)
            
            // Cerchiamo nel testo (la regex è case-insensitive grazie alle opzioni di inizializzazione)
            if let match = regex.firstMatch(in: formattedTxt, range: fullRange) {
                if let rangeToRemove = Range(match.range, in: formattedTxt) {
                    let matchedPart = String(formattedTxt[rangeToRemove])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    tags.append(matchedPart.capitalized)
                    formattedTxt.removeSubrange(rangeToRemove)
                }
            }
        }
        
        // 2. Gestione casi speciali (Letteratura Russa con encoding rotto ??) o Parentesi generiche
        if let regex = parenthesisRegex {
            let nsString = formattedTxt as NSString
            let matches = regex.matches(in: formattedTxt, range: NSRange(location: 0, length: nsString.length))
            
            // Iteriamo al contrario per non invalidare i range quando rimuoviamo testo
            for match in matches.reversed() {
                if let range = Range(match.range, in: formattedTxt) {
                    var content = String(formattedTxt[range])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if formattedTxt.contains("??") {
                        // Logica specifica per Letteratura Russa
                        if content.contains("Letteratura russa") || content.contains("Letteratura e cultura russa") {
                            // Cerca il numero prima della chiusura parentesi (es: "... 2)")
                            let index = content.index(content.endIndex, offsetBy: -2)
                            if index > content.startIndex {
                                let number = content[index]
                                let prefix = content.contains("cultura") ? "Русская литература и культура" : "Русская литература"
                                formattedTxt = "\(prefix) \(number) \(content)"
                            }
                        } else {
                            // Rimuovi parentesi e imposta come testo principale se c'erano ??
                            content.removeFirst()
                            content.removeLast()
                            formattedTxt = content
                        }
                    } else {
                        // Estrazione standard parentesi -> Tag
                        formattedTxt.removeSubrange(range)
                        content.removeFirst()
                        content.removeLast()
                        tags.append(content)
                    }
                }
            }
        }
        
        // 3. Estrazione parti in MAIUSCOLO (es. codici o sigle alla fine)
        if !formattedTxt.contains("??"), let regex = upperCaseRegex {
            let nsString = formattedTxt as NSString
            let matches = regex.matches(in: formattedTxt, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: formattedTxt) {
                    let upperCasePart = String(formattedTxt[range])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if upperCasePart.count >= 5 {
                        // Controllo se ci sono "due punti" subito dopo, nel qual caso potrebbe essere parte del titolo
                        // Es: "MATERIA: Sottotitolo" -> non lo stacchiamo brutalmente se fa parte della struttura
                        let isTitlePrefix = range.upperBound < formattedTxt.endIndex && formattedTxt[range.upperBound...].hasPrefix(":")
                        
                        if isTitlePrefix {
                            // Logica originale: se c'è ':', estende la parte maiuscola per includerlo e la rimuove
                            // Nota: La logica originale era complessa qui. Semplifichiamo mantenendo l'intento:
                            // Se fa parte di un titolo "TITOLO: ...", spesso è meglio lasciarlo o gestirlo diversamente.
                            // Nel tuo codice originale lo rimuovevi e lo mettevi nei tag.
                            
                            // Cerchiamo di replicare la logica originale di "appendere"
                            let nextIndex = formattedTxt.index(range.upperBound, offsetBy: 3, limitedBy: formattedTxt.endIndex) ?? formattedTxt.endIndex
                            let colonRange = range.upperBound..<nextIndex
                            // Questo controllo `contains(":")` su un range di 3 char è un po' fragile,
                            // ma manteniamo la fedeltà al codice originale se funzionava per i tuoi casi.
                            if formattedTxt[colonRange].contains(":") {
                                // Rimuovi anche i due punti e lo spazio dopo
                                formattedTxt.removeSubrange(range.lowerBound..<nextIndex)
                                // Aggiungi ai tag con i due punti? Nel codice originale facevi `upperCasePart.append(...)`
                                // Qui semplifichiamo: rimuoviamo la parte dal nome principale e la mettiamo nei tag.
                                tags.append(upperCasePart)
                            }
                        } else {
                            formattedTxt.removeSubrange(range)
                            tags.append(upperCasePart)
                        }
                    }
                }
            }
        }
        
        // 4. Pulizia spazi doppi generati dalle rimozioni
        if let regex = multipleSpacesRegex {
            let range = NSRange(location: 0, length: formattedTxt.utf16.count)
            formattedTxt = regex.stringByReplacingMatches(in: formattedTxt, options: [], range: range, withTemplate: " ")
        }
        
        return (formattedTxt.trimmingCharacters(in: .whitespacesAndNewlines), tags)
    }
}

public struct Stopwatch {
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
