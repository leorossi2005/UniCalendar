//
//  RoomCard.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct Line: View {
    var color: Color
    var lineWidth: CGFloat
    var dash: [CGFloat] = []
    
    var body: some View {
        LineShape()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash))
            .frame(height: lineWidth)
    }
    
    private struct LineShape: Shape {
        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
            return path
        }
    }
}

struct RoomCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    //let lesson: Lesson
    var events: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            lessonInfo
            Timeline(events: events)
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
            Text("Aula Gino Tessari")
                .foregroundStyle(.white)
                .font(.headline)
                .multilineTextAlignment(.leading)
            Text(events.isEmpty ? "Libera tutto il giorno" : "Libera ora (Fino alle 14:30)")
                .foregroundStyle(.white)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Timeline: View {
    var events: [String]
    
    var after: Bool {
        events.count > 1 && !events[1].isEmpty
    }
    
    var body: some View {
        Grid(horizontalSpacing: 8) {
            GridRow {
                Line(color: .white, lineWidth: 4, dash: [12, 12])
                Circle()
                    .fill(.white)
                    .frame(height: 16)
                    .overlay {
                        Circle()
                            .fill(.blue)
                            .frame(height: 10)
                    }
                Line(color: .green, lineWidth: 4)
                    .if(events.isEmpty) { view in
                        view
                            .gridCellColumns(2)
                    }
                if !events.isEmpty {
                    Circle()
                        .fill(.red)
                        .frame(height: 10)
                        .overlay {
                            Text("14:30")
                                .foregroundStyle(.red)
                                .fixedSize()
                                .font(.caption)
                                .offset(y: -14)
                        }
                    Line(color: .red.opacity(0.9), lineWidth: 4)
                    Circle()
                        .fill(after ? .red : .green)
                        .frame(height: 10)
                        .overlay {
                            Text("17:00")
                                .foregroundStyle(after ? .red : .green)
                                .fixedSize()
                                .font(.caption)
                                .offset(y: -14)
                        }
                    Line(color: after ? .red : .green, lineWidth: 4)
                        .overlay(alignment: .trailing) {
                            if events.count > 1 {
                                Text("+\(events.count - 1)")
                                    .foregroundStyle(Color(.lightGray))
                                    .fixedSize()
                                    .font(.caption)
                                    .offset(y: -14)
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            RoomCard(events: [])
            RoomCard(events: [""])
            RoomCard(events: ["", ""])
            RoomCard(events: ["", "", "", "", "", ""])
            RoomCard(events: ["", ".", ""])
        }
    }
}
