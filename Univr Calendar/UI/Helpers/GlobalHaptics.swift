//
//  GlobalHaptics.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/01/26.
//

import SwiftUI

@MainActor
@Observable
final class GlobalHaptics {
    static let shared = GlobalHaptics()
    
    // Questo contatore cambia ogni volta che chiedi una vibrazione
    var trigger: Int = 0
    
    // Qui memorizziamo CHE TIPO di vibrazione vuoi
    var style: SensoryFeedback = .selection
    
    private init() {}
    
    func play(_ feedback: SensoryFeedback) {
        // 1. Imposta lo stile che vuoi sentire
        self.style = feedback
        
        // 2. Incrementa il contatore per dire a SwiftUI "Ehi, è cambiato qualcosa!"
        self.trigger += 1
    }
}

// Helper statico per scrivere meno codice (zucchero sintattico)
struct Haptics {
    static func play(_ style: SensoryFeedback) {
        Task { @MainActor in
            GlobalHaptics.shared.play(style)
        }
    }
}

extension View {
    func enableGlobalHaptics() -> some View {
        self.modifier(GlobalHapticsModifier())
    }
}

struct GlobalHapticsModifier: ViewModifier {
    // Osserviamo il singleton
    @State private var haptics = GlobalHaptics.shared
    
    func body(content: Content) -> some View {
        content
            // Questo è l'UNICO sensoryFeedback di tutta l'app
            .sensoryFeedback(trigger: haptics.trigger) { _, _ in
                // Ritorna lo stile che abbiamo salvato nel singleton
                return haptics.style
            }
    }
}
