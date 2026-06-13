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
    @State var selectedDetent: CustomSheetDetent = .small
    
    @State private var networkObserver = NetworkStateObserver(
        provider: IOSNetworkMonitor.createProvider()
    )
    
    var body: some View {
        NavigationStack {
            List {
                Toggle(isOn: $isPresented) {
                    Label("Open sheet", systemImage: "iphone")
                }
                Button {
                    openSettings = true
                    selectedDetent = .large
                } label: {
                    Label("Open Settings", systemImage: "gearshape.fill")
                }
                Button {
                    openWhatsNew = true
                    selectedDetent = .large
                } label: {
                    Label("Open News", systemImage: "sparkles")
                }
                Button {
                    selectedLesson = .sample
                    openAddToCalendar = true
                    selectedDetent = .large
                } label: {
                    Label("Open Calendar", systemImage: "calendar")
                }
                Button {
                    selectedLesson = .sample
                    selectedDetent = .large
                } label: {
                    Label("Open Lesson", systemImage: "graduationcap.fill")
                }
            }
            .navigationTitle("Sheet Testing View")
            .customSheet(isPresented: $isPresented, selectedDetent: $selectedDetent, lockSheet: $lockSheet) {
                DynamicSheetContent(
                    selectedWeek: $selectedWeek,
                    selectedDetent: $selectedDetent,
                    selectedLesson: $selectedLesson,
                    openAddToCalendar: $openAddToCalendar,
                    openSettings: $openSettings,
                    openWhatsNew: $openWhatsNew,
                    tempSettings: $tempSettings,
                    lockSheet: $lockSheet
                )
            }
            .environment(networkObserver)
            .environment(UserSettings.shared)
        }
    }
}

public enum CustomSheetDetent {
    case small, medium, large

    var value: CGFloat {
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
                return windowHeight - topMargin - 10
            }
        }
    }
}

@Observable
public class GlobalSheetManager {
    // MARK: - Sensori (Stati in sola lettura per l'utente)
    public var liveHeight: CGFloat = 0
    public var isDragging: Bool = false
    public var presentationProgress: CGFloat = 0.0 // Da 0.0 (small) a 1.0 (large)
    
    // MARK: - Motore Interno (Chiusure collegate dalla CustomSheet)
    var actionChangeDetent: ((CustomSheetDetent) -> Void)?
    var actionDismiss: (() -> Void)?
    
    public init() {}
    
    // MARK: - Comandi Pubblici (Quelli che userai nella tua app)
    public func setDetent(_ detent: CustomSheetDetent) {
        actionChangeDetent?(detent)
    }
    
    public func dismiss() {
        actionDismiss?()
    }
}

struct CustomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var selectedDetent: CustomSheetDetent
    
    @Binding var lockSheet: Bool
    var detents: [CustomSheetDetent]
    
    @State var sheetShapeRadii: SheetCornerRadii = SheetCornerRadii(tl: .deviceCornerRadius, tr: .deviceCornerRadius, bl: .deviceCornerRadius, br: .deviceCornerRadius)
    
    @State private var manager = GlobalSheetManager()
    
    // Gesture & Layout States
    @State private var enableBackground: Bool = false
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
        lockSheet: Binding<Bool>,
        detents: [CustomSheetDetent],
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self._selectedDetent = selectedDetent
        self._baseHeight = State(initialValue: selectedDetent.wrappedValue.value)
        self._lockSheet = lockSheet
        self.detents = detents
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
                selectedDetent = .small
            }
        }
        .onChange(of: selectedDetent) { oldValue, newValue in
            enableBackground = newValue == .large
            
            if oldValue == .large {
                //detents = [.small, .medium]
            } else if newValue == .large {
                //detents = [.small, .medium, .large]
            }
            
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
        .onChange(of: lockSheet) { _, newValue in
            if selectedDetent == .large {
                //detents = newValue ? [.large] : [.small, .medium, .large]
            } else {
                lockSheet = false
            }
        }
        .onChange(of: liveHeight) { _, newHeight in
            manager.liveHeight = newHeight
        }
        .onAppear {
            if #available(iOS 26, *) {
                sheetPadding = 8
            }
            initialPadding = sheetPadding
            basePadding = sheetPadding
            setSheetShape()
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
    
    // MARK: - Drag Logic
    func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragUpdating(value: CGFloat, state: inout CGFloat) {
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
                setSheetShape(sheetCornerRadius: 37)
            }
            enableBackground = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape()
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
    
    // MARK: - Logic
    //private func changeOpenCalendar(_ toOpen: Bool) {
    //    guard isPresented != toOpen else { return }
    //    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
    //        isPresented = toOpen
    //    }
    //}
    
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

#Preview {
    MainView()
}

// MARK: - Don't Ask
struct customSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.self) var completeEnvironment
    
    @Binding var isPresented: Bool
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var lockSheet: Bool
    var availableDetents: [CustomSheetDetent]
    
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .background(
                OverlayAnchorView(
                    capturedEnvironment: completeEnvironment,
                    isPresented: $isPresented,
                    selectedDetent: $selectedDetent,
                    lockSheet: $lockSheet,
                    availableDetents: availableDetents,
                    sheetContent: sheetContent
                )
            )
    }
}

extension View {
    func customSheet<Content: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<CustomSheetDetent>,
        lockSheet: Binding<Bool>,
        availableDetents: [CustomSheetDetent] = [.small, .medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(customSheetModifier(
            isPresented: isPresented,
            selectedDetent: selectedDetent,
            lockSheet: lockSheet,
            availableDetents: availableDetents,
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
    @Binding var lockSheet: Bool
    var availableDetents: [CustomSheetDetent]
    
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
                lockSheet: $lockSheet,
                detents: availableDetents,
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
