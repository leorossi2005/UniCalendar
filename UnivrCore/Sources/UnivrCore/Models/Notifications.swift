//
//  Notifications.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct SavedNotification: Sendable, Codable, Identifiable, Equatable {
    public let id: String
    public let courseId: String
    public let courseName: String
    public let courseYear: String
    public let lessonName: String
    public let date: Date
    public let offsetMinutes: Int
    public var itemPayload: Data?
    
    public init(id: String, courseId: String, courseName: String, courseYear: String, lessonName: String, date: Date, offsetMinutes: Int, itemPayload: Data? = nil) {
        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.courseYear = courseYear
        self.lessonName = lessonName
        self.date = date
        self.offsetMinutes = offsetMinutes
        self.itemPayload = itemPayload
    }
}
