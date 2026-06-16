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
    
    var selectedLesson: Lesson? = nil
    var openSettings: Bool = false
    var openWhatsNew: Bool = false
    var openAddToCalendar: Bool = false
    
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
    
    func routeToLesson(_ lesson: Lesson, addToCalendar: Bool = false) {
        selectedLesson = lesson
        openAddToCalendar = addToCalendar
        detents = [.small, .medium, .large]
        manager.setDetent(.large)
    }
    
    // MARK: - Reset automatico
    func resetToCalendar() {
        selectedLesson = nil
        openSettings = false
        openWhatsNew = false
        openAddToCalendar = false
        detents = [.small, .medium]
    }
}
