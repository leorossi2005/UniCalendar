//
//  UserSettings.kt
//  UnivrCore
//
//  Translated from UserSettings.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class UserSettings private constructor(context: Context) {

    companion object {
        @Volatile
        private var instance: UserSettings? = null

        fun getInstance(context: Context): UserSettings =
            instance ?: synchronized(this) {
                instance ?: UserSettings(context.applicationContext).also { instance = it }
            }

        // Chiavi SharedPreferences
        private const val PREFS_NAME = "univr_calendar_prefs"
        private const val KEY_SELECTED_YEAR = "selectedYear"
        private const val KEY_SELECTED_COURSE = "selectedCourse"
        private const val KEY_SELECTED_ACADEMIC_YEAR = "selectedAcademicYear"
        private const val KEY_FOUND_MATRICOLA = "foundMatricola"
        private const val KEY_MATRICOLA = "matricola"
        private const val KEY_ONBOARDING_COMPLETED = "onboardingCompleted"

        // Defaults
        private const val DEFAULT_YEAR = "2025"
        private const val DEFAULT_COURSE = "0"
        private const val DEFAULT_ACADEMIC_YEAR = "0"
        private const val DEFAULT_MATRICOLA = "pari"
        private const val DEFAULT_BOOL_FALSE = false
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // ── StateFlow-backed properties ──

    private val _selectedYear = MutableStateFlow(prefs.getString(KEY_SELECTED_YEAR, DEFAULT_YEAR) ?: DEFAULT_YEAR)
    val selectedYear: StateFlow<String> = _selectedYear.asStateFlow()

    private val _selectedCourse = MutableStateFlow(prefs.getString(KEY_SELECTED_COURSE, DEFAULT_COURSE) ?: DEFAULT_COURSE)
    val selectedCourse: StateFlow<String> = _selectedCourse.asStateFlow()

    private val _selectedAcademicYear = MutableStateFlow(prefs.getString(KEY_SELECTED_ACADEMIC_YEAR, DEFAULT_ACADEMIC_YEAR) ?: DEFAULT_ACADEMIC_YEAR)
    val selectedAcademicYear: StateFlow<String> = _selectedAcademicYear.asStateFlow()

    private val _foundMatricola = MutableStateFlow(prefs.getBoolean(KEY_FOUND_MATRICOLA, DEFAULT_BOOL_FALSE))
    val foundMatricola: StateFlow<Boolean> = _foundMatricola.asStateFlow()

    private val _matricola = MutableStateFlow(prefs.getString(KEY_MATRICOLA, DEFAULT_MATRICOLA) ?: DEFAULT_MATRICOLA)
    val matricola: StateFlow<String> = _matricola.asStateFlow()

    private val _onboardingCompleted = MutableStateFlow(prefs.getBoolean(KEY_ONBOARDING_COMPLETED, DEFAULT_BOOL_FALSE))
    val onboardingCompleted: StateFlow<Boolean> = _onboardingCompleted.asStateFlow()

    // ── Setters (scrivono su SharedPreferences + aggiornano StateFlow) ──

    fun setSelectedYear(value: String) {
        _selectedYear.value = value
        prefs.edit().putString(KEY_SELECTED_YEAR, value).apply()
    }

    fun setSelectedCourse(value: String) {
        _selectedCourse.value = value
        prefs.edit().putString(KEY_SELECTED_COURSE, value).apply()
    }

    fun setSelectedAcademicYear(value: String) {
        _selectedAcademicYear.value = value
        prefs.edit().putString(KEY_SELECTED_ACADEMIC_YEAR, value).apply()
    }

    fun setFoundMatricola(value: Boolean) {
        _foundMatricola.value = value
        prefs.edit().putBoolean(KEY_FOUND_MATRICOLA, value).apply()
    }

    fun setMatricola(value: String) {
        _matricola.value = value
        prefs.edit().putString(KEY_MATRICOLA, value).apply()
    }

    fun setOnboardingCompleted(value: Boolean) {
        _onboardingCompleted.value = value
        prefs.edit().putBoolean(KEY_ONBOARDING_COMPLETED, value).apply()
    }

    // ── Reset ──

    fun reset() {
        setSelectedYear(DEFAULT_YEAR)
        setSelectedCourse(DEFAULT_COURSE)
        setSelectedAcademicYear(DEFAULT_ACADEMIC_YEAR)
        setFoundMatricola(DEFAULT_BOOL_FALSE)
        setMatricola(DEFAULT_MATRICOLA)
        setOnboardingCompleted(DEFAULT_BOOL_FALSE)
    }
}

// ── TempSettingsState ──

data class TempSettingsState(
    var selectedYear: String = "",
    var selectedCourse: String = "",
    var selectedAcademicYear: String = "",
    var matricola: String = ""
) {
    fun sync(settings: UserSettings) {
        selectedYear = settings.selectedYear.value
        selectedCourse = settings.selectedCourse.value
        selectedAcademicYear = settings.selectedAcademicYear.value
        matricola = settings.matricola.value
    }

    fun hasChanged(settings: UserSettings): Boolean {
        return selectedCourse != settings.selectedCourse.value ||
                selectedYear != settings.selectedYear.value ||
                selectedAcademicYear != settings.selectedAcademicYear.value
    }

    fun apply(settings: UserSettings) {
        settings.setSelectedYear("")
        settings.setSelectedCourse("")
        settings.setSelectedAcademicYear("")
        settings.setMatricola("")

        settings.setSelectedYear(selectedYear)
        settings.setSelectedCourse(selectedCourse)
        settings.setSelectedAcademicYear(selectedAcademicYear)
        settings.setMatricola(matricola)
    }
}
