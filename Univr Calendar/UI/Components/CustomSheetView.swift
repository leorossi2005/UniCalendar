//
//  CustomSheetView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/12/25.
//

import SwiftUI
import UnivrCore

enum CustomSheetDetent {
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
                return windowHeight - 74 - 1
            } else {
                return windowHeight - topMargin - 1
            }
        }
    }
}

struct CustomSheetView: View {
    @Environment(\.colorScheme) var colorScheme
    var transition: Namespace.ID
    
    var positionObserver = WindowPositionObserver.shared
    
    // MARK: - Binding dal Padre
    @Binding var openSettings: Bool
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var sheetShape: UnevenRoundedRectangle
    @Binding var sheetShapeRadii: SheetCornerRadii
    
    @Binding var selectedWeek: Date
    @Binding var selectedLesson: Lesson?
    @Binding var tempSettings: TempSettingsState
    @Binding var openCalendar: Bool
    
    // Gesture & Layout States
    @State private var enableBackground: Bool = false
    @State private var trigger: Int = 0
    @State private var detents: [CustomSheetDetent] = [.small, .medium]
    @State private var baseHeight: CGFloat = CustomSheetDetent.small.value
    
    @State private var dragY: CGFloat = .zero
    
    @State private var draggingDirection: CustomSheetDraggingDirection = .none
    
    @State private var isContentAtTop: Bool = true
    @State private var initialIsContentAtTop: Bool = true
    
    @State private var lockSheet: Bool = false
    
    @State private var basePadding: CGFloat = .zero
    @State private var initialPadding: CGFloat = .zero
    @State private var sheetPadding: CGFloat = 8
    
    @State private var offset: CGFloat = .zero
    
    private var liveHeight: CGFloat { baseHeight - dragY }
    
    enum GestureDirection {
        case horizontal, vertical
    }
    
    var body: some View {
        Group {
            if #available(iOS 26, *) {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .opacity(enableBackground ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: enableBackground)
                    
                    GlassContainerr(radii: sheetShapeRadii, animationDuration: 0.2, isEnabled: !enableBackground, resetGlassEffect: trigger) {
                        if openCalendar {
                            mainSheet
                                .transition(.blurReplace)
                                .ignoresSafeArea(edges: .bottom)
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
                                .transition(.blurReplace)
                        }
                    }
                    .frame(width: openCalendar ? nil : 123.3, height: openCalendar ? liveHeight : 47.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(y: -offset)
                    .padding(.horizontal, openCalendar ? sheetPadding : UIApplication.shared.safeAreas.bottom)
                    .padding(.bottom, openCalendar ? sheetPadding : UIApplication.shared.safeAreas.bottom)
                    .ignoresSafeArea(edges: .bottom)
                }
            } else {
                mainSheet
            }
        }
        .onChange(of: openCalendar) { oldValue, newValue in
            if newValue {
                trigger += 1
            }
        }
        .onChange(of: selectedDetent) { oldValue, newValue in
            changeOpenCalendar(true)
            
            if oldValue == .large {
                detents = [.small, .medium]
            } else if newValue == .large {
                detents = [.small, .medium, .large]
            }
            
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 300,
                damping: 25,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(isOpen: true, sheetCornerRadius: 36)
                } else {
                    sheetPadding = initialPadding
                    setSheetShape(isOpen: true, sheetCornerRadius: -1)
                }
                
