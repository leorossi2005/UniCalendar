//
//  NetworkError.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case badURL
    case badServerResponse(statusCode: Int)
    case emptyData
    case decodingError(Error)
    case offline
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .offline: return String(localized: .networkErrorOffline)
        case .timeout: return String(localized: .networkErrorTimeout)
        case .badURL: return String(localized: .networkErrorBadUrl)
        case .badServerResponse: return String(localized: .networkErrorServer)
        case .emptyData: return String(localized: .networkErrorEmptyData)
        case .decodingError: return String(localized: .networkErrorDecoding)
        case .unknown: return String(localized: .unknownError)
        }
    }
}
