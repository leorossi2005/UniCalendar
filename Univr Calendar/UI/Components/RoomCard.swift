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

struct HorizontalLine: View {
    var color: Color
    var lineWidth: CGFloat
    var dash: [CGFloat] = []
    
    var body: some View {
        if dash.isEmpty {
            LineShape(lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(height: lineWidth)
        } else {
            AdaptiveDashedLineShape(
                lineWidth: lineWidth,
                dashLength: dash[0],
                gapLength: dash.count > 1 ? dash[1] : dash[0],
                isHorizontal: true
            )
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)) // Niente parametro 'dash' qui!
            .frame(height: lineWidth)
        }
    }
    
    private struct LineShape: Shape {
        var lineWidth: CGFloat
        
        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            let inset = lineWidth / 2
            
            path.move(to: CGPoint(x: inset, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width - inset, y: rect.midY))
            return path
        }
    }
}

struct VerticalLine: View {
    var color: Color
    var lineWidth: CGFloat
    var dash: [CGFloat] = []
    
    var body: some View {
        if dash.isEmpty {
            LineShape(lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: lineWidth)
        } else {
            AdaptiveDashedLineShape(
                lineWidth: lineWidth,
                dashLength: dash[0],
                gapLength: dash.count > 1 ? dash[1] : dash[0],
                isHorizontal: false
            )
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: lineWidth)
        }
    }
    
    private struct LineShape: Shape {
        var lineWidth: CGFloat
        
        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            let inset = lineWidth / 2
            
            path.move(to: CGPoint(x: rect.midX, y: inset))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height - inset))
            return path
        }
    }
}

private struct AdaptiveDashedLineShape: Shape {
    var lineWidth: CGFloat
    var dashLength: CGFloat
    var gapLength: CGFloat
    var isHorizontal: Bool
    
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = lineWidth / 2
        
        let start = inset
        let end = isHorizontal ? (rect.width - inset) : (rect.height - inset)
        let totalLength = end - start
        
        guard totalLength > 0 else { return path }
        
        var count = Int(round((totalLength + gapLength) / (dashLength + gapLength)))
        count = max(1, count)
        
        if count == 1 {
            let maxDash = min(dashLength, totalLength)
            if isHorizontal {
                path.move(to: CGPoint(x: start, y: rect.midY))
                path.addLine(to: CGPoint(x: start + maxDash, y: rect.midY))
            } else {
                path.move(to: CGPoint(x: rect.midX, y: start))
                path.addLine(to: CGPoint(x: rect.midX, y: start + maxDash))
            }
            return path
        }
        
        let actualGap = (totalLength - (CGFloat(count) * dashLength)) / CGFloat(count - 1)
        
        for i in 0..<count {
            let offset = start + CGFloat(i) * (dashLength + actualGap)
            if isHorizontal {
                path.move(to: CGPoint(x: offset, y: rect.midY))
                path.addLine(to: CGPoint(x: offset + dashLength, y: rect.midY))
            } else {
                path.move(to: CGPoint(x: rect.midX, y: offset))
                path.addLine(to: CGPoint(x: rect.midX, y: offset + dashLength))
            }
        }
        
        return path
    }
}


struct RoomCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var room: Room
    
    var body: some View {
        VStack(spacing: 20) {
            lessonInfo
            Timeline(room: room)
        }
        .padding()
        .padding(.bottom, 4)
        .background(backgroundLayer)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect(.lift)
        .padding(.horizontal, 15)
    }
    
    // MARK: - Components
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .fill(Color(.darkGray))
        
    }
    
    private var lessonInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(room.name)
                .foregroundStyle(.white)
                .font(.headline)
                .multilineTextAlignment(.leading)
            Text(room.events.isEmpty ? "Libera tutto il giorno" : "Libera ora (fino alle \(room.events.first!.startTime.formatted(.dateTime.hour().minute())))")
                .foregroundStyle(.white)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Timeline: View {
    var room: Room
    
    var after: Bool {
        room.events.count > 1 && room.events[0].endTime == room.events[1].startTime
    }
    
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                Color.clear.frame(width: 16, height: 0)
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            }
            
            GridRow {
                HorizontalLine(color: .white, lineWidth: 4, dash: [12, 12])
                Circle()
                    .fill(.white)
                    .frame(height: 16)
                    .overlay {
                        Circle()
                            .fill(.blue)
                            .frame(height: 10)
                    }
                HStack {
                    HorizontalLine(color: .green, lineWidth: 4)
                    if let event = room.events.first {
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
                                if room.events.count > 1 {
                                    Text("+\(room.events.count - 1)")
                                        .foregroundStyle(Color(.lightGray))
                                        .fixedSize()
                                        .font(.caption)
                                        .offset(y: -16)
                                }
                            }
                    }
                }
                .gridCellColumns(3)
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
