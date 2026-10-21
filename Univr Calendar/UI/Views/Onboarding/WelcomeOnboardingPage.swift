//
//  WelcomeOnboardingPage.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 18/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct WelcomeOnboardingPage: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringResource
    @Binding var errorMessage: String?
    let bottomPadding: CGFloat
    
    let buttonTitle: LocalizedStringKey
    let isLoading: Bool
    let isButtonDisabled: Bool
    let buttonAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isExpanded: Bool = false
    @State private var isBlurred: Bool = false
    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showButton: Bool = false
    
    @State private var zStackCenterY: CGFloat = 0
    
    private let initialSize: CGFloat = 200
    
    private var initialOffset: CGFloat {
        guard zStackCenterY > 0 else { return 0 }
        let screenCenterY = UIScreen.main.bounds.height / 2
        return screenCenterY - zStackCenterY
    }
    
    private var styledSubtitle: AttributedString {
        var attributed = AttributedString(localized: subtitle)
        attributed.foregroundColor = Color.secondary
        
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.stronglyEmphasized) {
                attributed[run.range].foregroundColor = Color.primary
            }
        }
        
        return attributed
    }
    
    var body: some View {
        GeometryReader { proxy in
            let targetSize = max(proxy.size.width - 32, 200)
            let currentSize = isExpanded ? targetSize : initialSize
            let currentOffset = isExpanded ? -40 : initialOffset
            
            VStack(spacing: 12) {
                Spacer()
                
                ZStack {
                    iconView(size: currentSize)
                        .offset(y: currentOffset)
                    
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.largeTitle.bold())
                            .opacity(showTitle ? 1 : 0)
                            .blur(radius: showTitle ? 0 : 8)
                            .scaleEffect(showTitle ? 1 : 0.95)
                            .offset(y: showTitle ? 0 : 32)
                        
                        Text(styledSubtitle)
                            .font(.body)
                            .lineSpacing(2)
                            .opacity(showSubtitle ? 1 : 0)
                            .blur(radius: showSubtitle ? 0 : 8)
                            .offset(y: showSubtitle ? 0 : 26)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .background {
                    Color.clear
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .global).midY
                        } action: { midY in
                            zStackCenterY = midY
                        }
                }
                
                Spacer()
                
                OnboardingErrorLabel(message: $errorMessage)
                OnboardingButton(
                    title: buttonTitle,
                    isLoading: isLoading,
                    isDisabled: isButtonDisabled,
                    action: buttonAction
                )
                .padding(.horizontal, max(bottomPadding, 16))
                .safeAreaPadding(.bottom, bottomPadding == 0 ? 16 : 0)
                .opacity(showButton ? 1 : 0)
                .blur(radius: showButton ? 0 : 12)
                .allowsHitTesting(showButton)
            }
            .multilineTextAlignment(.center)
        }
        .containerRelativeFrame(.horizontal)
        .task {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private func iconView(size: CGFloat) -> some View {
        ZStack {
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
            
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
                .blur(radius: isBlurred ? 28 : 0)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.08),
                            .init(color: .black, location: 0.40)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isBlurred ? 1 : 0)
            
            if colorScheme == .light {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.25),
                        .init(color: Color(.systemBackground).opacity(0.70), location: 0.72),
                        .init(color: Color(.systemBackground), location: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(isBlurred ? 1 : 0)
            }
        }
        .frame(width: size, height: size)
        .mask(
            LinearGradient(
                stops: opacityStops,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .mask {
            Image("InternalIcon")
                .resizable()
                .scaledToFit()
        }
    }
    
    private var opacityStops: [Gradient.Stop] {
        if colorScheme == .light {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.10),
                .init(color: .black.opacity(isBlurred ? 0.70 : 1.0), location: 0.35),
                .init(color: .black.opacity(isBlurred ? 0.38 : 1.0), location: 0.52),
                .init(color: .black.opacity(isBlurred ? 0.15 : 1.0), location: 0.68),
                .init(color: .black.opacity(isBlurred ? 0.04 : 1.0), location: 0.78),
                .init(color: .black.opacity(isBlurred ? 0.008 : 1.0), location: 0.84),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 0.88),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 1.0)
            ]
        } else {
            return [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.12),
                .init(color: .black.opacity(isBlurred ? 0.08 : 1.0), location: 0.82),
                .init(color: .black.opacity(isBlurred ? 0.0 : 1.0), location: 1.0)
            ]
        }
    }
    
    private func startAnimation() {
        guard !isExpanded else { return }
        
        Task { @MainActor in
            withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
                isExpanded = true
            }
            
            withAnimation(.easeInOut(duration: 0.7).delay(0.35)) {
                isBlurred = true
            }
            
            withAnimation(.spring(response: 0.85, dampingFraction: 0.84).delay(0.50)) {
                showTitle = true
            }
            
            withAnimation(.spring(response: 0.85, dampingFraction: 0.84).delay(0.62)) {
                showSubtitle = true
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.75)) {
                showButton = true
            }
        }
    }
}
