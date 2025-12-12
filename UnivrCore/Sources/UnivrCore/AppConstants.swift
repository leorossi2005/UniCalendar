//
//  AppConstants.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//

import Foundation

public struct AppConstants: Sendable {
    public struct URLs {
        public static let donation = URL(string: "https://revolut.me/leorossi05?currency=EUR&amount=100")!
        public static let portfolio = URL(string: "https://www.leonardorossi.dev")!
    }
    
    public struct AppInfo {
        public static let appName = "UniVR Calendar"
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
            Contributor(name: "Leonardo Rossi", role: "Sviluppatore", url: URLs.portfolio),
            Contributor(name: "Gaia", role: "Aiuto Sviluppo", url: nil),
            Contributor(name: "Nicola", role: "Aiuto Testing", url: nil),
            Contributor(name: "Edoardo", role: "Aiuto Testing", url: nil)
        ]
    }
}
