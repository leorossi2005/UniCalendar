//
//  CalendarCoordinator.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 01/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

enum CalendarPage {
    case main
    case classrooms
}

@MainActor
@Observable
final class CalendarCoordinator {
    private(set) var selectedWeek: Date
    var page: CalendarPage = .main
    
    init(initialDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.selectedWeek = initialDate
    }
    
    @discardableResult
    func selectDate(_ newDate: Date) -> Bool {
        let normalized = Calendar.current.startOfDay(for: newDate)
        let changed = selectedWeek != normalized
        selectedWeek = normalized
        return changed
    }
}
