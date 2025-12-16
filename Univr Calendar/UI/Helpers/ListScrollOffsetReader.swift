//
//  ListScrollOffsetReader.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 16/12/25.
//

import SwiftUI

// 1. Il Coordinatore (Corretto: Solo NSObject)
class ScrollDelegate: NSObject {
    var isAtTop: Binding<Bool>
    weak var scrollView: UIScrollView?
    private var observer: NSKeyValueObservation?

    init(isAtTop: Binding<Bool>) {
        self.isAtTop = isAtTop
    }

    func attach(to view: UIView) {
        // Se siamo già agganciati, usciamo
        if scrollView != nil { return }
        
        // Usiamo la nuova ricerca aggressiva
        guard let foundScrollView = view.findListScrollView() else {
            return
        }
        
        self.scrollView = foundScrollView
        
        // Osserviamo
        observer = foundScrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            DispatchQueue.main.async {
                let visibleOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                if visibleOffset >= 1 {
                    self?.isAtTop.wrappedValue = false
                } else {
                    self?.isAtTop.wrappedValue = true
                }
            }
        }
    }
    
    deinit {
        observer?.invalidate()
    }
}


// 2. Il wrapper UIViewRepresentable
struct ListScrollOffsetReader: UIViewRepresentable {
    @Binding var isAtTop: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Un piccolo ritardo aiuta a trovare la gerarchia completa
        DispatchQueue.main.async {
            context.coordinator.attach(to: uiView)
        }
    }

    func makeCoordinator() -> ScrollDelegate {
        ScrollDelegate(isAtTop: $isAtTop)
    }
}

// 3. Estensione sicura per trovare la ScrollView
extension UIView {
    func findListScrollView() -> UIScrollView? {
        // Funzione helper per cercare ricorsivamente nei figli
        func searchSubviews(in view: UIView) -> UIScrollView? {
            // Se è la view che cerchiamo (Le List sono spesso UICollectionView)
            if let scrollView = view as? UIScrollView {
                // Filtriamo scrollview piccolissime o nascoste che a volte SwiftUI crea
                if view.bounds.height > 0 { return scrollView }
            }
            
            for subview in view.subviews {
                if let found = searchSubviews(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        // Algoritmo:
        // 1. Partiamo da "self" (la view invisibile)
        // 2. Risaliamo di un genitore alla volta
        // 3. Per ogni genitore, cerchiamo in TUTTI i suoi sotto-alberi (tranne il ramo da cui veniamo)
        
        var currentParent = self.superview
        var levels = 0
        
        while let parent = currentParent, levels < 10 { // Limite a 10 livelli per sicurezza
            // Cerca nei discendenti di questo genitore
            if let found = searchSubviews(in: parent) {
                return found
            }
            currentParent = parent.superview
            levels += 1
        }
        
        return nil
    }
}


// Estensione per lanciare la ricerca dal basso verso l'alto
// Questa va usata SOLO sulla view sonda iniziale
extension UIView {
    func searchHierarchyForScrollView() -> UIScrollView? {
        // Cerca in se stesso e figli
        if let found = self.findListScrollView() { return found }
        
        // Risale la gerarchia e cerca nei fratelli/padri
        var current = self.superview
        while let p = current {
            for subview in p.subviews {
                // Non ricontrollare il ramo da cui veniamo (opzionale ma ottimizza)
                if subview !== self, let found = subview.findListScrollView() {
                    return found
                }
            }
            current = p.superview
        }
        return nil
    }
}
