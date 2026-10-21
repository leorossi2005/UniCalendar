//
//  OnboardingPage.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 18/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct OnboardingPage<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringResource
    let isActive: Bool
    var isSearching: Bool = false
    @Binding var errorMessage: String?
    let bottomPadding: CGFloat
    
    let buttonTitle: LocalizedStringKey
    let isLoading: Bool
    let isButtonDisabled: Bool
    var textFieldFocus: Bool = false
    let buttonAction: () -> Void
    @ViewBuilder let content: Content
    
    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showContent: Bool = false
    
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
        VStack(spacing: 12) {
            Color.clear
                .overlay(alignment: .bottom) {
                    VStack(spacing: isSearching ? 0 : 12) {
                        if !isSearching {
                            Spacer(minLength: 0)
                        }
                        
                        VStack(spacing: 12) {
                            Text(title)
                                .font(.largeTitle.bold())
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(isSearching ? 0 : (showTitle ? 1 : 0))
                                .blur(radius: isSearching ? 16 : (showTitle ? 0 : 8))
                                .scaleEffect(isSearching ? 0.94 : (showTitle ? 1 : 0.95))
                                .offset(y: isSearching ? -36 : (showTitle ? 0 : 28))
                            
                            Text(styledSubtitle)
                                .font(.body)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(isSearching ? 0 : (showSubtitle ? 1 : 0))
                                .blur(radius: isSearching ? 16 : (showSubtitle ? 0 : 8))
                                .scaleEffect(isSearching ? 0.94 : (showSubtitle ? 1 : 0.95))
                                .offset(y: isSearching ? -28 : (showSubtitle ? 0 : 22))
                        }
                        .frame(maxHeight: isSearching ? 0 : nil, alignment: .bottom)
                        .allowsHitTesting(!isSearching)
                        
                        content
                            .opacity(showContent ? 1 : 0)
                            .blur(radius: showContent ? 0 : 8)
                            .offset(y: showContent ? 0 : 20)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, isSearching ? 8 : 0)
                    .animation(.snappy(duration: 0.35), value: isSearching)
                }

            OnboardingErrorLabel(message: $errorMessage)
            OnboardingButton(
                title: buttonTitle,
                isLoading: isLoading,
                isDisabled: isButtonDisabled || !isActive,
                action: buttonAction
            )
        }
        .padding(.horizontal, max(bottomPadding, 16))
        .safeAreaPadding(.bottom, bottomPadding == 0 ? 16 : textFieldFocus ? 10 : 0)
        .multilineTextAlignment(.center)
        .containerRelativeFrame(.horizontal)
        .task(id: isActive) {
            if isActive {
                withAnimation(.spring(response: 0.80, dampingFraction: 0.84)) {
                    showTitle = true
                }
                withAnimation(.spring(response: 0.80, dampingFraction: 0.84).delay(0.10)) {
                    showSubtitle = true
                }
                withAnimation(.spring(response: 0.80, dampingFraction: 0.84).delay(0.20)) {
                    showContent = true
                }
            } else {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled, !isActive else { return }
                
                withAnimation(nil) {
                    showTitle = false
                    showSubtitle = false
                    showContent = false
                }
            }
        }
    }
}
