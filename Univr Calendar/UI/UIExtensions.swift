//
//  UIExtensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

extension Color {
    init?(hex: String) {
        guard let components = HexColorParser.parse(hex) else { return nil }
        self.init(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }
}

struct ShimmeringGradient: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        PhaseAnimator([false, true]) { phase in
            LinearGradient(
                colors: [
                    .black.opacity(0),
                    colorScheme == .light ? .black.opacity(0.3) : .white.opacity(0.05),
                    .black.opacity(0)
                ],
                startPoint: phase ? UnitPoint(x: 1, y: 0.5) : UnitPoint(x: -1, y: 0.5),
                endPoint: phase ? UnitPoint(x: 2, y: 0.5) : UnitPoint(x: 0, y: 0.5)
            )
        } animation: { _ in
            .linear(duration: 1.5).repeatForever(autoreverses: false)
        }
    }
}

extension View {
    @ViewBuilder
    func shimmeringPlaceholder(active: Bool = true, opacity: CGFloat) -> some View {
        if active {
            self
                .redacted(reason: .placeholder)
                .saturation(0)
                .opacity(opacity)
                .colorMultiply(Color(.tertiarySystemGroupedBackground))
                .overlay {
                    ZStack {
                        ShimmeringGradient()
                            .mask {
                                self
                                    .redacted(reason: .placeholder)
                            }
                    }
                    .opacity(opacity)
                }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func textOverlay(
        text: String,
        rotation: Double,
        offset: CGSize,
        alignment: Alignment = .topTrailing,
        font: String = "Noteworthy-Light",
        fontSize: CGFloat = 14,
        color: Color = Color(red: 1.0, green: 0.9, blue: 0.4)
    ) -> some View {
        self
            .overlay(alignment: alignment) {
                Text(text)
                    .font(.custom(font, size: fontSize))
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(rotation))
                    .offset(offset)
            }
    }
    
    func keyboardPadding(_ value: CGFloat) -> some View {
        self.safeAreaPadding(.bottom, value)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: Fallback iOS 18
    @ViewBuilder
    func glassProminentIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glassProminent)
        } else {
            self
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            
        }
    }
    
    @ViewBuilder
    func glassIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            
        }
    }
    
    @ViewBuilder
    func sheetDesign(_ namespace: Namespace.ID, sourceID: String, detent: Binding<PresentationDetent>) -> some View {
        if #available(iOS 26, *) {
            self
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
                .presentationCornerRadius(detent.wrappedValue != .large ? .deviceCornerRadius - 8 : nil)
                .animation(.easeInOut, value: detent.wrappedValue)
        } else {
            self
                .presentationCornerRadius(detent.wrappedValue != .large ? .deviceCornerRadius : nil)
                .animation(.easeInOut, value: detent.wrappedValue)
            
        }
    }
    
    @ViewBuilder
    func scrollViewTopPadding() -> some View {
        if #available(iOS 26, *) {
            self
                .contentMargins(.top, 5, for: .scrollContent)
                .contentMargins(.top, 5, for: .scrollIndicators)
        } else if #available(iOS 18, *) {
            self
                .contentMargins(.top, 15, for: .scrollContent)
                .contentMargins(.top, 15, for: .scrollIndicators)
        } else {
            self
                .contentMargins(.top, UIApplication.shared.safeAreas.top * 1.9, for: .scrollContent)
                .contentMargins(.top, UIApplication.shared.safeAreas.top * 1.9, for: .scrollIndicators)
        }
    }
    
    @ViewBuilder
    func onScrollGeometry(
        openCalendar: Binding<Bool>,
        selectedDetent: Binding<CustomSheetDetent>,
        firstLoading: Binding<Bool>,
        changeOpenCalendar: ((_ isOpen: Bool) -> Void)?
    ) -> some View {
        if #available(iOS 26, *) {
            self
                .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                    (geometry.contentOffset.y + geometry.contentInsets.top)
                }) { oldValue, newValue in
                    if !firstLoading.wrappedValue {
                        let isLarge = selectedDetent.wrappedValue == .large
                        
                        if newValue <= 0 && !openCalendar.wrappedValue {
                            changeOpenCalendar?(true)
                        } else if newValue > 10 && !isLarge && openCalendar.wrappedValue {
                            changeOpenCalendar?(false)
                        }
                    }
                }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func toolbarTitleShadow(_ colorScheme: ColorScheme) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            self
                .shadow(color: colorScheme == .light ? .white : .black, radius: 5)
                .shadow(color: colorScheme == .light ? .white : .black, radius: 10)
                .shadow(color: colorScheme == .light ? .white : .black, radius: 20)
        }
    }
    
    // MARK: Fallback iOS 17
    @ViewBuilder
    func removeTopSafeArea() -> some View {
        if #available(iOS 18, *) {
            self
        } else {
            self.ignoresSafeArea(edges: .top)
        }
    }
}

