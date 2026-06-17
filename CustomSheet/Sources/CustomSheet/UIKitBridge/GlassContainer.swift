//
//  GlassContainer.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 17/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

public struct SheetCornerRadii: Equatable {
    var tl: CGFloat
    var tr: CGFloat
    var bl: CGFloat
    var br: CGFloat
    
    public init(tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat) {
        self.tl = tl
        self.tr = tr
        self.bl = bl
        self.br = br
    }
    
    public init (all: CGFloat) {
        self.tl = all
        self.tr = all
        self.bl = all
        self.br = all
    }
}

public enum GlassEffectStyle {
    case regular
    case clear
    
    @available(iOS 26, *)
    var glassStyle: UIGlassEffect.Style {
        switch self {
        case .regular: return .regular
        case .clear: return .clear
        }
    }
}

final class GlassContainerView: UIView {
    private let shadowView = UIView()
    private let glassView = UIVisualEffectView()
    
    var cornerRadii: SheetCornerRadii = .init(all: 0)
    var style: GlassEffectStyle = .regular { didSet { updateAppearance() } }
    var tint: UIColor? = nil { didSet { updateAppearance() } }
    var isEnabled = true { didSet { updateAppearance() } }
    var resetTrigger: Int = 0 { didSet { resetEffect() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setup() {
        if #unavailable(iOS 26) {
            shadowView.backgroundColor = .clear
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
            shadowView.layer.shadowRadius = 2
            addSubview(shadowView)
        }
        
        addSubview(glassView)
        glassView.clipsToBounds = true
        
        if #unavailable(iOS 26) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: GlassContainerView, previousTraitCollection: UITraitCollection) in
                self.updateAppearance()
            }
        }
        updateAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #unavailable(iOS 26) { shadowView.frame = bounds }
        glassView.frame = bounds
        
        if #unavailable(iOS 26) {
            applyCornerMask()
            updateShadowPath()
        }
    }
    
    private func updateAppearance() {
        updateEffect()
        if #unavailable(iOS 26) { updateShadow() }
    }
    
    private func updateEffect() {
        if isEnabled {
            if #available(iOS 26, *) {
                let effect = UIGlassEffect(style: style.glassStyle)
                effect.isInteractive = true
                effect.tintColor = tint
                glassView.effect = effect
            } else {
                glassView.effect = nil
                glassView.backgroundColor = traitCollection.userInterfaceStyle == .dark ?
                    .secondarySystemBackground :
                    .systemBackground
            }
        } else {
            glassView.effect = nil
        }
    }
    
    private func updateShadow() {
        let shouldShowShadow = traitCollection.userInterfaceStyle != .dark
        UIView.animate(withDuration: 0.2) {
            self.shadowView.layer.shadowOpacity = shouldShowShadow ? 0.1 : 0.0
        }
    }
    
    private func resetEffect() {
        glassView.effect = nil
        DispatchQueue.main.async { self.updateEffect() }
    }
    
    var contentView: UIView { return glassView.contentView }
    
    func applyCorners(animated: Bool, duration: TimeInterval) {
        let block = {
            if #available(iOS 26, *) {
                let corners: UICornerConfiguration = .corners(
                    topLeftRadius: .fixed(self.cornerRadii.tl),
                    topRightRadius: .fixed(self.cornerRadii.tr),
                    bottomLeftRadius: .fixed(self.cornerRadii.bl),
                    bottomRightRadius: .fixed(self.cornerRadii.br)
                )
                if self.glassView.cornerConfiguration != corners {
                    self.glassView.cornerConfiguration = corners
                }
            } else {
                self.applyCornerMask()
                self.updateShadowPath()
            }
        }
        
        if animated {
            UIView.animate(withDuration: duration, animations: block)
        } else { block() }
    }
    
    private func applyCornerMask() {
        let maxRadius = max(cornerRadii.tl, cornerRadii.tr, cornerRadii.bl, cornerRadii.br)
        
        var maskedCorners: CACornerMask = []
        if cornerRadii.tl > 0 { maskedCorners.insert(.layerMinXMinYCorner) }
        if cornerRadii.tr > 0 { maskedCorners.insert(.layerMaxXMinYCorner) }
        if cornerRadii.bl > 0 { maskedCorners.insert(.layerMinXMaxYCorner) }
        if cornerRadii.br > 0 { maskedCorners.insert(.layerMaxXMaxYCorner) }
        
        glassView.layer.cornerRadius = maxRadius
        glassView.layer.maskedCorners = maskedCorners
        
        shadowView.layer.cornerRadius = maxRadius
        shadowView.layer.maskedCorners = maskedCorners
    }
    
    private func updateShadowPath() {
        shadowView.layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: shadowView.layer.cornerRadius
        ).cgPath
    }
}

public struct GlassContainer<Content: View>: UIViewControllerRepresentable {
    var radii: SheetCornerRadii
    var style: GlassEffectStyle = .regular
    var tint: Color? = nil
    var animationDuration: TimeInterval = 0.2
    var isEnabled: Bool = true
    var resetGlassEffect: Int = 0
    private let content: Content
    
    public init(
        radii: SheetCornerRadii,
        style: GlassEffectStyle = .regular,
        tint: Color? = nil,
        animationDuration: TimeInterval = 0.2,
        isEnabled: Bool = true,
        resetGlassEffect: Int = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.radii = radii
        self.style = style
        self.tint = tint
        self.animationDuration = animationDuration
        self.isEnabled = isEnabled
        self.resetGlassEffect = resetGlassEffect
        self.content = content()
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        let glassContainer = GlassContainerView()
        glassContainer.cornerRadii = radii
        glassContainer.style = style
        if let tint { glassContainer.tint = UIColor(tint) }
        glassContainer.isEnabled = isEnabled
        glassContainer.resetTrigger = resetGlassEffect
        
        controller.view.addSubview(glassContainer)
        glassContainer.frame = controller.view.bounds
        glassContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.insetsLayoutMarginsFromSafeArea = false
        hosting.safeAreaRegions = []
        hosting.traitOverrides.userInterfaceLevel = .elevated
        
        glassContainer.contentView.addSubview(hosting.view)
        hosting.view.frame = glassContainer.contentView.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        controller.addChild(hosting)
        hosting.didMove(toParent: controller)
        
        context.coordinator.glassContainer = glassContainer
        context.coordinator.hostingController = hosting
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let shouldAnimate = (context.transaction.animation != nil)
        if let glass = context.coordinator.glassContainer {
            if glass.cornerRadii != radii { glass.cornerRadii = radii }
            if glass.style != style { glass.style = style }
            glass.tint = tint.map { UIColor($0) }
            if glass.isEnabled != isEnabled { glass.isEnabled = isEnabled }
            if glass.resetTrigger != resetGlassEffect { glass.resetTrigger = resetGlassEffect }
            glass.applyCorners(animated: shouldAnimate, duration: animationDuration)
            
            let transaction = context.transaction
            withTransaction(transaction) {
                context.coordinator.hostingController?.rootView = content
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator {
        weak var glassContainer: GlassContainerView?
        weak var hostingController: UIHostingController<Content>?
    }
}
