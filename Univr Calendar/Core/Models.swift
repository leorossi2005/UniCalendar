//
//  Models.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

// MARK: Year struct
struct Year: Decodable, Sendable {
    let label: String
    let valore: String
}

// MARK: Lesson struct
struct ResponseAPI: Codable, Sendable {
    var celle: [Lesson]
    let colori: [String]
}

struct Lesson: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let nomeInsegnamento: String
    let nameOriginal: String
    let data: String
    let aula: String
    let orario: String
    let tipo: String
    let docente: String
    let annullato: String
    let colorIndex: String
    let codiceInsegnamento: String
    var color: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case nomeInsegnamento = "nome_insegnamento"
        case nameOriginal = "name_original"
        case data, aula, orario, tipo, docente
        case annullato = "Annullato"
        case colorIndex = "color_index"
        case codiceInsegnamento = "codice_insegnamento"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.nomeInsegnamento = try container.decodeIfPresent(String.self, forKey: .nomeInsegnamento) ?? ""
        self.nameOriginal = try container.decodeIfPresent(String.self, forKey: .nameOriginal) ?? ""
        self.data = try container.decodeIfPresent(String.self, forKey: .data) ?? ""
        self.aula = try container.decodeIfPresent(String.self, forKey: .aula) ?? ""
        self.orario = try container.decodeIfPresent(String.self, forKey: .orario) ?? ""
        self.tipo = try container.decodeIfPresent(String.self, forKey: .tipo) ?? ""
        self.docente = try container.decodeIfPresent(String.self, forKey: .docente) ?? ""
        self.annullato = try container.decodeIfPresent(String.self, forKey: .annullato) ?? ""
        self.colorIndex = try container.decodeIfPresent(String.self, forKey: .colorIndex) ?? ""
        self.codiceInsegnamento = try container.decodeIfPresent(String.self, forKey: .codiceInsegnamento) ?? ""
        
        self.id = UUID()
        self.color = ""
    }
    
    init(
        id: UUID = UUID(),
        nome_insegnamento: String = "",
        name_original: String = "",
        data: String,
        aula: String = "",
        orario: String,
        tipo: String,
        docente: String = "",
        Annullato: String = "",
        color_index: String = "",
        codice_insegnamento: String = "",
        color: String = ""
    ) {
        self.id = id
        self.nomeInsegnamento = nome_insegnamento
        self.nameOriginal = name_original
        self.data = data
        self.aula = aula
        self.orario = orario
        self.tipo = tipo
        self.docente = docente
        self.annullato = Annullato
        self.colorIndex = color_index
        self.codiceInsegnamento = codice_insegnamento
        self.color = color
    }
}

// MARK: Struct corsi per il network
struct Corso: Codable, Sendable {
    let elenco_anni: [Anno]
    let label: String
    let valore: String
}

struct Anno: Codable, Sendable {
    let label: String
    let valore: String
    let elenco_insegnamenti: [Insegnamento]
}

struct Insegnamento: Codable, Sendable {
    let label: String
}

extension Lesson {
    static let sample = Lesson(
        id: UUID(),
        nome_insegnamento: "Insegnamento di prova molto lungo",
        name_original: "",
        data: "01-01-2025",
        aula: "Aula Gino Tessari",
        orario: "08:30 - 10:30",
        tipo: "Lezione",
        docente: "Prof. Rossi",
        Annullato: "0",
        color_index: "",
        codice_insegnamento: "XYZ",
        color: "#A0A0A0"
    )
}
