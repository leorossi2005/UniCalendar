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
        sendSubviewToBack(glassView)
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
