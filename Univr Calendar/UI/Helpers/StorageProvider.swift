//
//  StorageProvider.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import SwiftData
import UnivrCore

@Model
final class NotificationRecord {
    @Attribute(.unique) var id: String
    var itemData: Data
    
    @Transient
    var item: SavedNotification? {
        get { try? JSONDecoder().decode(SavedNotification.self, from: itemData) }
        set { 
            if let encoded = try? JSONEncoder().encode(newValue) {
                itemData = encoded
            }
        }
    }
    
    init(item: SavedNotification) {
        self.id = item.id
        self.itemData = (try? JSONEncoder().encode(item)) ?? Data()
    }
}

@ModelActor
actor DatabaseHandler {
    func fetchNotifications() throws -> [SavedNotification] {
        let descriptor = FetchDescriptor<NotificationRecord>()
        let records = try modelContext.fetch(descriptor)
        return records.compactMap { $0.item }
    }
    
    func saveNotification(_ notification: SavedNotification) throws {
        let id = notification.id
        let descriptor = FetchDescriptor<NotificationRecord>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.item = notification
        } else {
            modelContext.insert(NotificationRecord(item: notification))
        }
        try modelContext.save()
    }
    
    func deleteNotification(id: String) throws {
        let descriptor = FetchDescriptor<NotificationRecord>(predicate: #Predicate { $0.id == id })
        if let toDelete = try modelContext.fetch(descriptor).first {
            modelContext.delete(toDelete)
            try modelContext.save()
        }
    }
}

final class IOSStorageService: Sendable {
    static func createProvider(container: ModelContainer) -> StorageProvider {
        let handler = DatabaseHandler(modelContainer: container)
        
        return StorageProvider(
            fetchNotifications: {
                try await handler.fetchNotifications()
            },
            saveNotification: { notification in
                try await handler.saveNotification(notification)
            },
            deleteNotification: { id in
                try await handler.deleteNotification(id: id)
            }
        )
    }
}
