//
//  AppConstants.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public struct AppConstants: Sendable {
    public struct URLs {
        public static let donation = URL(string: "https://revolut.me/leorossi05?currency=EUR&amount=100")!
        public static let portfolio = URL(string: "https://www.leonardorossi.dev")!
        public static let github = URL(string: "https://github.com/leorossi2005")!
        public static let instagram = URL(string: "https://www.instagram.com/leorossi05")!
        public static let feedback = URL(string: "mailto:leonardo.rossi1922005@gmail.com?subject=Feedback%20App%20Univr")!
        public static let email = URL(string: "mailto:leonardo.rossi1922005@gmail.com")!
    }
    
    public struct AppInfo {
        public static let appName = NSLocalizedString("Calendario per UniVR", bundle: .module, comment: "")
        public static let developerName = "Leonardo Rossi"
    }
    
    public struct Contributor: Identifiable, Sendable, Equatable {
        public let id: String
        public let name: String
        public let role: String
        public let url: URL?
        public let image: String
        
        public init(name: String, role: String, url: URL? = nil, image: String = "") {
            self.id = name
            self.name = name
            self.role = role
            self.url = url
            self.image = image
        }
    }
    
    public struct Credits {
        public static let contributors: [Contributor] = [
            Contributor(name: "Gaia", role: NSLocalizedString("Aiuto Sviluppo", bundle: .module, comment: ""), image: "GaiaPhoto"),
            Contributor(name: "Nicola", role: NSLocalizedString("Aiuto Testing", bundle: .module, comment: ""), image: "NicolaPhoto"),
            Contributor(name: "Edoardo", role: NSLocalizedString("Aiuto Testing", bundle: .module, comment: ""))
        ]
    }
}
