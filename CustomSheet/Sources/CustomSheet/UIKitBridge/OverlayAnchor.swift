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
    
    private var lastDeepHitTime: TimeInterval = 0
    private var lastDeepHitPoint: CGPoint = .zero
    
    private let fixIsNeeded: Bool = {
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        return majorVersion == 26 || majorVersion == 18
    }()

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
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
    
    func cleanup() {
        hostingController?.willMove(toParent: nil)
        containerView?.removeFromSuperview()
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
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
        
        container.addSubview(hc.view)
        window.addSubview(container)
        
        if let rootVC = window.rootViewController {
            rootVC.addChild(hc)
            hc.didMove(toParent: rootVC)
        }
        
        self.hostingController = hc
        self.containerView = container
        
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: container.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            container.topAnchor.constraint(equalTo: window.topAnchor),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
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
    var capturedEnvironment: EnvironmentValues
    
    @Binding var isPresented: Bool
    var manager: GlobalSheetManager?
    var detents: [CustomSheetDetent]
    
    let sheetContent: () -> SheetContent
    
    class Coordinator {
        var lastPhase: ScenePhase?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> OverlayAnchorUIView {
        let view = OverlayAnchorUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: OverlayAnchorUIView, context: Context) {
        let currentPhase = context.environment.scenePhase
        let lastPhase = context.coordinator.lastPhase
        
        let didPhaseChange = (lastPhase != nil && lastPhase == .inactive && lastPhase != currentPhase)
        
        let updatedView = AnyView(
            CustomSheet(
                isPresented: $isPresented,
                detents: detents,
                manager: manager,
                content: sheetContent
            )
            .environment(\.scenePhase, capturedEnvironment.scenePhase)
            .environment(\.colorScheme, capturedEnvironment.colorScheme)
            .environment(\.self, capturedEnvironment)
        )
        
        if let hc = uiView.hostingController {
            if didPhaseChange {
                UIView.transition(with: hc.view, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    hc.rootView = updatedView
                }, completion: nil)
            } else {
                hc.rootView = updatedView
            }
        } else {
            uiView.pendingRootView = updatedView
        }
        
        context.coordinator.lastPhase = currentPhase
        
        let isLarge = manager?.selectedDetent == .large
        uiView.updateNavigationSafeArea(isLarge: isLarge)
    }
    
    static func dismantleUIView(_ uiView: OverlayAnchorUIView, coordinator: ()) {
        uiView.cleanup()
    }
}
