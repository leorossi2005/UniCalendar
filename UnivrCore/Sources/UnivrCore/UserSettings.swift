//
//  UserSettings.swift
//  Univr Core
//
//  Created by Leonardo Rossi on 21/11/25.
//

import Foundation
#if canImport(Observation)
import Observation
#endif

@MainActor
#if canImport(Observation)
@Observable
#endif
public class UserSettings {
    public static let shared = UserSettings()
    
    private enum Key: String {
        case selectedYear, selectedCourse, selectedAcademicYear
        case foundMatricola, matricola, onboardingCompleted
    }
    
    private enum Default {
        static let year = "2025"
        static let course = "0"
        static let academicYear = "0"
        static let matricola = "pari"
        static let boolFalse = false
    }
    
    public var selectedYear: String {
        didSet { save(selectedYear, key: .selectedYear) }
    }
    
    public var selectedCourse: String {
        didSet { save(selectedCourse, key: .selectedCourse) }
    }
    
    public var selectedAcademicYear: String {
        didSet { save(selectedAcademicYear, key: .selectedAcademicYear) }
    }
    
    public var foundMatricola: Bool {
        didSet { save(foundMatricola, key: .foundMatricola) }
    }
    
    public var matricola: String {
        didSet { save(matricola, key: .matricola) }
    }
    
    public var onboardingCompleted: Bool {
        didSet { save(onboardingCompleted, key: .onboardingCompleted) }
    }
    
    private init() {
        self.selectedYear = Self.load(.selectedYear, fallback: Default.year)
        self.selectedCourse = Self.load(.selectedCourse, fallback: Default.course)
        self.selectedAcademicYear = Self.load(.selectedAcademicYear, fallback: Default.academicYear)
        self.foundMatricola = Self.load(.foundMatricola, fallback: Default.boolFalse)
        self.matricola = Self.load(.matricola, fallback: Default.matricola)
        self.onboardingCompleted = Self.load(.onboardingCompleted, fallback: Default.boolFalse)
    }
    
    public func reset() {
        selectedYear = Default.year
        selectedCourse = Default.course
        selectedAcademicYear = Default.academicYear
        foundMatricola = Default.boolFalse
        matricola = Default.matricola
        onboardingCompleted =  Default.boolFalse
    }
    
    private func save(_ value: Any, key: Key) {
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
        return selectedCourse != settings.selectedCourse || selectedYear != settings.selectedYear || selectedAcademicYear != settings.selectedAcademicYear
    }
    
    public func apply(to settings: UserSettings) {
        settings.selectedYear = ""
        settings.selectedCourse = ""
        settings.selectedAcademicYear = ""
        settings.matricola = ""
        
        settings.selectedYear = self.selectedYear
        settings.selectedCourse = self.selectedCourse
        settings.selectedAcademicYear = self.selectedAcademicYear
        settings.matricola = self.matricola
    }
}
