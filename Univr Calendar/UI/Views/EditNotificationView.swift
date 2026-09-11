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
    let notification: SavedNotification
    @State private var offsetMinutes: Int
    @State private var enableLiveActivity: Bool = false
    
    @State private var notificationManager = NotificationManager.shared
    
    init(notification: SavedNotification) {
        self.notification = notification
        _offsetMinutes = State(initialValue: notification.offsetMinutes)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Avviso", selection: $offsetMinutes) {
                    Text("Ad inizio lezione").tag(0)
                        .disabled(!canSchedule(offset: 0))
                    Text("5 minuti prima").tag(5)
                        .disabled(!canSchedule(offset: 5))
                    Text("15 minuti prima").tag(15)
                        .disabled(!canSchedule(offset: 15))
                    Text("30 minuti prima").tag(30)
                        .disabled(!canSchedule(offset: 30))
                    Text("1 ora prima").tag(60)
                        .disabled(!canSchedule(offset: 60))
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
                offsetMinutes: offsetMinutes
            )
            
            await notificationManager.updateNotification(updatedNotification)
        }
    }
    
    private func canSchedule(offset: Int) -> Bool {
        notification.date.addingTimeInterval(Double(-offset * 60)) > Date().addingTimeInterval(60)
    }
}
