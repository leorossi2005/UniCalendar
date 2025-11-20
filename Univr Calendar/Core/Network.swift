//
//  Network.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case badServerResponse
    case cannotDecodeContentData
    case jsonNotFound
}

protocol NetworkServiceProtocol {
    func getYears() async throws -> [Year]
    func getCourses(year: String) async throws -> [Corso]
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI
}

struct NetworkService: NetworkServiceProtocol {
    private func extractJSON(from text: String, isArray: Bool = true) -> Data? {
        // Cerca tutto ciò che è racchiuso tra [ ... ] o { ... }
        let pattern = isArray ? "\\[.*\\]" : "\\{.*\\}"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: text.utf16.count)
            
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let swiftRange = Range(match.range, in: text) {
                let jsonString = String(text[swiftRange])
                return jsonString.data(using: .utf8)
            }
        } catch {
            print("Errore Regex: \(error)")
        }
        return nil
    }
    
    func extractElencoCorsiJSON(from text: String) -> Data? {
        // 1. Definiamo i marcatori di inizio e fine specifici per quel testo
        let startMarker = "var elenco_corsi ="
        let endMarker = "var elenco_cdl =" // La variabile successiva nel testo
        
        // 2. Troviamo l'inizio
        guard let startRange = text.range(of: startMarker) else { return nil }
        let searchStartIndex = startRange.upperBound
        
        // 3. Troviamo la fine (cerchiamo la prossima variabile definita)
        guard let endRange = text.range(of: endMarker, range: searchStartIndex..<text.endIndex) else {
            // Se non trova la variabile successiva, proviamo a cercare l'ultimo punto e virgola
            return nil
        }
        
        // 4. Estraiamo la sottostringa
        var jsonString = String(text[searchStartIndex..<endRange.lowerBound])
        
        // 5. Pulizia: Rimuoviamo spazi bianchi e il punto e virgola finale
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasSuffix(";") {
            jsonString.removeLast()
        }
        
        // 6. Convertiamo in Data
        return jsonString.data(using: .utf8)
    }
    
    private func fetchText(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return text
    }
    
    func getYears() async throws -> [Year] {
        var components = URLComponents(string: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php")
        components?.queryItems = [
            URLQueryItem(name: "aa", value: "1")
        ]
        
        guard let urlString = components?.url?.absoluteString else { throw NetworkError.badURL }
        let text = try await fetchText(from: urlString)
        
        guard let jsonData = extractJSON(from: text, isArray: false) else {
            throw NetworkError.jsonNotFound
        }
        
        let decoder = JSONDecoder()
        let anniDict = try decoder.decode([String: Year].self, from: jsonData)
        let yearsData = anniDict.values.map { $0 }
        
        return yearsData.sorted(by: { $0.valore < $1.valore })
    }
    
    func getCourses(year: String) async throws -> [Corso] {
        var components = URLComponents(string: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php")
        components?.queryItems = [
            URLQueryItem(name: "aa", value: year),
            URLQueryItem(name: "page", value: "corsi")
        ]
        
        guard let urlString = components?.url?.absoluteString else { throw NetworkError.badURL }
        let text = try await fetchText(from: urlString)
        
        guard let jsonData = extractElencoCorsiJSON(from: text) else {
            throw NetworkError.jsonNotFound
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Corso].self, from: jsonData)
    }
    
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI {
        guard let url = URL(string: "https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "view", value: "easycourse"),
            URLQueryItem(name: "include", value: "corso"),
            URLQueryItem(name: "anno", value: selyear),
            URLQueryItem(name: "cdl", value: corso),
            URLQueryItem(name: "anno2", value: anno),
            URLQueryItem(name: "_lang", value: "it"),
            URLQueryItem(name: "date", value: Formatters.displayDate.string(from: Date())),
            URLQueryItem(name: "all_events", value: "1")
        ]

        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
            
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ResponseAPI.self, from: data)
    }

}
