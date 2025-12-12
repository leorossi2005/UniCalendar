//
//  Univr_CalendarApp.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import SwiftUI
import UnivrCore

@main
struct Univr_CalendarApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(UserSettings.shared)
                .environment(\.safeAreaInsets, UIApplication.shared.safeAreas)
        }
    }
}
