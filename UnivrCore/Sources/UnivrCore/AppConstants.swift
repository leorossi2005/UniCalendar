//
//  AppConstants.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum AppConstants: Sendable {
    public enum URLs {
        public static let donation = URL(string: "https://revolut.me/leorossi05?currency=EUR&amount=100")!
        public static let portfolio = URL(string: "https://www.leonardorossi.dev")!
        public static let github = URL(string: "https://github.com/leorossi2005")!
        public static let instagram = URL(string: "https://www.instagram.com/leorossi05")!
        public static let feedback = URL(string: "mailto:leonardo.rossi1922005@gmail.com?subject=Feedback%20App%20Univr")!
        public static let email = URL(string: "mailto:leonardo.rossi1922005@gmail.com")!
    }
    
    public enum AppInfo {
        public static let appName: LocalizedStringResource = .appName
        public static let developerName = "Leonardo Rossi"
    }
    
    public enum Credits {
        public static let contributors: [Contributor] = [
            Contributor(name: "Gaia", role: .developmentHelp, image: "GaiaPhoto"),
            Contributor(name: "Nicola", role: .developmentTesting, image: "NicolaPhoto"),
            Contributor(name: "Edoardo", role: .developmentTesting)
        ]
    }
    
    public enum WhatsNewData {
        public static let versions: [WhatsNewVersion] = [
            WhatsNewVersion(
                version: "0.9",
                date: Date(year: 2026, month: 1, day: 6),
                headline: .v09Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("ipad.landscape"),
                        accentColor: .blue,
                        title: .v0900Title,
                        shortDescription: .v0900Short,
                        detailedDescription: .v0900Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wifi.slash"),
                        accentColor: .orange,
                        title: .v0901Title,
                        shortDescription: .v0901Short,
                        detailedDescription: .v0901Long
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkles"),
                        accentColor: .purple,
                        title: .v0902Title,
                        shortDescription: .v0902Short,
                        detailedDescription: .v0902Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0903Title,
                        shortDescription: .v0903Short,
                        detailedDescription: .v0903Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.8",
                date: Date(year: 2025, month: 12, day: 12),
                headline: .v08Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("cup.and.saucer"),
                        accentColor: .blue,
                        title: .v0800Title,
                        shortDescription: .v0800Short,
                        detailedDescription: .v0800Long
                    ),
                    WhatsNewFeature(
                        icon: .system("list.bullet.rectangle"),
                        accentColor: .orange,
                        title: .v0801Title,
                        shortDescription: .v0801Short,
                        detailedDescription: .v0801Long
                    ),
                    WhatsNewFeature(
                        icon: .system("square.3.layers.3d.bottom.filled"),
                        accentColor: .purple,
                        title: .v0802Title,
                        shortDescription: .v0802Short,
                        detailedDescription: .v0802Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0803Title,
                        shortDescription: .v0803Short,
                        detailedDescription: .v0803Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.7",
                date: Date(year: 2025, month: 12, day: 4),
                headline: .v07Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("globe"),
                        accentColor: .blue,
                        title: .v0700Title,
                        shortDescription: .v0700Short,
                        detailedDescription: .v0700Long
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkle"),
                        accentColor: .orange,
                        title: .v0701Title,
                        shortDescription: .v0701Short,
                        detailedDescription: .v0701Long
                    ),
                    WhatsNewFeature(
                        icon: .system("gearshape"),
                        accentColor: .purple,
                        title: .v0702Title,
                        shortDescription: .v0702Short,
                        detailedDescription: .v0702Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0703Title,
                        shortDescription: .v0703Short,
                        detailedDescription: .v0703Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.6",
                date: Date(year: 2025, month: 12, day: 2),
                headline: .v06Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("textformat.abc"),
                        accentColor: .blue,
                        title: .v0600Title,
                        shortDescription: .v0600Short,
                        detailedDescription: .v0600Long
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkles.rectangle.stack"),
                        accentColor: .orange,
                        title: .v0601Title,
                        shortDescription: .v0601Short,
                        detailedDescription: .v0601Long
                    ),
                    WhatsNewFeature(
                        icon: .asset("AppIconV0.6"),
                        accentColor: .purple,
                        title: .v0602Title,
                        shortDescription: .v0602Short,
                        detailedDescription: .v0602Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0603Title,
                        shortDescription: .v0603Short,
                        detailedDescription: .v0603Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.5",
                date: Date(year: 2025, month: 11, day: 27),
                headline: .v05Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("info.circle"),
                        accentColor: .blue,
                        title: .v0500Title,
                        shortDescription: .v0500Short,
                        detailedDescription: .v0500Long
                    ),
                    WhatsNewFeature(
                        icon: .system("chart.line.uptrend.xyaxis"),
                        accentColor: .orange,
                        title: .v0501Title,
                        shortDescription: .v0501Short(0.4.formatted(.percent)),
                        detailedDescription: .v0501Long(0.4.formatted(.percent))
                    ),
                    WhatsNewFeature(
                        icon: .system("cylinder.split.1x2"),
                        accentColor: .purple,
                        title: .v0502Title,
                        shortDescription: .v0502Short,
                        detailedDescription: .v0502Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0503Title,
                        shortDescription: .v0503Short,
                        detailedDescription: .v0503Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.4",
                date: Date(year: 2025, month: 11, day: 23),
                headline: .v04Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("hare"),
                        accentColor: .blue,
                        title: .v0400Title,
                        shortDescription: .v0400Short,
                        detailedDescription: .v0400Long
                    ),
                    WhatsNewFeature(
                        icon: .system("network.badge.shield.half.filled"),
                        accentColor: .orange,
                        title: .v0401Title,
                        shortDescription: .v0401Short,
                        detailedDescription: .v0401Long
                    ),
                    WhatsNewFeature(
                        icon: .system("paintbrush.pointed"),
                        accentColor: .purple,
                        title: .v0402Title,
                        shortDescription: .v0402Short,
                        detailedDescription: .v0402Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0403Title,
                        shortDescription: .v0403Short,
                        detailedDescription: .v0403Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.3",
                date: Date(year: 2025, month: 11, day: 20),
                headline: .v03Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("rectangle.portrait.on.rectangle.portrait.angled"),
                        accentColor: .blue,
                        title: .v0300Title,
                        shortDescription: .v0300Short,
                        detailedDescription: .v0300Long
                    ),
                    WhatsNewFeature(
                        icon: .system("hand.draw"),
                        accentColor: .orange,
                        title: .v0301Title,
                        shortDescription: .v0301Short,
                        detailedDescription: .v0301Long
                    ),
                    WhatsNewFeature(
                        icon: .system("square.stack.3d.up"),
                        accentColor: .purple,
                        title: .v0302Title,
                        shortDescription: .v0302Short,
                        detailedDescription: .v0302Long
                    ),
                    WhatsNewFeature(
                        icon: .system("iphone.gen2"),
                        accentColor: .green,
                        title: .v0303Title,
                        shortDescription: .v0303Short,
                        detailedDescription: .v0303Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0304Title,
                        shortDescription: .v0304Short,
                        detailedDescription: .v0304Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.2",
                date: Date(year: 2025, month: 11, day: 19),
                headline: .v02Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("hand.draw"),
                        accentColor: .blue,
                        title: .v0200Title,
                        shortDescription: .v0200Short,
                        detailedDescription: .v0200Long
                    ),
                    WhatsNewFeature(
                        icon: .system("calendar"),
                        accentColor: .red,
                        title: .v0201Title,
                        shortDescription: .v0201Short,
                        detailedDescription: .v0201Long
                    ),
                    WhatsNewFeature(
                        icon: .system("network.badge.shield.half.filled"),
                        accentColor: .orange,
                        title: .v0202Title,
                        shortDescription: .v0202Short,
                        detailedDescription: .v0202Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0203Title,
                        shortDescription: .v0203Short,
                        detailedDescription: .v0203Long
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.1",
                date: Date(year: 2025, month: 10, day: 20),
                headline: .v01Headline,
                features: [
                    WhatsNewFeature(
                        icon: .system("app.badge.checkmark"),
                        accentColor: .blue,
                        title: .v0100Title,
                        shortDescription: .v0100Short,
                        detailedDescription: .v0100Long
                    ),
                    WhatsNewFeature(
                        icon: .system("calendar"),
                        accentColor: .green,
                        title: .v0101Title,
                        shortDescription: .v0101Short,
                        detailedDescription: .v0101Long
                    ),
                    WhatsNewFeature(
                        icon: .system("magnifyingglass"),
                        accentColor: .teal,
                        title: .v0102Title,
                        shortDescription: .v0102Short,
                        detailedDescription: .v0102Long
                    ),
                    WhatsNewFeature(
                        icon: .system("person.text.rectangle"),
                        accentColor: .purple,
                        title: .v0103Title,
                        shortDescription: .v0103Short,
                        detailedDescription: .v0103Long
                    ),
                    WhatsNewFeature(
                        icon: .system("bolt.fill"),
                        accentColor: .orange,
                        title: .v0104Title,
                        shortDescription: .v0104Short,
                        detailedDescription: .v0104Long
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: .v0105Title,
                        shortDescription: .v0105Short,
                        detailedDescription: .v0105Long
                    )
                ]
            )
        ]
    }
}
