//
//  AdditionalSafeAreaInsetsModifier.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 06/01/26.
//

import SwiftUI

/// Un wrapper che crea un ambiente isolato con i propri SafeAreaInsets
struct IsolatedSafeAreaWrapper<Content: View>: UIViewControllerRepresentable {
    var topInset: CGFloat = 0
    var leftInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    var rightInset: CGFloat = 0
    @ViewBuilder var content: Content

    func makeUIViewController(context: Context) -> UIViewController {
        // Creiamo un controller contenitore trasparente
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        
        // Creiamo l'HostingController per il contenuto
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        // 👇 Qui avviene la magia: applichiamo l'inset SOLO a questo controller interno
        hostingController.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        
        // Aggiungiamo l'hosting come figlio
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        
        // Layout
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: viewController)
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Aggiorniamo il contenuto SwiftUI quando cambia lo stato
        if let hosting = uiViewController.children.first as? UIHostingController<Content> {
            hosting.rootView = content
            
            // Aggiorniamo l'inset se dovesse cambiare dinamicamente
            if hosting.additionalSafeAreaInsets.top != topInset {
                hosting.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            }
        }
    }
}
