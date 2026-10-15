//
//  AppNoticesListView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 09/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct AppNoticesListView: View {
    @Environment(AppStatusManager.self) var statusManager
    @State private var isRefreshing = false
    
    var body: some View {
        Group {
            if statusManager.allNotices.isEmpty {
                ContentUnavailableView(
                    "Nessun Avviso",
                    systemImage: "bell.slash",
                    description: Text("Al momento non ci sono avvisi attivi.")
                )
            } else {
                List {
                    ForEach(statusManager.allNotices) { notice in
                        NavigationLink(destination: AppNoticeView(notices: [notice])) {
                            NoticeRow(notice: notice)
                        }
                    }
                }
            }
        }
        .navigationTitle("Avvisi di Sistema")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard !isRefreshing else { return }
                    isRefreshing = true
                    Haptics.play(.impact(weight: .light))
                    Task {
                        await statusManager.refresh()
                        statusManager.dismissAllNonBlocking()
                        isRefreshing = false
                        if statusManager.lastAttemptFailed {
                            Haptics.play(.error)
                        } else {
                            Haptics.play(.success)
                        }
                    }
                } label: {
                    if #available(iOS 18, *) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .symbolEffect(.rotate, options: .speed(6), isActive: isRefreshing)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .symbolEffect(.pulse, isActive: isRefreshing)
                    }
                }
            }
        }
    }
}

private struct NoticeRow: View {
    let notice: AppNotice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: notice.level.systemImage)
                    .foregroundStyle(notice.level.tintColor)
                    .font(.title2)
                Text(notice.localizedTitle)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                VStack(alignment: .trailing) {
                    if let endsAt = notice.endsAt {
                        Text("Dal \(notice.startsAt.formatted(date: .numeric, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Fino al \(endsAt.formatted(date: .numeric, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(notice.startsAt.formatted(date: .numeric, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text(notice.localizedMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AppNoticesListView()
    }
    .environment(AppStatusManager())
}
