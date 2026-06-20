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
    var lesson: Lesson? = .sample
    
    @State private var showOriginalName: Bool = false
    
    var onDismiss: (() -> Void)?
    
    var body: some View {
        if let lesson = lesson {
            VStack(alignment: .leading, spacing: 20) {
                headerInfo(lesson: lesson)
                detailRows(lesson: lesson)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .onChange(of: lesson) {
                showOriginalName = false
            }
        }
    }
    
    // MARK: - Subviews
    private func headerInfo(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(lesson.name ?? "")
                .font(.title2.bold())
                .contentShape(.rect)
                .onTapGesture {
                    showOriginalName.toggle()
                }
            Text("Aula libera tutto il giorno")
                .font(.title3)
                .contentShape(.rect)
                .onTapGesture {
                    showOriginalName.toggle()
                }
        }
    }
    
    private func detailRows(lesson: Lesson) -> some View {
        ScrollView {
            Grid {
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
                ForEach(["", "", "", "", "", "", "", ""], id: \.self) { _ in
                    GridRow {
                        Circle()
                            .fill(.red)
                            .frame(width: 12)
                        Text("Evento di prova")
                    }
                    GridRow {
                        VerticalLine(color: .green, lineWidth: 4)
                            .frame(height: 48)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


#Preview {
    @Previewable @State var lesson: Lesson? = Lesson.sample
    
    Text("")
        .customSheet(isPresented: .constant(true)) {
            RoomDetailsView(lesson: lesson)
                .interactiveDismissDisabled(true)
        }
}
