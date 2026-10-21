//
//  NetworkService.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

fileprivate final class SessionStore: @unchecked Sendable {
    private let lock = NSLock()
    private var currentSession: URLSession
    private var currentGeneration: Int = 1
    
    init() {
        self.currentSession = Self.makeSession()
    }
    
    var session: URLSession {
        lock.lock()
        defer { lock.unlock() }
        return currentSession
    }
    
    var generation: Int {
        lock.lock()
        defer { lock.unlock() }
        return currentGeneration
    }
    
    func replace() -> Int {
        let old: URLSession
        let newGen: Int
        
        lock.lock()
        old = currentSession
        currentGeneration += 1
        newGen = currentGeneration
        currentSession = Self.makeSession()
        lock.unlock()
        
        old.finishTasksAndInvalidate()
        
        return newGen
    }
    
    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        
        configuration.httpAdditionalHeaders = [
            "User-Agent": NetworkService.userAgent,
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        return URLSession(configuration: configuration)
    }
}

struct NetworkService: Sendable {
    fileprivate static let store = SessionStore()
    
    static func resetConnections() {
        _ = store.replace()
    }
    
    let baseURL = "https://alpha.unicalendar.dedyn.io/api/v1"
    
    fileprivate static var userAgent: String {
        "UniCalendar/\(Bundle.main.clearAppVersion) (\(Device.model); \(Device.os.name) \(Device.os.version))"
    }
    
    init() {}
    
    private func fetch<T: Decodable>(from endpoint: String) async throws -> T {
        let startedAt = Date()
        let session = Self.store.session

        let insideHandler = TickContext.isHandler
        if await ServerStatusCenter.shared.shouldBlockRequest(insideHandler: insideHandler) {
            await ServerStatusCenter.shared.noteBlockedRequest()
            throw NetworkError.serverUnreachable
        }
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.badURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.unknown))
            }
            
            let univrStatus = httpResponse.value(forHTTPHeaderField: "X-UniVR-Status")
            switch univrStatus {
            case "offline": await ServerStatusCenter.shared.reportUniVROffline()
            case "online": await ServerStatusCenter.shared.reportUniVROnline()
            default: break // route senza header (es. /status): non cambia il flag
            }
            
            if (500...599).contains(httpResponse.statusCode) {
                if univrStatus == "offline" {
                    await ServerStatusCenter.shared.reportSuccess()
                    throw NetworkError.univrOffline
                }
                await ServerStatusCenter.shared.reportServerFailure(startedAt: startedAt)
                throw NetworkError.serverUnreachable
            }
            
            await ServerStatusCenter.shared.reportSuccess()
            
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
            case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
                throw NetworkError.offline
            case .timedOut:
                await ServerStatusCenter.shared.reportServerFailure(startedAt: startedAt)
                throw NetworkError.timeout
            case .cancelled:
                throw CancellationError()
            case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .networkConnectionLost, .resourceUnavailable:
                await ServerStatusCenter.shared.reportServerFailure(startedAt: startedAt)
                throw NetworkError.serverUnreachable
            default:
                throw NetworkError.unknown(error)
            }
        } catch is CancellationError {
            throw CancellationError()
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
    
    func getRoomsAvailability(date: String) async throws -> [String: [Room]] {
        struct RootWrapper: Decodable { let rooms: [String: [Room]] }
        let wrapper: RootWrapper = try await fetch(from: "/roomsavailability?date=\(date)")
        return wrapper.rooms
    }
    
    func getLocations() async throws -> [String: String] {
        struct RootWrapper: Decodable { let locations: [String: String] }
        let wrapper: RootWrapper = try await fetch(from: "/locations")
        return wrapper.locations
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
