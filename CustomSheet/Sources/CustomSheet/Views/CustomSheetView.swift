//
//  CustomSheetView.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 13/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

enum DraggerValues {
    static var width: CGFloat {
        if #available(iOS 27, *) {
            return 60
        } else {
            return 36
        }
    }
    
    static var height: CGFloat {
        if #available(iOS 27, *) {
            return 4
        } else {
            return 5
        }
    }
    
    static var topPadding: CGFloat {
        if #available(iOS 27, *) {
            return 6
        } else {
            return 5
        }
    }
}

struct CustomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    var detents: [CustomSheetDetent]
    
    @State private var manager: GlobalSheetManager
    @State private var activeDetents: [CustomSheetDetent]
    
    @State var sheetShapeRadii: SheetCornerRadii
    @State private var isAtMax: Bool
    
    // Gesture & Layout States
    @State private var enableBackground: Bool
    @State private var baseHeight: CGFloat
    @State private var width: CGFloat
    @State private var hasMounted: Bool = false
    
    @State private var dragY: CGFloat = .zero
    
    private let defaultPadding: CGFloat
    @State private var sheetPadding: CGFloat
    
    @State private var offset: CGFloat = .zero
    @State private var cornerAnimationDuration: TimeInterval = 0.2
    @State private var useSpringForCorners: Bool = false
    
    private var liveHeight: CGFloat {
        let h = baseHeight - dragY
        return h.isFinite ? max(0, h) : 0
    }
    
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        detents: [CustomSheetDetent],
        manager: GlobalSheetManager?,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.detents = detents
        
        let safeDefault = detents.min(by: { $0.value < $1.value }) ?? .small
        let initialManager: GlobalSheetManager
        
        if let providedManager = manager {
            if !detents.contains(providedManager.selectedDetent) {
                providedManager.setDetent(safeDefault)
            }
            initialManager = providedManager
        } else {
            initialManager = GlobalSheetManager(initialDetent: safeDefault)
        }
        
        self._manager = State(initialValue: initialManager)
        self._activeDetents = State(initialValue: detents)
        
        let startingDetent = initialManager.selectedDetent
        
        self._baseHeight = State(initialValue: startingDetent.value)
        self._enableBackground = State(initialValue: startingDetent == .large)
        
        let basePad: CGFloat
        if #available(iOS 26, *) {
            basePad = 8
        } else {
            basePad = 0
        }
        
        self.defaultPadding = basePad
        let actualPadding = startingDetent == .large ? 0 : basePad
        self._sheetPadding = State(initialValue: actualPadding)
        
        let isLarge = (startingDetent == .large)
        self._isAtMax = State(initialValue: isLarge)
        let initialRadius: CGFloat = isLarge ? (UIDevice.isIpad ? 29 : 37) : -1
        self._sheetShapeRadii = State(initialValue: Self.calculateRadii(
            sheetCornerRadius: initialRadius,
            padding: actualPadding,
            defaultPadding: basePad,
            isAtMax: isLarge
        ))
        
        self._width = State(initialValue: UIApplication.shared.windowSize.width)
        
        self.content = content()
    }
    
    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(enableBackground ? 0.37 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(enableBackground)
                    .animation(.easeInOut(duration: 0.2), value: enableBackground)
                    .animation(.easeInOut(duration: 0.2), value: isPresented)
                    .animation(.easeInOut(duration: 0.2), value: hasMounted)
                
                GlassContainer(
                    radii: sheetShapeRadii,
                    animationDuration: cornerAnimationDuration,
                    useSpring: useSpringForCorners,
                    isEnabled: !enableBackground
                ) {
                    mainSheet
                        .ignoresSafeArea()
                }
                .overlay {
                    SheetDragger(
                        onDrag: { translationY, _ in
                            handleDragUpdating(value: translationY, state: &self.dragY)
                        },
                        onEnded: { translationY, predictedEndTranslation in
                            handleDragEnded(translationY, predictedEndTranslation)
                        }
                    )
                    .allowsHitTesting(false)
                }
                .frame(height: liveHeight)
                .frame(maxWidth: 580)
                .offset(y: (isPresented && hasMounted) ? -offset : liveHeight + defaultPadding)
                .modifier(ClampedPadding(padding: sheetPadding))
                .opacity(isPresented ? 1 : 0)
            }
            .frame(maxHeight: .infinity)
            .environment(manager)
            .animation(.smooth(duration: 0.3), value: isPresented)
            .animation(.smooth(duration: 0.3), value: hasMounted)
            .onChange(of: enableBackground) { _, newValue in
                manager.onBackgroundToggle?(newValue)
            }
            .onAppear {
                manager.onBackgroundToggle?(enableBackground)
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size) { _, newSize in
                        if manager.selectedDetent == .large && !manager.isDragging {
                            baseHeight = CustomSheetDetent.large.value
                        }
                        width = UIApplication.shared.windowSize.width
                    }
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                let lowestDetent = detents.min(by: { $0.value < $1.value }) ?? .small
                manager.setDetent(lowestDetent)
            }
        }
        .onChange(of: manager.selectedDetent) { oldValue, newValue in
            manager.previousDetent = oldValue
            enableBackground = newValue == .large
            let atMax = newValue == .large
            isAtMax = atMax
            
            cornerAnimationDuration = newValue == .large ? 0.55 : 0.35
            useSpringForCorners = true
            
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 30,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37, isAtMax: true)
                } else {
                    sheetPadding = defaultPadding
                    setSheetShape(isAtMax: false)
                }
                
                baseHeight = newValue.value
                dragY = 0
                offset = 0
            }
        }
        .onChange(of: manager.locked) { _, isLocked in
            if isLocked {
                activeDetents = [manager.selectedDetent]
            } else {
                activeDetents = detents
            }
        }
        .onChange(of: detents) { _, newDetents in
            if !manager.locked {
                activeDetents = newDetents
                
                if !newDetents.contains(manager.selectedDetent) {
                    let safeFallback = newDetents.min(by: { $0.value < $1.value }) ?? .small
                    manager.setDetent(safeFallback)
                }
            }
        }
        .onAppear {
            manager.actionDismiss = {
                isPresented = false
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(100))
            hasMounted = true
        }
    }
    
    private var mainSheet: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground)
                .opacity(enableBackground ? 1 : 0)
            
            content
                .scrollDismissesKeyboard(.interactively)
                .frame(width: min(580, width))
                .frame(maxHeight: CustomSheetDetent.large.value)
                .overlay(alignment: .top) {
                    if !manager.locked && activeDetents.count > 1 {
                        RoundedRectangle(cornerRadius: DraggerValues.height / 2)
                            .fill(Color(.systemGray2))
                            .frame(width: DraggerValues.width, height: DraggerValues.height)
                            .padding(.top, DraggerValues.topPadding)
                            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: DraggerValues.height / 2))
                            .hoverEffect(.highlight)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            DispatchQueue.main.async {
                if manager.selectedDetent == .large {
                    baseHeight = CustomSheetDetent.large.value
                }
            }
        }
    }
    
    // MARK: - Drag Logic
    func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        guard dimension > 0 else { return 0 }
        
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragUpdating(value: CGFloat, state: inout CGFloat) {
        cornerAnimationDuration = 0.2
        useSpringForCorners = false
        if !manager.isDragging { manager.isDragging = true }
        
        if manager.selectedDetent == .large {
            if value < 0 {
                if !isAtMax || !enableBackground {
                    isAtMax = true
                    enableBackground = true
                    setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37, isAtMax: true)
                }
                state = 0
                return
            }
        }
        
        let predictedHeight = baseHeight - value
        
        guard let first = activeDetents.first, let last = activeDetents.last else { return }
        let minDetent = first.value
        let maxDetent = last.value
        
        // 1. Calcola prima stato e offset (incluso il rubber-banding se bloccata)
        if predictedHeight >= minDetent && predictedHeight <= maxDetent {
            state = value
            offset = 0
        } else if predictedHeight > maxDetent {
            let excess = predictedHeight - maxDetent
            let dampedExcess = rubberBandDistance(offset: excess, dimension: maxDetent - maxDetent * 0.75)
            state = baseHeight - (maxDetent + dampedExcess)
            offset = 0
        } else if predictedHeight < minDetent {
            let excess = minDetent - predictedHeight
            let dampedExcess = rubberBandDistance(offset: excess, dimension: maxDetent - maxDetent * 0.75)
            state = baseHeight - minDetent
            offset = -dampedExcess
        }
        
        // 2. Calcola l'altezza visiva reale sullo schermo (considerando anche l'offset del rubber-band)
        let effectiveHeight = (baseHeight - state) + offset
        
        // 3. Usa `detents` invece di `activeDetents` così il padding si adatta anche col lock attivo
        if detents.contains(.large) && detents.contains(.medium) {
            if effectiveHeight >= CustomSheetDetent.medium.value && effectiveHeight <= CustomSheetDetent.large.value {
                sheetPadding = min(max(defaultPadding - ((defaultPadding * (effectiveHeight - CustomSheetDetent.medium.value)) / (CustomSheetDetent.large.value - CustomSheetDetent.medium.value)), 0), defaultPadding)
            } else if effectiveHeight > CustomSheetDetent.large.value {
                sheetPadding = 0
            } else {
                sheetPadding = defaultPadding
            }
        }
        
        // 4. Unifica il controllo della soglia dell'80% e degli angoli per tutti i casi
        let shouldEnableBackground = effectiveHeight > CustomSheetDetent.large.value * 0.8
        let currentlyAtMax = effectiveHeight >= CustomSheetDetent.large.value
        let backgroundChanged = enableBackground != shouldEnableBackground
        let maxChanged = isAtMax != currentlyAtMax
        
        if backgroundChanged || maxChanged {
            enableBackground = shouldEnableBackground
            isAtMax = currentlyAtMax
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(
                    sheetCornerRadius: shouldEnableBackground ? (UIDevice.isIpad ? 29 : 37) : -1,
                    isAtMax: currentlyAtMax
                )
            }
        }
    }
    
    private func handleDragEnded(_ value: CGFloat, _ predictedEndTranslation: CGFloat) {
        cornerAnimationDuration = 0.2
        useSpringForCorners = false
        
        if manager.selectedDetent == .large {
            if value < 0 {
                manager.isDragging = false
                isAtMax = true
                enableBackground = true
                dragY = 0
                offset = 0
                withAnimation(.interpolatingSpring(
                    mass: 1.0,
                    stiffness: 300,
                    damping: 25,
                    initialVelocity: 0
                )) {
                    baseHeight = CustomSheetDetent.large.value
                    sheetPadding = 0
                    setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37, isAtMax: true)
                }
                return
            }
        }
        
        let rawPredictedHeight = baseHeight - value
        
        guard let minDetent = activeDetents.first, let maxDetent = activeDetents.last else { return }
        
        var effectiveTranslation = rawPredictedHeight
        
        if rawPredictedHeight > maxDetent.value {
            let excess = rawPredictedHeight - maxDetent.value
            let dampedExcess = rubberBandDistance(offset: excess, dimension: maxDetent.value - maxDetent.value * 0.75)
            effectiveTranslation = maxDetent.value + dampedExcess
        }
        else if rawPredictedHeight < minDetent.value {
            effectiveTranslation = minDetent.value
        }
        
        let currentH = effectiveTranslation
                
        let predictedTranslation = predictedEndTranslation
        let predictedHeight = baseHeight - predictedTranslation
        var target = activeDetents.min(by: { abs($0.value - predictedHeight) < abs($1.value - predictedHeight) }) ?? .small
        
        if currentH < minDetent.value || rawPredictedHeight < minDetent.value {
            target = minDetent
        } else if currentH > maxDetent.value {
            target = maxDetent
        }
        
        let isGoingDown = target.value < currentH
        
        let projectedDelta = predictedTranslation - value
        let baseVelocityPerSecond = -(projectedDelta * 5.0)
        
        var boostFactor: CGFloat = 1.0
        
        if !isGoingDown && currentH >= minDetent.value && currentH <= maxDetent.value {
            let distanceToMove = abs(target.value - currentH)
            let maxDistance = maxDetent.value - minDetent.value
            if maxDistance > 0 {
                boostFactor = 1.0 + 2.0 * (distanceToMove / maxDistance)
            }
        }
        
        let boostedVelocityPerSecond = baseVelocityPerSecond * boostFactor
        
        let distanceToTarget: CGFloat = target.value - currentH
        let relativeVelocity = abs(distanceToTarget) > 1 ? boostedVelocityPerSecond / distanceToTarget : 0
        
        baseHeight = currentH
        
        if target == .large {
            isAtMax = true
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37, isAtMax: true)
            }
            enableBackground = true
        } else {
            isAtMax = false
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(isAtMax: false)
            }
            enableBackground = false
        }
        
        var limit: CGFloat = isGoingDown ? manager.selectedDetent == .large ? 30 : 45 : 45
        if baseHeight - dragY > activeDetents.last!.value {
            limit = 0
        }
        
        manager.isDragging = false
        manager.setDetent(target)
        dragY = 0
        
        withAnimation(.interpolatingSpring(
            mass: 1.0,
            stiffness: 300,
            damping: 25,
            initialVelocity: min(max(relativeVelocity, -limit), limit)
        )) {
            baseHeight = target.value
            offset = 0
            
            if target == .large {
                sheetPadding = 0
            } else {
                sheetPadding = defaultPadding
            }
        }
    }
    
    // MARK: - Logic
    @MainActor
    private static func calculateRadii(sheetCornerRadius: CGFloat = -1, padding: CGFloat, defaultPadding: CGFloat, isAtMax: Bool) -> SheetCornerRadii {
        let isLarge = sheetCornerRadius != -1
        
        if UIDevice.isIpad {
            let top: CGFloat = sheetCornerRadius == -1 ? 32 : sheetCornerRadius
            let bottom: CGFloat = defaultPadding == 0 ? 0 : 32
            return .init(tl: top, tr: top, bl: bottom, br: bottom)
        }
        
        let isSquareScreen = CGFloat.deviceCornerRadius == 0
        
        if #unavailable(iOS 26) {
            let top: CGFloat = isSquareScreen ? 16 : (isLarge ? sheetCornerRadius : .deviceCornerRadius)
            return .init(tl: top, tr: top, bl: 0, br: 0)
        } else {
            if isSquareScreen {
                let radius: CGFloat = 16
                let bottom: CGFloat = isAtMax ? 0 : radius
                return .init(tl: radius, tr: radius, bl: bottom, br: bottom)
            }
            
            let top: CGFloat = isLarge ? sheetCornerRadius : max(0, .deviceCornerRadius - padding)
            let bottom: CGFloat = isAtMax ? 0 : max(0, .deviceCornerRadius - padding)
            return .init(tl: top, tr: top, bl: bottom, br: bottom)
        }
    }
    
    private func setSheetShape(sheetCornerRadius: CGFloat = -1, isAtMax: Bool? = nil) {
        if let isAtMax {
            self.isAtMax = isAtMax
        }
        let atMax = isAtMax ?? self.isAtMax
        sheetShapeRadii = Self.calculateRadii(
            sheetCornerRadius: sheetCornerRadius,
            padding: sheetPadding,
            defaultPadding: defaultPadding,
            isAtMax: atMax
        )
    }
}
