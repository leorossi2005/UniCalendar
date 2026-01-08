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
    /// Applica inset personalizzati alla Safe Area e protegge dai gesture di sistema indesiderati (Window Drag su iPad).
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
            // Se attivo, usiamo il container che gestisce gli insets E protegge dai drag
            SafeAreaControllerWrapper(insets: insets) {
                content
            }
            .ignoresSafeArea() // Importante per lasciare che sia il controller a gestire gli spazi
        } else {
            // Se disattivato, ritorniamo il contenuto liscio
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
        // Applichiamo gli inset iniziali
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
            // Aggiorniamo gli inset solo se cambiati
            if hosting.additionalSafeAreaInsets != insets {
                hosting.additionalSafeAreaInsets = insets
            }
        }
    }
}

// MARK: - Safe Container Controller (API Pubbliche)
// Questo controller serve a due scopi:
// 1. Contenere l'UIHostingController con gli inset modificati.
// 2. Dichiarare preferenze di sistema per evitare conflitti di gesture (API Pubbliche).
class SafeContainerViewController: UIViewController {
    
    // API PUBBLICA UIViewController:
    // Chiede al sistema di dare priorità ai gesture dell'app rispetto a quelli di sistema (es. Control Center, Window Drag)
    // sui bordi specificati.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .top
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Opzionale: Se deferringSystemGestures non basta, si può aggiungere qui logica extra,
        // ma proviamo prima con la sola proprietà nativa che è la via "Apple way".
    }
}
