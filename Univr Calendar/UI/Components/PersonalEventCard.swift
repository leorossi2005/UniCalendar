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
            .overlay {
                CustomMeshGradient(
                    width: BaseGradient.width,
                    height: BaseGradient.height,
                    points: BaseGradient.points,
                    colors: BaseGradient.colors,
                    background: BaseGradient.background,
                    smoothsColors: BaseGradient.smoothsColors
                )
                .opacity(0.7)
                .background(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
    }
    
    private var timeInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.startTime.formatted(.dateTime.hour().minute()))
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.medium)
            
            Label(Duration.seconds(event.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)), systemImage: "clock")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Spacer()
        }
        .foregroundStyle(Color.black)
    }
    
    private var eventInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.title)
                .foregroundStyle(Color.black)
                .font(.headline)
                .multilineTextAlignment(.leading)
            
            if let location = event.location, !location.isEmpty {
                Text(location)
                    .foregroundStyle(Color(white: 0.3))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            if !event.tags.isEmpty {
                tagsList
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(event.tags, id: \.self) { tag in
                Text(tag)
                    .foregroundStyle(.black)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }
}
