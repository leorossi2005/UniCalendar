//
//  UserSettings.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 21/11/25.
//

import Foundation

@Observable
public class UserSettings {
    public static let shared = UserSettings()
    
    private let defaults: UserDefaults = .standard
    
    private enum Keys {
        static let selectedYear = "selectedYear"
        static let selectedCourse = "selectedCourse"
        static let selectedAcademicYear = "selectedAcademicYear"
        static let foundMatricola = "foundMatricola"
        static let matricola = "matricola"
        static let onboardingCompleted = "onboardingCompleted"
    }
    
    public var selectedYear: String {
        didSet { defaults.set(selectedYear, forKey: Keys.selectedYear) }
    }
    
    public var selectedCourse: String {
        didSet { defaults.set(selectedCourse, forKey: Keys.selectedCourse) }
    }
    
    public var selectedAcademicYear: String {
        didSet { defaults.set(selectedAcademicYear, forKey: Keys.selectedAcademicYear) }
    }
    
    public var foundMatricola: Bool {
        didSet { defaults.set(foundMatricola, forKey: Keys.foundMatricola) }
    }
    
    public var matricola: String {
        didSet { defaults.set(matricola, forKey: Keys.matricola) }
    }
    
    public var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) }
    }
    
    init() {
        self.selectedYear = defaults.string(forKey: Keys.selectedYear) ?? "2025"
        self.selectedCourse = defaults.string(forKey: Keys.selectedCourse) ?? "0"
        self.selectedAcademicYear = defaults.string(forKey: Keys.selectedAcademicYear) ?? "0"
        self.foundMatricola = defaults.bool(forKey: Keys.foundMatricola)
        self.matricola = defaults.string(forKey: Keys.matricola) ?? "pari"
        self.onboardingCompleted = defaults.bool(forKey: Keys.onboardingCompleted)
    }
    
    public func reset() {
        selectedYear = "2025"
        selectedCourse = "0"
        selectedAcademicYear = "0"
        foundMatricola = false
        matricola = "pari"
        onboardingCompleted = false
    }
}
