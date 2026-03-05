//
//  CourseSelectorManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 04/03/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import Observation

@MainActor
@Observable
public final class CourseSearchManager {
    public var searchText: String = ""
    public var courses: [Corso] = []
    
    public init() {}
    
    public var filteredCourses: [Corso] {
        Corso.filter(courses, with: searchText)
    }
    
    public func labelForCourse(_ value: String) -> String {
        Corso.label(for: value, in: courses)
    }
    
    public func clearSearch() {
        searchText = ""
    }
}

