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
    @State private var settings: UserSettings = .shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
    }
}
