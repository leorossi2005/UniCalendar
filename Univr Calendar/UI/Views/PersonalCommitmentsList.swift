//
//  PersonalCommitmentsList.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 01/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct PersonalCommitmentsList: View {
    @State private var commitmentsManager = CommitmentsManager.shared
    @State private var editingEvent: PersonalEvent? = nil
    
    private var groupedEvents: [(Date, [PersonalEvent])] {
        let grouped = Dictionary(grouping: commitmentsManager.personalEvents) { event in
            Calendar.current.startOfDay(for: event.startTime)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        List {
            if groupedEvents.isEmpty {
                ContentUnavailableView(
                    "Nessun impegno personale",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Non hai ancora aggiunto nessun impegno personale.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedEvents, id: \.0) { date, events in
                    Section {
                        ForEach(events) { event in
                            ZStack {
                                NavigationLink(destination: CalendarItemDetailsView(
                                    item: .personal(event),
                                    internalItem: event,
                                    openAddToCalendar: false,
                                    onDismiss: nil,
                                    onEdit: {
                                        editingEvent = event
                                    }
                                )) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                CalendarItemCard(item: .personal(event), internalItem: event)
                            }
                            .contextMenu {
                                Button {
                                    editingEvent = event
                                } label: {
                                    Label("Modifica", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Task { await CommitmentsManager.shared.deleteEvent(id: event.id) }
                                } label: {
                                    Label("Cancella", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text(date.formatted(date: .complete, time: .omitted).capitalized)
                            .font(.headline)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Impegni Personali")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $editingEvent) { eventToEdit in
            AddPersonalEventView(selectedDate: eventToEdit.startTime, editingEvent: eventToEdit) { _ in
                editingEvent = nil
            }
        }
    }
}
