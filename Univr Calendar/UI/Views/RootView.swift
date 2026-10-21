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
    @Environment(\.scenePhase) private var scenePhase
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
            } else {
                ZStack {
                    if showSplash {
                        splashScreen
                    } else if settings.onboardingCompleted {
                        CalendarView()
                    } else {
                        Onboarding()
                    }
                }
            }
        }
        .task {
            Task { await statusManager.refresh() }
            try? await Task.sleep(for: .milliseconds(250))
            showSplash = false
        }
        .onChange(of: statusManager.isResolved, initial: true) { _, resolved in
            if resolved && settings.onboardingCompleted {
                showSplash = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            if ServerStatusCenter.shared.isUnreachable {
                Task {
                    await ServerStatusCenter.shared.retryNow()
                }
            }
        }
        .onChange(of: NetworkStatusMonitor.shared.status) { oldStatus, newStatus in
            if oldStatus == .disconnected && newStatus == .connected {
                Task {
                    if ServerStatusCenter.shared.isUnreachable {
                        await ServerStatusCenter.shared.retryNow()
                    } else {
                        await ServerStatusCenter.shared.executeHandlersOnce()
                    }
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
