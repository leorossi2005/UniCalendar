//
//  CustomSheet.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 13/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct MainView: View {
    @State var isPresented: Bool = true
    
    // Test
    @State var selectedWeek: Date = Date()
    @State var selectedLesson: Lesson? = nil
    @State var openAddToCalendar: Bool = false
    @State var openSettings: Bool = false
    @State var openWhatsNew: Bool = false
    @State var tempSettings: TempSettingsState = .init()
    @State var lockSheet: Bool = false
    @State var isGoingLarge: Bool = false
    @State var selectedDetent: CustomSheetDetent = .small
    
    @State private var networkObserver = NetworkStateObserver(
        provider: IOSNetworkMonitor.createProvider()
    )
    
    var body: some View {
        VStack {
            Toggle("Ciao", isOn: $isPresented)
            Button("Open Settings") {
                openSettings = true
                selectedDetent = .large
            }
            Button("Open News") {
                openWhatsNew = true
                selectedDetent = .large
            }
            Button("Open Calendar") {
                selectedLesson = .sample
                openAddToCalendar = true
                selectedDetent = .large
            }
            Button("Open Lesson") {
                selectedLesson = .sample
                selectedDetent = .large
            }
        }
        .customSheet(isPresented: $isPresented, selectedDetent: $selectedDetent) {
            DynamicSheetContent(
                selectedWeek: $selectedWeek,
                selectedDetent: $selectedDetent,
                selectedLesson: $selectedLesson,
                openAddToCalendar: $openAddToCalendar,
                openSettings: $openSettings,
                openWhatsNew: $openWhatsNew,
                tempSettings: $tempSettings,
                lockSheet: $lockSheet,
                isGoingLarge: isGoingLarge
            )
        }
        .padding()
        .ignoresSafeArea(edges: .bottom)
        .environment(networkObserver)
        .environment(UserSettings.shared)
    }
}

