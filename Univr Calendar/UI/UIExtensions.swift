//
//  UIExtensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        switch hexSanitized.count {
        case 6: // RGB (es. "FF5733")
            (r, g, b, a) = (
                Double((rgb >> 16) & 0xFF) / 255.0,
                Double((rgb >> 8) & 0xFF) / 255.0,
                Double(rgb & 0xFF) / 255.0,
                1.0
            )
        case 8: // RGBA (es. "FF5733FF")
            (r, g, b, a) = (
                Double((rgb >> 24) & 0xFF) / 255.0,
                Double((rgb >> 16) & 0xFF) / 255.0,
                Double((rgb >> 8) & 0xFF) / 255.0,
                Double(rgb & 0xFF) / 255.0
            )
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension View {
    @ViewBuilder
    func shimmeringPlaceholder() -> some View {
        self.overlay {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.2), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 1.5, height: height)
                    .offset(x: -width)
                    // Animazione continua
                    .phaseAnimator([false, true]) { content, phase in
                        content
                            .offset(x: phase ? width * 2 : -width)
                    } animation: { _ in
                        .linear(duration: 1.5).repeatForever(autoreverses: false)
                    }
            }
            .mask(self)
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
    func sheetDesign(_ namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            self
                .navigationTransition(
                    .zoom(sourceID: "calendar", in: namespace)
                )
                .presentationCornerRadius(.deviceCornerRadius)
        } else {
            self
                .presentationCornerRadius(.deviceCornerRadius)
            
        }
    }
    
    @ViewBuilder
    func scrollViewTopPadding() -> some View {
        if #available(iOS 26, *) {
            self
        } else if #available(iOS 18, *) {
            self
                .padding(.top, 15)
            
        } else {
            self
        }
    }
    
    @ViewBuilder
    func onScrollGeometry(openCalendar: Binding<Bool>, selectedDetent: Binding<PresentationDetent>) -> some View {
        if #available(iOS 26, *) {
            self
                .onScrollGeometryChange(for: ScrollGeometry.self, of: { geometry in
                    geometry
                }) { oldValue, newValue in
                    withAnimation {
                        if (newValue.contentOffset.y + newValue.contentInsets.top) <= 0 {
                            openCalendar.wrappedValue = true
                        } else {
                            if selectedDetent.wrappedValue != .large {
                                openCalendar.wrappedValue = false
                            }
                        }
                    }
                }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func hideTabBarCompatible() -> some View {
        if #available(iOS 18.0, *) {
            // API iOS 18+
            self
                .tabViewStyle(.tabBarOnly)
                .toolbarVisibility(.hidden, for: .tabBar)
        } else {
            // API iOS 17 e precedenti
            self
                .toolbar(.hidden, for: .tabBar)
        }
    }
    
    @ViewBuilder
    func removeTopSafeArea() -> some View {
        if #available(iOS 17, *) {
            if #unavailable(iOS 18.0) {
                self
                    .ignoresSafeArea(edges: .top)
            } else {
                self
            }
        }
    }
}

extension UIApplication {
    /// Ritorna le dimensioni della safe area attuale (se disponibili)
    var safeAreas: UIEdgeInsets {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)
        else {
            return .zero
        }
        return window.safeAreaInsets
    }
    
    var screenSize: CGRect {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)
        else {
            return .init()
        }
        return window.screen.bounds
    }
}

extension CGFloat {
    static var deviceCornerRadius: CGFloat {
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
        
        let bottomSafeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 0
        
        if bottomSafeArea > 0 {
            return 47.33
        } else {
            return 0
        }
    }
}
