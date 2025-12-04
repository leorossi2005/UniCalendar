//
//  Network.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation


public nonisolated struct NetworkCache: Encodable, Decodable {
    public static var shared = NetworkCache()
    
    public var years: [Year] = []
    public var courses: [String: [Corso]] = [:]
    public var academicYears: [String: [String: [Anno]]] = [:]
}

enum NetworkError: Error {
    case badURL
    case badServerResponse(statusCode: Int)
    case emptyData
    case dataNotFound(variable: String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
            case .badURL: return "URL is not valid"
            case .badServerResponse(let code): return "server Error: \(code)."
            case .emptyData: return "Empty data recieved from the server"
            case .dataNotFound(let variable): return "Impossible to find data for: \(variable)."
            case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

public protocol NetworkServiceProtocol {
    func getYears() async throws -> [Year]
    func getCourses(year: String) async throws -> [Corso]
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI
}

public struct NetworkService: NetworkServiceProtocol {
    public init() {}
    
    private func extractJSONVariable(name variableName: String, from text: String) -> Data? {
        let pattern: Regex<(Substring, Substring)>
        do {
            pattern = try Regex("var\\s+\(variableName)\\s+=\\s+(.*?);")
                .dotMatchesNewlines()
        } catch {
            return nil
        }
        
        guard let match = text.firstMatch(of: pattern) else { return nil }
        
        let jsonString = match.1
        return String(jsonString).data(using: .utf8)
    }
    
    private func fetchText(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badServerResponse(statusCode: 0)
        }
            
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            throw NetworkError.emptyData
        }
        
        return text
    }
    
    public func getYears() async throws -> [Year] {
        var components = URLComponents(string: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php")
        components?.queryItems = [
            URLQueryItem(name: "aa", value: "1")
        ]
        
        guard let urlString = components?.url?.absoluteString else {
            throw NetworkError.badURL
        }
        
        let text = try await fetchText(from: urlString)
        
        guard let jsonData = extractJSONVariable(name: "anni_accademici_ec", from: text) else {
            throw NetworkError.dataNotFound(variable: "anni_accademici_ec")
        }
        
        let decoder = JSONDecoder()
        do {
            let anniDict = try decoder.decode([String: Year].self, from: jsonData)
            let yearsData = anniDict.values.sorted(by: { $0.valore < $1.valore })
            
            return yearsData
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    public func getCourses(year: String) async throws -> [Corso] {
        var components = URLComponents(string: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php")
        components?.queryItems = [
            URLQueryItem(name: "aa", value: year),
            URLQueryItem(name: "page", value: "corsi")
        ]
        
        guard let urlString = components?.url?.absoluteString else {
            throw NetworkError.badURL
        }
        
        let text = try await fetchText(from: urlString)
        
        guard let jsonData = extractJSONVariable(name: "elenco_corsi", from: text) else {
            throw NetworkError.dataNotFound(variable: "elenco_corsi")
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([Corso].self, from: jsonData)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    public func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI {
        guard let url = URL(string: "https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        let dateString = Formatters.displayDate.string(from: Date())
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "view", value: "easycourse"),
            URLQueryItem(name: "include", value: "corso"),
            URLQueryItem(name: "anno", value: selyear),
            URLQueryItem(name: "cdl", value: corso),
            URLQueryItem(name: "anno2", value: anno),
            URLQueryItem(name: "_lang", value: "it"),
            URLQueryItem(name: "date", value: dateString),
            URLQueryItem(name: "all_events", value: "1")
        ]

        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badServerResponse(statusCode: 0)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ResponseAPI.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

}
