//
//  Models.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

// MARK: Year struct
struct Year: Encodable, Decodable, Sendable, Equatable {
    let label: String
    let valore: String
}

// MARK: Lesson struct
struct ResponseAPI: Codable, Sendable, Equatable {
    var celle: [Lesson]
    let colori: [String]
}

struct Lesson: Codable, Sendable, Hashable, Identifiable, Equatable {
    enum GruppoMatricola: String, Codable {
        case pari, dispari, tutti
    }
    
    var id: String
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
    var color: String
    let infoAulaHTML: String
    
    let formattedName: String
    let formattedClassroom: String
    let durationCalculated: String
    let gruppo: GruppoMatricola
    
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
    
    // Chiavi per navigare dentro "informazioni_lezione" -> "contenuto" -> "5"
    private enum InfoLezioneKeys: String, CodingKey {
        case contenuto
    }
    
    private enum ContenutoKeys: String, CodingKey {
        case key5 = "5" // La chiave "5" che contiene l'array dell'aula
    }
    
    // Struct di appoggio interna per decodificare l'oggetto dentro l'array "5"
    private struct DettaglioAula: Codable {
        let contenuto: String
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
        self.color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        
        do {
            let infoContainer = try container.nestedContainer(keyedBy: InfoLezioneKeys.self, forKey: .infoAulaHTML)
            let contenutoContainer = try infoContainer.nestedContainer(keyedBy: ContenutoKeys.self, forKey: .contenuto)
            let dettagliAula = try contenutoContainer.decodeIfPresent([DettaglioAula].self, forKey: .key5)
            self.infoAulaHTML = dettagliAula?.first?.contenuto ?? ""
        } catch {
            self.infoAulaHTML = try container.decodeIfPresent(String.self, forKey: .infoAulaHTML) ?? ""
        }
        
        self.formattedName = self.nomeInsegnamento
            .replacingOccurrences(of: "Matricole pari", with: "")
            .replacingOccurrences(of: "Matricole dispari", with: "")
        
        if let bracketIndex = self.aula.firstIndex(of: "[") {
            let index = self.aula.index(bracketIndex, offsetBy: -2, limitedBy: self.aula.startIndex) ?? self.aula.startIndex
            self.formattedClassroom = String(self.aula[...index])
        } else {
            self.formattedClassroom = self.aula
        }
        
        self.durationCalculated = Lesson.calculateDuration(orario: orario)
        
        if nomeInsegnamento.contains("Matricole pari") {
            self.gruppo = .pari
        } else if nomeInsegnamento.contains("Matricole dispari") {
            self.gruppo = .dispari
        } else {
            self.gruppo = .tutti
        }
        
        var hasher = Hasher()
        hasher.combine(nomeInsegnamento)
        hasher.combine(nameOriginal)
        hasher.combine(data)
        hasher.combine(aula)
        hasher.combine(orario)
        hasher.combine(tipo)
        hasher.combine(docente)
        hasher.combine(annullato)
        hasher.combine(colorIndex)
        hasher.combine(codiceInsegnamento)
        hasher.combine(color)
        hasher.combine(infoAulaHTML)
        hasher.combine(formattedName)
        hasher.combine(formattedClassroom)
        hasher.combine(durationCalculated)
        hasher.combine(gruppo)
        let hashValue = hasher.finalize()
        self.id = String(hashValue)
    }
    
