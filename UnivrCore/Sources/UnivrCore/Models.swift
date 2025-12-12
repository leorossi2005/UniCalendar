//
//  Models.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

private extension KeyedDecodingContainer {
    func decodeOrEmpty(_ key: Key) throws -> String {
        (try decodeIfPresent(String.self, forKey: key)) ?? ""
    }
}

// MARK: Year struct
public struct Year: Encodable, Decodable, Sendable, Equatable {
    public let label: String
    public let valore: String
}

// MARK: Lesson struct
public struct ResponseAPI: Codable, Sendable, Equatable {
    var celle: [Lesson]
    let colori: [String]
}

public struct Lesson: Codable, Sendable, Hashable, Identifiable, Equatable {
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(nomeInsegnamento)
        hasher.combine(data)
        hasher.combine(orario)
        hasher.combine(docente)
        return hasher.finalize()
    }
    
    public let nomeInsegnamento: String
    public let nameOriginal: String
    public let data: String
    public let aula: String
    public let orario: String
    public let tipo: String
    public let docente: String
    public let annullato: String
    public let colorIndex: String
    public let codiceInsegnamento: String
    public var color: String
    public let infoAulaHTML: String
    
    public let durationCalculated: String
    public let cleanName: String
    public let tags: [String]
    
    nonisolated(unsafe) private static let addressRegex = /\[(.*?)]/
    nonisolated(unsafe) private static let capacityRegex = /Capacità: <\/span>\s*(\d+)\s*</
    
    private enum CodingKeys: String, CodingKey {
        case nomeInsegnamento = "nome_insegnamento"
        case nameOriginal = "name_original"
        case data, aula, orario, tipo, docente
        case annullato = "Annullato"
        case colorIndex = "color_index"
        case codiceInsegnamento = "codice_insegnamento"
        case color
        case infoAulaHTML = "informazioni_lezione"
    }
    
    public var startTime: String {
        orario.split(separator: " - ").first.map(String.init) ?? ""
    }
    
    public var formattedClassroom: String {
        aula.split(whereSeparator: { "[<".contains($0) })
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? aula
    }
    
    public var gruppo: GruppoMatricola {
        if nomeInsegnamento.contains("Matricole pari") { return .pari }
        if nomeInsegnamento.contains("Matricole dispari") { return .dispari }
        return .tutti
    }
    
    public var indirizzoAula: String? {
        infoAulaHTML.firstMatch(of: Self.addressRegex)?.1.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var capacity: Int? {
        guard let match = infoAulaHTML.firstMatch(of: Self.capacityRegex) else { return nil }
        return Int(match.1)
    }
    
    public enum GruppoMatricola: String, Codable, Sendable {
        case pari, dispari, tutti
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.nomeInsegnamento = try container.decodeOrEmpty(.nomeInsegnamento)
        self.nameOriginal = try container.decodeOrEmpty(.nameOriginal)
        self.data = try container.decodeOrEmpty(.data)
        self.aula = try container.decodeOrEmpty(.aula)
        self.orario = try container.decodeOrEmpty(.orario)
        self.tipo = try container.decodeOrEmpty(.tipo)
        self.docente = try container.decodeOrEmpty(.docente)
        self.annullato = try container.decodeOrEmpty(.annullato)
        self.colorIndex = try container.decodeOrEmpty(.colorIndex)
        self.codiceInsegnamento = try container.decodeOrEmpty(.codiceInsegnamento)
        self.color = try container.decodeOrEmpty(.color)
        
        self.infoAulaHTML = try Lesson.decodeInfoAula(from: container)
        
        (self.cleanName, self.tags) = LessonNameFormatter.format(self.nomeInsegnamento)
        self.durationCalculated = Lesson.calculateDuration(orario: self.orario)
    }
    
    init(
        nomeInsegnamento: String = "",
        nameOriginal: String = "",
        data: String,
        aula: String = "",
        orario: String,
        tipo: String,
        docente: String = "",
        annullato: String = "",
        colorIndex: String = "",
        codiceInsegnamento: String = "",
        color: String = "",
        infoAulaHTML: String = ""
    ) {
        self.nomeInsegnamento = nomeInsegnamento
        self.nameOriginal = nameOriginal
        self.data = data
        self.aula = aula
        self.orario = orario
        self.tipo = tipo
        self.docente = docente
        self.annullato = annullato
        self.colorIndex = colorIndex
        self.codiceInsegnamento = codiceInsegnamento
        self.color = color
        self.infoAulaHTML = infoAulaHTML
        
        (self.cleanName, self.tags) = LessonNameFormatter.format(self.nomeInsegnamento)
        self.durationCalculated = Lesson.calculateDuration(orario: self.orario)
    }
    
    private static func decodeInfoAula(from container: KeyedDecodingContainer<CodingKeys>) throws -> String {
        if let simpleString = try? container.decodeIfPresent(String.self, forKey: .infoAulaHTML) {
            return simpleString
        }
        
        struct DettaglioAula: Decodable { let contenuto: String }
        
        guard let infoContainer = try? container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .infoAulaHTML),
              let contenutoKey = GenericCodingKeys(stringValue: "contenuto"),
              let contenutoContainer = try? infoContainer.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: contenutoKey),
              let listKey = GenericCodingKeys(stringValue: "5"),
              let arrayWrapper = try? contenutoContainer.decode([DettaglioAula].self, forKey: listKey) else {
            return ""
        }
        
        return arrayWrapper.first?.contenuto ?? ""
    }
    
    private static func calculateDuration(orario: String) -> String {
        let times = orario.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard times.count == 2 else { return "" }
        
        let start = toMinutes(times[0])
        let end = toMinutes(times[1])
              
        guard end > start else { return "" }
        
        let diff = end - start
        let h = diff / 60
        let m = diff % 60
        
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        if m > 0 { return "\(m)m" }
        return ""
    }
    
    private static func toMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
        return h * 60 + m
    }
}

