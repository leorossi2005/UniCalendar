//
//  PersonalEventDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import SwiftData
import UnivrCore

struct PersonalEventDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    
    let event: PersonalEvent
    let onDismiss: () -> Void
    
    @State var showDeletePopover: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                CalendarItemCard(item: .personal(event), internalItem: event)

                List {
                    if false {
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(event.title)
                                    .font(.title2)
                                    .bold()
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                    Text("\(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute()))")
                                }
                                
                                if let location = event.location?.name, !location.isEmpty {
                                    HStack {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.blue)
                                        Text(location)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    if let notes = event.notes, !notes.isEmpty {
                        Section(header: Text("Note")) {
                            Text(notes)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    Section {
                        Button("Elimina Impegno", role: .destructive, action: { showDeletePopover = true })
                            .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Dettagli Impegno")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Modifica", action: onDismiss)
                    }
                }
                .alert("Eliminare questo impegno?", isPresented: $showDeletePopover) {
                    Button("Conferma", role: .destructive, action: deleteEvent)
                    Button("Annulla", role: .cancel) {}
                } message: {
                    Text("Questa azione non può essere annullata.")
                }
            }
        }
    }
    
    private func deleteEvent() {
        Task {
            await CommitmentsManager.shared.deleteEvent(id: event.id)
            onDismiss()
        }
    }
}
