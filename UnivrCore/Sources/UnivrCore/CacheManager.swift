//
//  CacheManager.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 21/11/25.
//

import Foundation

struct CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func save<T: Encodable>(_ object: T, fileName: String) {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        Task.detached {
            do {
                let data = try JSONEncoder().encode(object)
                try data.write(to: fileUrl)
            } catch {
                print("Error saving cache \(fileName): \(error)")
            }
        }
    }
    
    func load<T: Decodable>(fileName: String, type: T.Type) -> T? {
        guard let folder = cacheDirectory else { return nil }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileUrl.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let object = try JSONDecoder().decode(type, from: data)
            return object
        } catch {
            print("Error loading cache \(fileName): \(error)")
            return nil
        }
    }
    
    func clear(fileName: String) {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileUrl)
    }
}

nonisolated struct NetworkCacheManager {
    static let shared = NetworkCacheManager()
    
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func save<T: Encodable>(_ object: T, fileName: String) {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        Task.detached {
            do {
                let data = try JSONEncoder().encode(object)
                try data.write(to: fileUrl)
            } catch {
                print("Error saving cache \(fileName): \(error)")
            }
        }
    }
    
    func load<T: Decodable>(fileName: String, type: T.Type) -> T? {
        guard let folder = cacheDirectory else { return nil }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileUrl.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let object = try JSONDecoder().decode(type, from: data)
            return object
        } catch {
            print("Error loading cache \(fileName): \(error)")
            return nil
        }
    }
    
    func clear(fileName: String) {
        guard let folder = cacheDirectory else { return }
        let fileUrl = folder.appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileUrl)
    }
}

