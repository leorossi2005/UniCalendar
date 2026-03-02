//
//  CalendarViewModel.kt
//  UnivrCore
//
//  Translated from CalendarViewModel.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.yield
import java.time.LocalDate

internal data class YearStructure(
    val year: Int,
    val days: List<String>,
    val dates: List<LocalDate>
)

class CalendarViewModel(
    private val cacheManager: CacheManager
) : ViewModel() {

    private val _lessons = MutableStateFlow<List<Lesson>>(emptyList())
    val lessons: StateFlow<List<Lesson>> = _lessons.asStateFlow()

    private val _days = MutableStateFlow<List<List<Lesson>>>(emptyList())
    val days: StateFlow<List<List<Lesson>>> = _days.asStateFlow()

    private val _daysString = MutableStateFlow<List<String>>(emptyList())
    val daysString: StateFlow<List<String>> = _daysString.asStateFlow()

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val _checkingUpdates = MutableStateFlow(false)
    val checkingUpdates: StateFlow<Boolean> = _checkingUpdates.asStateFlow()

    private val _showUpdateAlert = MutableStateFlow(false)
    val showUpdateAlert: StateFlow<Boolean> = _showUpdateAlert.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _noLessonsFound = MutableStateFlow(false)
    val noLessonsFound: StateFlow<Boolean> = _noLessonsFound.asStateFlow()

    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline.asStateFlow()

    private var pendingNewLessons: List<Lesson>? = null
    private var currentPalette: List<String> = emptyList()
    private var cachedStructure: YearStructure? = null

    private val service = NetworkService()
    private val cacheKey = "calendar_cache.json"

    suspend fun loadFromCache(selYear: String, matricola: String) {
        val cacheResponse = cacheManager.load(cacheKey, ResponseAPI.serializer())
        if (cacheResponse != null) {
            _lessons.value = cacheResponse.celle
            currentPalette = cacheResponse.colori

            organizeData(selectedYear = selYear, matricola = matricola)

            _loading.value = false
            _noLessonsFound.value = _lessons.value.isEmpty()
        }
    }

    suspend fun loadNetworkFromCache() {
        val cacheResponse = cacheManager.load("network_cache.json", NetworkCacheData.serializer())
        if (cacheResponse != null) {
            NetworkCache.update(cacheResponse)
        }
    }

    fun loadLessons(corso: String, anno: String, selYear: String, matricola: String, updating: Boolean) {
        if (corso == "0") return
        _isOffline.value = false

        viewModelScope.launch {
            if (!updating && _lessons.value.isEmpty()) {
                loadFromCache(selYear, matricola)
            }

            if (!updating && _lessons.value.isNotEmpty()) {
                _checkingUpdates.value = true
            } else {
                clearAll()
                _loading.value = true
            }
            _errorMessage.value = null

            try {
                val response = service.fetchOrario(corso = corso, anno = anno, selyear = selYear)

                currentPalette = response.colori

                var fetchedLessons = response.celle
                if (fetchedLessons.isNotEmpty()) {
                    fetchedLessons = CalendarLogic.applyColors(fetchedLessons, currentPalette)
                }

                handleNewData(fetchedLessons, selYear, matricola, updating)

                _loading.value = false
            } catch (e: Exception) {
                handleError(e)
            }

            _checkingUpdates.value = false
        }
    }

    fun confirmUpdate(selectedYear: String, matricola: String) {
        viewModelScope.launch {
            val newLessons = pendingNewLessons ?: return@launch

            try {
                handleNewData(newLessons, selectedYear, matricola, update = true)
            } catch (_: Exception) { }

            _noLessonsFound.value = false
            pendingNewLessons = null
            _showUpdateAlert.value = false
        }
    }

    fun clearPendingUpdate() {
        pendingNewLessons = null
        _checkingUpdates.value = false
        _showUpdateAlert.value = false
    }

    suspend fun organizeData(selectedYear: String, matricola: String) {
        val annoInt = selectedYear.toIntOrNull() ?: return

        val lessonsSnapshot = _lessons.value
        val currentCache = cachedStructure

        val (newStructure, organizedDays) = CalendarLogic.processCalendarData(
            year = annoInt,
            matricola = matricola,
            lessons = lessonsSnapshot,
            cachedStructure = currentCache
        )

        if (cachedStructure?.year != annoInt) {
            cachedStructure = newStructure
        }
        _daysString.value = newStructure.days
        _days.value = organizedDays

        val activeActivities = mutableMapOf<String, Double>()
        for (index in organizedDays.indices) {
            val date = newStructure.days[index]
            val dayLessons = organizedDays[index]

            val validLessons = dayLessons.filter { !it.annullato && it.tipo != "pause" }

            if (validLessons.isNotEmpty()) {
                val totalMinutes = validLessons.sumOf { lesson ->
                    val times = lesson.orario.split("-").map { it.trim() }
                    if (times.size != 2) return@sumOf 0

                    fun toMinutes(time: String): Int {
                        val parts = time.split(":")
                        if (parts.size != 2) return 0
                        val h = parts[0].toIntOrNull() ?: return 0
                        val m = parts[1].toIntOrNull() ?: return 0
                        return h * 60 + m
                    }

                    val start = toMinutes(times[0])
                    val end = toMinutes(times[1])
                    end - start
                }

                val hours = totalMinutes / 60.0
                if (hours > 0) {
                    activeActivities[date] = hours
                }
            }
        }

        DatePickerCache.getInstance().updateActivities(activeActivities)
    }

    private suspend fun handleNewData(
        fetchedLessons: List<Lesson>,
        selectedYear: String,
        matricola: String,
        update: Boolean
    ) {
        if (fetchedLessons.isEmpty()) {
            _noLessonsFound.value = true
            updateStateAndCache(emptyList(), selectedYear, matricola)
            return
        }

        _noLessonsFound.value = false

        if (_lessons.value.isEmpty() || update) {
            updateStateAndCache(fetchedLessons, selectedYear, matricola)
            return
        }

        if (_lessons.value != fetchedLessons) {
            pendingNewLessons = fetchedLessons
            _showUpdateAlert.value = true
        }
    }

    private suspend fun updateStateAndCache(
        newLessons: List<Lesson>,
        selectedYear: String,
        matricola: String
    ) {
        _lessons.value = newLessons

        val cacheObject = ResponseAPI(celle = newLessons, colori = currentPalette)
        cacheManager.save(cacheObject, cacheKey, ResponseAPI.serializer())

        organizeData(selectedYear, matricola)
    }

    private suspend fun clearCache() {
        cacheManager.clear(cacheKey)
    }

    suspend fun clearAll() {
        _loading.value = true
        yield()
        clearCache()
        clearPendingUpdate()
        _lessons.value = emptyList()
        _days.value = emptyList()
    }

    private fun handleError(error: Exception) {
        if (error is NetworkError) {
            if (error is NetworkError.Offline) {
                _isOffline.value = _lessons.value.isEmpty()
            }
            _errorMessage.value = error.message
        } else {
            _errorMessage.value = "Errore generico: ${error.localizedMessage}"
        }
        println("Debug Error: $error")
    }
}

