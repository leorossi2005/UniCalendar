//
//  Network.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 08/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct NetworkCacheData: Codable, Sendable {
    public let years: [AcademicYear]
    public let courses: [String: [Corso]]
}

@MainActor
public final class NetworkCache: Sendable {
    public static let shared = NetworkCache()
    
    public var years: [AcademicYear] = []
    public var courses: [String: [Corso]] = [:]
    
    private init() {}
    
    public func toData() -> NetworkCacheData {
        return NetworkCacheData(years: self.years, courses: self.courses)
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

public protocol NetworkServiceProtocol: Sendable {
    func getYears() async throws -> [AcademicYear]
    func getCourses(year: String) async throws -> [Corso]
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [DailySchedule]
}

public struct NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    let baseURL = "http://192.168.0.20:3001/api/v1"
    
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        
        // Da rendere per dispositivo
        configuration.httpAdditionalHeaders = [
            "User-Agent": "CalendarForUniVR/\(Bundle.main.clearAppVersion) (Device, OS)",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: configuration)
    }
    
    private func fetch<T: Decodable>(from endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw NetworkError.badURL }
        
        do {
            let (data, response) = try await self.session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.unknown))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Europe/Rome")
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet: throw NetworkError.offline
            case .timedOut: throw NetworkError.timeout
            default: throw NetworkError.unknown(error)
            }
        } catch let error as DecodingError {
            print("Decode error for \(endpoint): \(error)")
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // MARK: - Public Methods
    public func getYears() async throws -> [AcademicYear] {
        struct RootWrapper: Decodable { let years: [AcademicYear] }
        let wrapper: RootWrapper = try await fetch(from: "/years")
        return wrapper.years
    }
    
    public func getCourses(year: String) async throws -> [Corso] {
        struct RootWrapper: Decodable { let courses: [Corso] }
        let wrapper: RootWrapper = try await fetch(from: "/courses?year=\(year)")
        return wrapper.courses
    }
    
    public func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [DailySchedule] {
        return try await fetch(from: "/schedule?course=\(corso)&academicYear=\(anno)&year=\(selyear)")
    }
}
