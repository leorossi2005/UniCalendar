//
//  Notifications.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct SavedNotification: Sendable, Codable, Identifiable, Hashable {
    public let id: String
    public let courseId: String
    public let courseName: String
    public let lessonName: String
    public let date: Date
    public let offsetMinutes: Int
    
    public init(id: String, courseId: String, courseName: String, lessonName: String, date: Date, offsetMinutes: Int) {
        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.lessonName = lessonName
        self.date = date
        self.offsetMinutes = offsetMinutes
    }
}
