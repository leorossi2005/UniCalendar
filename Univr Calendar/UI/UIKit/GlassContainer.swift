//
//  GlassContainer.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/12/25.
//

import SwiftUI
internal import Combine

struct SheetCornerRadii: Equatable {
    var tl: CGFloat
    var tr: CGFloat
    var bl: CGFloat
    var br: CGFloat
}

enum GlassEffectStyle {
    case regular
    case clear
    
    @available(iOS 26, *)
    var glassStyle: UIGlassEffect.Style {
        switch self {
        case .regular: return .regular
        case .clear: return .clear
        }
    }
    
    var blurStyle: UIBlurEffect.Style {
        switch self {
        case .regular: return .regular
        case .clear: return .regular
        }
    }
}

final class GlassContainerView: UIView {
    private let glassView = UIVisualEffectView()
    var style: GlassEffectStyle = .regular {
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
    var resetTrigger: Int = 0 {
        didSet { resetEffect() }
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
        
        glassView.clipsToBounds = true
        
        updateEffect()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Solo su iOS 17-18, riapplica i corner quando cambiano i bounds
        if #unavailable(iOS 26) {
            applyCornerMask()
        }
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
                glassView.backgroundColor = .secondarySystemBackground
            }
        } else {
            glassView.effect = nil
        }
    }
    
    private func resetEffect() {
        glassView.effect = nil
        
        DispatchQueue.main.async {
            self.updateEffect()
        }
    }
    
    public var contentView: UIView {
        return glassView.contentView
    }
    
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
            }
        }
        
        if animated {
            UIView.animate(withDuration: duration, animations: block)
        } else {
            block()
        }
    }
    
    private func applyCornerMask() {
        let path = UIBezierPath()
        let rect = glassView.bounds
        
        // Crea un path con corner radii diversi per ogni angolo
        path.move(to: CGPoint(x: rect.minX + cornerRadii.tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadii.tr, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadii.tr),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadii.br))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadii.br, y: rect.maxY),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadii.bl, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadii.bl),
                          controlPoint: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadii.tl))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadii.tl, y: rect.minY),
                          controlPoint: CGPoint(x: rect.minX, y: rect.minY))
        path.close()
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        glassView.layer.mask = mask
    }
}

struct GlassContainer<Content: View>: UIViewControllerRepresentable {
    var radii: SheetCornerRadii
    var style: GlassEffectStyle = .regular
    var tint: Color? = nil
    var animationDuration: TimeInterval = 0.2
    var isEnabled: Bool = true
    var lockGesture: Bool = false
    var resetGlassEffect: Int = 0
    private let content: Content
    
    init(
        radii: SheetCornerRadii,
        style: GlassEffectStyle = .regular,
        tint: Color? = nil,
        animationDuration: TimeInterval = 0.2,
        isEnabled: Bool = true,
        lockGesture: Bool = false,
        resetGlassEffect: Int = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.radii = radii
        self.style = style
        self.tint = tint
        self.animationDuration = animationDuration
        self.isEnabled = isEnabled
        self.lockGesture = lockGesture
        self.resetGlassEffect = resetGlassEffect
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Crea il GlassContainerView (il vetro UIKit)
        let glassContainer = GlassContainerView()
        glassContainer.cornerRadii = radii
        glassContainer.style = style
        if let tint {
            glassContainer.tint = UIColor(tint)
        } else {
            glassContainer.tint = nil
        }
        glassContainer.isEnabled = isEnabled
        glassContainer.resetTrigger = resetGlassEffect
        
        controller.view.addSubview(glassContainer)
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glassContainer.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            glassContainer.topAnchor.constraint(equalTo: controller.view.topAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        
        let bridge = BridgeView(coordinator: context.coordinator)
        let hosting = UIHostingController(rootView: bridge)
        hosting.view.backgroundColor = .clear
        hosting.view.insetsLayoutMarginsFromSafeArea = false
        hosting.traitOverrides.userInterfaceLevel = .elevated
        if lockGesture { hosting.view.tag = 422 }
        
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
        context.coordinator.hostingController = hosting
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let shouldAnimate = (context.transaction.animation != nil)
        if let glass = context.coordinator.glassContainer {
            if glass.cornerRadii != radii { glass.cornerRadii = radii }
            if glass.style != style { glass.style = style }
            glass.tint = tint.map { UIColor($0) }
            if glass.isEnabled != isEnabled { glass.isEnabled = isEnabled }
            if glass.resetTrigger != resetGlassEffect { glass.resetTrigger = resetGlassEffect }
            glass.applyCorners(animated: shouldAnimate, duration: animationDuration)
            
            if let animation = context.transaction.animation {
                withAnimation(animation) {
                    context.coordinator.content = content
                }
            } else {
                context.coordinator.content = content
            }
            context.coordinator.hostingController?.view.setNeedsLayout()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(content: content)
    }
    
    class Coordinator: ObservableObject {
        @Published var content: Content
        
        var glassContainer: GlassContainerView?
        var hostingController: UIHostingController<BridgeView>?
        
        init(content: Content) {
            self.content = content
        }
    }
    
    struct BridgeView: View {
        @ObservedObject var coordinator: Coordinator
        
        var body: some View {
            coordinator.content
        }
    }
}
