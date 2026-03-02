//
//  NetworkMonitor.kt
//  UnivrCore
//
//  Translated from NetworkMonitor.swift
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

package dev.leonardorossi.univrcore

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class NetworkStatus { CONNECTED, DISCONNECTED }

class NetworkMonitor private constructor(context: Context) {

    companion object {
        @Volatile
        private var instance: NetworkMonitor? = null

        fun getInstance(context: Context): NetworkMonitor =
            instance ?: synchronized(this) {
                instance ?: NetworkMonitor(context.applicationContext).also { instance = it }
            }
    }

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private val _status = MutableStateFlow(getCurrentStatus())
    val status: StateFlow<NetworkStatus> = _status.asStateFlow()

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            _status.value = NetworkStatus.CONNECTED
        }

        override fun onLost(network: Network) {
            _status.value = NetworkStatus.DISCONNECTED
        }

        override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
            val hasInternet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            _status.value = if (hasInternet) NetworkStatus.CONNECTED else NetworkStatus.DISCONNECTED
        }
    }

    init {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager.registerNetworkCallback(request, networkCallback)
    }

    private fun getCurrentStatus(): NetworkStatus {
        val network = connectivityManager.activeNetwork ?: return NetworkStatus.DISCONNECTED
        val caps = connectivityManager.getNetworkCapabilities(network) ?: return NetworkStatus.DISCONNECTED
        return if (caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        ) {
            NetworkStatus.CONNECTED
        } else {
            NetworkStatus.DISCONNECTED
        }
    }

    fun unregister() {
        connectivityManager.unregisterNetworkCallback(networkCallback)
    }
}
