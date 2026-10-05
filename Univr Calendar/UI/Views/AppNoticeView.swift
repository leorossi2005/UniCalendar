//
//  AppNoticeView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct AppNoticeView: View {
    @Environment(\.safeAreaInsets) private var safeAreas
    
    let notice: EvaluatedNotice
    var onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
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
                        Text("Aggiorna")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .glassProminentIfAvailable()
                }
            }
            .padding(.horizontal, safeAreas.bottom)
        }
    }
}
