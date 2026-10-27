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
    var selectedDate: Date
    @AccessibilityFocusState private var isHeaderFocused: Bool
    
    var body: some View {
        TimelineView(.everyMinute) { context in
            let currentStatus = RoomDailyStatus(room: room, selectedDate: selectedDate, now: context.date)
            
            VStack(alignment: .leading, spacing: 20) {
                HeaderInfo(room: room, status: currentStatus, isHeaderFocused: $isHeaderFocused)
                Timeline(room: room, status: currentStatus, now: context.date)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            isHeaderFocused = true
        }
    }
}

private struct HeaderInfo: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    let room: Room
    let status: RoomDailyStatus
    var isHeaderFocused: AccessibilityFocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(room.name)
                .font(.title2.bold())
                .contentShape(.rect)
            Text(status.statusText)
                .font(.title3)
                .contentShape(.rect)
        }
        .accessibilityHidden(true)
        .overlay {
            if voiceOverEnabled {
                SpeechLanguageLabel(
                    .it(room.name),
                    traits: .header
                )
                .accessibilityValue(status.statusText)
                .accessibilityFocused(isHeaderFocused)
            }
        }
    }
}

private struct Timeline: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    let room: Room
    let status: RoomDailyStatus
    let now: Date
    
    var body: some View {
        Group {
            if let firstEvent = room.events.first {
                ScrollView {
                    Grid(verticalSpacing: 8) {
                        let startOfDay = Calendar.current.startOfDay(for: firstEvent.startTime)
                        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                        
                        GridRow {
                            VStack(spacing: 0) {
                                if startOfDay > now {
                                    VerticalLine(color: .green, lineWidth: 4)
                                        .frame(height: 48)
                                } else if firstEvent.startTime > now {
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
                        .accessibilityHidden(true)
                        
                        ForEach(Array(room.events.enumerated()), id: \.element.id) { index, event in
                            GridRow {
                                if event.startTime == now {
                                    nowIndicator
                                } else {
                                    Circle()
                                        .fill(event.startTime < now ? Color.primary : Color.red)
                                        .frame(width: 12)
                                }
                                Text(event.startTime, format: .dateTime.hour().minute())
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(event.startTime <= now ? Color.primary : Color.red)
                            }
                            .accessibilityHidden(true)
                            
                            GridRow {
                                VStack(spacing: 0) {
                                    if event.endTime <= now {
                                        VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                            .frame(minHeight: 48)
                                    } else if event.startTime >= now {
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
                                .accessibilityHidden(true)
                                
                                Text(event.cleanName ?? event.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .accessibilityHidden(true)
                                    .overlay {
                                        if voiceOverEnabled {
                                            SpeechLanguageLabel(.it(event.cleanName ?? event.name))
                                                .accessibilityValue(eventValue(event: event))
                                        }
                                    }
                            }
                            
                            let isLast = index == room.events.count - 1
                            let hasGap = !isLast && event.endTime != room.events[index + 1].startTime
                            if isLast || hasGap {
                                GridRow {
                                    if event.endTime == now {
                                        nowIndicator
                                    } else {
                                        Circle()
                                            .fill(event.endTime < now ? Color.primary : Color.green)
                                            .frame(width: 12)
                                    }
                                    Text(event.endTime, format: .dateTime.hour().minute())
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(event.endTime <= now ? Color.primary : Color.green)
                                }
                                .accessibilityHidden(true)
                                
                                let nextStartTime = isLast ? endOfDay : room.events[index + 1].startTime
                                
                                GridRow {
                                    VStack(spacing: 0) {
                                        if nextStartTime <= now {
                                            VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                                .frame(height: 48)
                                        } else if event.endTime >= now {
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
                                    .accessibilityHidden(true)
                                    Color.clear
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel("Aula libera")
                                        .accessibilityValue(gapValue(start: event.endTime, nextStart: nextStartTime, isLast: isLast))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if status == .pastDay {
                VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                    .frame(maxHeight: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Nessun evento, giornata conclusa")
            } else if status == .freeAllDay {
                Grid(verticalSpacing: 8) {
                    GridRow {
                        VStack(spacing: 0) {
                            VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                                .frame(height: 48)
                            nowIndicator
                            VerticalLine(color: .green, lineWidth: 4)
                                .frame(maxHeight: .infinity)
                        }
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Nessuna lezione in programma, aula libera per tutta la giornata")
            } else {
                VerticalLine(color: .green, lineWidth: 4)
                    .frame(maxHeight: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Nessuna lezione in programma, aula libera per tutta la giornata")
            }
        }
    }
    
    private func eventValue(event: Event) -> String {
        let start = event.startTime.formatted(.dateTime.hour().minute())
        let end = event.endTime.formatted(.dateTime.hour().minute())
        var value = String(localized: "Dalle \(start) alle \(end)")
        
        if event.startTime <= now && event.endTime > now {
            value += ", " + String(localized: "In corso adesso")
        } else if event.endTime <= now {
            value += ", " + String(localized: "Conclusa")
        }
        
        return value
    }
    
    private func gapValue(start: Date, nextStart: Date, isLast: Bool) -> String {
        let startStr = start.formatted(.dateTime.hour().minute())
        var value = ""
        
        if isLast {
            value = String(localized: "Dalle \(startStr) a fine giornata")
        } else {
            let endStr = nextStart.formatted(.dateTime.hour().minute())
            value = String(localized: "Dalle \(startStr) alle \(endStr)")
        }
        
        if start <= now && nextStart > now {
            value += ", " + String(localized: "In corso adesso")
        } else if nextStart <= now || status == .pastDay {
            value += ", " + String(localized: "Conclusa")
        }
        
        return value
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
            .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var room: Room? = nil
    
    Text("")
        .customSheet(isPresented: .constant(true)) {
            if let room = room {
                RoomDetailsView(room: room, selectedDate: Date())
                    .interactiveDismissDisabled(true)
            }
        }
}
