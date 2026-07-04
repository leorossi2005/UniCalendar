//
//  RoomDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 20/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct RoomDetailsView: View {
    var room: Room
    
    @State private var showOriginalName: Bool = false
    @State private var date: Date = Date()
    
    var onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerInfo
            detailRows
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .onChange(of: room) {
            showOriginalName = false
        }
    }
    
    // MARK: - Subviews
    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(room.name)
                .font(.title2.bold())
                .contentShape(.rect)
                .onTapGesture {
                    showOriginalName.toggle()
                }
            Text(room.events.isEmpty ? "Libera tutto il giorno" : "Libera ora (fino alle \(room.events.first!.startTime.formatted(.dateTime.hour().minute())))")
                .font(.title3)
                .contentShape(.rect)
                .onTapGesture {
                    showOriginalName.toggle()
                }
        }
    }
    
    private var detailRows: some View {
        ScrollView {
            Grid(verticalSpacing: 8) {
                if let firstEvent = room.events.first {
                    let startOfDay = Calendar.current.startOfDay(for: firstEvent.startTime)
                    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                    
                    GridRow {
                        VStack(spacing: 0) {
                            if startOfDay > date {
                                VerticalLine(color: .green, lineWidth: 4)
                                    .frame(height: 48)
                            } else if firstEvent.startTime > date {
                                VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                    .frame(height: 48)
                                nowIndicator
                                VerticalLine(color: .green, lineWidth: 4)
                                    .frame(height: 48)
                            } else {
                                VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                    .frame(height: 48)
                            }
                        }
                        Color.clear
                    }
                    ForEach(Array(room.events.enumerated()), id: \.element.id) { index, event in
                        GridRow {
                            if event.startTime == date {
                                nowIndicator
                            } else {
                                Circle()
                                    .fill(event.startTime < date ? Color.primary : Color.red)
                                    .frame(width: 12)
                            }
                            Text(event.startTime, format: .dateTime.hour().minute())
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(event.startTime <= date ? Color.primary : Color.red)
                        }
                        GridRow {
                            VStack(spacing: 0) {
                                if event.endTime <= date {
                                    VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                        .frame(minHeight: 48)
                                } else if event.startTime >= date {
                                    VerticalLine(color: .red, lineWidth: 4)
                                        .frame(minHeight: 48)
                                } else {
                                    VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                        .frame(minHeight: 48)
                                    nowIndicator
                                    VerticalLine(color: .red, lineWidth: 4)
                                        .frame(minHeight: 48)
                                }
                            }
                            Text(event.cleanName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16)
                        }
                        let isLast = index == room.events.count - 1
                        let hasGap = !isLast && event.endTime != room.events[index + 1].startTime
                        if isLast || hasGap {
                            GridRow {
                                if event.endTime == date {
                                    nowIndicator
                                } else {
                                    Circle()
                                        .fill(event.endTime < date ? Color.primary : Color.green)
                                        .frame(width: 12)
                                }
                                Text(event.endTime, format: .dateTime.hour().minute())
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(event.endTime <= date ? Color.primary : Color.green)
                            }
                            let nextStartTime = isLast ? endOfDay : room.events[index + 1].startTime
                            
                            GridRow {
                                VStack(spacing: 0) {
                                    if nextStartTime <= date {
                                        VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                            .frame(height: 48)
                                    } else if event.endTime >= date {
                                        VerticalLine(color: .green, lineWidth: 4)
                                            .frame(height: 48)
                                    } else {
                                        VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                            .frame(height: 48)
                                        nowIndicator
                                        VerticalLine(color: .green, lineWidth: 4)
                                            .frame(height: 48)
                                    }
                                }
                                Color.clear
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding(.vertical, 8)
    }
}

#Preview {
    @Previewable @State var room: Room? = nil
    
    Text("")
        .customSheet(isPresented: .constant(true)) {
            if let room = room {
                RoomDetailsView(room: room)
                    .interactiveDismissDisabled(true)
            }
        }
}
