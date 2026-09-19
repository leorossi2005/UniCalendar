//
//  CalendarItem.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 18/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum CalendarItem: Identifiable, Equatable {
    case lesson(Lesson)
    case personal(PersonalEvent)
    
    public var id: String {
        switch self {
        case .lesson(let lesson): return "lesson_\(lesson.id)"
        case .personal(let event): return "personal_\(event.id)"
        }
    }
    
    public var startTime: Date {
        switch self {
        case .lesson(let lesson): return lesson.startTime
        case .personal(let event): return event.startTime
        }
    }
    
    public var displayable: any CalendarDisplayable {
        switch self {
        case .lesson(let lesson): return lesson
        case .personal(let event): return event
        }
    }
}
