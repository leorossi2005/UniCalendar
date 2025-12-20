//
//  Network.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct NetworkCacheData: Codable, Sendable {
    public let years: [Year]
    public let courses: [String: [Corso]]
}

@MainActor
public final class NetworkCache: Sendable {
    public static let shared = NetworkCache()
    
    public var years: [Year] = []
    public var courses: [String: [Corso]] = [:]
    
    private init() {}
    
    public func toData() -> NetworkCacheData {
        return NetworkCacheData(
            years: self.years,
            courses: self.courses
        )
    }
    
    public func update(from data: NetworkCacheData) {
        self.years = data.years
        self.courses = data.courses
    }
}

enum NetworkError: Error {
    case badURL
    case badServerResponse(statusCode: Int)
    case emptyData
    case dataNotFound(variable: String)
    case decodingError(Error)
    case offline
    
    var errorDescription: String? {
        switch self {
            case .offline: return "Device is offline."
            case .badURL: return "URL is not valid"
            case .badServerResponse(let code): return "Server Error: \(code)."
            case .emptyData: return "Empty data recieved from the server"
            case .dataNotFound(let variable): return "Impossible to find data for: \(variable)."
            case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

public protocol NetworkServiceProtocol: Sendable {
    func getYears() async throws -> [Year]
    func getCourses(year: String) async throws -> [Corso]
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI
}

public struct NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    
    public init() {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 30
        
        // Da rendere per dispositivo
        configuration.httpAdditionalHeaders = [
            "User-Agent": "CalendarForUniVR/\(Bundle.main.clearAppVersion) (Device, OS)",
            "Accept": "application/json, text/html, */*",
            "Accept-Language": "it-IT,it;q=0.9,en;q=0.8"
        ]
        
        self.session = URLSession(configuration: configuration)
    }
    
    nonisolated(unsafe) private static let yearsRegex = /var\s+anni_accademici_ec\s+=\s+(.*?);/.dotMatchesNewlines()
    nonisolated(unsafe) private static let coursesRegex = /var\s+elenco_corsi\s+=\s+(.*?);/.dotMatchesNewlines()
    
    private func buildURL(endpoint: String = "combo.php", queryItems: [String: String]) -> URL? {
        var components = URLComponents(string: "https://logistica.univr.it/PortaleStudentiUnivr/\(endpoint)")
        components?.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }
    
    private func fetchAndExtract<T: Decodable>(
        queryItems: [String: String],
        regex: Regex<(Substring, Substring)>,
        variableName: String
    ) async throws -> T {
        do {
            guard let url = buildURL(queryItems: queryItems) else { throw NetworkError.badURL }
            
            let (data, response) = try await self.session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw NetworkError.badServerResponse(statusCode: code)
            }
            
            guard let text = String(data: data, encoding: .utf8) else { throw NetworkError.emptyData }
            
            guard let match = text.firstMatch(of: regex),
                  let jsonData = String(match.1).data(using: .utf8) else {
                throw NetworkError.dataNotFound(variable: variableName)
            }
            
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            print("Decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    public func getYears() async throws -> [Year] {
        let yearsDict: [String: Year] = try await fetchAndExtract(
            queryItems: ["aa": "1"],
            regex: Self.yearsRegex,
            variableName: "anni_accademici_ec"
        )
        return yearsDict.values.sorted(by: { $0.valore < $1.valore })
    }
    
    public func getCourses(year: String) async throws -> [Corso] {
        try await fetchAndExtract(
            queryItems: ["aa": year, "page": "corsi"],
            regex: Self.coursesRegex,
            variableName: "elenco_corsi"
        )
    }
    
    public func fetchOrario(corso: String, anno: String, selyear: String) async throws -> ResponseAPI {
        do {
            guard let url = URL(string: "https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php") else { throw NetworkError.badURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            
            let queryParams = [
                "view": "easycourse",
                "include": "corso",
                "anno": selyear,
                "cdl": corso,
                "anno2": anno,
                "_lang": "it",
                "date": Date().formatUnivrStyle(),
                "all_events": "1"
            ]
            
            var components = URLComponents()
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.httpBody = components.query?.data(using: .utf8)
            
            let (data, response) = try await self.session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw NetworkError.badServerResponse(statusCode: code)
            }
            
            return try JSONDecoder().decode(ResponseAPI.self, from: data)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            print("Decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }

}
