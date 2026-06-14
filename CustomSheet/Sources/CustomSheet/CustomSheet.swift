//
//  CustomSheet.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 13/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

@MainActor
public enum CustomSheetDetent {
    case small, medium, large

    public var value: CGFloat {
        switch self {
        case .small:  return (((500 - 70) / 7) * 1.35) + 50
        case .medium: return 350 + 75
        case .large:
            let windowHeight = UIApplication.shared.windowSize.height
            let topSafeArea = UIApplication.shared.safeAreas.top
            let topMargin = topSafeArea > 0 ? topSafeArea : 20
            
            if UIDevice.isIpad {
                return windowHeight - 75
            } else {
                return windowHeight - topMargin
            }
        }
    }
}

@MainActor
@Observable
public class GlobalSheetManager {
    // MARK: - Sensori (Stati in sola lettura per l'utente)
    public var liveHeight: CGFloat = 0
    public var isDragging: Bool = false
    public var locked: Bool = false
    public var selectedDetent: CustomSheetDetent
    
    // MARK: - Motore Interno (Chiusure collegate dalla CustomSheet)
    var actionDismiss: (() -> Void)?
        
    // MARK: - Comandi Pubblici (Quelli che userai nella tua app)
    public func setDetent(_ detent: CustomSheetDetent) {
        selectedDetent = detent
    }
    
    public func dismiss() {
        actionDismiss?()
    }
    
    public func setLock(_ lock: Bool) {
        locked = lock
    }
    
    public init(initialDetent: CustomSheetDetent = .small) {
        self.selectedDetent = initialDetent
    }
}

struct CustomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    var detents: [CustomSheetDetent]
    
    @State private var manager: GlobalSheetManager
    @State private var activeDetents: [CustomSheetDetent]
    
    @State var sheetShapeRadii: SheetCornerRadii = SheetCornerRadii(tl: .deviceCornerRadius, tr: .deviceCornerRadius, bl: .deviceCornerRadius, br: .deviceCornerRadius)
        
    // Gesture & Layout States
    @State private var enableBackground: Bool
    @State private var baseHeight: CGFloat
    
    @State private var dragY: CGFloat = .zero
    
    @State private var basePadding: CGFloat = .zero
    @State private var initialPadding: CGFloat = .zero
    @State private var sheetPadding: CGFloat = .zero
    
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
                providedManager.selectedDetent = safeDefault
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
        
        self._initialPadding = State(initialValue: basePad)
        self._basePadding = State(initialValue: basePad)
        self._sheetPadding = State(initialValue: startingDetent == .large ? 0 : basePad)
        
        let isLarge = (startingDetent == .large)
        let topRadius: CGFloat = isLarge ? 37 : .deviceCornerRadius
        let bottomRadius: CGFloat = basePad == 0 ? 0 : topRadius
        
        if UIDevice.isIpad {
            self._sheetShapeRadii = State(initialValue: .init(tl: 32, tr: 32, bl: basePad == 0 ? 0 : 32, br: basePad == 0 ? 0 : 32))
        } else {
            self._sheetShapeRadii = State(initialValue: .init(tl: topRadius, tr: topRadius, bl: bottomRadius, br: bottomRadius))
        }
        
        self.content = content()
    }
    
    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                ZStack {
                    if enableBackground {
                        Color.black.opacity(0.37)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: enableBackground)
                
                GlassContainer(radii: sheetShapeRadii, animationDuration: 0.2, isEnabled: !enableBackground) {
                    mainSheet
                        .ignoresSafeArea()
                }
                .frame(height: liveHeight)
                .frame(maxWidth: .infinity)
                .offset(y: isPresented ? -offset : liveHeight + basePadding)
                .padding(.horizontal, sheetPadding)
                .padding(.bottom, sheetPadding)
                .opacity(isPresented ? 1 : 0)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .environment(manager)
            .animation(.smooth(duration: 0.3), value: isPresented)
        }
        //.background(WindowAccessor { window in
        //    if UIDevice.isIpad {
        //        positionObserver.startObserving(window: window)
        //    }
        //})
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                let lowestDetent = detents.min(by: { $0.value < $1.value }) ?? .small
                manager.setDetent(lowestDetent)
            }
        }
        .onChange(of: manager.selectedDetent) { oldValue, newValue in
            enableBackground = newValue == .large
            
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 30,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(sheetCornerRadius: 37)
                } else {
                    sheetPadding = initialPadding
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
        .onChange(of: liveHeight) { _, newHeight in
            manager.liveHeight = newHeight
        }
        .onAppear {
            manager.actionDismiss = {
                self.isPresented = false
            }
        }
    }
    
    private var mainSheet: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(enableBackground ? 1 : 0)
            
            content
                .overlay(alignment: .top) {
                    if !manager.locked && activeDetents.count > 1 {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(.tertiary)
                            .frame(width: 35, height: 5)
                            .padding(.top, 5)
                            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 2.5))
                            .hoverEffect(.highlight)
                    }
                }
        }
        .overlay {
            VerticalDragger(
                onDrag: { translationY, _ in
                    handleDragUpdating(value: translationY, state: &self.dragY)
                },
                onEnded: { translationY, predictedEndTranslation in
                    handleDragEnded(translationY, predictedEndTranslation)
                }
            )
            .allowsHitTesting(false)
        }
        //.onChange(of: positionObserver.edges) {
        //    setSheetShape()
        //}
        //.onChange(of: positionObserver.windowFrame) {
        //    if selectedDetent == .large {
        //        baseHeight = CustomSheetDetent.large.value
        //    }
        //}
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
                sheetPadding = min(max(initialPadding - ((initialPadding * (predictedHeight - CustomSheetDetent.medium.value)) / (CustomSheetDetent.large.value - CustomSheetDetent.medium.value)), 0), initialPadding)
            } else if predictedHeight > CustomSheetDetent.large.value {
                sheetPadding = 0
            } else {
                sheetPadding = initialPadding
            }
        }
        
        if predictedHeight >= minDetent && predictedHeight <= maxDetent {
            state = value

            if predictedHeight > CustomSheetDetent.large.value * 0.8 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape(sheetCornerRadius: 37)
                }
                enableBackground = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape()
                }
                enableBackground = false
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
                setSheetShape(sheetCornerRadius: 37)
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
                sheetPadding = initialPadding
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
                    bl: initialPadding == 0 ? 0 : 32,
                    br: initialPadding == 0 ? 0 : 32
                )
            } else {
                sheetShapeRadii = .init(
                    tl: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                    tr: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                    bl: initialPadding == 0 ? 0 : .deviceCornerRadius,
                    br: initialPadding == 0 ? 0 : .deviceCornerRadius
                )
            }
        }
    }
}

