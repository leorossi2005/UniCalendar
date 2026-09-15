//
//  StorageProvider.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

public struct StorageProvider: Sendable {
    public var fetchNotifications: @Sendable () async throws -> [SavedNotification]
    public var saveNotification: @Sendable (SavedNotification) async throws -> Void
    public var deleteNotification: @Sendable (String) async throws -> Void
    
    public init(
        fetchNotifications: @escaping @Sendable () async throws -> [SavedNotification],
        saveNotification: @escaping @Sendable (SavedNotification) async throws -> Void,
        deleteNotification: @escaping @Sendable (String) async throws -> Void
    ) {
        self.fetchNotifications = fetchNotifications
        self.saveNotification = saveNotification
        self.deleteNotification = deleteNotification
    }
}
