//
//  CacheManager.swift
//  UnioCore
//
//  Created by Leonardo Rossi on 21/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public actor CacheManager: Sendable {
    public static let shared = CacheManager()
    
    private let folder: URL = .cachesDirectory
    
    func save<T: Encodable>(_ object: T, file: CacheFile) async {
        let fileUrl = folder.appending(path: file.fileName)
        
        do {
            let data = try JSONEncoder().encode(object)
            try await Task.detached(priority: .utility) {
                try data.write(to: fileUrl)
            }.value
        } catch {
            print("Error saving cache \(file.fileName): \(error)")
        }
    }
    
    func load<T: Decodable & Sendable>(file: CacheFile, type: T.Type) async -> T? {
        let fileUrl = folder.appending(path: file.fileName)
        
        guard FileManager.default.fileExists(atPath: fileUrl.path()) else { return nil }
        
        do {
            let data = try await Task.detached(priority: .utility) {
                try Data(contentsOf: fileUrl)
            }.value
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Error loading cache \(file.fileName): \(error)")
            try? FileManager.default.removeItem(at: fileUrl)
            return nil
        }
    }
    
    public func clear(file: CacheFile) async {
        let fileUrl = folder.appending(path: file.fileName)
        
        guard FileManager.default.fileExists(atPath: fileUrl.path()) else { return }
        
        do {
            try await Task.detached(priority: .utility) {
                try FileManager.default.removeItem(at: fileUrl)
            }.value
        } catch {
            print("Error clearing cache \(file.fileName): \(error)")
        }
    }
    
    public func clearAllDiskCache() async {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return }
        
        do {
            try await Task.detached(priority: .utility) {
                for url in contents where url.pathExtension == "json" {
                    try FileManager.default.removeItem(at: url)
                }
            }.value
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}
