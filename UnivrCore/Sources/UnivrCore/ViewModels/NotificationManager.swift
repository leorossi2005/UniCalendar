//
//  NotificationManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    // Dati pronti per la UI
    public private(set) var activeNotifications: [SavedNotification] = []
    public var hasPermission: Bool = false
    
    // I nostri Bridge
    private var notificationProvider: NotificationProvider?
    private var storageProvider: StorageProvider?
    
    private init() {}
    
    // Iniezione delle dipendenze dall'App iOS
    public func configure(notificationProvider: NotificationProvider, storageProvider: StorageProvider) {
        self.notificationProvider = notificationProvider
        self.storageProvider = storageProvider
        Task {
            await fetchSavedNotifications()
        }
    }
    
    public func fetchSavedNotifications() async {
        guard let storage = storageProvider else { return }
        do {
            activeNotifications = try await storage.fetchNotifications()
        } catch {
            print("Errore caricamento notifiche dal database: \(error)")
        }
    }
    
    public func toggleNotification(notification: SavedNotification) async -> Bool {
        guard let notifier = notificationProvider, let storage = storageProvider else { return false }
        
        let granted = await notifier.requestPermission()
        self.hasPermission = granted
        guard granted else { return false }
        
        // Cancella eventuali duplicati
        notifier.cancel(notification.id)
        
        // Suona l'allarme nell'OS
        let success = await notifier.schedule(notification)
        guard success else { return false }
        
        // Salva nel database e aggiorna la UI
        do {
            try await storage.saveNotification(notification)
            await fetchSavedNotifications()
            return true
        } catch {
            print("Errore salvataggio database: \(error)")
            return false
        }
    }
    
    public func removeNotification(id: String) async {
        guard let notifier = notificationProvider, let storage = storageProvider else { return }
        
        // Rimuove dall'OS
        notifier.cancel(id)
        
        // Rimuove dal Database
        do {
            try await storage.deleteNotification(id)
            await fetchSavedNotifications()
        } catch {
            print("Errore eliminazione dal database: \(error)")
        }
    }
}
