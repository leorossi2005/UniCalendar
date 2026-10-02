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
    let onDismiss: (PersonalEvent?) -> Void
    
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: EventLocation?
    @State private var tags: [TagItem]
    @State private var notes: String
    
    @FocusState private var focusedTag: UUID?
    
    init(selectedDate: Date, editingEvent: PersonalEvent? = nil, onDismiss: @escaping (PersonalEvent?) -> Void) {
        self.selectedDate = selectedDate
        self.editingEvent = editingEvent
        self.onDismiss = onDismiss
        
        if let event = editingEvent {
            _title = State(initialValue: event.title)
            _startTime = State(initialValue: event.startTime)
            _endTime = State(initialValue: event.endTime)
            _location = State(initialValue: event.location)
            _tags = State(initialValue: event.tags)
            _notes = State(initialValue: event.notes ?? "")
        } else {
            _title = State(initialValue: "")
            
            let defaultStart = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: defaultStart) ?? defaultStart
            
            _startTime = State(initialValue: defaultStart)
            _endTime = State(initialValue: defaultEnd)
            _location = State(initialValue: nil)
            _tags = State(initialValue: [])
            _notes = State(initialValue: "")
        }
    }
    
    var body: some View {
        Form {
            Section("Dettagli") {
                TextField("Titolo", text: $title)
                    NavigationLink {
                        LocationPickerView(selectedLocation: $location)
                    } label: {
                        HStack {
                            Text("Luogo")
                            Spacer()
                            Text(location?.name ?? "Nessuno")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Orario") {
                    SwiftUI.DatePicker("Inizio", selection: $startTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: startTime) { oldValue, newValue in
                            let minEnd = Calendar.current.date(byAdding: .minute, value: 1, to: newValue) ?? newValue
                            if endTime < minEnd {
                                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? minEnd
                            }
                        }
                    
                    let minEndTime = Calendar.current.date(byAdding: .minute, value: 1, to: startTime) ?? startTime
                    SwiftUI.DatePicker("Fine", selection: $endTime, in: minEndTime..., displayedComponents: [.hourAndMinute])
                }
                
                Section("Tag") {
                    ForEach($tags) { tag in
                        TextField("Nome", text: tag.name)
                            .focused($focusedTag, equals: tag.id)
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                    Button("Aggiugni un nuovo tag") {
                        let newTag = TagItem()
                        tags.append(newTag)
                        focusedTag = newTag.id
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
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26, *) {
                        Button("Annulla", systemImage: "xmark", role: .cancel, action: { onDismiss(nil) })
                    } else {
                        Button("Annulla", role: .cancel, action: { onDismiss(nil) })
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
                    .disabled(!hasChanges)
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
        
        let finalTags = tags.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let minSafeEndTime = calendar.date(byAdding: .minute, value: 1, to: finalStartTime) ?? finalStartTime
        
        let newEvent = PersonalEvent(
            id: editingEvent?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: finalStartTime,
            endTime: max(minSafeEndTime, finalEndTime),
            tags: finalTags,
            location: location,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            await CommitmentsManager.shared.addEvent(newEvent)
            onDismiss(newEvent)
        }
    }
    
    private var hasChanges: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty { return false }
        
        guard let event = editingEvent else {
            return true
        }
        
        let finalTags = tags.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if trimmedTitle != event.title { return true }
        if location != event.location { return true }
        if notes.trimmingCharacters(in: .whitespacesAndNewlines) != (event.notes ?? "") { return true }
        if finalTags != event.tags { return true }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        if let finalStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: selectedDate),
           let finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: selectedDate) {
            
            let minSafeEndTime = calendar.date(byAdding: .minute, value: 1, to: finalStartTime) ?? finalStartTime
            
            if finalStartTime != event.startTime { return true }
            if max(minSafeEndTime, finalEndTime) != event.endTime { return true }
        }
        
        return false
    }
}
