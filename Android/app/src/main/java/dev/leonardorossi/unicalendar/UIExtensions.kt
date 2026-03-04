package dev.leonardorossi.unicalendar

import androidx.compose.ui.graphics.Color
import dev.leonardorossi.univrcore.HexColorParser

fun Color.Companion.fromHex(hex: String): Color? {
    val components = HexColorParser.parse(hex) ?: return null
    return Color(
        red = components.red.toFloat(),
        green = components.green.toFloat(),
        blue = components.blue.toFloat(),
        alpha = components.opacity.toFloat()
    )
}