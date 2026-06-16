//
//  NetworkError.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

enum NetworkError: Error {
    case badURL
    case badServerResponse(statusCode: Int)
    case emptyData
    case decodingError(Error)
    case offline
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .offline: return "Il dispositivo è offline."
        case .timeout: return "La richiesta è scaduta (Timeout)."
        case .badURL: return "L'URL non è valido."
        case .badServerResponse(let code): return "Errore Server: \(code)."
        case .emptyData: return "Nessun dato ricevuto dal server."
        case .decodingError(let err): return "Errore di decodifica: \(err.localizedDescription)"
        case .unknown(let err): return "Errore sconosciuto: \(err.localizedDescription)"
        }
    }
}
