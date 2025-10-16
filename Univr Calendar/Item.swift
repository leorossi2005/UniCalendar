//
//  Item.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var text: String
    
    init(text: String) {
        self.text = text
    }
}

struct Year: Decodable {
    let label: String
    let valore: String
}

struct Course: Decodable {
    let label: String
}

struct Lesson {
    let nome_insegnamento: String
    let name_original: String
    let orario: String
    let data: String
    let aula: String
    let docente: String
    let color: String
    let type: String
}

// MARK: Struct corsi per il network
struct Corso: Codable {
    let elenco_anni: [Anno]
    let label: String
    let tipo: String
    let TipoID: String
    let valore: String
    let cdl_id: String
    let scuola: String
    let pub_type: String
    let default_grid: String
    let pub_periodi: [Periodo]
    let periodi: [Periodo]
    let facolta_id: String
    let facolta_code: String
}

struct Periodo: Codable {
    let label: String
    let valore: String
    let pub: String
    let id: String
    let aa_id: String
    let facolta_code: String
}

struct Anno: Codable {
    let label: String
    let valore: String
    let elenco_insegnamenti: [Insegnamento]
    let order_lbl: String
    let external: Int
    let elenco_canali: ElencoCanali
}

struct Insegnamento: Codable {
    let label: String
    let valore: String
    let id: String
    let id_periodo: Int
    let docente: String
}

struct ElencoCanali: Codable {
    let value: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // caso 1: oggetto con chiave→valore
        if let dict = try? container.decode([String: String].self) {
            self.value = dict
        }
        // caso 2: array vuoto []
        else if let array = try? container.decode([String].self), array.isEmpty {
            self.value = [:]
        }
        // caso 3: qualcos’altro o valore nullo
        else {
            self.value = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value.isEmpty {
            try container.encode([String]()) // encode come []
        } else {
            try container.encode(value)      // encode come { ... }
        }
    }
}
