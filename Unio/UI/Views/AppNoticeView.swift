//
//  AppNoticeView.swift
//  Unio
//
//  Created by Leonardo Rossi on 05/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnioCore
import CustomSheet

struct AppNoticeView: View {
    @Environment(\.safeAreaInsets) private var safeAreas
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(GlobalSheetManager.self) private var sheetManager: GlobalSheetManager?
    
    let notices: [AppNotice]
    var onDismiss: (() -> Void)?
    
    @State private var currentIndex: Int? = 0
    
    private var currentNotice: AppNotice? {
        guard let currentIndex, notices.indices.contains(currentIndex) else {
            return notices.first
        }
        return notices[currentIndex]
    }
    
    @AccessibilityFocusState private var isToolbarFocused: Bool
    @AccessibilityFocusState private var isHeaderFocused: Bool
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(notices.enumerated()), id: \.element.id) { index, notice in
                    noticePage(notice: notice, index: index)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                        .accessibilityElement(children: .contain)
                        .accessibilityHidden(currentIndex != index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.never, axes: .horizontal)
        .scrollPosition(id: $currentIndex, anchor: .center)
        .scrollDisabled(true)
        .toolbar {
            if notices.count > 1 {
                ToolbarItem(placement: .topBarLeading) {
                    Text("\((currentIndex ?? 0) + 1) di \(notices.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding()
                        .fixedSize()
                        .contentTransition(.numericText())
                        .accessibilityLabel("Avviso \((currentIndex ?? 0) + 1) di \(notices.count)")
                        .accessibilityFocused($isToolbarFocused)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if let currentNotice {
                    ShareLink(item: currentNotice.shareText)
                }
            }
        }
        .animation(.snappy, value: currentIndex)
        .onChange(of: (currentIndex ?? 0), initial: true) { _, newIndex in
            updateLockState(for: newIndex)
            
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isHeaderFocused = true
            }
        }
        .onDisappear { sheetManager?.setLock(false) }
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            isToolbarFocused = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func updateLockState(for index: Int) {
        guard !notices.isEmpty else {
            sheetManager?.setLock(false)
            return
        }
        let safeIndex = min(max(index, 0), notices.count - 1)
        if safeIndex < notices.count - 1 {
            sheetManager?.setLock(true)
        } else {
            let isLastBlocking = notices[safeIndex].level == .blocking
            sheetManager?.setLock(isLastBlocking)
        }
    }
    
    private func levelPrefix(notice: AppNotice) -> String {
        switch notice.level {
        case .info: String(localized: .lowPriorityNoticeTag)
        case .warning: String(localized: "Attenzione")
        case .blocking: String(localized: "Avviso importante")
        }
    }

    private func accessibleDateText(startsAt: Date, endsAt: Date?) -> String {
        let start = startsAt.formatted(.dateTime.day().month(.wide).year())
        if let endsAt {
            let end = endsAt.formatted(.dateTime.day().month(.wide).year())
            return String(localized: "Dal \(start) al \(end)")
        } else {
            return String(localized: "Pubblicato il \(start)")
        }
    }

    private func noticePage(notice: AppNotice, index: Int) -> some View {
        let isLast = index == notices.count - 1
        let hasButtons = (notice.actionURL != nil) || (!isLast) || (onDismiss != nil && notice.level != .blocking)
        
        return VStack(spacing: hasButtons ? 16 : 0) {
            GeometryReader { geo in
                ScrollView(.vertical) {
                    VStack(spacing: 20) {
                        Spacer(minLength: 0)
                        
                        Image(systemName: notice.level.systemImage)
                            .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 48 : 64))
                            .foregroundStyle(notice.level.tintColor)
                            .accessibilityHidden(true)
                        
                        VStack(spacing: 8) {
                            Text(notice.localizedTitle)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("\(levelPrefix(notice: notice)): \(notice.localizedTitle)")
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused($isHeaderFocused)
                            
                            if !notices.isEmpty {
                                let dateText = if let endDate = notice.endsAt {
                                    "\(formatDate(notice.startsAt)) - \(formatDate(endDate))"
                                } else {
                                    formatDate(notice.startsAt)
                                }
                                
                                Text(dateText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .accessibilityLabel(accessibleDateText(startsAt: notice.startsAt, endsAt: notice.endsAt))
                            }
                        }
                        
                        Text(notice.localizedMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollDisabled(false)
                .scrollBounceBehavior(.basedOnSize)
            }
            
            if hasButtons {
                VStack(spacing: 12) {
                    if let url = notice.actionURL {
                        Button {
                            Haptics.play(.impact(weight: .medium))
                            UIApplication.shared.open(url)
                        } label: {
                            Text(notice.localizedButtonText ?? String(localized: "Aggiorna"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .glassIfAvailable(prominent: isLast && (onDismiss == nil || notice.level == .blocking))
                        .accessibilityHint(notice.level == .blocking ? "Apre l'aggiornamento su App Store" : "Apre il link esterno")
                    }
                    
                    if !isLast {
                        Button {
                            Haptics.play(.impact(weight: .light))
                            let nextIndex = (currentIndex ?? 0) + 1
                            currentIndex = min(nextIndex, notices.count - 1)
                        } label: {
                            Text("Continua")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .glassIfAvailable(prominent: true)
                        .accessibilityHint("Passa all'avviso successivo")
                    } else if onDismiss != nil && notice.level != .blocking {
                        Button {
                            Haptics.play(.impact(weight: .medium))
                            onDismiss?()
                        } label: {
                            let buttonLabel = (notice.actionURL == nil ? notice.localizedButtonText : nil) ?? String(localized: "Chiudi")
                            Text(buttonLabel)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .glassIfAvailable(prominent: true)
                    }
                }
            }
        }
        .padding(.horizontal, max(safeAreas.bottom, 16))
        .safeAreaPadding(.bottom, hasButtons ? (safeAreas.bottom == 0 ? 16 : 0) : 0)
    }
}
