//
//  OnboardingComponents.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 21/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct OnboardingErrorLabel: View {
    @Binding var message: String?

    var body: some View {
        ZStack {
            Text(" ")
                .font(.caption)
                .hidden()

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: message)
        .task(id: message) {
            guard message != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { message = nil }
        }
    }
}

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
                    .accessibilityLabel("Caricamento in corso")
            } else {
                Text(title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .glassIfAvailable(prominent: true)
        .disabled(isDisabled || isLoading)
        .accessibilityRemoveTraits(isLoading ? [.isButton] : [])
    }
}

private struct RotatingSemicircleLoader: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.6)
            .stroke(.primary, lineWidth: 4)
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
