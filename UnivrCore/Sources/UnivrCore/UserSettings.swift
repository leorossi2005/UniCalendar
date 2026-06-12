//
//  UserSettings.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 21/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

@MainActor
@Observable
public class UserSettings {
    public static let shared = UserSettings()
    
    private enum Key: String {
        case selectedYear, selectedCourse, selectedAcademicYear
        case foundMatricola, matricola, onboardingCompleted
        case settingsVersion, latestVersion
    }
    
    private enum Default {
        static let year = "2025"
        static let course = "0"
        static let academicYear = "0"
        static let matricola = "even"
        static let latestVersion: String = ""
        static let boolFalse = false
        static let currentVersion = 1
    }
    
    public var selectedYear: String {
        didSet { Self.save(selectedYear, key: .selectedYear) }
    }
    
    public var selectedCourse: String {
        didSet { Self.save(selectedCourse, key: .selectedCourse) }
    }
    
    public var selectedAcademicYear: String {
        didSet { Self.save(selectedAcademicYear, key: .selectedAcademicYear) }
    }
    
    public var foundMatricola: Bool {
        didSet { Self.save(foundMatricola, key: .foundMatricola) }
    }
    
    public var matricola: String {
        didSet { Self.save(matricola, key: .matricola) }
    }
    
    public var onboardingCompleted: Bool {
        didSet { Self.save(onboardingCompleted, key: .onboardingCompleted) }
    }
    
    public var latestVersion: String {
        didSet { Self.save(latestVersion, key: .latestVersion) }
    }
    
    private init() {
        let savedVersion = Self.load(.settingsVersion, fallback: 0)
        if savedVersion < 1 { Self.performV1Migration() }
        
        self.selectedYear = Self.load(.selectedYear, fallback: Default.year)
        self.selectedCourse = Self.load(.selectedCourse, fallback: Default.course)
        self.selectedAcademicYear = Self.load(.selectedAcademicYear, fallback: Default.academicYear)
        self.foundMatricola = Self.load(.foundMatricola, fallback: Default.boolFalse)
        self.matricola = Self.load(.matricola, fallback: Default.matricola)
        self.onboardingCompleted = Self.load(.onboardingCompleted, fallback: Default.boolFalse)
        self.latestVersion = Self.load(.latestVersion, fallback: Default.latestVersion)
    }
    
    private static func performV1Migration() {
        let oldMatricola = load(.matricola, fallback: "pari")
        
        save(oldMatricola == "pari" ? "even" : "odd", key: .matricola)
        save(Default.currentVersion, key: .settingsVersion)
    }
    
    public func reset() {
        selectedYear = Default.year
        selectedCourse = Default.course
        selectedAcademicYear = Default.academicYear
        foundMatricola = Default.boolFalse
        matricola = Default.matricola
        onboardingCompleted =  Default.boolFalse
        latestVersion =  Default.latestVersion
    }
    
    private static func save(_ value: Any, key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    private static func load<T>(_ key: Key, fallback: T) -> T {
        UserDefaults.standard.object(forKey: key.rawValue) as? T ?? fallback
    }
}

@MainActor
public struct TempSettingsState {
    public var selectedYear: String = ""
    public var selectedCourse: String = ""
    public var selectedAcademicYear: String = ""
    public var matricola: String = ""
    
    public init() {}
    
    public mutating func sync(with settings: UserSettings) {
        self.selectedYear = settings.selectedYear
        self.selectedCourse = settings.selectedCourse
        self.selectedAcademicYear = settings.selectedAcademicYear
        self.matricola = settings.matricola
    }
    
    public func hasChanged(from settings: UserSettings) -> Bool {
        selectedCourse != settings.selectedCourse ||
        selectedYear != settings.selectedYear ||
        selectedAcademicYear != settings.selectedAcademicYear
    }
    
    public func apply(to settings: UserSettings) {
        settings.selectedYear = self.selectedYear
        settings.selectedCourse = self.selectedCourse
        settings.selectedAcademicYear = self.selectedAcademicYear
        settings.matricola = self.matricola
    }
}
