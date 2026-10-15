//
//  AppNoticeView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 05/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct AppNoticeView: View {
    @Environment(\.safeAreaInsets) private var safeAreas
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
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(notices.enumerated()), id: \.element.id) { index, notice in
                    noticePage(notice: notice, index: index)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
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
        }
        .onDisappear { sheetManager?.setLock(false) }
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
    
    private func noticePage(notice: AppNotice, index: Int) -> some View {
        let isLast = index == notices.count - 1
        
        return VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: notice.level.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(notice.level.tintColor)
            
            VStack(spacing: 8) {
                Text(notice.localizedTitle)
                    .font(.title.bold())
                
                if !notices.isEmpty {
                    if let endDate = notice.endsAt {
                        Text("\(formatDate(notice.startsAt)) - \(formatDate(endDate))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatDate(notice.startsAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text(notice.localizedMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
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
        .padding(.horizontal, safeAreas.bottom > 0 ? safeAreas.bottom : 24)
    }
}
