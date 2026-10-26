//
//  OverlayAnchor.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

class PassthroughContainerView: UIView {
    weak var hostingView: UIView?
    var shouldPassThrough: Bool = true
    
    private var lastDeepHitTime: TimeInterval = 0
    private var lastDeepHitPoint: CGPoint = .zero
    
    private let fixIsNeeded: Bool = {
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        return majorVersion == 26 || majorVersion == 18
    }()

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        if !shouldPassThrough {
            return hitView
        }
        
        if hitView == self {
            return nil
        }
        
        if !fixIsNeeded {
            if hitView == hostingView {
                return nil
            }
            return hitView
        }
        
        let currentTime = Date().timeIntervalSince1970
        
        if hitView != hostingView && hitView != nil {
            lastDeepHitTime = currentTime
            lastDeepHitPoint = point
            return hitView
        }
        
        if hitView == hostingView {
            let timeElapsed = currentTime - lastDeepHitTime
            let isSamePoint = point == lastDeepHitPoint
            
            if timeElapsed < 0.05 && isSamePoint {
                return hitView
            } else {
                return nil
            }
        }
        
        return hitView
    }
}

class OverlayAnchorUIView: UIView {
    var hostingController: UIHostingController<AnyView>?
    var containerView: PassthroughContainerView?
    var pendingRootView: AnyView?
    var isLargeActive: Bool = false
    
    func cleanup() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        containerView?.removeFromSuperview()
        hostingController?.view.removeFromSuperview()
        containerView = nil
        hostingController = nil
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let window = self.window, hostingController == nil,
              let rootView = pendingRootView else { return }
        
        let hc = UIHostingController(rootView: rootView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.safeAreaRegions = []

        let container = PassthroughContainerView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.hostingView = hc.view
        container.accessibilityViewIsModal = false
        
        container.addSubview(hc.view)
        window.addSubview(container)
        
        self.hostingController = hc
        self.containerView = container
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: container.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            container.topAnchor.constraint(equalTo: window.topAnchor, constant: 1),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
    }
    
    @objc private func voiceOverStatusChanged() {
        guard UIAccessibility.isVoiceOverRunning,
              isLargeActive,
              let container = containerView else { return }
        
        container.accessibilityViewIsModal = false
        hostingController?.view.setNeedsLayout()
        hostingController?.view.layoutIfNeeded()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self, weak container] in
            guard let self, let container, self.isLargeActive else { return }
            container.accessibilityViewIsModal = true
            UIAccessibility.post(notification: .screenChanged, argument: container)
        }
    }
    
    func updateNavigationSafeArea(isLarge: Bool) {
        guard let hc = hostingController else { return }
        
        func findNav(in vc: UIViewController) -> UINavigationController? {
            if let nav = vc as? UINavigationController { return nav }
            for child in vc.children {
                if let nav = findNav(in: child) { return nav }
            }
            return nil
        }
        
        DispatchQueue.main.async {
            if let nav = findNav(in: hc) {
                let targetInset: CGFloat = isLarge ? UIDevice.isIpad ? 8 : 16 : 0
                if nav.additionalSafeAreaInsets.top != targetInset {
                    UIView.animate(withDuration: 0.2) {
                        nav.additionalSafeAreaInsets.top = targetInset
                        nav.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
}

struct OverlayAnchorView<SheetContent: View>: UIViewRepresentable {
    @Binding var isPresented: Bool
    var manager: GlobalSheetManager?
    var detents: [CustomSheetDetent]
    
    let sheetContent: () -> SheetContent
    
    func makeUIView(context: Context) -> OverlayAnchorUIView {
        let view = OverlayAnchorUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: OverlayAnchorUIView, context: Context) {
        let env = context.environment
        
        let updatedView = AnyView(
            CustomSheet(
                isPresented: $isPresented,
                detents: detents,
                manager: manager,
                content: sheetContent
            )
            .environment(\.self, env)
        )
        
        if let hc = uiView.hostingController {
            hc.rootView = updatedView
        } else {
            uiView.pendingRootView = updatedView
        }
        
        manager?.onBackgroundToggle = { [weak uiView] isEnabled in
            uiView?.containerView?.shouldPassThrough = !isEnabled
        }
        
        manager?.onLargeDetentToggle = { [weak uiView, weak manager] isLarge in
            uiView?.isLargeActive = isLarge
            uiView?.updateNavigationSafeArea(isLarge: isLarge)
            
            let keepFocus = manager?.keepAccessibilityFocusOnLargeExit ?? false
            manager?.keepAccessibilityFocusOnLargeExit = false
            
            if uiView?.containerView?.accessibilityViewIsModal != isLarge {
                uiView?.containerView?.accessibilityViewIsModal = isLarge
                if isLarge || !keepFocus {
                    UIAccessibility.post(notification: .layoutChanged, argument: nil)
                } else {
                    UIAccessibility.post(notification: .layoutChanged, argument: uiView?.containerView)
                }
            }
        }
    }
    
    static func dismantleUIView(_ uiView: OverlayAnchorUIView, coordinator: ()) {
        uiView.cleanup()
    }
}
