//
//  CourseSelectorManager.kt
//  UnivrCore
//
//  Translated from CourseSelectorManager.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class CourseSelectorManager {
    private val _searchText = MutableStateFlow("")
    val searchText: StateFlow<String> = _searchText.asStateFlow()

    private val _courses = MutableStateFlow<List<Corso>>(emptyList())
    val courses: StateFlow<List<Corso>> = _courses.asStateFlow()

    val filteredCourses: List<Corso>
        get() = Corso.filter(_courses.value, _searchText.value)

    fun setSearchText(text: String) {
        _searchText.value = text
    }

    fun setCourses(courses: List<Corso>) {
        _courses.value = courses
    }

    fun labelForCourse(value: String): String {
        return Corso.label(value, _courses.value)
    }

    fun clearSearch() {
        _searchText.value = ""
    }
}