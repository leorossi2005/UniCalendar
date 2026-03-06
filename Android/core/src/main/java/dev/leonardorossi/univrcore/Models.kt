//
//  Models.kt
//  UnivrCore
//
//  Translated from Models.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

// MARK: Year data class
@Serializable
data class Year(
    val label: String = "",
    val valore: String = ""
)

// MARK: ResponseAPI data class
@Serializable
data class ResponseAPI(
    var celle: List<Lesson> = emptyList(),
    val colori: List<String> = emptyList()
)

// MARK: Lesson data class
@Serializable(with = LessonSerializer::class)
data class Lesson(
    val nomeInsegnamento: String = "",
    val nameOriginal: String = "",
    val data: String = "",
    val aula: String = "",
    val orario: String = "",
    val tipo: String = "",
    val docente: String = "",
    val annullato: Boolean = false,
    val colorIndex: String = "",
    val codiceInsegnamento: String = "",
    var color: String = "",
    val infoAulaHTML: String = ""
) {
    val cleanName: String
    val tags: List<String>
    val durationCalculated: String

    init {
        val (formattedName, formattedTags) = LessonNameFormatter.format(nomeInsegnamento)
        this.cleanName = formattedName
        this.tags = formattedTags
        this.durationCalculated = calculateDuration(orario)
    }

    val id: Int
        get() {
            var result = nomeInsegnamento.hashCode()
            result = 31 * result + data.hashCode()
            result = 31 * result + orario.hashCode()
            result = 31 * result + docente.hashCode()
            return result
        }

    val startTime: String
        get() = orario.split(" - ").firstOrNull() ?: ""

    val formattedClassroom: String
        get() {
            val idx = aula.indexOfFirst { it == '[' || it == '<' }
            return if (idx >= 0) aula.substring(0, idx).trim() else aula.trim()
        }

    val gruppo: GruppoMatricola
        get() = when {
            nomeInsegnamento.contains("Matricole pari") -> GruppoMatricola.PARI
            nomeInsegnamento.contains("Matricole dispari") -> GruppoMatricola.DISPARI
            else -> GruppoMatricola.TUTTI
        }

    val indirizzoAula: String?
        get() {
            val match = ADDRESS_REGEX.find(infoAulaHTML) ?: return null
            return match.groupValues[1].trim()
        }

    val capacity: Int?
        get() {
            val match = CAPACITY_REGEX.find(infoAulaHTML) ?: return null
            return match.groupValues[1].toIntOrNull()
        }

    val category: EventCategory
        get() = when (tipo) {
            "pause" -> EventCategory.PAUSE
            "chiusura_type" -> EventCategory.CLOSURE
            else -> EventCategory.REGULAR
        }

    enum class GruppoMatricola {
        PARI,
        DISPARI,
        TUTTI
    }

    enum class EventCategory {
        REGULAR,
        PAUSE,
        CLOSURE
    }

    companion object {
        private val ADDRESS_REGEX = Regex("""\[(.*?)]""")
        private val CAPACITY_REGEX = Regex("""Capacità: </span>\s*(\d+)\s*<""")

        internal fun calculateDuration(orario: String): String {
            val times = orario.split("-").map { it.trim() }
            if (times.size != 2) return ""

            val start = toMinutes(times[0])
            val end = toMinutes(times[1])
            if (end <= start) return ""

            val diff = end - start
            val h = diff / 60
            val m = diff % 60

            return when {
                h > 0 && m > 0 -> "${h}h ${m}m"
                h > 0 -> "${h}h"
                m > 0 -> "${m}m"
                else -> ""
            }
        }

        private fun toMinutes(time: String): Int {
            val parts = time.split(":")
            if (parts.size != 2) return 0
            val h = parts[0].toIntOrNull() ?: return 0
            val m = parts[1].toIntOrNull() ?: return 0
            return h * 60 + m
        }

        val sample = Lesson(
            nomeInsegnamento = "Insegnamento di prova molto lungo Laboratorio",
            nameOriginal = "Insegnamento di prova molto lungo lungo lungo",
            data = "01-01-2025",
            aula = "Aula Gino Tessari",
            orario = "08:30 - 10:30",
            tipo = "Lezione",
            docente = "Prof. Rossi",
            annullato = false,
            colorIndex = "",
            codiceInsegnamento = "XYZ",
            color = "#A0A0A0",
            infoAulaHTML = "<span style=\"font-weight:bold\">Nome aula: </span><a aria-label=\"Aula Gino Tessari\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&aula=32&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Aula Aula Gino Tessari\">Aula Gino Tessari</a><br><span style=\"font-weight:bold\">Capacità: </span>236<br><span style=\"font-weight:bold\">Sede: </span><a aria-label=\"Borgo Roma - Ca' Vignal 2\" href=\"index.php?view=rooms&include=rooms&_lang=&sede=2&date=30-01-2026\" target=\"_blank\" title=\"Apri un'altra TAB del browser per consultare l'orario di: Borgo Roma - Ca' Vignal 2\">Borgo Roma - Ca' Vignal 2</a> [Strada Le Grazie, 15 - 37134 Verona]"
        )

        val pausaSample = Lesson(
            data = "01-01-2025",
            orario = "08:30 - 10:30",
            tipo = "pause"
        )
    }
}

