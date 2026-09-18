//
//  PersonalEventCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct PersonalEventCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let event: PersonalEvent
    
    private var durationMinutes: Int {
        let diff = event.endTime.timeIntervalSince(event.startTime)
        return Int(max(0, diff) / 60)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            timeInfo
            eventInfo
        }
        .padding()
        .background(backgroundLayer)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect(.lift)
        .padding(.horizontal, 15)
    }
    
    // MARK: - Components
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .fill(Color.blue.opacity(0.8)) // Un colore distintivo per gli eventi personali
    }
    
    private var timeInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.startTime.formatted(.dateTime.hour().minute()))
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.medium)
            
            Label(Duration.seconds(durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)), systemImage: "clock")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Spacer()
        }
        .foregroundStyle(Color.white)
    }
    
    private var eventInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.title)
                .foregroundStyle(Color.white)
                .font(.headline)
                .multilineTextAlignment(.leading)
            
            if let location = event.location, !location.isEmpty {
                Text(location)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
