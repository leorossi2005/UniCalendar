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
        HStack(alignment: .top, spacing: 20) {
            timeInfo
            itemInfo
        }
        .padding()
        .padding(.bottom, 12)
        .opacity(internalItem.isCanceled ? 0.5 : 1.0)
        .background(backgroundLayer)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect(.lift)
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 2) {
            Text(item.startTime.formatted(.dateTime.hour().minute()))
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.medium)
            
            if !internalItem.isCanceled {
                HStack {
                    VerticalLine(color: Color(white: 0.3), lineWidth: 2)
                        .frame(height: 16)
                    Text(Duration.seconds(internalItem.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.3))
                }
                .padding(.leading, 8)
                Text(item.displayable.endTime.formatted(.dateTime.hour().minute()))
                    .font(.title3.monospacedDigit())
                    .fontWeight(.regular)
                    .foregroundStyle(Color(white: 0.3))
            }
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
                Label(loc, systemImage: "mappin")
                    .foregroundStyle(Color(white: 0.3))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            if !internalItem.tagsItems.isEmpty && !internalItem.isCanceled {
                tagsList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tagsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(internalItem.tagsItems.prefix(3)) { tag in
                HStack {
                    Text(tag.name)
                        .foregroundStyle(.black)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    
                    if internalItem.tagsItems.count > 3 && internalItem.tagsItems[2] == tag {
                        Text("+\(internalItem.tagsItems.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.3))
                    }
                }
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
    
    @State private var showDeletePopover: Bool = false
    
    var body: some View {
        if case .lesson(let lesson) = item, lesson.type == .pause || lesson.type == .closure {
            PauseCard(item: internalItem)
        } else {
            CalendarItemCard(item: item, internalItem: internalItem)
                .onTapGesture {
                    Haptics.play(.impact(weight: .light, intensity: 0.5))
                    sheetRouter.routeToItem(item)
                }
                .contextMenu {
                    switch item {
                    case .lesson:
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToItem(item, addToCalendar: true)
                        }) {
                            Label("Aggiungi al calendario", systemImage: "calendar.badge.plus")
                        }
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToItem(item)
                        }) {
                            Label("Vedi più dettagli", systemImage: "ellipsis")
                        }
                    case .personal(let event):
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToAddPersonalEvent(editing: event)
                        }) {
                            Label("Modifica", systemImage: "pencil")
                        }
                        Button(action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            sheetRouter.routeToItem(item)
                        }) {
                            Label("Vedi più dettagli", systemImage: "ellipsis")
                        }
                        Button(role: .destructive, action: {
                            Haptics.play(.impact(weight: .light, intensity: 0.5))
                            showDeletePopover = true
                        }) {
                            Label("Cancella", systemImage: "trash")
                        }
                    }
                } preview: {
                    CalendarItemPreview(item: item, internalItem: internalItem)
                }
                .alert("Eliminare questo impegno?", isPresented: $showDeletePopover) {
                    Button("Conferma", role: .destructive, action: deleteEvent)
                    Button("Annulla", role: .cancel) {}
                } message: {
                    Text("Questa azione non può essere annullata.")
                }
        }
    }
    
    private func deleteEvent() {
        if case .personal(let event) = item {
            Task {
                await CommitmentsManager.shared.deleteEvent(id: event.id)
            }
        }
    }
}
