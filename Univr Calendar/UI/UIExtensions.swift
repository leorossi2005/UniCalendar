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

extension NoticeLevel {
    var tintColor: Color {
        switch self {
        case .info: .blue
        case .warning: .orange
        case .blocking: .red
        }
    }
}

import SwiftUI

enum AppState {
    case offline, serveroffline, unioffline
    
    var icon: String {
        switch self {
        case .offline:
            return "wifi.slash"
        case .serveroffline:
            return "network.slash"
        case .unioffline:
            return "building.columns"
        }
    }
    
    var color: Color {
        switch self {
        case .offline:
            return .yellow
        case .serveroffline:
            return .orange
        case .unioffline:
            return .blue
        }
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
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let duration: Double = 1.5
                let progress = (time.truncatingRemainder(dividingBy: duration)) / duration
                let xOffset = -width + (progress * width * 2)
                
                LinearGradient(
                    colors: [
                        .black.opacity(0),
                        colorScheme == .light ? .black.opacity(0.3) : .white.opacity(0.05),
                        .black.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width, height: geometry.size.height)
                .offset(x: xOffset)
            }
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
                    ShimmeringGradient()
                        .mask {
                            self
                                .redacted(reason: .placeholder)
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
                    .accessibilityHidden(true)
            }
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

extension SearchFieldPlacement {
    static var automaticPlacement: SearchFieldPlacement {
        if #available(iOS 26, *) {
            .automatic
        } else {
            .navigationBarDrawer(displayMode: .always)
        }
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder
    func toolbarBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        if #available(iOS 26, *) {
            self.sharedBackgroundVisibility(visibility)
        } else {
            self
        }
    }
    
    @ToolbarContentBuilder
    func modify<Content: ToolbarContent>(@ToolbarContentBuilder _ transform: (Self) -> Content) -> some ToolbarContent {
        transform(self)
    }
}

extension EnvironmentValues {
    @Entry var safeAreaInsets: UIEdgeInsets = .zero
}

private struct WindowInsetsReader: UIViewRepresentable {
    let onChange: (UIEdgeInsets) -> Void

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = onChange
        uiView.report()
    }

    final class ReaderView: UIView {
        var onChange: ((UIEdgeInsets) -> Void)?
        private var last: UIEdgeInsets?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        func report() {
            guard let insets = window?.safeAreaInsets, insets != last else { return }
            last = insets
            DispatchQueue.main.async { [weak self] in
                self?.onChange?(insets)
            }
        }
    }
}

private struct SafeAreaInsetsReader: ViewModifier {
    @State private var insets: UIEdgeInsets = .zero

    func body(content: Content) -> some View {
        content
            .environment(\.safeAreaInsets, insets)
            .background {
                WindowInsetsReader { insets = $0 }
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func readSafeAreaInsets() -> some View {
        modifier(SafeAreaInsetsReader())
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
    
    @available(iOSApplicationExtension, unavailable)
    static var deviceSymbol: String {
        if UIDevice.isIpad {
            switch UIDevice.iPadScreenType {
            case .homeButton: "ipad.gen1"
            case .noHomeButton: "ipad.gen2"
            case .unknown : "ipad"
            }
        } else {
            switch UIDevice.iPhoneScreenType {
            case .homeButton: "iphone.gen1"
            case .notch: "iphone.gen2"
            case .dynamicIsland: "iphone.gen3"
            case .unknown : "iphone"
            }
        }
    }
}

enum iPhoneScreenType {
    case homeButton
    case notch
    case dynamicIsland
    case unknown
}

enum iPadScreenType {
    case homeButton
    case noHomeButton
    case unknown
}

@available(iOSApplicationExtension, unavailable)
extension UIDevice {
    static var iPhoneScreenType: iPhoneScreenType {
        guard !UIDevice.isIpad else { return .unknown }
        let safeAreas = UIApplication.shared.safeAreas
        
        if safeAreas.bottom == 0 {
            return .homeButton
        }
        
        let sensorInset = max(safeAreas.top, safeAreas.left, safeAreas.right)
        
        if sensorInset >= 51.0 {
            return .dynamicIsland
        } else {
            return .notch
        }
    }
    
    static var iPadScreenType: iPadScreenType {
        guard UIDevice.isIpad else { return .unknown }
        
        if UIApplication.shared.safeAreas.bottom > 0 {
            return .noHomeButton
        } else {
            return .homeButton
        }
    }
}

final class AccessibleSpeechUIView: UIView {
    var onActivate: (() -> Void)?
    
    override func accessibilityActivate() -> Bool {
        if let onActivate {
            onActivate()
            return true
        }
        return super.accessibilityActivate()
    }
}

struct SpeechLanguageLabel: UIViewRepresentable {
    let text: NSAttributedString
    var traits: UIAccessibilityTraits = .none
    var onActivate: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> AccessibleSpeechUIView {
        let view = AccessibleSpeechUIView()
        view.isAccessibilityElement = true
        view.accessibilityTraits = traits
        view.onActivate = onActivate
        return view
    }
    
    func updateUIView(_ view: AccessibleSpeechUIView, context: Context) {
        view.accessibilityTraits = traits
        view.accessibilityAttributedLabel = text
        view.onActivate = onActivate
    }
}

struct SpeechSegment {
    let text: String
    let attributes: [NSAttributedString.Key: Any]
    
    init(_ text: String, language: String? = nil) {
        self.text = text
        if let language {
            self.attributes = [.accessibilitySpeechLanguage: language]
        } else {
            self.attributes = [:]
        }
    }
    
    init(_ text: String, attributes: [NSAttributedString.Key: Any]) {
        self.text = text
        self.attributes = attributes
    }
    
    static func it(_ text: String) -> SpeechSegment {
        SpeechSegment(text, language: "it-IT")
    }
    
    static func system(_ text: String) -> SpeechSegment {
        let localized = text.isEmpty ? "" : String(localized: String.LocalizationValue(text))
        return SpeechSegment(localized, language: nil)
    }
    
    static func system(localized key: String.LocalizationValue) -> SpeechSegment {
        SpeechSegment(String(localized: key), language: nil)
    }
}

extension NSAttributedString {
    static func composed(_ segments: SpeechSegment...) -> NSAttributedString {
        composed(segments)
    }
    
    static func composed(_ segments: [SpeechSegment]) -> NSAttributedString {
        let full = NSMutableAttributedString()
        for segment in segments where !segment.text.isEmpty {
            full.append(NSAttributedString(string: segment.text, attributes: segment.attributes))
        }
        return full
    }
}

extension SpeechLanguageLabel {
    init(_ segments: SpeechSegment..., traits: UIAccessibilityTraits = .none, onActivate: (() -> Void)? = nil) {
        self.init(text: .composed(segments), traits: traits, onActivate: onActivate)
    }
}
