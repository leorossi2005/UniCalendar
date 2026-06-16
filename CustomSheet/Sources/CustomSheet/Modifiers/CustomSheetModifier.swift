//
//  CustomSheetModifier.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct ClampedPadding: ViewModifier, Animatable {
    var padding: CGFloat
    
    var animatableData: CGFloat {
        get { padding }
        set { padding = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, max(0, padding))
            .padding(.bottom, max(0, padding))
    }
}

struct customSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.self) var completeEnvironment
    
    @Binding var isPresented: Bool
    var manager: GlobalSheetManager?
    var detents: [CustomSheetDetent]
    
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .background(
                OverlayAnchorView(
                    capturedEnvironment: completeEnvironment,
                    isPresented: $isPresented,
                    manager: manager,
                    detents: detents,
                    sheetContent: sheetContent
                )
            )
    }
}

extension View {
    public func customSheet<Content: View>(
        isPresented: Binding<Bool>,
        manager: GlobalSheetManager? = nil,
        detents: [CustomSheetDetent] = [.large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(customSheetModifier(
            isPresented: isPresented,
            manager: manager,
            detents: detents,
            sheetContent: content
        ))
    }
}
