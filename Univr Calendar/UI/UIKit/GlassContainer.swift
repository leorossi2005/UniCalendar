//
//  GlassContainer.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/12/25.
//

import SwiftUI

struct SheetCornerRadii: Equatable {
    var tl: CGFloat
    var tr: CGFloat
    var bl: CGFloat
    var br: CGFloat
}

@available(iOS 26.0, *)
final class GlassContainerView: UIView {
    private let glassView = UIVisualEffectView(effect: nil)
    var style: UIGlassEffect.Style = .regular {
        didSet { updateEffect() }
    }
    var tint: UIColor? = nil {
        didSet { updateEffect() }
    }
    var cornerRadii: SheetCornerRadii = .init(tl: 0, tr: 0, bl: 0, br: 0) {
        didSet { applyCorners(animated: true, duration: 0.2)  }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateEffect()
    }
    
    private func updateEffect() {
        let effect = UIGlassEffect(style: style)
        effect.isInteractive = true
        effect.tintColor = tint
        glassView.effect = effect
    }
    
    func applyCorners(animated: Bool, duration: TimeInterval) {
        let block = {
            self.glassView.cornerConfiguration = .corners(
                topLeftRadius: .fixed(self.cornerRadii.tl),
                topRightRadius: .fixed(self.cornerRadii.tr),
                bottomLeftRadius: .fixed(self.cornerRadii.bl),
                bottomRightRadius: .fixed(self.cornerRadii.br)
            )
        }
        
        if animated {
            UIView.animate(withDuration: duration, animations: block)
        } else {
            block()
        }
    }
}

@available(iOS 26.0, *)
struct GlassContainer: UIViewRepresentable {
    var radii: SheetCornerRadii
    var style: UIGlassEffect.Style = .regular
    var tint: Color? = nil
    var animationDuration: TimeInterval = 0.2

    func makeUIView(context: Context) -> GlassContainerView {
        let v = GlassContainerView()
        v.cornerRadii = radii
        v.style = style
        if let tint {
            v.tint = UIColor(tint)
        } else {
            v.tint = nil
        }
        return v
    }

    func updateUIView(_ uiView: GlassContainerView, context: Context) {
        let shouldAnimate = (context.transaction.animation != nil)
        uiView.cornerRadii = radii
        uiView.style = style
        if let tint {
            uiView.tint = UIColor(tint)
        } else {
            uiView.tint = nil
        }
        uiView.applyCorners(animated: shouldAnimate, duration: animationDuration)
    }
}

@available(iOS 26.0, *)
final class GlassContainerVieww: UIView {
    private let glassView = UIVisualEffectView()
    private let glassEffect = UIGlassEffect()
    var style: UIGlassEffect.Style = .regular {
        didSet { updateEffect() }
    }
    var tint: UIColor? = nil {
        didSet { updateEffect() }
    }
    var cornerRadii: SheetCornerRadii = .init(tl: 0, tr: 0, bl: 0, br: 0) {
        didSet { applyCorners(animated: true, duration: 0.2)  }
    }
    var isEnabled = true {
        didSet { updateEffect() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateEffect()
    }
    
    private func updateEffect() {
        if isEnabled {
            let effect = UIGlassEffect(style: style)
            effect.isInteractive = true
            effect.tintColor = tint
            glassView.effect = effect
        } else {
            glassView.effect = nil
        }
    }
    
    // Esponi il contentView per aggiungere le view DENTRO il container
    public var contentView: UIView {
        return glassView.contentView
    }
    
    func applyCorners(animated: Bool, duration: TimeInterval) {
        let block = {
            let corners: UICornerConfiguration = .corners(
                topLeftRadius: .fixed(self.cornerRadii.tl),
                topRightRadius: .fixed(self.cornerRadii.tr),
                bottomLeftRadius: .fixed(self.cornerRadii.bl),
                bottomRightRadius: .fixed(self.cornerRadii.br)
            )
            if self.glassView.cornerConfiguration != corners {
                self.glassView.cornerConfiguration = corners
            }
        }
        
        if animated {
            UIView.animate(withDuration: duration, animations: block)
        } else {
            block()
        }
    }
}

@available(iOS 26.0, *)
struct GlassContainerr<Content: View>: UIViewControllerRepresentable {
    var radii: SheetCornerRadii
    var style: UIGlassEffect.Style = .regular
    var tint: Color? = nil
    var animationDuration: TimeInterval = 0.2
    var isEnabled: Bool = true
    private let content: Content
    
    init(
        radii: SheetCornerRadii,
        style: UIGlassEffect.Style = .regular,
        tint: Color? = nil,
        animationDuration: TimeInterval = 0.2,
        isEnabled: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.radii = radii
        self.style = style
        self.tint = tint
        self.animationDuration = animationDuration
        self.isEnabled = isEnabled
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Crea il GlassContainerView (il vetro UIKit)
        let glassContainer = GlassContainerVieww()
        glassContainer.cornerRadii = radii
        glassContainer.style = style
        if let tint {
            glassContainer.tint = UIColor(tint)
        } else {
            glassContainer.tint = nil
        }
        glassContainer.isEnabled = isEnabled
        
        controller.view.addSubview(glassContainer)
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glassContainer.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            glassContainer.topAnchor.constraint(equalTo: controller.view.topAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        
        // Crea l'hosting controller per SwiftUI
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.insetsLayoutMarginsFromSafeArea = false
        
        // Aggiungi il contenuto SwiftUI DENTRO il glass container
        glassContainer.contentView.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor)
        ])
        
        controller.addChild(hosting)
        hosting.didMove(toParent: controller)
        
        // Store per update
        context.coordinator.glassContainer = glassContainer
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let shouldAnimate = (context.transaction.animation != nil)
        if context.coordinator.glassContainer?.cornerRadii != radii {
            context.coordinator.glassContainer?.cornerRadii = radii
        }
        if context.coordinator.glassContainer?.style != style {
            context.coordinator.glassContainer?.style = style
        }
        if let tint {
            context.coordinator.glassContainer?.tint = UIColor(tint)
        } else {
            context.coordinator.glassContainer?.tint = nil
        }
        if context.coordinator.glassContainer?.isEnabled != isEnabled {
            context.coordinator.glassContainer?.isEnabled = isEnabled
        }
        context.coordinator.glassContainer?.applyCorners(animated: shouldAnimate, duration: animationDuration)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var glassContainer: GlassContainerVieww?
    }
}
