//
//  AppConstants.kt
//  UnivrCore
//
//  Translated from AppConstants.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

object AppConstants {

    object URLs {
        const val DONATION = "https://revolut.me/leorossi05?currency=EUR&amount=100"
        const val PORTFOLIO = "https://www.leonardorossi.dev"
        const val GITHUB = "https://github.com/leorossi2005"
        const val INSTAGRAM = "https://www.instagram.com/leorossi05"
        const val FEEDBACK = "mailto:leonardo.rossi1922005@gmail.com?subject=Feedback%20App%20Univr"
        const val EMAIL = "mailto:leonardo.rossi1922005@gmail.com"
    }

    object AppInfo {
        // Su Android la stringa localizzata viene fornita dalle risorse (R.string.*)
        // Qui definiamo le chiavi di fallback; la UI caricherà da strings.xml
        const val APP_NAME_DEFAULT = "Calendario per UniVR"
        const val DEVELOPER_NAME = "Leonardo Rossi"
    }

    data class Contributor(
        val id: String,
        val name: String,
        val role: String,
        val url: String? = null,
        val image: String = ""
    ) {
        constructor(name: String, role: String, url: String? = null, image: String = "") :
                this(id = name, name = name, role = role, url = url, image = image)
    }

    object Credits {
        // I ruoli localizzati verranno sostituiti dalla UI con stringhe da R.string.*
        val contributors: List<Contributor> = listOf(
            Contributor(name = "Gaia", role = "Aiuto Sviluppo", image = "GaiaPhoto"),
            Contributor(name = "Nicola", role = "Aiuto Testing", image = "NicolaPhoto"),
            Contributor(name = "Edoardo", role = "Aiuto Testing")
        )
    }
}
