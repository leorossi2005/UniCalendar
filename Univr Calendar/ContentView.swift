//
//  ContentView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    
    @State var selectedTab: Int = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Onboarding(selectedTab: $selectedTab)
                .toolbarVisibility(.hidden, for: .tabBar)
                .tag(1)
            CalendarView(selectedTab: $selectedTab)
                .toolbarVisibility(.hidden, for: .tabBar)
                .tag(0)
        }
        .tabViewStyle(.tabBarOnly)
        .onAppear {
            selectedTab = onboardingCompleted ? 0 : 1
        }
    }
}

#Preview {
    ContentView()
}
