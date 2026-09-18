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
    let onDismiss: () -> Void
    
    @State private var title: String = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String = ""
    @State private var notes: String = ""
    
    init(selectedDate: Date, onDismiss: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.onDismiss = onDismiss
        
        let defaultStart = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: defaultStart) ?? defaultStart
        
        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultEnd)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dettagli")) {
                    TextField("Titolo", text: $title)
                    TextField("Luogo (opzionale)", text: $location)
                }
                
                Section(header: Text("Orario")) {
                    SwiftUI.DatePicker("Inizio", selection: $startTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: startTime) { oldValue, newValue in
                            if endTime < newValue {
                                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                            }
                        }
                    SwiftUI.DatePicker("Fine", selection: $endTime, displayedComponents: [.hourAndMinute])
                }
                
                Section(header: Text("Note (opzionale)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nuovo Impegno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveEvent) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : Color.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveEvent() {
        // Correggi le date per usare il giorno selezionato
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let finalStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: selectedDate),
              let finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: selectedDate) else {
            return
        }
        
        let newEvent = PersonalEvent(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: finalStartTime,
            endTime: max(finalStartTime, finalEndTime), // Fallback di sicurezza
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            await CommitmentsManager.shared.addEvent(newEvent)
            onDismiss()
        }
    }
}
