//
//  ClassroomAvailabilityView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 01/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct ClassroomAvailabilityView: View {
    @Environment(UserSettings.self) var settings
    
    var coordinator: CalendarCoordinator
    var sheetRouter: CalendarSheetRouter
    
    @State private var availabilityManager = AvailabilityDataManager()
    
    private struct RequestKey: Equatable {
        let locationKey: String
        let date: Date
    }
    
    var body: some View {
        VStack {
            locationPicker
            
            content
                .onChange(of: coordinator.selectedWeek) { oldValue, newValue in
                    guard !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
                    availabilityManager.reset()
                }
                .task(id: RequestKey(
                    locationKey: settings.locationKey,
                    date: coordinator.selectedWeek
                )) {
                    await availabilityManager.getAvailability(locationKey: settings.locationKey, date: coordinator.selectedWeek)
                }
                .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollContent)
                .contentMargins(.bottom, CustomSheetDetent.small.value, for: .scrollIndicators)
        }
    }
    
    private var locationPicker: some View {
        Picker("", selection: Bindable(settings).locationKey) {
            ForEach(availabilityManager.sortedLocations, id: \.key) { location in
                Text(location.value).tag(location.key)
            }
        }
        .tint(.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(35)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    private var content: some View {
        switch availabilityManager.state {
        case .idle, .loading:
            ProgressView("Caricamento disponibilità...")
                .frame(maxHeight: .infinity)
        case .loaded:
            ScrollView {
                VStack {
                    if let rooms = availabilityManager.rooms {
                        ForEach(rooms) { room in
                            RoomCard(room: room, selectedDate: coordinator.selectedWeek)
                                .onTapGesture {
                                    Haptics.play(.impact(weight: .light, intensity: 0.5))
                                    sheetRouter.routeToRoom(room)
                                }
                        }
                    }
                }
            }
            .cornerRadius(35)
            .padding(.horizontal, 15)
        case .empty:
            ContentUnavailableView(
                "Nessuna aula disponibile",
                systemImage: "building.2",
                description: Text("Non ci sono aule disponibili per questa sede.")
            )
        case .offline:
            ContentUnavailableView(
                "Sei Offline",
                systemImage: "wifi.slash",
                description: Text("Connettiti a internet per controllare le disponibilità di oggi.")
            )
        case .error(let msg):
            ContentUnavailableView(
                "Si è verificato un errore",
                systemImage: "exclamationmark.triangle",
                description: Text(msg)
            )
        }
    }
}
