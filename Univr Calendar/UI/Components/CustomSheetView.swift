//
//  CustomSheetView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/12/25.
//

import SwiftUI
import UnivrCore

enum CustomSheetDetent {
    case small
    case medium
    case large

    var value: CGFloat {
        switch self {
        case .small:  return (((500 - 70) / 7) * 1.35) + 50
        case .medium: return 350 + 75
        case .large:
            let screenHeight = UIApplication.shared.windowSize.height
            let topSafeArea = UIApplication.shared.safeAreas.top
            let topMargin = topSafeArea > 0 ? topSafeArea : 20
            
            return screenHeight - topMargin - 1
        }
    }
}

struct CustomSheetView: View {
    @Environment(\.colorScheme) var colorScheme
    var transition: Namespace.ID
    // MARK: - Binding dal Padre
    @Binding var selectedWeek: Date
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var selectionFraction: String?
    @Binding var loading: Bool
    @Binding var sheetShape: UnevenRoundedRectangle
    @Binding var sheetShapeRadii: SheetCornerRadii
    
    @Binding var selectedLesson: Lesson?
    @Binding var openSettings: Bool
    @Binding var settingsSearchFocus: Bool
    @Binding var tempSettings: TempSettingsState
    @Binding var openCalendar: Bool
    
    @Binding var offset: CGFloat
    @Binding var enableBackground: Bool
    @Binding var sheetPadding: CGFloat
    var setSheetShape: (Bool, CGFloat) -> ()
    
    // Gesture & Layout States
    @State private var baseHeight: CGFloat = CustomSheetDetent.small.value
    @State private var basePadding: CGFloat = .zero
    @State private var sheetDetents: [CustomSheetDetent] = [.small, .medium]
    
    @State private var dragY: CGFloat = .zero
    
    @State private var gestureLockedDirection: GestureDirection? = nil
    @State private var draggingDirection: CustomSheetDraggingDirection = .none
    @State private var isContentAtTop: Bool = true
    @State private var initialIsContentAtTop: Bool = true
    @State private var lockSheet: Bool = false
    @State private var initialPadding: CGFloat = .zero
    
    private var liveHeight: CGFloat {
        min(max(baseHeight - dragY, CustomSheetDetent.small.value), CustomSheetDetent.large.value)
    }
    
    enum GestureDirection {
        case horizontal, vertical
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                GlassContainer(radii: sheetShapeRadii, animationDuration: 0.2)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .frame(width: 35, height: 5)
                            .padding(.top, 5)
                            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 2.5))
                            .hoverEffect(.highlight)
                    }
                    .matchedGeometryEffect(id: "calendarBackground", in: transition)
            } else {
                Color(.systemBackground)
                    .clipShape(sheetShape)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .frame(width: 35, height: 5)
                            .padding(.top, 5)
                            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 2.5))
                            .hoverEffect(.highlight)
                    }
            }
            Color(.secondarySystemBackground)
                .clipShape(sheetShape)
                .opacity(enableBackground ? 1 : 0)
            
            DynamicSheetContent(
                selectedWeek: $selectedWeek,
                selectedDetent: $selectedDetent,
                selectedFraction: $selectionFraction,
                selectedLesson: $selectedLesson,
                openSettings: $openSettings,
                settingsSearchFocus: $settingsSearchFocus,
                loading: $loading,
                tempSettings: $tempSettings,
                openCalendar: $openCalendar,
                isContentAtTop: $isContentAtTop,
                sheetInitialIsContentAtTop: $initialIsContentAtTop,
                lockSheet: $lockSheet,
                draggingDirection: $draggingDirection
            )
            .clipShape(sheetShape)
        }
        .frame(height: liveHeight)
        //.simultaneousGesture(
        //    DragGesture(minimumDistance: 1, coordinateSpace: .global)
        //        .onChanged { value in
        //            handleDragChanged(value)
        //        }
        //        .updating($dragY) { value, state, _ in
        //            handleDragUpdating(value: value, state: &state)
        //        }
        //        .onEnded { value in
        //            handleDragEnded(value)
        //        }
        //)
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
        .onChange(of: selectedDetent) { oldValue, newValue in
            withAnimation(.interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 30,
                initialVelocity: 0
            )) {
                if newValue == .large {
                    sheetPadding = 0
                    setSheetShape(true, 36)
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        enableBackground = true
                    }
                } else {
                    sheetPadding = initialPadding
                    setSheetShape(true, -1)
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        enableBackground = false
                    }
                }
                
                baseHeight = newValue.value
                offset = 0
            }
            
            if oldValue == .large {
                sheetDetents = [.small, .medium]
            } else if newValue == .large {
                sheetDetents = [.small, .medium, .large]
            }
        }
        .onChange(of: isContentAtTop) {
            if isContentAtTop && draggingDirection == .none {
                lockSheet = false
                if selectedDetent == .large {
                    sheetDetents = [.small, .medium, .large]
                } else {
                    sheetDetents = [.small, .medium]
                }
            }
        }
        .onAppear {
            initialPadding = sheetPadding
            basePadding = sheetPadding
        }
    }
    
    // MARK: - Logic
    func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let coefficient: CGFloat = 0.55
        return (1.0 - (1.0 / ((offset * coefficient / dimension) + 1.0))) * dimension
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if gestureLockedDirection == nil {
            let dx = abs(value.translation.width)
            let dy = abs(value.translation.height)
            
            let angle = atan2(dy, dx) * 180 / .pi
            gestureLockedDirection = angle > 45 ? .vertical : .horizontal
            
            if gestureLockedDirection == .vertical {
                let isDraggingUp = value.translation.height > 0
                let isDraggingDown = value.translation.height < 0
                let isDraggingLeft = value.translation.width < 0
                let isDraggingRight = value.translation.width > 0
                
                if isDraggingUp {
                    draggingDirection = .up
                } else if isDraggingDown {
                    draggingDirection = .down
                } else if isDraggingLeft {
                    draggingDirection = .left
                } else if isDraggingRight {
                    draggingDirection = .right
                }
                
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    baseHeight = liveHeight
                }
            }
            
            initialIsContentAtTop = isContentAtTop
        }
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
                sheetDetents = [.large]
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
        let minDetent = sheetDetents.first!.value
        let maxDetent = sheetDetents.last!.value
        
        if maxDetent == CustomSheetDetent.large.value && sheetDetents.contains(.medium) {
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
                    setSheetShape(true, 36)
                    enableBackground = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    setSheetShape(true, -1)
                    enableBackground = false
                }
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
                Task { @MainActor in
                    self.gestureLockedDirection = nil
                }
                return
            }
        }
        
        let rawPredictedHeight = baseHeight - value
        let minDetent = sheetDetents.first!
        let maxDetent = sheetDetents.last!
        
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
        var target = sheetDetents.min(by: { abs($0.value - predictedHeight) < abs($1.value - predictedHeight) }) ?? .small
        
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
        selectedDetent = target
        
        if target == .large {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(true, 36)
                enableBackground = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                setSheetShape(true, -1)
                enableBackground = false
            }
        }
        
        var limit: CGFloat = isGoingDown ? 65 : 65
        if baseHeight - dragY > sheetDetents.last!.value {
            limit = 0
        }
        
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
                sheetDetents = [.small, .medium, .large]
            } else {
                sheetDetents = [.small, .medium]
            }
        }
        
        Task { @MainActor in
            self.gestureLockedDirection = nil
        }
    }
}

