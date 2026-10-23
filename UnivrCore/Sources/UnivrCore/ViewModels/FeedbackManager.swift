//
//  FeedbackManager.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 22/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

// MARK: - Limiti (la UI e il server devono usare gli stessi valori)

public enum FeedbackLimits {
    public static let titleMin = 3
    public static let titleMax = 100
    public static let detailsMin = 10
    public static let detailsMax = 1000
    /// Il server accetta richieste fino a 512 KB (`maxRequestBodySize` in index.ts):
    /// l'allegato deve restare ben sotto, lasciando spazio ai campi di testo.
    public static let attachmentMaxBytes = 400 * 1024
}

public enum FeedbackError: Error, Sendable {
    /// Troppi invii ravvicinati (HTTP 429)
    case rateLimited
    /// Immagine rifiutata dal server (HTTP 413/415)
    case attachmentRejected
}

// MARK: - Info dispositivo (tutte da `Device` + `Bundle`)

public struct FeedbackDeviceInfo: Sendable, Equatable {
    public let appVersion: String
    public let build: String
    public let deviceIdentifier: String
    public let deviceName: String
    public let osName: String
    public let osVersion: String
    
    public static var current: FeedbackDeviceInfo {
        let device = Device.current
        
        let baseName = DeviceNames.marketingName(for: device.model) ?? device.name
        let formattedName = device.isSimulator ? "\(baseName) (Simulator)" : baseName
        
        return FeedbackDeviceInfo(
            appVersion: Bundle.main.clearAppVersion,
            build: Bundle.main.clearBuildNumber,
            deviceIdentifier: device.model,
            deviceName: formattedName,
            osName: device.os.name,
            osVersion: device.os.version
        )
    }
}

// MARK: - Payload interno

struct FeedbackPayload: Sendable {
    let title: String
    let details: String
    let device: FeedbackDeviceInfo
    let attachment: Data?
}

// MARK: - Manager

public enum FeedbackManager {
    /// `attachment` deve essere già un JPEG compresso (vedi `FeedbackLimits.attachmentMaxBytes`).
    /// Un invio ripetuto con lo stesso testo viene deduplicato dal server.
    public static func submit(title: String, details: String, attachment: Data?) async throws {
        let payload = FeedbackPayload(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            device: .current,
            attachment: attachment
        )
        do {
            try await NetworkService().sendFeedback(payload)
        } catch NetworkError.badServerResponse(statusCode: 429) {
            throw FeedbackError.rateLimited
        } catch NetworkError.badServerResponse(statusCode: 413), NetworkError.badServerResponse(statusCode: 415) {
            throw FeedbackError.attachmentRejected
        }
    }
}
