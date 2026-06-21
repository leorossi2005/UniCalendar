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
                GridRow {
                    VerticalLine(color: .primary, lineWidth: 4, dash: [8, 12])
                        .frame(height: 48)
                }
                GridRow {
                    Circle()
                        .frame(height: 16)
                        .overlay {
                            Circle()
                                .fill(.blue)
                                .frame(height: 10)
                        }
                }
                GridRow {
                    VerticalLine(color: .green, lineWidth: 4)
                        .frame(height: 48)
                }
                ForEach(Array(room.events.enumerated()), id: \.element.id) { index, event in
                    GridRow {
                        Circle()
                            .fill(.red)
                            .frame(width: 12)
                        Text(event.startTime, format: .dateTime.hour().minute())
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.red)
                    }
                    GridRow {
                        VerticalLine(color: .red, lineWidth: 4)
                        Text(event.cleanName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                    }
                    if (index != room.events.count - 1 && room.events[index].endTime != room.events[index + 1].startTime) || index == room.events.count - 1 {
                        GridRow {
                            Circle()
                                .fill(.green)
                                .frame(width: 12)
                            Text(event.endTime, format: .dateTime.hour().minute())
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.green)
                        }
                        GridRow {
                            VerticalLine(color: .green, lineWidth: 4)
                                .frame(height: 48)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
