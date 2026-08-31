//
//  RoomCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct RoomCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var room: Room
    var selectedDate: Date
        
    var body: some View {
        TimelineView(.everyMinute) { context in
            let currentStatus = RoomDailyStatus(room: room, selectedDate: selectedDate, now: context.date)
            
            VStack(spacing: 20) {
                LessonInfo(room: room, status: currentStatus)
                Timeline(room: room, now: context.date, currentStatus: currentStatus)
            }
            .padding()
            .padding(.bottom, 4)
            .background(backgroundLayer)
            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 35, style: .continuous))
            .hoverEffect(.lift)
        }
    }
    
    // MARK: - Components
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .fill(Color(colorScheme == .dark ? .secondarySystemGroupedBackground : .systemGroupedBackground))
        
    }
}

private struct LessonInfo: View {
    var room: Room
    var status: RoomDailyStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(room.name)
                .font(.headline)
                .multilineTextAlignment(.leading)
            Text(status.statusText)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Timeline: View {
    var room: Room
    var now: Date
    var currentStatus: RoomDailyStatus
    
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                Color.clear.frame(width: 16, height: 0)
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            }
            
            GridRow {
                switch currentStatus {
                case .pastDay, .futureDay, .futureDayFree:
                    EmptyView()
                default:
                    HorizontalLine(color: .primary, lineWidth: 4, dash: [12, 12])
                    nowIndicator
                }
                
                HStack {
                    switch currentStatus {
                    case .occupiedUntil(let event, let index, _):
                        eventSegment(event: event, index: index, showStartMarker: false)
                    case .freeUntil(let event, let index), .futureDay(let event, let index):
                        eventSegment(event: event, index: index, showStartMarker: true)
                    case .pastDay:
                        HorizontalLine(color: .primary, lineWidth: 4, dash: [12, 12])
                    default:
                        HorizontalLine(color: .green, lineWidth: 4)
                    }
                }
                .gridCellColumns(3)
            }
        }
    }
    
    private var nowIndicator: some View {
        Circle()
            .frame(height: 16)
            .overlay {
                Circle()
                    .fill(.blue)
                    .frame(height: 10)
            }
    }
    
    private func eventSegment(event: Event, index: Int, showStartMarker: Bool) -> some View {
        let subsequentEventsCount = room.events.count - (index + 1)
        let after = subsequentEventsCount > 0 && event.endTime == room.events[index + 1].startTime
        
        return Group {
            if showStartMarker {
                HorizontalLine(color: .green, lineWidth: 4)
                Circle()
                    .fill(.red)
                    .frame(height: 12)
                    .overlay {
                        Text(event.startTime, format: .dateTime.hour().minute())
                            .foregroundStyle(.red)
                            .fixedSize()
                            .font(.caption)
                            .offset(y: -16)
                    }
            }
            HorizontalLine(color: .red.opacity(0.9), lineWidth: 4)
            Circle()
                .fill(after ? .red : .green)
                .frame(height: 12)
                .overlay {
                    Text(event.endTime, format: .dateTime.hour().minute())
                        .foregroundStyle(after ? .red : .green)
                        .fixedSize()
                        .font(.caption)
                        .offset(y: -16)
                }
            HorizontalLine(color: after ? .red : .green, lineWidth: 4)
                .overlay(alignment: .trailing) {
                    if subsequentEventsCount > 0 {
                        Text("+\(subsequentEventsCount)")
                            .foregroundStyle(Color(.lightGray))
                            .fixedSize()
                            .font(.caption)
                            .offset(y: -16)
                    }
                }
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            //RoomCard(events: nil)
        }
    }
}