struct CustomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var selectedDetent: CustomSheetDetent
    @State var sheetShape: UnevenRoundedRectangle = UnevenRoundedRectangle()
    @State var sheetShapeRadii: SheetCornerRadii = SheetCornerRadii(tl: 62, tr: 62, bl: 62, br: 62)
    
    // Gesture & Layout States
    @State private var enableBackground: Bool = false
    @State private var trigger: Int = 0
    @State private var detents: [CustomSheetDetent] = [.small, .medium]
    @State private var baseHeight: CGFloat = CustomSheetDetent.small.value
    
    @State private var dragY: CGFloat = .zero
    
    @State private var basePadding: CGFloat = .zero
    @State private var initialPadding: CGFloat = .zero
    @State private var sheetPadding: CGFloat = .zero
    
    @State private var offset: CGFloat = .zero
    
    private var liveHeight: CGFloat { baseHeight - dragY }
    
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<CustomSheetDetent>,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self._selectedDetent = selectedDetent
        self._baseHeight = State(initialValue: selectedDetent.wrappedValue.value)
        self.content = content()
    }
    
    // TEMP
    @State private var isGoingLarge: Bool = false
    @State private var lockSheet: Bool = false
    
    var body: some View {
        Group {
            ZStack(alignment: .bottom) {
                ZStack {
                    if enableBackground {
                        Color.black.opacity(0.37)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: enableBackground)
                
                if #available(iOS 26, *) {
                    GlassContainer(radii: sheetShapeRadii, animationDuration: 0.2, isEnabled: !enableBackground, resetGlassEffect: trigger) {
                        if isPresented {
                            mainSheet
                                .ignoresSafeArea()
                                .transition(.blurReplace)
                        } else {
                            Button {
                                changeOpenCalendar(true)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                    Text("Calendario")
                                        .fixedSize()
                                }
                                .padding(.vertical, 12.2)
                                .padding(.horizontal, 10)
                            }
                            .contentShape(.capsule)
                            .contentShape(.hoverEffect, .capsule)
                            .hoverEffect(.highlight)
                            .buttonStyle(.plain)
                            .ignoresSafeArea()
                            .transition(.blurReplace)
                        }
                    }
                    .frame(width: isPresented ? nil : 123.3, height: isPresented ? liveHeight : 47.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(y: -offset)
                    .padding(.horizontal, isPresented ? sheetPadding : UIApplication.shared.safeAreas.bottom)
                    .padding(.bottom, isPresented ? sheetPadding : UIApplication.shared.safeAreas.bottom)
                    .ignoresSafeArea()
                } else {
                    GlassContainer(radii: sheetShapeRadii, animationDuration: 0.2, isEnabled: !enableBackground, resetGlassEffect: trigger) {
                        mainSheet
                            .ignoresSafeArea()
                    }
                    .frame(height: liveHeight)
                    .offset(y: -offset)
                    .padding(.horizontal, sheetPadding)
                    .padding(.bottom, sheetPadding)
                    .ignoresSafeArea()
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        //.background(WindowAccessor { window in
        //    if UIDevice.isIpad {
        //        positionObserver.startObserving(window: window)
        //    }
        //})
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                trigger += 1
            }
        }
        .onChange(of: selectedDetent) { oldValue, newValue in
            enableBackground = newValue == .large
            changeOpenCalendar(true)
            
            if oldValue == .large {
                isGoingLarge = false
                detents = [.small, .medium]
            } else if newValue == .large {
                isGoingLarge = true
                detents = [.small, .medium, .large]
            }
            
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 30,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(isOpen: true, sheetCornerRadius: 37)
                } else {
                    sheetPadding = initialPadding
                    setSheetShape(isOpen: true)
                }
                
                baseHeight = newValue.value
                offset = 0
            }
        }
        .onChange(of: lockSheet) { _, newValue in
            if selectedDetent == .large {
                detents = newValue ? [.large] : [.small, .medium, .large]
            } else {
                lockSheet = false
            }
        }
        .onAppear {
            if #available(iOS 26, *) {
                sheetPadding = 8
            }
            initialPadding = sheetPadding
            basePadding = sheetPadding
            setSheetShape(isOpen: false)
        }
    }
    
    private var mainSheet: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(enableBackground ? 1 : 0)
            
            content
            .overlay(alignment: .top) {
                if !lockSheet {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(.tertiary)
                        .frame(width: 35, height: 5)
                        .padding(.top, 5)
                        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 2.5))
                        .hoverEffect(.highlight)
                }
            }
        }
        .clipShape(sheetShape)
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
        //    setSheetShape(isOpen: openCalendar)
        //}
        //.onChange(of: positionObserver.windowFrame) {
        //    if selectedDetent == .large {
        //        baseHeight = CustomSheetDetent.large.value
        //    }
        //}
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            DispatchQueue.main.async {
                if selectedDetent == .large {
                    baseHeight = CustomSheetDetent.large.value
                }
            }
        }
    }
    
    // MARK: - Logic
    func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragUpdating(value: CGFloat, state: inout CGFloat) {
        if isGoingLarge {
            isGoingLarge = false
        }
        
        if selectedDetent == .large {
            if value < 0 {
                state = 0
                return
            }
        }
        
        let predictedHeight = baseHeight - value
        let minDetent = detents.first!.value
        let maxDetent = detents.last!.value
        
        if maxDetent == CustomSheetDetent.large.value && detents.contains(.medium) {
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
                    setSheetShape(isOpen: true, sheetCornerRadius: 37)
                }
                enableBackground = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape(isOpen: true)
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
        if selectedDetent == .large {
            if value < 0 {
                return
            }
        }
        
        let rawPredictedHeight = baseHeight - value
        let minDetent = detents.first!
        let maxDetent = detents.last!
        
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
        var target = detents.min(by: { abs($0.value - predictedHeight) < abs($1.value - predictedHeight) }) ?? .small
        
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
                setSheetShape(isOpen: true, sheetCornerRadius: 37)
            }
            enableBackground = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(isOpen: true)
            }
            enableBackground = false
        }
        
        var limit: CGFloat = isGoingDown ? selectedDetent == .large ? 30 : 45 : 45
        if baseHeight - dragY > detents.last!.value {
            limit = 0
        }
        
        selectedDetent = target
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
    
    private func changeOpenCalendar(_ toOpen: Bool) {
        guard isPresented != toOpen else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            setSheetShape(isOpen: toOpen)
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            isPresented = toOpen
        }
    }
    
    private func setSheetShape(isOpen: Bool, sheetCornerRadius: CGFloat = -1) {
        withAnimation {
            if UIDevice.isIpad {
                sheetShapeRadii = .init(
                    tl: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.7 / 2 + initialPadding)) - initialPadding : sheetCornerRadius,
                    tr: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.7 / 2 + initialPadding)) - initialPadding : sheetCornerRadius,
                    bl: initialPadding == 0 ? 0 : (isOpen ? 32 : (47.7 / 2 + initialPadding)) - initialPadding,
                    br: initialPadding == 0 ? 0 : (isOpen ? 32 : (47.7 / 2 + initialPadding)) - initialPadding
                )
            } else {
                let radius: CGFloat = (isOpen ? .deviceCornerRadius : (47.7 / 2 + initialPadding)) - initialPadding
                sheetShapeRadii = .init(
                    tl: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                    tr: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                    bl: initialPadding == 0 ? 0 : radius,
                    br: initialPadding == 0 ? 0 : radius
                )
            }
            sheetShape = UnevenRoundedRectangle(
                topLeadingRadius: sheetShapeRadii.tl,
                bottomLeadingRadius: sheetShapeRadii.bl,
                bottomTrailingRadius: sheetShapeRadii.br,
                topTrailingRadius: sheetShapeRadii.tr
            )
        }
    }
}

#Preview {
    MainView()
}

// MARK: - Don't Ask
struct customSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.self) var completeEnvironment
    
    @Binding var isPresented: Bool
    @Binding var selectedDetent: CustomSheetDetent
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .background(
                OverlayAnchorView(
                    capturedEnvironment: completeEnvironment,
                    isPresented: $isPresented,
                    selectedDetent: $selectedDetent,
                    sheetContent: sheetContent
                )
            )
    }
}

extension View {
    func customSheet<Content: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<CustomSheetDetent>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(customSheetModifier(
            isPresented: isPresented,
            selectedDetent: selectedDetent,
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
}

struct OverlayAnchorView<SheetContent: View>: UIViewRepresentable {
    var capturedEnvironment: EnvironmentValues
    
    @Binding var isPresented: Bool
    @Binding var selectedDetent: CustomSheetDetent
    
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
                selectedDetent: $selectedDetent,
                content: sheetContent
            )
            .environment(\.self, capturedEnvironment)
        )
        
        if let hc = uiView.hostingController {
            hc.rootView = updatedView
        } else {
            uiView.pendingRootView = updatedView
        }
    }
}
