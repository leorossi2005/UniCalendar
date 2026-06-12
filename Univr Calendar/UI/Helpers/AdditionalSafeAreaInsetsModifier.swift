//
//  AdditionalSafeAreaInsetsModifier.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 06/01/26.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UIKit

// MARK: - Extension per uso facile in SwiftUI
extension View {
    func customSafeAreaInsets(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0, isEnabled: Bool = true) -> some View {
        modifier(AdditionalSafeAreaInsetsModifier(
            insets: UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing),
            isEnabled: isEnabled
        ))
    }
}

// MARK: - ViewModifier
struct AdditionalSafeAreaInsetsModifier: ViewModifier {
    var insets: UIEdgeInsets
    var isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            SafeAreaControllerWrapper(insets: insets) {
                content
            }
            .ignoresSafeArea()
        } else {
            content
        }
    }
}

// MARK: - UIViewControllerRepresentable
private struct SafeAreaControllerWrapper<Content: View>: UIViewControllerRepresentable {
    var insets: UIEdgeInsets
    @ViewBuilder var content: Content
    
    func makeUIViewController(context: Context) -> SafeContainerViewController {
        let vc = SafeContainerViewController()
        vc.view.backgroundColor = .clear
        
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.additionalSafeAreaInsets = insets
        
        vc.addChild(hosting)
        vc.view.addSubview(hosting.view)
        
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: vc.view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        
        hosting.didMove(toParent: vc)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SafeContainerViewController, context: Context) {
        if let hosting = uiViewController.children.first as? UIHostingController<Content> {
            hosting.rootView = content
            if hosting.additionalSafeAreaInsets != insets {
                hosting.additionalSafeAreaInsets = insets
            }
        }
    }
}

// MARK: - Safe Container Controller (API Pubbliche)
class SafeContainerViewController: UIViewController {
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .top
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
