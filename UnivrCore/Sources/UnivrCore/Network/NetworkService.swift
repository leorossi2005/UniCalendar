//
//  NetworkService.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

struct NetworkService {
    private let session: URLSession
    let baseURL = "https://alpha.unicalendar.dedyn.io/api/v1"
    
    private static var userAgent: String {
        "UniCalendar/\(Bundle.main.clearAppVersion) (\(Device.model); \(Device.os.name) \(Device.os.version))"
    }
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        
        configuration.httpAdditionalHeaders = [
            "User-Agent": Self.userAgent,
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
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let strategy = Date.ParseStrategy(
                    format: "\(year: .defaultDigits)-\(month: .defaultDigits)-\(day: .defaultDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .defaultDigits):\(second: .defaultDigits)",
                    timeZone: TimeZone(identifier: "Europe/Rome")!
                )
                
                if let date = try? Date(dateString, strategy: strategy) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Formato data non valido")
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet: throw NetworkError.offline
            case .timedOut: throw NetworkError.timeout
            case .cancelled: throw CancellationError()
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
    func getYears() async throws -> [AcademicYear] {
        struct RootWrapper: Decodable { let years: [AcademicYear] }
        let wrapper: RootWrapper = try await fetch(from: "/years")
        return wrapper.years
    }
    
    func getCourses(year: String) async throws -> [Course] {
        guard year != "0", !year.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        struct RootWrapper: Decodable { let courses: [Course] }
        let wrapper: RootWrapper = try await fetch(from: "/courses?year=\(year)")
        return wrapper.courses
    }
    
    func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [DailySchedule] {
        return try await fetch(from: "/schedule?course=\(corso)&academicYear=\(anno)&year=\(selyear)")
    }
    
    func getAvailability(date: String) async throws -> Availability {
        struct RootWrapper: Decodable { let availability: Availability }
        let wrapper: RootWrapper = try await fetch(from: "/roomsavailability?date=\(date)")
        return wrapper.availability
    }
    
    func getAppStatus(appVersion: String, osVersion: String) async throws -> [AppNotice] {
        struct RootWrapper: Decodable { let notices: [Lossy<AppNotice>] }
        let safeApp = appVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appVersion
        let safeOS = osVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? osVersion
        let wrapper: RootWrapper = try await fetch(from: "/status?appVersion=\(safeApp)&osVersion=\(safeOS)")
        return wrapper.notices.compactMap(\.value)
    }
}

private struct Lossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        self.value = try? T(from: decoder)
    }
}
