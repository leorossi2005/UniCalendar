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
    var isScrollReady: Bool = false
    var scrollTarget: Date? = nil
    
    init(initialDate: Date = Calendar.current.startOfDay(for: Date())) {
        self.selectedWeek = initialDate
    }
    
    @discardableResult
    func selectDate(_ newDate: Date) -> Bool {
        let changed = !Calendar.current.isDate(selectedWeek, inSameDayAs: newDate)
        selectedWeek = newDate
        return changed
    }
}
