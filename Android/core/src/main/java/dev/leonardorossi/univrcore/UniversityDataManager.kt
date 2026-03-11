//
//  UniversityDataManager.kt
//  UnivrCore
//
//  Translated from UniversityDataManager.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class UniversityDataManager(
    private val cacheManager: CacheManager
) : ViewModel() {

    private val _years = MutableStateFlow<List<Year>>(emptyList())
    val years: StateFlow<List<Year>> = _years.asStateFlow()

    private val _courses = MutableStateFlow<List<Corso>>(emptyList())
    val courses: StateFlow<List<Corso>> = _courses.asStateFlow()

    private val _academicYears = MutableStateFlow<List<Anno>>(emptyList())
    val academicYears: StateFlow<List<Anno>> = _academicYears.asStateFlow()

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val service = NetworkService()
    private val cacheKey = "network_cache.json"

    fun loadFromCache() {
        viewModelScope.launch {
            val cacheResponse = cacheManager.load(cacheKey, NetworkCacheData.serializer())
            if (cacheResponse != null) {
                NetworkCache.update(cacheResponse)
                _years.value = NetworkCache.years
            }
        }
    }

    suspend fun clearCalendarCache() {
        cacheManager.clear("calendar_cache.json")
    }

    suspend fun loadYears() {
        fetchAndRefresh(
            currentData = NetworkCache.years,
            fetchOperation = { service.getYears() },
            updateState = { newYears ->
                NetworkCache.years = newYears
                _years.value = newYears
            }
        )
    }

    suspend fun loadCourses(year: String) {
        _loading.value = true
        try {
            fetchAndRefresh(
                currentData = NetworkCache.courses[year],
                fetchOperation = { service.getCourses(year) },
                updateState = { newCourses ->
                    NetworkCache.courses[year] = newCourses
                    _courses.value = newCourses
                }
            )
        } finally {
            _loading.value = false
        }
    }

    fun updateAcademicYears(courseValue: String, year: String) {
        val selectedCourse = _courses.value.firstOrNull { it.valore == courseValue } ?: return
        _academicYears.value = selectedCourse.elencoAnni
    }

    fun clearCourses() {
        _courses.value = emptyList()
    }

    fun clearAcademicYears() {
        _academicYears.value = emptyList()
    }

    fun checkForMatricola(academicYearValue: String): Boolean {
        val anno = _academicYears.value.firstOrNull { it.valore == academicYearValue } ?: return false
        return anno.elencoInsegnamenti.any { item ->
            val label = item.label.lowercase()
            label.contains("matricole dispari") || label.contains("matricole pari")
        }
    }

    private suspend fun <T> fetchAndRefresh(
        currentData: T?,
        fetchOperation: suspend () -> T,
        updateState: (T) -> Unit
    ) where T : Any {
        val hasCache = when (currentData) {
            is List<*> -> currentData.isNotEmpty()
            else -> currentData != null
        }

        if (currentData != null && hasCache) {
            updateState(currentData)

            // Background refresh
            viewModelScope.launch {
                try {
                    val newData = fetchOperation()
                    if (currentData != newData) {
                        updateState(newData)
                        saveCache()
                    }
                } catch (e: Exception) {
                    println("Background refresh failed: $e")
                }
            }
            return
        }

        try {
            val newData = fetchOperation()
            updateState(newData)
            saveCache()
        } catch (e: Exception) {
            if (e is NetworkError.Offline) {
                _errorMessage.value = e.message
            } else {
                _errorMessage.value = "Errore generico: ${e.localizedMessage}"
            }
            throw e
        }
    }

    private suspend fun saveCache() {
        val data = NetworkCache.toData()
        cacheManager.save(data, cacheKey, NetworkCacheData.serializer())
    }
}
