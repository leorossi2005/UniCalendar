//
//  DatePickerLogic.kt
//  UnivrCore
//
//  Translated from DatePickerLogic.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale
import kotlin.collections.iterator

data class CalendarCell(
    val dayNumber: String,
    val isCurrentMonth: Boolean,
    val hasActivity: Boolean,
    val activityQuantity: Double,
    val date: LocalDate
)

data class FractionDay(
    val id: String,
    val dayNumber: String,
    val weekdayString: String,
    val isOutOfBounds: Boolean,
    val date: LocalDate
)

class DatePickerCache : ViewModel() {

    companion object {
        @Volatile
        private var instance: DatePickerCache? = null

        fun getInstance(): DatePickerCache =
            instance ?: synchronized(this) {
                instance ?: DatePickerCache().also { instance = it }
            }
    }

    // ── StateFlows ──

    private val _monthGrids = MutableStateFlow<Map<String, List<CalendarCell>>>(emptyMap())
    val monthGrids: StateFlow<Map<String, List<CalendarCell>>> = _monthGrids.asStateFlow()

    private val _academicWeeks = MutableStateFlow<List<List<FractionDay>>>(emptyList())
    val academicWeeks: StateFlow<List<List<FractionDay>>> = _academicWeeks.asStateFlow()

    private val _additionalWeek = MutableStateFlow<List<FractionDay>>(emptyList())
    val additionalWeek: StateFlow<List<FractionDay>> = _additionalWeek.asStateFlow()

    private val _currentYear = MutableStateFlow("")
    val currentYear: StateFlow<String> = _currentYear.asStateFlow()

    private var activeDatesCache: Map<String, Double> = emptyMap()

    fun updateActivities(dates: Map<String, Double>) {
        activeDatesCache = dates
        println("\uD83D\uDD04 Updating Activities in Cache: ${dates.size} items") // DEBUG

        val currentGrids = _monthGrids.value.toMutableMap()
        for ((monthKey, cells) in currentGrids) {
            currentGrids[monthKey] = cells.map { cell ->
                val dateKey = cell.date.formatUnivrStyle()
                val quantity = dates[dateKey]
                cell.copy(
                    hasActivity = quantity != null,
                    activityQuantity = quantity ?: 0.0
                )
            }
        }
        _monthGrids.value = currentGrids
    }

    suspend fun generateMonthGrid(date: LocalDate, monthName: String) {
        val gridKey = "$monthName-${date.yearSymbol}"
        if (_monthGrids.value.containsKey(gridKey)) return

        val cachedActiveDates = activeDatesCache

        val cells: List<CalendarCell> = withContext(Dispatchers.IO) {
            val newGrid = mutableListOf<CalendarCell>()

            val yearMonth = YearMonth.of(date.year, date.month)
            val startOfMonth = yearMonth.atDay(1)
            val numDays = yearMonth.lengthOfMonth()

            // Monday-first: Monday=0 ... Sunday=6
            val firstWeekday = startOfMonth.dayOfWeek.value // 1=Mon..7=Sun
            val startOffset = (firstWeekday + 5) % 7

            val prevMonth = yearMonth.minusMonths(1)
            val prevMonthDays = prevMonth.lengthOfMonth()

            for (i in 0 until 42) {
                val cellDate: LocalDate
                val dayValue: Int
                val isCurrentMonth: Boolean

                when {
                    i < startOffset -> {
                        dayValue = prevMonthDays - (startOffset - i - 1)
                        isCurrentMonth = false
                        cellDate = startOfMonth.minusDays((startOffset - i).toLong())
                    }
                    i >= startOffset + numDays -> {
                        dayValue = i - (startOffset + numDays) + 1
                        isCurrentMonth = false
                        val nextMonth = yearMonth.plusMonths(1).atDay(1)
                        cellDate = nextMonth.plusDays((dayValue - 1).toLong())
                    }
                    else -> {
                        dayValue = i - startOffset + 1
                        isCurrentMonth = true
                        cellDate = startOfMonth.plusDays((dayValue - 1).toLong())
                    }
                }

                val dateKey = cellDate.formatUnivrStyle()

                newGrid.add(
                    CalendarCell(
                        dayNumber = dayValue.toString(),
                        isCurrentMonth = isCurrentMonth,
                        hasActivity = cachedActiveDates[dateKey] != null,
                        activityQuantity = cachedActiveDates[dateKey] ?: 0.0,
                        date = cellDate
                    )
                )
            }
            newGrid
        }

        val updated = _monthGrids.value.toMutableMap()
        updated[gridKey] = cells
        _monthGrids.value = updated
    }

    suspend fun generateAcademicWeeks(selectedYear: String) {
        if (_currentYear.value == selectedYear) return
        val yearInt = selectedYear.toIntOrNull() ?: return

        val (weeks, additional) = withContext(Dispatchers.IO) {
            val startAcademicYear = LocalDate.of(yearInt, 10, 1)
            val endAcademicYear = LocalDate.of(yearInt + 1, 9, 30)

            var currentWeekStart = startAcademicYear.startOfWeek()
            val allWeeks = mutableListOf<List<FractionDay>>()

            while (!currentWeekStart.isAfter(endAcademicYear)) {
                val weekDates = currentWeekStart.weekDates()
                val weekOfDays = weekDates.map { date ->
                    FractionDay(
                        id = date.formatUnivrStyle(),
                        dayNumber = date.dayOfMonth.toString(),
                        weekdayString = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault())
                            .replaceFirstChar { it.uppercaseChar() },
                        isOutOfBounds = date.isOutOfAcademicBounds(yearInt),
                        date = date
                    )
                }
                allWeeks.add(weekOfDays)
                currentWeekStart = currentWeekStart.plusWeeks(1)
            }

            // Additional week after the last
            val additionalWeekDates = currentWeekStart.weekDates()
            val additionalWeek = additionalWeekDates.map { date ->
                FractionDay(
                    id = date.formatUnivrStyle(),
                    dayNumber = date.dayOfMonth.toString(),
                    weekdayString = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault())
                        .replaceFirstChar { it.uppercaseChar() },
                    isOutOfBounds = date.isOutOfAcademicBounds(yearInt),
                    date = date
                )
            }

            Pair(allWeeks, additionalWeek)
        }

        _academicWeeks.value = weeks
        _additionalWeek.value = additional
        _currentYear.value = selectedYear
    }
}
