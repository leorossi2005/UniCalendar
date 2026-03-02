//
//  Utilities.kt
//  UnivrCore
//
//  Translated from Utilities.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import java.util.Locale

// MARK: LessonNameFormatter

object LessonNameFormatter {

    private val keywordsRegex =
        Regex("""(?:laboratorio|teoria|esercitazioni)\s*[^A-Za-zÀ-ÖØ-Þa-zà-öø-þ]*""", RegexOption.IGNORE_CASE)
    private val parenthesisRegex = Regex("""\((.*?)\)""")
    private val upperCaseRegex = Regex("""\b[A-ZÀ-ÖØ-Þ]+(?:[A-ZÀ-ÖØ-Þ\s]+)*\b""")
    private val multipleSpacesRegex = Regex("""\s+""")

    fun format(text: String): Pair<String, List<String>> {
        var formattedTxt = text
            .replace("Matricole pari", "")
            .replace("Matricole dispari", "")

        val tags = mutableListOf<String>()

        // Extract keyword tag
        keywordsRegex.find(formattedTxt)?.let { match ->
            val matchedString = match.value.trim()
            tags.add(matchedString.replaceFirstChar { it.titlecase(Locale.getDefault()) })
            formattedTxt = formattedTxt.removeRange(match.range)
        }

        // Extract parenthesis content (reverse order to keep indices valid)
        val parenMatches = parenthesisRegex.findAll(formattedTxt).toList()
        for (match in parenMatches.reversed()) {
            val content = match.groupValues[1].trim()

            if (formattedTxt.contains("??")) {
                val fixedName = fixLiterature(content)
                if (fixedName != null) {
                    formattedTxt = fixedName
                    continue
                }
            }
            formattedTxt = formattedTxt.removeRange(match.range)
            tags.add(content)
        }

        // Extract UPPER CASE blocks (>=5 chars)
        if (!formattedTxt.contains("??")) {
            val upperMatches = upperCaseRegex.findAll(formattedTxt).toList()
            for (match in upperMatches.reversed()) {
                val upperPart = match.value.trim()
                if (upperPart.length >= 5) {
                    val endIdx = match.range.last + 1
                    val checkEnd = minOf(endIdx + 3, formattedTxt.length)
                    val nextChars = formattedTxt.substring(endIdx, checkEnd)

                    if (nextChars.contains(":")) {
                        formattedTxt = formattedTxt.removeRange(match.range.first until checkEnd)
                    } else {
                        formattedTxt = formattedTxt.removeRange(match.range)
                    }
                    tags.add(upperPart)
                }
            }
        }

        formattedTxt = formattedTxt.replace(multipleSpacesRegex, " ")

        return Pair(formattedTxt.trim(), tags)
    }

    private fun fixLiterature(content: String): String? {
        val lastChar = content.lastOrNull() ?: return null
        if (!lastChar.isDigit()) return null
        val isCulture = content.contains("cultura")

        if (content.contains("Letteratura russa")) {
            val prefix = if (isCulture) "Русская литература и культура" else "Русская литература"
            return "$prefix $lastChar ($content)"
        } else if (content.contains("Letteratura cinese")) {
            val prefix = if (isCulture) "中国文学与文化" else "中国文学"
            return "$prefix $lastChar ($content)"
        }
        return null
    }
}

// MARK: HexColorParser

object HexColorParser {

    data class RGBComponents(
        val red: Double,
        val green: Double,
        val blue: Double,
        val opacity: Double = 1.0
    )

    fun parse(hex: String): RGBComponents? {
        val hexSanitized = hex.trim().removePrefix("#")
        val rgb = hexSanitized.toLongOrNull(16) ?: return null

        return when (hexSanitized.length) {
            6 -> RGBComponents(
                red = ((rgb shr 16) and 0xFF).toDouble() / 255.0,
                green = ((rgb shr 8) and 0xFF).toDouble() / 255.0,
                blue = (rgb and 0xFF).toDouble() / 255.0
            )
            8 -> RGBComponents(
                red = ((rgb shr 24) and 0xFF).toDouble() / 255.0,
                green = ((rgb shr 16) and 0xFF).toDouble() / 255.0,
                blue = ((rgb shr 8) and 0xFF).toDouble() / 255.0,
                opacity = (rgb and 0xFF).toDouble() / 255.0
            )
            else -> null
        }
    }
}

// MARK: Stopwatch

class Stopwatch {
    private var startTime: Long? = null

    fun start() {
        startTime = System.nanoTime()
    }

    fun stop(): Double {
        val start = startTime ?: return 0.0
        val now = System.nanoTime()
        startTime = null
        return (now - start) / 1_000_000_000.0
    }
}
