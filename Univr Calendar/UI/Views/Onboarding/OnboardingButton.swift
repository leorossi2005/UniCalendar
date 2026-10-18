//
//  OnboardingButton.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 18/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct OnboardingButton: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            Haptics.play(.impact(weight: .medium))
            action()
        } label: {
            if isLoading {
                RotatingSemicircleLoader()
            } else {
                Text(title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .glassIfAvailable(prominent: true)
        .disabled(isDisabled || isLoading)
    }
}

private struct RotatingSemicircleLoader: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(colorScheme == .light ? .black : .white, lineWidth: 4)
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    OnboardingButton(title: "Continua", isLoading: false, isDisabled: false) {}
}
