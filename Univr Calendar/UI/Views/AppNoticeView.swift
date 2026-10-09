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
    
    let notices: [EvaluatedNotice]
    var onDismiss: (() -> Void)?
    
    @State private var currentIndex: Int? = 0
    
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
        .animation(.snappy, value: currentIndex)
        .onChange(of: (currentIndex ?? 0), initial: true) { _, newIndex in
            updateLockState(for: newIndex)
        }
        .onDisappear {
            sheetManager?.setLock(false)
        }
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
                let safeIndex = min(max(currentIndex ?? 0, 0), max(0, notices.count - 1))
                if !notices.isEmpty {
                    if let endDate = notices[safeIndex].endsAt {
                        Text("\(formatDate(notices[safeIndex].date)) - \(formatDate(endDate))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .fixedSize()
                            .contentTransition(.numericText())
                    } else {
                        Text(formatDate(notices[safeIndex].date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .fixedSize()
                            .contentTransition(.numericText())
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    private func updateLockState(for index: Int) {
        let safeIndex = min(max(index, 0), notices.count - 1)
        if safeIndex < notices.count - 1 {
            sheetManager?.setLock(true)
        } else {
            let isLastBlocking = notices[safeIndex].level == .blocking
            sheetManager?.setLock(isLastBlocking)
        }
    }
    
    private func noticePage(notice: EvaluatedNotice, index: Int) -> some View {
        let isLast = index == notices.count - 1
        
        return VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: notice.level == .warning ? "exclamationmark.triangle.fill" : notice.level == .blocking ? "xmark.octagon.fill" : "info.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(notice.level == .warning ? .orange : notice.level == .blocking ? .red : .blue)
                .padding(.bottom, 16)
            
            Text(notice.title)
                .font(.title.bold())
            
            Text(notice.message)
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
                        Text(notice.buttonText ?? String(localized: "Aggiorna"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .glassIfAvailable(prominent: true)
                }
                
                if !isLast {
                    Button {
                        Haptics.play(.impact(weight: .light))
                        let nextIndex = (currentIndex ?? 0) + 1
                        
                        withAnimation {
                            currentIndex = min(nextIndex, notices.count - 1)
                        }
                    } label: {
                        Text("Continua")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .glassIfAvailable(prominent: false)
                } else if onDismiss != nil && notice.level != .blocking {
                    Button {
                        Haptics.play(.impact(weight: .medium))
                        onDismiss?()
                    } label: {
                        Text(notice.buttonText != nil && notice.actionURL == nil ? notice.buttonText! : String(localized: "Chiudi"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .glassIfAvailable(prominent: false)
                }
            }
        }
        .padding(.horizontal, safeAreas.bottom > 0 ? safeAreas.bottom : 24)
    }
}
