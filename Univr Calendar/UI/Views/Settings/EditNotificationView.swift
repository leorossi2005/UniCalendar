//
//  EditNotificationView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 11/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct EditNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let notification: SavedNotification
    @State private var offsetMinutes: Int
    @State private var enableLiveActivity: Bool = false
    
    private var notificationManager = NotificationManager.shared
    
    init(notification: SavedNotification) {
        self.notification = notification
        _offsetMinutes = State(initialValue: notification.offsetMinutes)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Avviso", selection: $offsetMinutes) {
                    if canSchedule(offset: 0) || offsetMinutes == 0 {
                        notificationText(for: 0)
                    }
                    if canSchedule(offset: 5) || offsetMinutes == 5 {
                        notificationText(for: 5)
                    }
                    if canSchedule(offset: 15) || offsetMinutes == 15 {
                        notificationText(for: 15)
                    }
                    if canSchedule(offset: 30) || offsetMinutes == 30 {
                        notificationText(for: 30)
                    }
                    if canSchedule(offset: 60) || offsetMinutes == 60 {
                        notificationText(for: 60)
                    }
                }
                .onChange(of: offsetMinutes) {
                    saveChanges()
                }
                
                Toggle("Usa Live Activity (Prossimamente)", isOn: $enableLiveActivity)
                    .disabled(true)
            } header: {
                Text("Impostazioni Notifica")
            } footer: {
                Text("Le Live Activity ti permetteranno di avere un timer a schermo sulla schermata di blocco o nella Dynamic Island.")
            }
        }
        .navigationTitle("Modifica Notifica")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notificationManager.activeNotifications) {
            if !notificationManager.activeNotifications.contains(where: { $0.id == notification.id }) {
                dismiss()
            }
        }
    }
    
    
    
    @ViewBuilder
    private func notificationText(for offset: Int) -> some View {
        let label = offset == 0 ? String(localized: "Ad inizio impegno") : (offset == 60 ? String(localized: "1 ora prima") : String(localized: "\(offset) minuti prima"))
        
        Text(label).tag(offset)
    }
    
    private func saveChanges() {
        Task {
            let updatedNotification = SavedNotification(
                id: notification.id,
                courseId: notification.courseId,
                courseName: notification.courseName,
                courseYear: notification.courseYear,
                lessonName: notification.lessonName,
                date: notification.date,
                offsetMinutes: offsetMinutes,
                itemPayload: notification.itemPayload
            )
            
            await notificationManager.updateNotification(updatedNotification)
        }
    }
    
    private func canSchedule(offset: Int) -> Bool {
        notification.date.addingTimeInterval(Double(-offset * 60)) > Date().addingTimeInterval(60)
    }
}