struct GenericCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int?
    init?(intValue: Int) { return nil }
}

// MARK: Struct corsi per il network
public struct Corso: Codable, Sendable, Equatable {
    public let elenco_anni: [Anno]
    public let label: String
    public let valore: String
    
    public static func filter(_ courses: [Corso], with searchText: String) -> [Corso] {
        guard !searchText.isEmpty else { return courses }
        return courses.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }
}

public struct Anno: Codable, Sendable, Equatable {
    public let label: String
    public let valore: String
    public let elenco_insegnamenti: [Insegnamento]
}

public struct Insegnamento: Codable, Sendable, Equatable {
    public let label: String
}

extension Lesson {
    public static let sample = Lesson(
        nomeInsegnamento: "Insegnamento di prova molto lungo Laboratorio",
        nameOriginal: "Insegnamento di prova molto lungo lungo lungo",
        data: "01-01-2025",
        aula: "Aula Gino Tessari",
        orario: "08:30 - 10:30",
        tipo: "Lezione",
        docente: "Prof. Rossi",
        annullato: "0",
        colorIndex: "",
        codiceInsegnamento: "XYZ",
        color: "#A0A0A0",
        infoAulaHTML: "<span style=\"font-weight:bold\">Nome aula: </span><a aria-label=\"Aula Gino Tessari\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&aula=32&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Aula Aula Gino Tessari\">Aula Gino Tessari</a><br><span style=\"font-weight:bold\">Capacità: </span>236<br><span style=\"font-weight:bold\">Sede: </span><a aria-label=\"Borgo Roma - Ca' Vignal 2\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Borgo Roma - Ca' Vignal 2\">Borgo Roma - Ca' Vignal 2</a> [Strada Le Grazie, 15 - 37134 Verona]"
    )
    
    public static let pausaSample = Lesson(
        data: "01-01-2025",
        orario: "08:30 - 10:30",
        tipo: "pause"
    )
}
