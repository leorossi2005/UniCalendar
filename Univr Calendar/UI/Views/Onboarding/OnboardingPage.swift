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
    let isSearching: Bool
    @Binding var errorMessage: String
    let isTopContent: Bool
    let content: Content
    let bottomPadding: CGFloat
    
    let buttonTitle: LocalizedStringKey
    let isLoading: Bool
    let isButtonDisabled: Bool
    let buttonAction: () -> Void
    
    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showContent: Bool = false
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringResource,
        isActive: Bool,
        isSearching: Bool = false,
        errorMessage: Binding<String>,
        isTopContent: Bool,
        content: Content,
        bottomPadding: CGFloat,
        buttonTitle: LocalizedStringKey,
        isLoading: Bool,
        isButtonDisabled: Bool,
        buttonAction: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.isSearching = isSearching
        self._errorMessage = errorMessage
        self.isTopContent = isTopContent
        self.content = content
        self.bottomPadding = bottomPadding
        self.buttonTitle = buttonTitle
        self.isLoading = isLoading
        self.isButtonDisabled = isButtonDisabled
        self.buttonAction = buttonAction
    }
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringResource,
        isActive: Bool,
        isSearching: Bool = false,
        errorMessage: Binding<String>,
        isTopContent: Bool,
        @ViewBuilder content: () -> Content,
        bottomPadding: CGFloat,
        buttonTitle: LocalizedStringKey,
        isLoading: Bool,
        isButtonDisabled: Bool,
        buttonAction: @escaping () -> Void
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            isActive: isActive,
            isSearching: isSearching,
            errorMessage: errorMessage,
            isTopContent: isTopContent,
            content: content(),
            bottomPadding: bottomPadding,
            buttonTitle: buttonTitle,
            isLoading: isLoading,
            isButtonDisabled: isButtonDisabled,
            buttonAction: buttonAction
        )
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
        VStack(spacing: 12) {
            Color.clear
                .overlay(alignment: .bottom) {
                    VStack(spacing: isSearching ? 0 : 12) {
                        if !isSearching {
                            Spacer(minLength: 0)
                        }
                        if isTopContent {
                            content
                                .opacity(showContent ? 1 : 0)
                                .blur(radius: showContent ? 0 : 8)
                                .offset(y: showContent ? 0 : 20)
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
                        
                        if !isTopContent {
                            content
                                .opacity(showContent ? 1 : 0)
                                .blur(radius: showContent ? 0 : 8)
                                .offset(y: showContent ? 0 : 20)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, isSearching ? 8 : 0)
                    .animation(.snappy(duration: 0.35), value: isSearching)
                }

            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .opacity(errorMessage == "nope" ? 0 : 1)
                .task(id: errorMessage) {
                    do {
                        try await Task.sleep(for: .seconds(3))
                        errorMessage = "nope"
                    } catch {}
                }
            OnboardingButton(
                title: buttonTitle,
                isLoading: isLoading,
                isDisabled: isButtonDisabled,
                action: buttonAction
            )
        }
        .padding(.horizontal, max(bottomPadding, 16))
        .safeAreaPadding(.bottom, bottomPadding == 0 ? 16 : 10)
        .multilineTextAlignment(.center)
        .containerRelativeFrame([.horizontal, .vertical], alignment: .bottom)
        .task(id: isActive) {
            if isActive {
                guard !Task.isCancelled, isActive else { return }
                
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
                
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    showTitle = false
                    showSubtitle = false
                    showContent = false
                }
            }
        }
    }
}
