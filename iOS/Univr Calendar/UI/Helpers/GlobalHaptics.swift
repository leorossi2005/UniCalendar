//
//  GlobalHaptics.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/01/26.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

@MainActor
@Observable
final class GlobalHaptics {
    static let shared = GlobalHaptics()
    
    var trigger: Int = 0
    
    var style: SensoryFeedback = .selection
    var state: String = ""
    
    private init() {}
    
    func play(_ feedback: SensoryFeedback, state: String = "") {
        self.style = feedback
        self.trigger += 1
        self.state = state
    }
}

struct Haptics {
    static func play(_ style: SensoryFeedback, state: String = "") {
        Task { @MainActor in
            GlobalHaptics.shared.play(style, state: state)
        }
    }
}

extension View {
    func enableGlobalHaptics() -> some View {
        self.modifier(GlobalHapticsModifier())
    }
}

struct GlobalHapticsModifier: ViewModifier {
    @State private var haptics = GlobalHaptics.shared
    
    func body(content: Content) -> some View {
        content
            .sensoryFeedback(trigger: haptics.trigger) { _, _ in
                return haptics.style
            }
    }
}