// MARK: - Subviews
struct DynamicSheetContent: View {
    @Binding var selectedWeek: Date
    @Binding var selectedDetent: CustomSheetDetent
    @Binding var selectedFraction: String?
    @Binding var selectedLesson: Lesson?
    @Binding var openSettings: Bool
    @Binding var settingsSearchFocus: Bool
    @Binding var loading: Bool
    @Binding var tempSettings: TempSettingsState
    @Binding var openCalendar: Bool
    @Binding var isContentAtTop: Bool
    @Binding var sheetInitialIsContentAtTop: Bool
    @Binding var lockSheet: Bool
    @Binding var draggingDirection: CustomSheetDraggingDirection
    
    @State private var path = NavigationPath()
    
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
        
                ZStack(alignment: .topLeading) {
                    FractionDatePickerContainer(
                        selectedWeek: $selectedWeek,
                        loading: $loading,
                        selectionFraction: $selectedFraction
                    )
                    .opacity(settingsSearchFocus ? 0 : min(max(smallOpacity, 0), 1))
                    .allowsHitTesting(selectedDetent == .small && !settingsSearchFocus)
                    .frame(width: UIApplication.shared.windowSize.width - 16, height: CustomSheetDetent.small.value)
                    .glassEffectIfAvailable()
                    
                    DatePickerContainer(
                        selectedWeek: $selectedWeek
                    )
                    .opacity(settingsSearchFocus ? 0 : min(max(mediumOpacity, 0), 1))
                    .allowsHitTesting(selectedDetent == .medium && !settingsSearchFocus)
                    .frame(width: UIApplication.shared.windowSize.width - 16, height: CustomSheetDetent.medium.value)
                    .glassEffectIfAvailable()
                    
                    Group {
                        if openSettings {
                            NavigationStack(path: $path) {
                                Settings(
                                    selectedYear: $tempSettings.selectedYear,
                                    selectedCourse: $tempSettings.selectedCourse,
                                    selectedAcademicYear: $tempSettings.selectedAcademicYear,
                                    matricola: $tempSettings.matricola,
                                    searchTextFieldFocus: $settingsSearchFocus,
                                    isContentAtTop: $isContentAtTop,
                                    sheetInitialIsContentAtTop: $sheetInitialIsContentAtTop,
                                    lockSheet: $lockSheet,
                                    draggingDirection: $draggingDirection,
                                    navigationPath: $path
                                )
                                .toolbar {
                                    ToolbarItem(placement: .principal) {
                                        Text("Impostazioni")
                                            .font(.headline)
                                            .opacity(settingsSearchFocus ? 1 : min(max(largeOpacity, 0), 1))
                                    }
                                }
                                .navigationBarTitleDisplayMode(.inline)
                            }
                            .opacity(settingsSearchFocus ? 1 : min(max(largeOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == .large)
                        } else {
                            NavigationStack {
                                LessonDetailsView(lesson: $selectedLesson)
                                    .background(Color(.secondarySystemBackground))
                            }
                            .opacity(settingsSearchFocus ? 0 : min(max(largeOpacity, 0), 1))
                            .allowsHitTesting(selectedDetent == .large)
                        }
                    }
                    .frame(width: UIApplication.shared.windowSize.width, height: CustomSheetDetent.large.value)
                }
            }
        }
        .onChange(of: openSettings) {
            if !openSettings {
                path = NavigationPath()
            }
        }
    }
}

#Preview {
    //CustomSheetView()
}