// Custom serializer handling the complex `informazioni_lezione` field and `Annullato` polymorphism
object LessonSerializer : KSerializer<Lesson> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("Lesson")

    override fun serialize(encoder: Encoder, value: Lesson) {
        // Delegate to the generated map-based approach
        val composite = encoder.beginStructure(descriptor)
        composite.endStructure(descriptor)
    }

    override fun deserialize(decoder: Decoder): Lesson {
        val input = decoder as JsonDecoder
        val json = input.decodeJsonElement().jsonObject

        val nomeInsegnamento = json["nome_insegnamento"]?.jsonPrimitive?.content ?: ""
        val nameOriginal = json["name_original"]?.jsonPrimitive?.content ?: ""
        val data = json["data"]?.jsonPrimitive?.content ?: ""
        val aula = json["aula"]?.jsonPrimitive?.content ?: ""
        val orario = json["orario"]?.jsonPrimitive?.content ?: ""
        val tipo = json["tipo"]?.jsonPrimitive?.content ?: ""
        val docente = json["docente"]?.jsonPrimitive?.content ?: ""

        val annullato = json["Annullato"]?.let { element ->
            when {
                element is JsonPrimitive && element.isString -> element.content == "1"
                element is JsonPrimitive -> element.booleanOrNull ?: false
                else -> false
            }
        } ?: false

        val colorIndex = json["color_index"]?.jsonPrimitive?.content ?: ""
        val codiceInsegnamento = json["codice_insegnamento"]?.jsonPrimitive?.content ?: ""
        val color = json["color"]?.jsonPrimitive?.content ?: ""

        val infoAulaHTML = decodeInfoAula(json["informazioni_lezione"])

        return Lesson(
            nomeInsegnamento = nomeInsegnamento,
            nameOriginal = nameOriginal,
            data = data,
            aula = aula,
            orario = orario,
            tipo = tipo,
            docente = docente,
            annullato = annullato,
            colorIndex = colorIndex,
            codiceInsegnamento = codiceInsegnamento,
            color = color,
            infoAulaHTML = infoAulaHTML
        )
    }

    private fun decodeInfoAula(element: JsonElement?): String {
        if (element == null) return ""

        // Case 1: simple string
        if (element is JsonPrimitive && element.isString) {
            return element.content
        }

        // Case 2: nested object { contenuto: { "5": [ { contenuto: "..." } ] } }
        try {
            val contenutoObj = element.jsonObject["contenuto"]?.jsonObject ?: return ""
            val array = contenutoObj["5"]?.jsonArray ?: return ""
            if (array.isNotEmpty()) {
                return array[0].jsonObject["contenuto"]?.jsonPrimitive?.content ?: ""
            }
        } catch (_: Exception) {
            // fall through
        }
        return ""
    }
}

// MARK: Struct corsi per il network
@Serializable
data class Corso(
    @SerialName("elenco_anni") val elencoAnni: List<Anno> = emptyList(),
    val label: String = "",
    val valore: String = ""
) {
    companion object {
        fun filter(courses: List<Corso>, searchText: String): List<Corso> {
            if (searchText.isEmpty()) return courses
            return courses.filter {
                it.label.contains(searchText, ignoreCase = true)
            }
        }

        fun label(value: String, courses: List<Corso>): String {
            return courses.firstOrNull { it.valore == value }?.label ?: ""
        }
    }
}

@Serializable
data class Anno(
    val label: String = "",
    val valore: String = "",
    @SerialName("elenco_insegnamenti") val elencoInsegnamenti: List<Insegnamento> = emptyList()
)

@Serializable
data class Insegnamento(
    val label: String = ""
)
