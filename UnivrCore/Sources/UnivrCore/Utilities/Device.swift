//
//  Device.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

private final class Locked<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
    
    func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        try lock.withLock {
            try body(&value)
        }
    }
}

public enum Device: Sendable {
    public struct OS: Sendable, Equatable {
        public let name: String
        public let version: String
        
        public init(name: String, version: String) {
            self.name = name
            self.version = version
        }
    }
    
    public struct Info: Sendable, Equatable {
        public let name: String
        public let model: String
        public let isSimulator: Bool
        public let os: OS
        
        public init(name: String, model: String, isSimulator: Bool = false, os: OS) {
            self.name = name
            self.model = model
            self.isSimulator = isSimulator
            self.os = os
        }
    }
    
    private static let storage = Locked(
        Info(
            name: "Unknown",
            model: "Unknown",
            isSimulator: false,
            os: OS(name: "Unknown", version: "0.0.0")
        )
    )
    
    public static var current: Info {
        storage.withLock { $0 }
    }
    
    public static var name: String { current.name }
    public static var model: String { current.model }
    public static var isSimulator: Bool { current.isSimulator }
    public static var os: OS { current.os }
    
    public static func configure(with info: Info) {
        storage.withLock { $0 = info }
    }
}