extension ToolbarItem {
    @ToolbarContentBuilder
    func toolbarBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        if #available(iOS 26, *) {
            self.sharedBackgroundVisibility(visibility)
        } else {
            self
        }
    }
}

@MainActor
extension UIApplication {
    var safeAreas: UIEdgeInsets {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets ?? .zero
    }
    
    var screenSize: CGRect {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds ?? .zero
    }
    
    var windowSize: CGRect {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.bounds ?? .zero
    }
}

@MainActor
extension UIDevice {
    static var isIpad: Bool {
        current.userInterfaceIdiom == .pad
    }
}

extension EnvironmentValues {
    @Entry var safeAreaInsets: UIEdgeInsets = .zero
}

extension CGFloat {
    static var deviceCornerRadius: CGFloat = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let radii: [String: CGFloat] = [
            // iPhone 17 Series
            "iPhone18,2": 62.0,  // 17 Pro Max
            "iPhone18,1": 62.0,  // 17 Pro
            "iPhone18,3": 62.0,  // 17
            
            // iPhone 16 Series
            "iPhone17,2": 62.0,  // 16 Pro Max
            "iPhone17,1": 62.0,  // 16 Pro
            "iPhone17,4": 55.0,  // 16 Plus
            "iPhone17,3": 55.0,  // 16
            "iPhone17,5": 47.33, // 16e
            
            // iPhone 15 Series
            "iPhone16,2": 55.0,  // 15 Pro Max
            "iPhone16,1": 55.0,  // 15 Pro
            "iPhone15,5": 55.0,  // 15 Plus
            "iPhone15,4": 55.0,  // 15

            // iPhone 14 Series
            "iPhone15,3": 55.0,  // 14 Pro Max
            "iPhone15,2": 55.0,  // 14 Pro
            "iPhone14,8": 53.33, // 14 Plus
            "iPhone14,7": 47.33, // 14
            
            // iPhone 13 Series
            "iPhone14,3": 53.33, // 13 Pro Max
            "iPhone14,2": 47.33, // 13 Pro
            "iPhone14,5": 47.33, // 13
            "iPhone14,4": 44.0,  // 13 Mini

            // iPhone 12 Series
            "iPhone13,4": 53.33, // 12 Pro Max
            "iPhone13,3": 47.33, // 12 Pro
            "iPhone13,2": 47.33, // 12
            "iPhone13,1": 44.0,  // 12 Mini
            
            // iPhone 11 Series
            "iPhone12,5": 39.0, // 11 Pro Max
            "iPhone12,3": 39.0, // 11 Pro
            "iPhone12,1": 41.5, // 11
            
            // iPhone XR Series
            "iPhone11,8": 41.5,  // XR
            
            // iPhone XS Series
            "iPhone11,6": 39.0,  // XS Max Global
            "iPhone11,4": 39.0,  // XS Max
            "iPhone11,2": 39.0,  // XS
            
            // iPhone X Series
            "iPhone10,6": 39.0,  // X GSM
            "iPhone10,3": 39.0,  // X Global
            
            // iPhone Air Series
            "iPhone18,4": 62.0,  // Air
            
            // iPad Air
            "iPad15,6": 18.0,    // iPad Air 13-inch 7th Gen (WiFi+Cellular)
            "iPad15,5": 18.0,    // iPad Air 13-inch 7th Gen (WiFi)
            "iPad15,4": 18.0,    // iPad Air 11-inch 7th Gen (WiFi+Cellular)
            "iPad15,3": 18.0,    // iPad Air 11-inch 7th Gen (WiFi)
            "iPad14,11": 18.0,   // iPad Air 13 inch 6th Gen (WiFi+Cellular)
            "iPad14,10": 18.0,   // iPad Air 13 inch 6th Gen (WiFi)
            "iPad14,9": 18.0,    // iPad Air 11 inch 6th Gen (WiFi+Cellular)
            "iPad14,8": 18.0,    // iPad Air 11 inch 6th Gen (WiFi)
            "iPad13,17": 18.0,   // iPad Air 5th Gen (WiFi+Cellular)
            "iPad13,16": 18.0,   // iPad Air 5th Gen (WiFi)
            "iPad13,2": 18.0,    // iPad Air 4th Gen (WiFi+Cellular)
            "iPad13,1": 18.0,    // iPad Air 4th Gen (WiFi)
            "iPad11,4": 18.0,    // iPad Air 3rd Gen (WiFi+Cellular)
            "iPad11,3": 18.0,    // iPad Air 3rd Gen (WiFi)
            "iPad5,4": 18.0,     // iPad Air 2 (Cellular)
            "iPad5,3": 18.0,     // iPad Air 2 (WiFi)
            "iPad4,3": 18.0,     // 1st Gen iPad Air (China)
            "iPad4,2": 18.0,     // iPad Air (GSM+CDMA)
            "iPad4,1": 18.0,     // iPad Air (WiFi)
            
            // iPad Pro
            "iPad16,6": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi+Cellular)
            "iPad16,5": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi)
            "iPad14,6": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi+Cellular)
            "iPad14,5": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi)
            "iPad13,11": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,10": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,9": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad13,8": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad16,4": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi+Cellular)
            "iPad16,3": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi)
            "iPad13,7": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,6": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,5": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,4": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad8,12": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
            "iPad8,11": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi)
            "iPad14,4": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad14,3": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,10": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad8,9": 18.0,     //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,8": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,7": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
            "iPad8,6": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
            "iPad8,5": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi)
            "iPad8,4": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,3": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
            "iPad8,2": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi)
            "iPad8,1": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi)
            "iPad7,4": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi+Cellular)
            "iPad7,3": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi)
            "iPad7,2": 18.0,     //iPad Pro 2nd Gen (WiFi+Cellular)
            "iPad7,1": 18.0,     //iPad Pro 2nd Gen (WiFi)
            "iPad6,8": 18.0,     //iPad Pro (12.9 inch, WiFi+LTE)
            "iPad6,7": 18.0,     //iPad Pro (12.9 inch, WiFi)
            "iPad6,4": 18.0,     //iPad Pro (9.7 inch, WiFi+LTE)
            "iPad6,3": 18.0,     //iPad Pro (9.7 inch, WiFi)
        ]
        
        if let radius = radii[modelIdentifier] {
            return radius
        }
        
        let bottomSafeArea = UIApplication.shared.safeAreas.bottom
        return bottomSafeArea > 0 ? 47.33 : 0
    }()
}

extension String {
    static var cupDynamic: String {
        if #available(iOS 18, *) {
            return "cup.and.heat.waves.fill"
        } else {
            return "cup.and.saucer.fill"
        }
    }
    
    static var infoPageDynamic: String {
        if #available(iOS 18, *) {
            return "info.circle.text.page"
        } else {
            return "info.circle"
        }
    }
}
