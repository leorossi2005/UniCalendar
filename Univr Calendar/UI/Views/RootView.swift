//
//  RootView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct RootView: View {
    @Environment(UserSettings.self) var settings
    @Environment(AppStatusManager.self) var statusManager
    
    @State private var showSplash: Bool = true
    
    private static let iconSize: CGFloat = 200
    
    var body: some View {
        Group {
            if let blockingNotice = statusManager.activeNotices.first(where: { $0.level == .blocking }) {
                NavigationStack {
                    AppNoticeView(notices: [blockingNotice])
                }
                .transition(.opacity)
            } else {
                ZStack {
                    if showSplash {
                        splashScreen
                    } else if settings.onboardingCompleted {
                        CalendarView()
                            .transition(.opacity)
                    } else {
                        Onboarding()
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(.default, value: settings.onboardingCompleted)
        .animation(.default, value: statusManager.activeNotices)
        .task {
            Task { await statusManager.refresh() }
            let delay = settings.onboardingCompleted ? 500 : 1500
            try? await Task.sleep(for: .milliseconds(delay))
            showSplash = false
        }
        .onChange(of: statusManager.isResolved, initial: true) { _, resolved in
            if resolved && settings.onboardingCompleted {
                showSplash = false
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
                .frame(width: Self.iconSize, height: Self.iconSize)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RootView()
        .environment(UserSettings.shared)
        .environment(AppStatusManager())
        .readSafeAreaInsets()
}
