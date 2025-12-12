//
//  CacheManager.swift
//  Univr Code
//
//  Created by Leonardo Rossi on 21/11/25.
//

import Foundation

public actor CacheManager: Sendable {
    static let shared = CacheManager()
    
    private let cacheDirectory: URL?
    
    private init() {
        self.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func save<T: Encodable & Sendable>(_ object: T, fileName: String) async {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        do {
            let data = try JSONEncoder().encode(object)
            try await Task.detached(priority: .utility) {
                try data.write(to: fileUrl)
            }.value
        } catch {
            print("Error saving cache \(fileName): \(error)")
        }
    }
    
    func load<T: Decodable & Sendable>(fileName: String, type: T.Type) async -> T? {
        guard let folder = cacheDirectory else { return nil }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileUrl.path()) else { return nil }
        
        do {
            let data = try await Task.detached(priority: .utility) {
                try Data(contentsOf: fileUrl)
            }.value
            let object = try JSONDecoder().decode(type, from: data)
            return object
        } catch {
            print("Error loading cache \(fileName): \(error)")
            return nil
        }
    }
    
    func clear(fileName: String) async {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.removeItem(at: fileUrl)
            }.value
        } catch {
            print("Error clearing cache \(fileName): \(error)")
        }
    }
}

public struct Coordinate: Sendable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public actor CoordinateCache {
    public static let shared = CoordinateCache()
    
    private var cache: [String: Coordinate] = [:]
    
    public func coordinate(for address: String) -> Coordinate? {
        cache[address]
    }
    
    public func save(_ coordinate: Coordinate, for address: String) {
        cache[address] = coordinate
    }
}