// MARK: - Don't Ask
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

class PassthroughContainerView: UIView {
    weak var hostingView: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        if hitView == hostingView || hitView == self {
            return nil
        }
        
        return hitView
    }
}

class OverlayAnchorUIView: UIView {
    var hostingController: UIHostingController<AnyView>?
    var containerView: PassthroughContainerView?
    var pendingRootView: AnyView?
    
    func cleanup() {
        hostingController?.willMove(toParent: nil)
        containerView?.removeFromSuperview()
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        containerView = nil
        hostingController = nil
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let window = self.window, hostingController == nil,
              let rootView = pendingRootView else { return }
        
        let hc = UIHostingController(rootView: rootView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.safeAreaRegions = []

        let container = PassthroughContainerView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.hostingView = hc.view
        
        container.addSubview(hc.view)
        window.addSubview(container)
        
        if let rootVC = window.rootViewController {
            rootVC.addChild(hc)
            hc.didMove(toParent: rootVC)
        }
        
        self.hostingController = hc
        self.containerView = container
        
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: container.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            container.topAnchor.constraint(equalTo: window.topAnchor),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
    }
    
    func updateNavigationSafeArea(isLarge: Bool) {
        guard let hc = hostingController else { return }
        
        func findNav(in vc: UIViewController) -> UINavigationController? {
            if let nav = vc as? UINavigationController { return nav }
            for child in vc.children {
                if let nav = findNav(in: child) { return nav }
            }
            return nil
        }
        
        DispatchQueue.main.async {
            if let nav = findNav(in: hc) {
                let targetInset: CGFloat = isLarge ? 16 : 0
                if nav.additionalSafeAreaInsets.top != targetInset {
                    UIView.animate(withDuration: 0.2) {
                        nav.additionalSafeAreaInsets.top = targetInset
                        nav.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
}

struct OverlayAnchorView<SheetContent: View>: UIViewRepresentable {
    var capturedEnvironment: EnvironmentValues
    
    @Binding var isPresented: Bool
    var manager: GlobalSheetManager?
    var detents: [CustomSheetDetent]
    
    let sheetContent: () -> SheetContent
    
    func makeUIView(context: Context) -> OverlayAnchorUIView {
        let view = OverlayAnchorUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: OverlayAnchorUIView, context: Context) {
        let updatedView = AnyView(
            CustomSheet(
                isPresented: $isPresented,
                detents: detents,
                manager: manager,
                content: sheetContent
            )
            .environment(\.self, capturedEnvironment)
        )
        
        if let hc = uiView.hostingController {
            hc.rootView = updatedView
        } else {
            uiView.pendingRootView = updatedView
        }
        
        let isLarge = manager?.selectedDetent == .large
        uiView.updateNavigationSafeArea(isLarge: isLarge)
    }
    
    static func dismantleUIView(_ uiView: OverlayAnchorUIView, coordinator: ()) {
        uiView.cleanup()
    }
}
