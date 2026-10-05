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
    @Namespace private var animation
    
    private static let iconSize: CGFloat = 200
    
    var body: some View {
        Group {
            if case .blocking(let notice) = statusManager.activeNoticeAction {
                AppNoticeView(notice: notice)
                    .transition(.opacity)
            } else {
                ZStack {
                    if showSplash {
                        splashScreen
                    } else if settings.onboardingCompleted {
                        CalendarView()
                            .transition(.opacity)
                    } else {
                        Onboarding(animation: animation, showSplash: $showSplash)
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(.default, value: settings.onboardingCompleted)
        .animation(.default, value: statusManager.activeNoticeAction)
        .task {
            Task { await statusManager.refresh() }
            let delay = settings.onboardingCompleted ? 500 : 1500
            try? await Task.sleep(for: .milliseconds(delay))
            withAnimation(settings.onboardingCompleted ? nil : .spring(response: 0.7, dampingFraction: 0.8)) {
                showSplash = false
            }
        }
        .onChange(of: statusManager.isResolved, initial: true) { _, resolved in
            if resolved && settings.onboardingCompleted {
                withAnimation(nil) {
                    showSplash = false
                }
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
    }
}

#Preview {
    RootView()
        .environment(UserSettings.shared)
        .environment(AppStatusManager())
}
