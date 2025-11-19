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
    let nome_insegnamento: String
    let name_original: String
    let data: String
    let aula: String
    let orario: String
    let tipo: String
    let docente: String
    let Annullato: String
    let color_index: String
    let codice_insegnamento: String
    var color: String
    
    private enum CodingKeys: String, CodingKey {
        case nome_insegnamento
        case name_original
        case data
        case aula
        case orario
        case tipo
        case docente
        case Annullato
        case color_index
        case codice_insegnamento
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID()
        
        self.nome_insegnamento = try container.decodeIfPresent(String.self, forKey: .nome_insegnamento) ?? ""
        self.name_original = try container.decodeIfPresent(String.self, forKey: .name_original) ?? ""
        self.data = try container.decodeIfPresent(String.self, forKey: .data) ?? ""
        self.aula = try container.decodeIfPresent(String.self, forKey: .aula) ?? ""
        self.orario = try container.decodeIfPresent(String.self, forKey: .orario) ?? ""
        self.tipo = try container.decodeIfPresent(String.self, forKey: .tipo) ?? ""
        self.docente = try container.decodeIfPresent(String.self, forKey: .docente) ?? ""
        self.Annullato = try container.decodeIfPresent(String.self, forKey: .Annullato) ?? ""
        self.color_index = try container.decodeIfPresent(String.self, forKey: .color_index) ?? ""
        self.codice_insegnamento = try container.decodeIfPresent(String.self, forKey: .codice_insegnamento) ?? ""
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
        self.nome_insegnamento = nome_insegnamento
        self.name_original = name_original
        self.data = data
        self.aula = aula
        self.orario = orario
        self.tipo = tipo
        self.docente = docente
        self.Annullato = Annullato
        self.color_index = color_index
        self.codice_insegnamento = codice_insegnamento
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
