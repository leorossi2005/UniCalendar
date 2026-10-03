//
//  CommitmentsManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 18/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public final class CommitmentsManager {
    public static let shared = CommitmentsManager()
    
    public private(set) var personalEvents: [PersonalEvent] = []
    
    private var storageProvider: StorageProvider?
    
    private init() {}
    
    public func configure(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
        Task {
            await fetchPersonalEvents()
        }
    }
    
    public func fetchPersonalEvents() async {
        guard let storage = storageProvider else { return }
        do {
            personalEvents = try await storage.fetchPersonalEvents()
        } catch {
            print("Errore caricamento impegni dal database: \(error)")
        }
    }
    
    public func addEvent(_ event: PersonalEvent) async {
        guard let storage = storageProvider else { return }
        do {
            try await storage.savePersonalEvent(event)
            
            let activeNotifications = NotificationManager.shared.activeNotifications
            if let existingNotif = activeNotifications.first(where: { $0.id == event.id }) {
                let triggerDate = event.startTime.addingTimeInterval(Double(-existingNotif.offsetMinutes * 60))
                if triggerDate > Date().addingTimeInterval(60) {
                    let updatedNotif = SavedNotification(
                        id: existingNotif.id,
                        courseId: existingNotif.courseId,
                        courseName: existingNotif.courseName,
                        courseYear: existingNotif.courseYear,
                        lessonName: event.title,
                        date: event.startTime,
                        offsetMinutes: existingNotif.offsetMinutes,
                        itemPayload: try? JSONEncoder().encode(CalendarItem.personal(event))
                    )
                    await NotificationManager.shared.updateNotification(updatedNotif)
                } else {
                    await NotificationManager.shared.removeNotification(id: existingNotif.id)
                }
            }
            
            await fetchPersonalEvents()
        } catch {
            print("Errore salvataggio impegno: \(error)")
        }
    }
    
    public func deleteEvent(id: String) async {
        guard let storage = storageProvider else { return }
        do {
            try await storage.deletePersonalEvent(id)
            await NotificationManager.shared.removeNotification(id: id)
            await fetchPersonalEvents()
        } catch {
            print("Errore eliminazione impegno: \(error)")
        }
    }
    
    public func deleteAllEvents() async {
        let events = personalEvents
        for event in events {
            await deleteEvent(id: event.id)
        }
    }
}
