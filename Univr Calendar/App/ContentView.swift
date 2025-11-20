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
    
    @State private var years: [Year] = []
    @State private var courses: [Corso] = []
    @State private var academicYears: [Anno] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Onboarding(selectedTab: $selectedTab)
                .hideTabBarCompatible()
                .tag(1)
            CalendarView(years: $years, courses: $courses, academicYears: $academicYears, selectedTab: $selectedTab)
                .hideTabBarCompatible()
                .tag(0)
        }
        .hideTabBarCompatible()
        .onAppear {
            selectedTab = onboardingCompleted ? 0 : 1
        }
    }
}

#Preview {
    ContentView()
}
