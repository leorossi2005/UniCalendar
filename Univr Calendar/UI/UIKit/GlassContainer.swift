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
    private let shadowView = UIView()
    private let glassView = UIVisualEffectView()
    var style: GlassEffectStyle = .regular {
        didSet { updateAppearance() }
    }
    var tint: UIColor? = nil {
        didSet { updateAppearance() }
    }
    var cornerRadii: SheetCornerRadii = .init(tl: 0, tr: 0, bl: 0, br: 0) {
        didSet { applyCorners(animated: true, duration: 0.2)  }
    }
    var isEnabled = true {
        didSet { updateAppearance() }
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
        if #unavailable(iOS 26) {
            shadowView.translatesAutoresizingMaskIntoConstraints = false
            shadowView.backgroundColor = .clear
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
            shadowView.layer.shadowRadius = 2
            addSubview(shadowView)
        }
        
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        
        if #unavailable(iOS 26) {
            NSLayoutConstraint.activate([
                shadowView.leadingAnchor.constraint(equalTo: leadingAnchor),
                shadowView.trailingAnchor.constraint(equalTo: trailingAnchor),
                shadowView.topAnchor.constraint(equalTo: topAnchor),
                shadowView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
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
        if #unavailable(iOS 26) {
            applyCornerMask()
        }
    }
    
    private func updateAppearance() {
        updateEffect()
        if #unavailable(iOS 26) {
            updateShadow()
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
            self.shadowView.layer.shadowOpacity = shouldShowShadow ? 0.12 : 0.0
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
                self.updateShadowPath()
                self.applyCornerMask()
            }
        }
        
        if animated {
            UIView.animate(withDuration: duration, animations: block)
        } else {
            block()
        }
    }
    
    private func generatePath(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
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
        return path
    }
    
    // 3. Nuova funzione per disegnare l'ombra seguendo i corner
    private func updateShadowPath() {
        let path = generatePath(rect: bounds)
        shadowView.layer.shadowPath = path.cgPath
    }
    
    private func applyCornerMask() {
        let path = generatePath(rect: glassView.bounds)
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
            
            let transaction = context.transaction
            DispatchQueue.main.async {
                withTransaction(transaction) {
                    context.coordinator.content = content
                }
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
