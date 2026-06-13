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

@main
struct Univr_CalendarApp: App {
    @State private var networkObserver = NetworkStateObserver(
        provider: IOSNetworkMonitor.createProvider()
    )
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(networkObserver)
                .environment(UserSettings.shared)
                .environment(\.safeAreaInsets, UIApplication.shared.safeAreas)
                .enableGlobalHaptics()
        }
    }
}