                baseHeight = newValue.value
                offset = 0
            }
            
            enableBackground = newValue == .large
        }
        .onAppear {
            initialPadding = sheetPadding
            basePadding = sheetPadding
        }
    }
    
    private var mainSheet: some View {
        ZStack {
            Color(.systemBackground)
                .clipShape(sheetShape)
                .opacity(enableBackground ? 1 : 0)
            
            DynamicSheetContent(
                selectedWeek: $selectedWeek,
                selectedDetent: $selectedDetent,
                selectedLesson: $selectedLesson,
                openSettings: $openSettings,
                tempSettings: $tempSettings,
                openCalendar: $openCalendar,
                isContentAtTop: $isContentAtTop,
                sheetInitialIsContentAtTop: $initialIsContentAtTop,
                lockSheet: $lockSheet,
                draggingDirection: $draggingDirection
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(.tertiary)
                    .frame(width: 35, height: 5)
                    .padding(.top, 5)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 2.5))
                    .hoverEffect(.highlight)
            }
            .clipShape(sheetShape)
        }
        .overlay {
            VerticalDragger(
                onDrag: { translationY, direction in
                    handleDragUpdating(value: translationY, direction: direction, state: &self.dragY)
                },
                onEnded: { translationY, predictedEndTranslation in
                    handleDragEnded(translationY, predictedEndTranslation)
                }
            )
        }
        .background(WindowAccessor { window in
            if UIDevice.isIpad {
                positionObserver.startObserving(window: window)
            }
        })
        .onChange(of: positionObserver.edges) {
            setSheetShape(isOpen: openCalendar)
        }
        .onChange(of: positionObserver.windowFrame.height) {
            if selectedDetent == .large {
                baseHeight = CustomSheetDetent.large.value
            }
        }
        .onChange(of: isContentAtTop) {
            if isContentAtTop && draggingDirection == .none {
                lockSheet = false
                if selectedDetent == .large {
                    detents = [.small, .medium, .large]
                } else {
                    detents = [.small, .medium]
                }
            }
        }
    }
    
    // MARK: - Logic
    func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragUpdating(value: CGFloat, direction: CustomSheetDraggingDirection, state: inout CGFloat) {
        if draggingDirection == .none {
            draggingDirection = direction
            
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                baseHeight = liveHeight
            }
            
            initialIsContentAtTop = isContentAtTop
        }
        
        guard initialIsContentAtTop else {
            state = 0
            return
        }
        
        if selectedDetent == .large {
            if !isContentAtTop {
                lockSheet = true
                detents = [.large]
            }
            
            if value < 0 {
                state = 0
                return
            }
            
            if value > 0 && !isContentAtTop {
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
                sheetPadding = 8
            }
        }
        
        if predictedHeight >= minDetent && predictedHeight <= maxDetent {
            state = value

            if predictedHeight > CustomSheetDetent.large.value * 0.8 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape(isOpen: true, sheetCornerRadius: 36)
                }
                enableBackground = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape(isOpen: true, sheetCornerRadius: -1)
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
        draggingDirection = .none
        
        if selectedDetent == .large {
            if value < 0 || (value > 0 && !isContentAtTop) {
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
                setSheetShape(isOpen: true, sheetCornerRadius: 36)
            }
            enableBackground = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(isOpen: true, sheetCornerRadius: -1)
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
        
        if isContentAtTop {
            lockSheet = false
            if selectedDetent == .large {
                detents = [.small, .medium, .large]
            } else {
                detents = [.small, .medium]
            }
        }
    }
    
    private func changeOpenCalendar(_ toOpen: Bool) {
        guard openCalendar != toOpen else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            setSheetShape(isOpen: toOpen)
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            openCalendar = toOpen
        }
    }
    
    private func setSheetShape(isOpen: Bool, sheetCornerRadius: CGFloat = -1) {
        withAnimation {
            if #available(iOS 26, *) {
                if UIDevice.isIpad {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? (isOpen ? 32 : (47.4 / 2 + 8)) - 8 : sheetCornerRadius,
                        bl: (isOpen ? (positionObserver.edges.bottomLeftSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8,
                        br: (isOpen ? (positionObserver.edges.bottomRightSquare ? 18 : 32) : (47.4 / 2 + 8)) - 8
                    )
                } else {
                    let radius: CGFloat = (isOpen ? .deviceCornerRadius : (47.4 / 2 + 8)) - 8
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? radius : sheetCornerRadius,
                        bl: radius,
                        br: radius
                    )
                }
            } else {
                if UIDevice.isIpad {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? 32 : sheetCornerRadius,
                        bl: 0,
                        br: 0
                    )
                } else {
                    sheetShapeRadii = .init(
                        tl: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                        tr: sheetCornerRadius == -1 ? .deviceCornerRadius : sheetCornerRadius,
                        bl: 0,
                        br: 0
                    )
                }
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

// MARK: - Subviews
struct DynamicSheetContent: View {
    @Binding var selectedWeek: Date
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var selectedLesson: Lesson?
    @Binding var openSettings: Bool
    @Binding var tempSettings: TempSettingsState
    @Binding var openCalendar: Bool
    @Binding var isContentAtTop: Bool
    @Binding var sheetInitialIsContentAtTop: Bool
    @Binding var lockSheet: Bool
    @Binding var draggingDirection: CustomSheetDraggingDirection
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let currentHeight = proxy.size.height
                let windowHeight = UIApplication.shared.windowSize.height
        
                let largeHeight = CustomSheetDetent.large.value
                let mediumHeightHigh = CustomSheetDetent.medium.value * 1.05
                let mediumHeightLow = CustomSheetDetent.medium.value * 0.95
                let smallHeight = CustomSheetDetent.small.value
                let fadeRange: CGFloat = windowHeight * 0.05
        
                let largeOpacity = 1.0 - (Double(largeHeight - currentHeight) / Double(fadeRange))
                let mediumOpacity = 1.0 - ((currentHeight < mediumHeightHigh ? Double(mediumHeightLow - currentHeight) : Double(currentHeight - mediumHeightHigh)) / Double(fadeRange))
                let smallOpacity = 1.0 - (Double(currentHeight - smallHeight) / Double(fadeRange))
        
                let smallIsHidden = currentHeight > smallHeight + fadeRange
                let mediumIsHidden = currentHeight > mediumHeightHigh + fadeRange
                ZStack(alignment: .topLeading) {
                    FractionDatePickerContainer(selectedWeek: $selectedWeek)
                        .opacity(smallIsHidden ? 0 : min(max(smallOpacity, 0), 1))
                        .allowsHitTesting(selectedDetent == .small)
                        .frame(width: UIApplication.shared.windowSize.width - 16)
                    
                    DatePickerContainer(selectedWeek: $selectedWeek)
                        .opacity(mediumIsHidden ? 0 : min(max(mediumOpacity, 0), 1))
                        .allowsHitTesting(selectedDetent == .medium)
                        .frame(width: UIApplication.shared.windowSize.width - 16)
                    
                    NavigationStack {
                        if openSettings {
                            Settings(
                                selectedYear: $tempSettings.selectedYear,
                                selectedCourse: $tempSettings.selectedCourse,
                                selectedAcademicYear: $tempSettings.selectedAcademicYear,
                                matricola: $tempSettings.matricola,
                                lockSheet: $lockSheet
                            )
                            .ignoresSafeArea(.keyboard)
                            //.toolbar {
                            //    ToolbarItem(placement: .principal) {
                            //        Text("Impostazioni")
                            //            .font(.headline)
                            //            .opacity(min(max(largeOpacity, 0), 1))
                            //    }
                            //}
                            //.navigationBarTitleDisplayMode(.inline)
                        } else {
                            LessonDetailsView(lesson: $selectedLesson)
                                .opacity(min(max(largeOpacity, 0), 1))
                                .allowsHitTesting(selectedDetent == .large)
                        }
                    }
                    .opacity(min(max(largeOpacity, 0), 1))
                    .allowsHitTesting(selectedDetent == .large)
                    .frame(width: UIApplication.shared.windowSize.width, height: CustomSheetDetent.large.value)
                }
            }
        }
    }
}

#Preview {
    //CustomSheetView()
}
