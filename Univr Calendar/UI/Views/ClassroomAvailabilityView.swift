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
    @Environment(\.colorScheme) var colorScheme
    @Environment(UserSettings.self) var settings
    
    var coordinator: CalendarCoordinator
    var sheetRouter: CalendarSheetRouter
    
    @State private var availabilityManager = AvailabilityDataManager()
    
    private struct RequestKey: Equatable {
        // periphery:ignore
        let locationKey: String
        // periphery:ignore
        let date: Date
        // periphery:ignore
        let isOffline: Bool
    }
    
    var body: some View {
        VStack {
            locationPicker
                .padding(.top, 15)
            
            content
                .onChange(of: coordinator.selectedWeek) { oldValue, newValue in
                    guard !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
                    availabilityManager.reset()
                }
                .task(id: RequestKey(
                    locationKey: settings.locationKey,
                    date: coordinator.selectedWeek,
                    isOffline: NetworkStatusMonitor.shared.status == .disconnected
                )) {
                    await availabilityManager.getAvailability(locationKey: settings.locationKey, date: coordinator.selectedWeek)
                }
                .task {
                    await availabilityManager.loadLocations()
                }
                .onDisappear {
                    availabilityManager.unregisterFromServerStatus()
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
        .disabled(availabilityManager.state == .offline || availabilityManager.state == .serverUnreachable || availabilityManager.state == .univrOffline)
        .tint(.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(35)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var content: some View {
        switch availabilityManager.state {
        case .idle, .loading:
            loadingPlaceholder
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
        case .empty:
            ContentUnavailableView(
                "Nessuna aula disponibile",
                systemImage: "building.2",
                description: Text("Non ci sono aule disponibili per questa sede.")
            )
        case .offline:
            ContentUnavailableView(
                "Sei Offline",
                systemImage: AppState.offline.icon,
                description: Text("Connettiti a internet per controllare le disponibilità di oggi.")
            )
        case .serverUnreachable:
            ContentUnavailableView {
                Label("Server non raggiungibile", systemImage: AppState.serveroffline.icon)
            } description: {
                Text("Non riusciamo a contattare il server. Riprova più tardi.")
            }
        case .univrOffline:
            ContentUnavailableView {
                Label("Università non raggiungibile", systemImage: AppState.unioffline.icon)
            } description: {
                Text("La disponibilità delle aule non è consultabile finché i server dell'università non tornano raggiungibili.")
            }
        case .error(let msg):
            ContentUnavailableView(
                "Si è verificato un errore",
                systemImage: "exclamationmark.triangle",
                description: Text(msg)
            )
        }
    }
    
    @ViewBuilder
    private var loadingPlaceholder: some View {
        ScrollView {
            VStack {
                ForEach(0..<6, id: \.self) { _ in
                    RoomCard(room: .sample, selectedDate: .now)
                        .shimmeringPlaceholder(opacity: colorScheme == .light ? 0.5 : 0.7)
                }
            }
            .allowsHitTesting(false)
        }
        .cornerRadius(35)
        .scrollIndicators(.never)
    }
}

#Preview {
    ClassroomAvailabilityView(coordinator: .init(), sheetRouter: .init())
        .environment(UserSettings.shared)
}
