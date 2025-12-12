//
//  RootView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
//

import SwiftUI
import UnivrCore

struct RootView: View {
    @Environment(UserSettings.self) var settings
    
    @State private var showSplash: Bool = true
    @Namespace private var animation
    
    
    private static let iconSize: CGFloat = 200
    
    var body: some View {
        ZStack {
            if settings.onboardingCompleted {
                CalendarView()
            } else {
                Onboarding(animation: animation, showSplash: $showSplash)
            }
            
            if showSplash {
                splashScreen
            }
        }
    }
    
    // MARK: - Subviews
    private var splashScreen: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("InternalIcon")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: Self.iconSize * 0.225, style: .continuous))
                .matchedGeometryEffect(id: "appIcon", in: animation, isSource: true)
                .frame(width: Self.iconSize, height: Self.iconSize)
        }
        .zIndex(1)
        .ignoresSafeArea()
        .task {
            await handleSplashDelay()
        }
    }
    
    // MARK: - Logic
    private func handleSplashDelay() async {
        if settings.onboardingCompleted {
            showSplash = false
        } else {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showSplash = false
            }
        }
    }
}

#Preview {
    RootView()
        .environment(UserSettings.shared)
}
