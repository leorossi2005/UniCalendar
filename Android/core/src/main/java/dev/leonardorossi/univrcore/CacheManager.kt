//
//  CacheManager.kt
//  UnivrCore
//
//  Translated from CacheManager.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import java.io.File

class CacheManager private constructor(private val cacheDir: File) {

    companion object {
        @Volatile
        private var instance: CacheManager? = null

        fun getInstance(cacheDir: File): CacheManager =
            instance ?: synchronized(this) {
                instance ?: CacheManager(cacheDir).also { instance = it }
            }
    }

    private val json = Json { ignoreUnknownKeys = true }
    private val mutex = Mutex()

    suspend fun <T> save(obj: T, fileName: String, serializer: KSerializer<T>) {
        mutex.withLock {
            withContext(Dispatchers.IO) {
                try {
                    val data = json.encodeToString(serializer, obj)
                    File(cacheDir, fileName).writeText(data, Charsets.UTF_8)
                } catch (e: Exception) {
                    println("Error saving cache $fileName: $e")
                }
            }
        }
    }

    suspend fun <T> load(fileName: String, serializer: KSerializer<T>): T? {
        return mutex.withLock {
            withContext(Dispatchers.IO) {
                try {
                    val file = File(cacheDir, fileName)
                    if (!file.exists()) return@withContext null
                    val text = file.readText(Charsets.UTF_8)
                    json.decodeFromString(serializer, text)
                } catch (e: Exception) {
                    println("Error loading cache $fileName: $e")
                    null
                }
            }
        }
    }

    suspend fun clear(fileName: String) {
        mutex.withLock {
            withContext(Dispatchers.IO) {
                try {
                    val file = File(cacheDir, fileName)
                    if (file.exists()) file.delete()
                } catch (e: Exception) {
                    println("Error clearing cache $fileName: $e")
                }
            }
        }
    }
}

// ── Coordinate (in-memory cache) ──

data class Coordinate(
    val latitude: Double,
    val longitude: Double
)

object CoordinateCache {
    private val cache = mutableMapOf<String, Coordinate>()

    fun coordinate(address: String): Coordinate? = cache[address]

    fun save(coordinate: Coordinate, address: String) {
        cache[address] = coordinate
    }
}