// ── CalendarLogic (pure functions) ──

internal object CalendarLogic {

    suspend fun processCalendarData(
        year: Int,
        matricola: String,
        lessons: List<Lesson>,
        cachedStructure: YearStructure?
    ): Pair<YearStructure, List<List<Lesson>>> = withContext(Dispatchers.Default) {
        val structure: YearStructure = if (cachedStructure != null && cachedStructure.year == year) {
            cachedStructure
        } else {
            generateYearStructure(year)
        }

        val lessonsByDate = lessons.groupBy { it.data }
        val userFilter = if (matricola == "pari") Lesson.GruppoMatricola.PARI else Lesson.GruppoMatricola.DISPARI

        val organized = ArrayList<List<Lesson>>(structure.days.size)

        for (dayString in structure.days) {
            val dailyLessons = lessonsByDate[dayString]
            if (dailyLessons == null) {
                organized.add(emptyList())
                continue
            }

            val filtered = dailyLessons.filter { lesson ->
                lesson.tipo != "chiusura_type" &&
                        (lesson.gruppo == Lesson.GruppoMatricola.TUTTI || lesson.gruppo == userFilter)
            }.sortedBy { it.orario }

            if (filtered.isEmpty()) {
                organized.add(emptyList())
            } else {
                organized.add(insertPauses(filtered, dayString))
            }
        }

        Pair(structure, organized)
    }

    fun generateYearStructure(year: Int): YearStructure {
        val startDate = LocalDate.of(year, 10, 1)
        val endDate = LocalDate.of(year + 1, 9, 30)

        val dateStrings = mutableListOf<String>()
        val dateObj = mutableListOf<LocalDate>()

        var currentDate = startDate
        while (!currentDate.isAfter(endDate)) {
            dateStrings.add(currentDate.formatUnivrStyle())
            dateObj.add(currentDate)
            currentDate = currentDate.plusDays(1)
        }

        return YearStructure(year = year, days = dateStrings, dates = dateObj)
    }

    private fun insertPauses(lessons: List<Lesson>, date: String): List<Lesson> {
        val processedDay = lessons.toMutableList()
        var offset = 0

        for (i in 0 until lessons.size - 1) {
            val currentEnd = lessons[i].orario.takeLast(5)
            val nextStart = lessons[i + 1].orario.take(5)

            if (currentEnd < nextStart) {
                val pauseLesson = Lesson(
                    data = date,
                    orario = "$currentEnd-$nextStart",
                    tipo = "pause"
                )
                processedDay.add(i + 1 + offset, pauseLesson)
                offset++
            }
        }
        return processedDay
    }

    fun applyColors(lessons: List<Lesson>, palette: List<String>): List<Lesson> {
        val processedLessons = lessons.map { it.copy() }.toMutableList()
        val colorMap = mutableMapOf<String, String>()
        var paletteIndex = 0

        for (lesson in processedLessons) {
            if (hasCustomColor(lesson)) {
                colorMap[lesson.codiceInsegnamento] = lesson.color
            }
        }

        for (i in processedLessons.indices) {
            if (processedLessons[i].annullato) {
                processedLessons[i] = processedLessons[i].copy(color = "#FFFFFF")
                continue
            }

            if (processedLessons[i].tipo == "chiusura_type") {
                processedLessons[i] = processedLessons[i].copy(color = "#BDF2F2")
                continue
            }

            if (processedLessons[i].colorIndex.isNotEmpty()) {
                println("Trovato uno")
                continue
            }

            val code = lessons[i].codiceInsegnamento

            val existingColor = colorMap[code]
            if (existingColor != null) {
                processedLessons[i] = processedLessons[i].copy(color = existingColor)
            } else {
                val newColor = if (paletteIndex < palette.size) palette[paletteIndex] else "#CCCCCC"
                colorMap[code] = newColor
                processedLessons[i] = processedLessons[i].copy(color = newColor)
                paletteIndex++
            }
        }
        return processedLessons
    }

    private fun hasCustomColor(lesson: Lesson): Boolean {
        return lesson.color.isNotEmpty() && lesson.color != "CCCCCC" && lesson.color != "A0A0A0"
    }
}
