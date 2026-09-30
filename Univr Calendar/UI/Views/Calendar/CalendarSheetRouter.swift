//
//  CalendarSheetRouter.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

@MainActor
@Observable
class CalendarSheetRouter {
    let manager: GlobalSheetManager
    
    var selectedItem: CalendarItem? = nil
    var selectedRoom: Room? = nil
    var openSettings: Bool = false
    var openWhatsNew: Bool = false
    var openAddToCalendar: Bool = false
    var openAddPersonalEvent: Bool = false
    var editingPersonalEvent: PersonalEvent? = nil
    var tempSettings: TempSettingsState = .init()
    
    var detents: [CustomSheetDetent] = [.small, .medium]
    
    init(selectedDetent: CustomSheetDetent? = nil) {
        if let detent = selectedDetent {
            manager = .init(initialDetent: detent)
        } else {
            manager = .init()
        }
    }
    
    // MARK: - Azioni di navigazione
    func routeToSettings() {
        openSettings = true
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToWhatsNew() {
        openWhatsNew = true
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToItem(_ item: CalendarItem, addToCalendar: Bool = false) {
        selectedItem = item
        openAddToCalendar = addToCalendar
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToRoom(_ room: Room) {
        selectedRoom = room
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    func routeToAddPersonalEvent(editing event: PersonalEvent? = nil) {
        editingPersonalEvent = event
        openAddPersonalEvent = true
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    // MARK: - Reset automatico
    func resetToCalendar() {
        selectedItem = nil
        selectedRoom = nil
        openSettings = false
        openWhatsNew = false
        openAddToCalendar = false
        openAddPersonalEvent = false
        editingPersonalEvent = nil
        detents = [.small, .medium]
    }
}
