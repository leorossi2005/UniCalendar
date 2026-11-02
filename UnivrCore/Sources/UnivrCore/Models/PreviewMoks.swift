//
//  PreviewMoks.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

extension Lesson {
    public static let sample = Lesson(
        id: "SAMPLE-123",
        code: "XYZ",
        type: .lesson,
        name: "Insegnamento di prova",
        cleanName: "Insegnamento di prova",
        tags: ["Informatica", "Base"],
        group: .all,
        startTime: Date(),
        endTime: Date().addingTimeInterval(7200),
        durationMinutes: 120,
        isCanceled: false,
        color: "#A0A0A0",
        teachers: ["Prof. Rossi", "Prof. Verdi"],
        location: LocationInfo(
            classroom: "Aula Gino Tessari",
            building: "Borgo Roma - Ca' Vignal 2",
            address: "Strada Le Grazie, 15 - 37134 Verona",
            capacity: 236,
            coordinates: Coordinates(latitude: 45.4037, longitude: 10.9991)
        )
    )
    
    // periphery:ignore
    public static let pausaSample = Lesson(
        id: "PAUSA-123",
        code: nil,
        type: .pause,
        name: "Pausa",
        cleanName: "Pausa",
        tags: [],
        group: .all,
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        durationMinutes: 60,
        isCanceled: false,
        color: "#FFFFFF",
        teachers: [],
        location: nil
    )
}

extension Room {
    public static func sample(date: Date) -> Room {
        return Room(
            id: "SAMPLE-123",
            name: "Aula di prova",
            events: [
                Event(
                    id: "EVENT-1",
                    name: "Evento di prova",
                    cleanName: "Evento di Prova",
                    startTime: date.add(type: .minute, value: -30),
                    endTime: date.add(type: .hour, value: 1)
                ),
                Event(
                    id: "EVENT-2",
                    name: "Evento di prova",
                    cleanName: "Evento di Prova",
                    startTime: date.add(type: .hour, value: 1),
                    endTime: date.add(type: .hour, value: 3)
                ),
                Event(
                    id: "EVENT-3",
                    name: "Evento di prova",
                    cleanName: "Evento di Prova",
                    startTime: date.add(type: .hour, value: 4),
                    endTime: date.add(type: .hour, value: 6)
                ),
                Event(
                    id: "EVENT-4",
                    name: "Evento di prova",
                    cleanName: "Evento di Prova",
                    startTime: date.add(type: .hour, value: 6),
                    endTime: date.add(type: .hour, value: 8)
                )
            ]
        )
    }
}

extension AppNotice {
    public static var sample: AppNotice {
        AppNotice(
            id: "SAMPLE-123",
            level: .info,
            title: ["en": "Notice sample", "it": "Avviso d'esempio"],
            message: ["en": "This notice is a sample", "it": "Questo avviso è un esempio"],
            buttonText: ["en": "I'm a button", "it": "Sono un bottone"],
            url: nil,
            startsAt: .now,
            endsAt: .distantFuture
        )
    }
}
