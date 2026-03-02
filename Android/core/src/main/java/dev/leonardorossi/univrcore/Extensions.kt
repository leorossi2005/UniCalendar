//
//  Extensions.kt
//  UnivrCore
//
//  Translated from Extensions.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.time.format.TextStyle
import java.time.temporal.ChronoField
import java.time.temporal.ChronoUnit
import java.time.temporal.WeekFields
import java.util.Locale

enum class CalendarSymbolLength { FULL, SHORT, VERY_SHORT }

// ── Date Formatter (dd-MM-yyyy) ──

private val UNIVR_DATE_FORMATTER: DateTimeFormatter =
    DateTimeFormatter.ofPattern("dd-MM-yyyy")

// ── LocalDate extensions ──

fun LocalDate.formatUnivrStyle(): String =
    this.format(UNIVR_DATE_FORMATTER)

fun LocalDate.startOfWeek(): LocalDate {
    val weekFields = WeekFields.of(Locale.getDefault())
    return this.with(weekFields.dayOfWeek(), 1)
}

fun LocalDate.weekDates(): List<LocalDate> {
    val start = this.startOfWeek()
    return (0L until 7L).map { start.plusDays(it) }
}

fun LocalDate.set(field: ChronoField, value: Int): LocalDate =
    this.with(field, value.toLong())

fun LocalDate.add(unit: ChronoUnit, value: Long): LocalDate =
    this.plus(value, unit)

fun LocalDate.remove(unit: ChronoUnit, value: Long): LocalDate =
    this.minus(value, unit)

fun LocalDate.getCurrentMonthSymbol(style: TextStyle): String =
    this.month.getDisplayName(style, Locale.getDefault())
        .replaceFirstChar { it.uppercaseChar() }

fun LocalDate.startWeekdaySymbolOfMonth(style: TextStyle): String {
    val firstOfMonth = this.withDayOfMonth(1)
    return firstOfMonth.getCurrentWeekdaySymbol(style)
}

fun LocalDate.getCurrentWeekdaySymbol(style: TextStyle): String =
    this.dayOfWeek.getDisplayName(style, Locale.getDefault())
        .replaceFirstChar { it.uppercaseChar() }

fun getWeekdaySymbols(length: CalendarSymbolLength): List<String> {
    val style = when (length) {
        CalendarSymbolLength.FULL -> TextStyle.FULL
        CalendarSymbolLength.SHORT -> TextStyle.SHORT
        CalendarSymbolLength.VERY_SHORT -> TextStyle.NARROW
    }
    val locale = Locale.getDefault()
    // Monday-first ordering (ISO week)
    val days = listOf(
        DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY,
        DayOfWeek.THURSDAY, DayOfWeek.FRIDAY, DayOfWeek.SATURDAY, DayOfWeek.SUNDAY
    )
    return days.map {
        it.getDisplayName(style, locale).replaceFirstChar { c -> c.uppercaseChar() }
    }
}

fun LocalDate.isOutOfAcademicBounds(academicYear: Int): Boolean =
    (monthValue == 9 && year == academicYear) || (monthValue == 10 && year == academicYear + 1)

fun LocalDate.isInAcademicYear(academicYear: String): Boolean {
    val yearInt = academicYear.toIntOrNull() ?: return false
    return when (year) {
        yearInt -> monthValue >= 10
        yearInt + 1 -> monthValue <= 9
        else -> false
    }
}

val LocalDate.yearSymbol: String get() = year.toString()

// ── String ──

fun String.toDateModern(): LocalDate? {
    return try {
        LocalDate.parse(this, UNIVR_DATE_FORMATTER)
    } catch (_: DateTimeParseException) {
        try {
            LocalDate.parse(this, DateTimeFormatter.ISO_DATE)
        } catch (_: DateTimeParseException) {
            null
        }
    }
}

// ── App version helper ──

object AppVersion {
    // Filled at initialization time from BuildConfig by the app module
    var versionName: String = "N/A"
    var versionCode: String = "N/A"

    val appVersion: String get() = "v$versionName ($versionCode)"
    val clearAppVersion: String get() = versionName
}
