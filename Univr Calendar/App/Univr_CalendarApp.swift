//
//  Univr_CalendarApp.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet
import SwiftData

@main
struct Univr_CalendarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: NotificationRecord.self, PersonalEventRecord.self)
        } catch {
            fatalError("Impossibile creare il database: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(UserSettings.shared)
                .environment(\.safeAreaInsets, UIApplication.shared.safeAreas)
                .modelContainer(container)
                .enableGlobalHaptics()
                .task {
                    NetworkStatusMonitor.shared.start(provider: IOSNetworkMonitor.createProvider())
                    let storage = IOSStorageService.createProvider(container: container)
                    NotificationManager.shared.configure(
                        notificationProvider: IOSNotificationService.createProvider(),
                        storageProvider: storage
                    )
                    CommitmentsManager.shared.configure(storageProvider: storage)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await NotificationManager.shared.cleanupExpiredNotifications()
                }
            }
        }
    }
}
