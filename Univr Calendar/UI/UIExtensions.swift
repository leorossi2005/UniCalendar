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
        } else {
            self
                .presentationCornerRadius(40)
            
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
