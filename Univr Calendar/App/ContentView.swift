//
//  ContentView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import SwiftUI
import UnivrCore

struct ContentView: View {
    @Environment(UserSettings.self) var settings

    @State var selectedTab: Int = 1

    @State var animation: Namespace.ID
    @Binding var showSplash: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Onboarding(selectedTab: $selectedTab, animation: animation, showSplash: $showSplash)
                .hideTabBarCompatible()
                .tag(1)
            CalendarView(selectedTab: $selectedTab)
                .hideTabBarCompatible()
                .tag(0)
        }
        .hideTabBarCompatible()
        .onAppear {
            selectedTab = settings.onboardingCompleted ? 0 : 1
        }
    }
}

#Preview {
    @Previewable @Namespace var animation: Namespace.ID
    @Previewable @State var showSplash: Bool = false
    
    ContentView(animation: animation, showSplash: $showSplash)
        .environment(UserSettings.shared)
}
