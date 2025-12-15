//
//  DisableTabViewScrolling.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/12/25.
//

import SwiftUI
import UIKit

struct DisableTabViewScrolling: ViewModifier {
    var isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                TabViewInteractionModifier(isDisabled: isDisabled)
            )
    }
}

struct TabViewInteractionModifier: UIViewRepresentable {
    var isDisabled: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            // Cerca tutte le ScrollView paging nelle vicinanze
            let foundViews = findAllPagingScrollViews(from: uiView)
            
            for targetView in foundViews {
                // 1. Disabilita lo scroll orizzontale
                targetView.isScrollEnabled = !isDisabled
                
                // 2. Disabilita completamente l'interazione
                targetView.isUserInteractionEnabled = !isDisabled
                
                // 3. Per le UICollectionView, disabilita anche le gesture recognizer
                if let collectionView = targetView as? UICollectionView {
                    collectionView.gestureRecognizers?.forEach { recognizer in
                        recognizer.isEnabled = !isDisabled
                    }
                }
            }
        }
    }
    
    private func findAllPagingScrollViews(from view: UIView) -> [UIScrollView] {
        var results: [UIScrollView] = []
        
        // Strategia 1: Cerca nei fratelli (più comune per TabView)
        if let parent = view.superview {
            for subview in parent.subviews {
                if let collectionView = subview as? UICollectionView, collectionView.isPagingEnabled {
                    results.append(collectionView)
                }
            }
        }
        
        // Strategia 2: Risali nella gerarchia e cerca in modo più ampio
        var current = view.superview
        var depth = 0
        
        while let parent = current, depth < 4 { // Aumentato a 4 livelli per essere più sicuri
            let found = searchForPagingScrollViews(in: parent, originatingView: view)
            results.append(contentsOf: found)
            current = parent.superview
            depth += 1
        }
        
        // Rimuovi duplicati
        return Array(Set(results.map { ObjectIdentifier($0) })).compactMap { id in
            results.first { ObjectIdentifier($0) == id }
        }
    }
    
    private func searchForPagingScrollViews(in view: UIView, originatingView: UIView) -> [UIScrollView] {
        var results: [UIScrollView] = []
        
        // Controlla se questa view è una collezione paginata
        if let collectionView = view as? UICollectionView {
            if collectionView.isPagingEnabled {
                results.append(collectionView)
            }
        }
        
        // Fallback per ScrollView generiche
        if let scrollView = view as? UIScrollView,
           !(view is UITableView),
           !(view is UICollectionView) {
            if scrollView.isPagingEnabled {
                results.append(scrollView)
            }
        }
        
        // Ricerca ricorsiva nei figli
        for subview in view.subviews {
            // Non cercare dentro la view da cui siamo partiti
            if subview === originatingView { continue }
            
            let found = searchForPagingScrollViews(in: subview, originatingView: originatingView)
            results.append(contentsOf: found)
        }
        
        return results
    }
}

extension View {
    /// Blocca completamente lo scroll orizzontale e l'interazione con il contenuto della TabView
    func disableTabViewScrolling(_ isDisabled: Bool) -> some View {
        modifier(DisableTabViewScrolling(isDisabled: isDisabled))
    }
}
