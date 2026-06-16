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
        
    // Gesture & Layout States
    @State private var enableBackground: Bool
    @State private var baseHeight: CGFloat
    @State private var width: CGFloat
    @State private var hasMounted: Bool = false
    
    @State private var dragY: CGFloat = .zero
    
    private let defaultPadding: CGFloat
    @State private var sheetPadding: CGFloat
    
    @State private var offset: CGFloat = .zero
    
    private var liveHeight: CGFloat { baseHeight - dragY }
    
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
        let topRadius: CGFloat = isLarge ? 37 : max(0, .deviceCornerRadius - actualPadding)
        let bottomRadius: CGFloat = basePad == 0 ? 0 : max(0, .deviceCornerRadius - actualPadding)
                
        if UIDevice.isIpad {
            self._sheetShapeRadii = State(initialValue: .init(tl: 32, tr: 32, bl: basePad == 0 ? 0 : 32, br: basePad == 0 ? 0 : 32))
        } else {
            self._sheetShapeRadii = State(initialValue: .init(tl: topRadius, tr: topRadius, bl: bottomRadius, br: bottomRadius))
        }
        
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
                
                GlassContainer(radii: sheetShapeRadii, animationDuration: 0.2, isEnabled: !enableBackground) {
                    mainSheet
                        .ignoresSafeArea()
                }
                .frame(height: liveHeight)
                .frame(maxWidth: 580)
                .offset(y: (isPresented && hasMounted) ? -offset : liveHeight + defaultPadding)
                .modifier(ClampedPadding(padding: sheetPadding))
                .opacity(isPresented ? 1 : 0)
                .compositingGroup()
            }
            .frame(maxHeight: .infinity)
            .environment(manager)
            .animation(.smooth(duration: 0.3), value: isPresented)
            .animation(.smooth(duration: 0.3), value: hasMounted)
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
            
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 30,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37)
                } else {
                    sheetPadding = defaultPadding
                    setSheetShape()
                }
                
                baseHeight = newValue.value
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
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(20))
                hasMounted = true
            }
        }
    }
    
    private var mainSheet: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground)
                .opacity(enableBackground ? 1 : 0)
            
            content
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
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragUpdating(value: CGFloat, state: inout CGFloat) {
        if !manager.isDragging { manager.isDragging = true }
        
        if manager.selectedDetent == .large {
            if value < 0 {
                state = 0
                return
            }
        }
        
        let predictedHeight = baseHeight - value
        let minDetent = activeDetents.first!.value
        let maxDetent = activeDetents.last!.value
        
        if maxDetent == CustomSheetDetent.large.value && activeDetents.contains(.medium) {
            if predictedHeight >= CustomSheetDetent.medium.value && predictedHeight <= CustomSheetDetent.large.value {
                sheetPadding = min(max(defaultPadding - ((defaultPadding * (predictedHeight - CustomSheetDetent.medium.value)) / (CustomSheetDetent.large.value - CustomSheetDetent.medium.value)), 0), defaultPadding)
            } else if predictedHeight > CustomSheetDetent.large.value {
                sheetPadding = 0
            } else {
                sheetPadding = defaultPadding
            }
        }
        
        if predictedHeight >= minDetent && predictedHeight <= maxDetent {
            state = value

            let shouldEnableBackground = predictedHeight > CustomSheetDetent.large.value * 0.8

            if enableBackground != shouldEnableBackground {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if shouldEnableBackground {
                        setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37)
                    } else {
                        setSheetShape()
                    }
                }
                enableBackground = shouldEnableBackground
            }
            
            offset = 0
        } else {
            if predictedHeight > maxDetent {
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
        }
    }
    
    private func handleDragEnded(_ value: CGFloat, _ predictedEndTranslation: CGFloat) {
        if manager.selectedDetent == .large {
            if value < 0 {
                return
            }
        }
        
        let rawPredictedHeight = baseHeight - value
        let minDetent = activeDetents.first!
        let maxDetent = activeDetents.last!
        
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
            boostFactor = 1.0 + 2.0 * (distanceToMove / maxDistance)
        }
        
        let boostedVelocityPerSecond = baseVelocityPerSecond * boostFactor
        
        let distanceToTarget: CGFloat = target.value - currentH
        let relativeVelocity = abs(distanceToTarget) > 1 ? boostedVelocityPerSecond / distanceToTarget : 0
        
        baseHeight = currentH
        
        if target == .large {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(sheetCornerRadius: UIDevice.isIpad ? 29 : 37)
            }
            enableBackground = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape()
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
    private func setSheetShape(sheetCornerRadius: CGFloat = -1) {
        withAnimation {
            if UIDevice.isIpad {
                sheetShapeRadii = .init(
                    tl: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                    tr: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                    bl: defaultPadding == 0 ? 0 : 32,
                    br: defaultPadding == 0 ? 0 : 32
                )
            } else {
                sheetShapeRadii = .init(
                    tl: sheetCornerRadius == -1 ? max(0, .deviceCornerRadius - sheetPadding) : sheetCornerRadius,
                    tr: sheetCornerRadius == -1 ? max(0, .deviceCornerRadius - sheetPadding) : sheetCornerRadius,
                    bl: defaultPadding == 0 ? 0 : max(0, .deviceCornerRadius - sheetPadding),
                    br: defaultPadding == 0 ? 0 : max(0, .deviceCornerRadius - sheetPadding)
                )
            }
        }
    }
}