    nonisolated init(
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
        color: String = "",
        infoAulaHTML: String = ""
    ) {
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
        self.infoAulaHTML = infoAulaHTML
        
        self.formattedName = self.nomeInsegnamento
            .replacingOccurrences(of: "Matricole pari", with: "")
            .replacingOccurrences(of: "Matricole dispari", with: "")
        
        if let bracketIndex = self.aula.firstIndex(of: "[") {
            let index = self.aula.index(bracketIndex, offsetBy: -2, limitedBy: self.aula.startIndex) ?? self.aula.startIndex
            self.formattedClassroom = String(self.aula[...index])
        } else {
            self.formattedClassroom = self.aula
        }
        
        self.durationCalculated = Lesson.calculateDuration(orario: orario)
        
        if nomeInsegnamento.contains("Matricole pari") {
            self.gruppo = .pari
        } else if nomeInsegnamento.contains("Matricole dispari") {
            self.gruppo = .dispari
        } else {
            self.gruppo = .tutti
        }
        
        var hasher = Hasher()
        hasher.combine(nomeInsegnamento)
        hasher.combine(nameOriginal)
        hasher.combine(data)
        hasher.combine(aula)
        hasher.combine(orario)
        hasher.combine(tipo)
        hasher.combine(docente)
        hasher.combine(annullato)
        hasher.combine(colorIndex)
        hasher.combine(codiceInsegnamento)
        hasher.combine(color)
        hasher.combine(infoAulaHTML)
        hasher.combine(formattedName)
        hasher.combine(formattedClassroom)
        hasher.combine(durationCalculated)
        hasher.combine(gruppo)
        let hashValue = hasher.finalize()
        self.id = String(hashValue)
    }
    
    nonisolated static private func calculateDuration(orario: String) -> String {
        let times = orario.split(separator: "-")
        guard times.count == 2 else { return "" }
        
        func parseMinutes(_ time: Substring) -> Int {
            let parts = time.trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]),
                  let m = Int(parts[1]) else { return 0 }
            return h * 60 + m
        }
        
        let startMin = parseMinutes(times[0])
        let endMin = parseMinutes(times[1])
        
        let diff = endMin - startMin
        guard diff > 0 else { return "" }
        
        let h = diff / 60
        let m = diff % 60
        
        if h >= 1 && m > 0 {
            return "\(h)h \(m)m"
        } else if h >= 1 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: Struct corsi per il network
struct Corso: Codable, Sendable, Equatable {
    let elenco_anni: [Anno]
    let label: String
    let valore: String
}

struct Anno: Codable, Sendable, Equatable {
    let label: String
    let valore: String
    let elenco_insegnamenti: [Insegnamento]
}

struct Insegnamento: Codable, Sendable, Equatable {
    let label: String
}

extension Lesson {
    static let sample = Lesson(
        nome_insegnamento: "Insegnamento di prova molto lungo",
        name_original: "Insegnamento di prova molto lungo lungo lungo",
        data: "01-01-2025",
        aula: "Aula Gino Tessari",
        orario: "08:30 - 10:30",
        tipo: "Lezione",
        docente: "Prof. Rossi",
        Annullato: "0",
        color_index: "",
        codice_insegnamento: "XYZ",
        color: "#A0A0A0",
        infoAulaHTML: "<span style=\"font-weight:bold\">Nome aula: </span><a aria-label=\"Aula Gino Tessari\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&aula=32&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Aula Aula Gino Tessari\">Aula Gino Tessari</a><br><span style=\"font-weight:bold\">Capacità: </span>236<br><span style=\"font-weight:bold\">Sede: </span><a aria-label=\"Borgo Roma - Ca' Vignal 2\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Borgo Roma - Ca' Vignal 2\">Borgo Roma - Ca' Vignal 2</a> [Strada Le Grazie, 15 - 37134 Verona]"
    )
    
    var indirizzoAula: String? {
            // Cerca l'ultima parentesi quadra aperta
            guard let openBracketIndex = infoAulaHTML.lastIndex(of: "["),
                  // Cerca l'ultima parentesi quadra chiusa
                  let closeBracketIndex = infoAulaHTML.lastIndex(of: "]"),
                  openBracketIndex < closeBracketIndex else {
                return nil
            }
            
            // Estrai la sottostringa e rimuovi eventuali spazi bianchi extra
            let startIndex = infoAulaHTML.index(after: openBracketIndex)
            let address = String(infoAulaHTML[startIndex..<closeBracketIndex])
            
            return address.trimmingCharacters(in: .whitespacesAndNewlines)
        }
}
