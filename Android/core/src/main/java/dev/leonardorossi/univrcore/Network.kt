//
//  Network.kt
//  UnivrCore
//
//  Translated from Network.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.FormBody
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException
import java.net.UnknownHostException
import java.time.LocalDate
import java.util.concurrent.TimeUnit

// ── Cache dati di rete (in-memory, condiviso) ──

@Serializable
data class NetworkCacheData(
    val years: List<Year> = emptyList(),
    val courses: Map<String, List<Corso>> = emptyMap()
)

object NetworkCache {
    var years: List<Year> = emptyList()
    var courses: MutableMap<String, List<Corso>> = mutableMapOf()

    fun toData(): NetworkCacheData = NetworkCacheData(
        years = years,
        courses = courses.toMap()
    )

    fun update(data: NetworkCacheData) {
        years = data.years
        courses = data.courses.toMutableMap()
    }
}

// ── Errori di rete ──

sealed class NetworkError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class BadURL : NetworkError("URL is not valid")
    class BadServerResponse(val statusCode: Int) : NetworkError("Server Error: $statusCode.")
    class EmptyData : NetworkError("Empty data received from the server")
    class DataNotFound(val variable: String) : NetworkError("Impossible to find data for: $variable.")
    class DecodingError(cause: Throwable) : NetworkError("Decoding error: ${cause.localizedMessage}", cause)
    class Offline : NetworkError("Device is offline.")
}

// ── Protocol / Interface ──

interface NetworkServiceProtocol {
    suspend fun getYears(): List<Year>
    suspend fun getCourses(year: String): List<Corso>
    suspend fun fetchOrario(corso: String, anno: String, selyear: String): ResponseAPI
}

// ── Implementazione OkHttp ──

class NetworkService : NetworkServiceProtocol {

    private val json = Json { ignoreUnknownKeys = true }

    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor { chain ->
            val original = chain.request()
            val newRequest = original.newBuilder()
                .header("User-Agent", "CalendarForUniVR/${AppVersion.clearAppVersion} (Android)")
                .header("Accept", "application/json, text/html, */*")
                .header("Accept-Language", "it-IT,it;q=0.9,en;q=0.8")
                .build()
            chain.proceed(newRequest)
        }
        .build()

    companion object {
        private val yearsRegex = Regex("""var\s+anni_accademici_ec\s+=\s+(.*?);""", RegexOption.DOT_MATCHES_ALL)
        private val coursesRegex = Regex("""var\s+elenco_corsi\s+=\s+(.*?);""", RegexOption.DOT_MATCHES_ALL)
    }

    private fun buildUrl(endpoint: String = "combo.php", queryItems: Map<String, String>): String? {
        val base = "https://logistica.univr.it/PortaleStudentiUnivr/$endpoint".toHttpUrlOrNull()
            ?: return null
        val builder = base.newBuilder()
        queryItems.forEach { (k, v) -> builder.addQueryParameter(k, v) }
        return builder.build().toString()
    }

    private suspend inline fun <reified T> fetchAndExtract(
        queryItems: Map<String, String>,
        regex: Regex,
        variableName: String
    ): T {
        return withContext(Dispatchers.IO) {
            try {
                val url = buildUrl(queryItems = queryItems) ?: throw NetworkError.BadURL()

                val request = Request.Builder().url(url).get().build()
                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    throw NetworkError.BadServerResponse(response.code)
                }

                val text = response.body?.string() ?: throw NetworkError.EmptyData()

                val match = regex.find(text) ?: throw NetworkError.DataNotFound(variableName)
                val jsonString = match.groupValues[1]

                json.decodeFromString<T>(jsonString)
            } catch (e: UnknownHostException) {
                throw NetworkError.Offline()
            } catch (e: IOException) {
                throw NetworkError.Offline()
            } catch (e: NetworkError) {
                throw e
            } catch (e: Exception) {
                println("Decode error: $e")
                throw NetworkError.DecodingError(e)
            }
        }
    }

    override suspend fun getYears(): List<Year> {
        val yearsDict: Map<String, Year> = fetchAndExtract(
            queryItems = mapOf("aa" to "1"),
            regex = yearsRegex,
            variableName = "anni_accademici_ec"
        )
        return yearsDict.values.sortedBy { it.valore }
    }

    override suspend fun getCourses(year: String): List<Corso> {
        return fetchAndExtract(
            queryItems = mapOf("aa" to year, "page" to "corsi"),
            regex = coursesRegex,
            variableName = "elenco_corsi"
        )
    }

    override suspend fun fetchOrario(corso: String, anno: String, selyear: String): ResponseAPI {
        return withContext(Dispatchers.IO) {
            try {
                val formBody = FormBody.Builder()
                    .add("view", "easycourse")
                    .add("include", "corso")
                    .add("anno", selyear)
                    .add("cdl", corso)
                    .add("anno2", anno)
                    .add("_lang", "it")
                    .add("date", LocalDate.now().formatUnivrStyle())
                    .add("all_events", "1")
                    .build()

                val request = Request.Builder()
                    .url("https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php")
                    .post(formBody)
                    .header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                    .build()

                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    throw NetworkError.BadServerResponse(response.code)
                }

                val body = response.body?.string() ?: throw NetworkError.EmptyData()
                json.decodeFromString<ResponseAPI>(body)
            } catch (e: UnknownHostException) {
                throw NetworkError.Offline()
            } catch (e: IOException) {
                throw NetworkError.Offline()
            } catch (e: NetworkError) {
                throw e
            } catch (e: Exception) {
                println("Decode error: $e")
                throw NetworkError.DecodingError(e)
            }
        }
    }
}
