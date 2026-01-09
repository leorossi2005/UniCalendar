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
        public static let email = URL(string: "mailto:tuo.email@dominio.com")!
        public static let twitter = URL(string: "https://x.com/tuo_username")!
        // Link mailto precompilato per il feedback
        public static let feedback = URL(string: "mailto:tuo.email@dominio.com?subject=Feedback%20App%20Univr")!
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
        
        public init(name: String, role: String, url: URL? = nil) {
            self.id = name
            self.name = name
            self.role = role
            self.url = url
        }
    }
    
    public struct Credits {
        public static let contributors: [Contributor] = [
            //Contributor(name: "Leonardo Rossi", role: NSLocalizedString("Sviluppatore", bundle: .module, comment: ""), url: URLs.portfolio),
            Contributor(name: "Gaia", role: NSLocalizedString("Aiuto Sviluppo", bundle: .module, comment: ""), url: nil),
            Contributor(name: "Nicola", role: NSLocalizedString("Aiuto Testing", bundle: .module, comment: ""), url: nil),
            Contributor(name: "Edoardo", role: NSLocalizedString("Aiuto Testing", bundle: .module, comment: ""), url: nil)
        ]
    }
}
