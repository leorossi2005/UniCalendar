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
    func getYears() async throws -> [AcademicYear]
    func getCourses(year: String) async throws -> [Corso]
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [Lesson]
}

public struct NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    
    let baseURL = "http://192.168.0.7:8787/api/v1"
    
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
    
    public func getYears() async throws -> [AcademicYear] {
        guard let url = URL(string: "\(baseURL)/years") else { throw NetworkError.badURL }
        
        do {
            let (data, response) = try await self.session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw NetworkError.badServerResponse(statusCode: code)
            }
            
            struct RootWrapper: Decodable { let years: [AcademicYear] }
            let wrapper = try JSONDecoder().decode(RootWrapper.self, from: data)
            print(wrapper.years)
            return wrapper.years
            
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            print("Decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    public func getCourses(year: String) async throws -> [Corso] {
        guard let url = URL(string: "\(baseURL)/courses?year=\(year)") else { throw NetworkError.badURL }
        
        do {
            let (data, response) = try await self.session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw NetworkError.badServerResponse(statusCode: code)
            }
            
            struct RootWrapper: Decodable { let courses: [Corso] }
            let wrapper = try JSONDecoder().decode(RootWrapper.self, from: data)
            return wrapper.courses
            
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            print("Decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    public func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [Lesson] {
        guard let url = URL(string: "\(baseURL)/schedule?course=\(corso)&academicYear=\(anno)&year=\(selyear)") else { throw NetworkError.badURL }
        
        do {
            let (data, response) = try await self.session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                throw NetworkError.badServerResponse(statusCode: code)
            }
            
            struct RootWrapper: Decodable { let lessons: [Lesson] }
            let wrapper = try JSONDecoder().decode(RootWrapper.self, from: data)
            return wrapper.lessons
            
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            print("Decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
