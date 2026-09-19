//
//  CalendarItemCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct CalendarItemCard: View {
    let item: CalendarItem
    let internalItem: any CalendarDisplayable
    
    var body: some View {
        HStack(spacing: 20) {
            timeInfo
            itemInfo
        }
        .padding()
        .opacity(internalItem.isCanceled ? 0.5 : 1.0)
        .background(backgroundLayer)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect(.lift)
        .padding(.horizontal, 15)
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var backgroundLayer: some View {
        switch item {
        case .lesson(let lesson):
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(lesson.isCanceled ? Color(.systemBackground) : lesson.uiColor)
                .overlay {
                    if lesson.isCanceled {
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .strokeBorder(.secondary, lineWidth: 0.5)
                    }
                }
        case .personal:
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
    }
    
    private var timeInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.startTime.formatted(.dateTime.hour().minute()))
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.medium)
            
            if !internalItem.isCanceled {
                Label(Duration.seconds(internalItem.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)), systemImage: "clock")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            Spacer()
        }
        .foregroundStyle(internalItem.isCanceled ? Color.primary : Color.black)
    }
    
    private var itemInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(internalItem.displayTitle)
                .foregroundStyle(internalItem.isCanceled ? Color.primary : Color.black)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .strikethrough(internalItem.isCanceled)
            
            if !internalItem.isCanceled, let loc = internalItem.displayLocation, !loc.isEmpty {
                Text(loc)
                    .foregroundStyle(Color(white: 0.3))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            if !internalItem.tags.isEmpty {
                tagsList
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(internalItem.tags, id: \.self) { tag in
                Text(tag)
                    .foregroundStyle(.black)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }
}

struct PauseCard: View {
    let item: any CalendarDisplayable
    
    var body: some View {
        HStack(alignment: .bottom) {
            Image(systemName: .cupDynamic)
                .font(.system(size: 40))
            Text(Duration.seconds(item.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                .font(.system(size: 30))
                .italic()
                .bold()
        }
        .foregroundStyle(.secondary)
    }
}

struct CardItemContainer: View {
    let item: CalendarItem
    let sheetRouter: CalendarSheetRouter
    let internalItem: any CalendarDisplayable
    
    init(item: CalendarItem, sheetRouter: CalendarSheetRouter) {
        self.item = item
        self.sheetRouter = sheetRouter
        internalItem = item.displayable
    }
    
    var body: some View {
        if case .lesson(let lesson) = item, lesson.type == .pause || lesson.type == .closure {
            PauseCard(item: internalItem)
        } else {
            CalendarItemCard(item: item, internalItem: internalItem)
                .onTapGesture {
                    Haptics.play(.impact(weight: .light, intensity: 0.5))
                    switch item {
                    case .lesson(let lesson):
                        sheetRouter.routeToLesson(lesson)
                    case .personal(let event):
                        sheetRouter.routeToPersonalEvent(event)
                    }
                }
                .contextMenu {
                    switch item {
                    case .lesson(let lesson):
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToLesson(lesson, addToCalendar: true)
                        }) {
                            Label("Aggiungi al calendario", systemImage: "calendar.badge.plus")
                        }
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToLesson(lesson)
                        }) {
                            Label("Vedi più dettagli", systemImage: "ellipsis")
                        }
                    case .personal(let event):
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToPersonalEvent(event)
                        }) {
                            Label("Modifica", systemImage: "pencil")
                        }
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToPersonalEvent(event)
                        }) {
                            Label("Vedi più dettagli", systemImage: "ellipsis")
                        }
                    }
                } preview: {
                    CalendarItemPreview(item: item, internalItem: internalItem)
                }
        }
    }
}
