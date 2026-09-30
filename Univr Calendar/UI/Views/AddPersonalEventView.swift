//
//  AddPersonalEventView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import SwiftData
import UnivrCore

struct AddPersonalEventView: View {
    @Environment(\.modelContext) private var modelContext
    
    let selectedDate: Date
    let editingEvent: PersonalEvent?
    let onDismiss: () -> Void
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String
    @State private var tags: [TagItem]
    @State private var notes: String
    
    init(selectedDate: Date, editingEvent: PersonalEvent? = nil, onDismiss: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.editingEvent = editingEvent
        self.onDismiss = onDismiss
        
        if let event = editingEvent {
            _title = State(initialValue: event.title)
            _startTime = State(initialValue: event.startTime)
            _endTime = State(initialValue: event.endTime)
            _location = State(initialValue: event.location?.name ?? "")
            _tags = State(initialValue: event.tags)
            _notes = State(initialValue: event.notes ?? "")
        } else {
            _title = State(initialValue: "")
            
            let defaultStart = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: defaultStart) ?? defaultStart
            
            _startTime = State(initialValue: defaultStart)
            _endTime = State(initialValue: defaultEnd)
            _location = State(initialValue: "")
            _tags = State(initialValue: [])
            _notes = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    TextField("Titolo", text: $title)
                    TextField("Luogo", text: $location)
                }
                
                Section("Orario") {
                    SwiftUI.DatePicker("Inizio", selection: $startTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: startTime) { oldValue, newValue in
                            if endTime < newValue {
                                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                            }
                        }
                    SwiftUI.DatePicker("Fine", selection: $endTime, displayedComponents: [.hourAndMinute])
                }
                
                Section("Tag") {
                    ForEach($tags) { tag in
                        TextField("Nome", text: tag.name)
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                    Button("Aggiugni un nuovo tag") {
                        tags.append(TagItem())
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(editingEvent != nil ? "Modifica Impegno" : "Nuovo Impegno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26, *) {
                        Button("Annulla", systemImage: "xmark", role: .cancel, action: onDismiss)
                    } else {
                        Button("Annulla", role: .cancel, action: onDismiss)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Group {
                        if #available(iOS 26, *) {
                            Button(editingEvent != nil ? "Salva" : "Aggiungi", systemImage: "checkmark", role: .confirm, action: saveEvent)
                        } else {
                            Button(editingEvent != nil ? "Salva" : "Aggiungi", action: saveEvent)
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveEvent() {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let finalStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: selectedDate),
              let finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: selectedDate) else {
            return
        }
        
        let locString = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let eventLocation = locString.isEmpty ? nil : EventLocation(name: locString)
        let finalTags = tags.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let newEvent = PersonalEvent(
            id: editingEvent?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: finalStartTime,
            endTime: max(finalStartTime, finalEndTime),
            tags: finalTags,
            location: eventLocation,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            await CommitmentsManager.shared.addEvent(newEvent)
            onDismiss()
        }
    }
}
