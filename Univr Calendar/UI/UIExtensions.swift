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
import CustomSheet

extension AppColor {
    var color: Color {
        switch self {
        case .blue: .blue
        case .orange: .orange
        case .purple: .purple
        case .gray: .gray
        case .green: .green
        case .red: .red
        case .teal: .teal
        case .pink: .pink
        case .yellow: .yellow
        case .indigo: .indigo
        case .mint: .mint
        case .cyan: .cyan
        case .brown: .brown
        }
    }
}

extension Color {
    init?(hex: String) {
        guard let components = HexColorParser.parse(hex) else { return nil }
        self.init(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }
}

extension Lesson {
    var uiColor: Color {
        guard let components = HexColorParser.parse(color) else { return .secondary }
        return Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
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
    func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
    
    @ViewBuilder
    func textOverlay(
        text: LocalizedStringKey,
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
    func glassIfAvailable(prominent: Bool) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                self
                    .buttonStyle(.glassProminent)
            } else {
                self
                    .buttonStyle(.glass)
            }
        } else {
            if prominent {
                self
                    .buttonStyle(.borderedProminent)
            } else {
                self
                    .buttonStyle(.bordered)
            }
            
        }
    }
    
    @ViewBuilder
    func backgroundVisibility(_ visibility: Color) -> some View {
        if #unavailable(iOS 26) {
            if #available(iOS 18, *) {
                self
                    .toolbarBackgroundVisibility(.visible, for: .bottomBar)
                    .toolbarBackground(visibility, for: .bottomBar)
            } else {
                self
            }
        } else {
            self
        }
    }
    
    // MARK: Fallback iOS 17
    @ViewBuilder
    func symbolReplace() -> some View {
        if #available(iOS 18, *) {
            self
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
        } else {
            self
                .contentTransition(.symbolEffect(.replace))
            
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

extension EnvironmentValues {
    @Entry var safeAreaInsets: UIEdgeInsets = .zero
}

private struct SafeAreaInsetsReader: ViewModifier {
    @State private var insets: UIEdgeInsets = .zero
    
    func body(content: Content) -> some View {
        content
            .environment(\.safeAreaInsets, insets)
            .background {
                Color.clear
                    .ignoresSafeArea(.keyboard)
                    .onGeometryChange(for: EdgeInsets.self) { proxy in
                        proxy.safeAreaInsets
                    } action: { new in
                        insets = UIEdgeInsets(
                            top: new.top,
                            left: new.leading,
                            bottom: new.bottom,
                            right: new.trailing
                        )
                    }
            }
    }
}

extension View {
    func readSafeAreaInsets() -> some View {
        modifier(SafeAreaInsetsReader())
    }
}

extension Array where Element == Corso {
    public func filtered(by searchText: String) -> [Corso] {
        guard !searchText.isEmpty else { return self }
        return self.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }
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
    
    static var personalCommitmentsDynamic: String {
        if #available(iOS 18, *) {
            return "calendar.and.person"
        } else {
            return "person.badge.clock"
        }
    }
}
