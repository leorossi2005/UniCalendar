//
//  ListScrollOffsetReader.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 16/12/25.
//

import SwiftUI

class ScrollDelegate: NSObject {
    var isAtTop: Binding<Bool>
    weak var scrollView: UIScrollView?
    private var observer: NSKeyValueObservation?

    init(isAtTop: Binding<Bool>) {
        self.isAtTop = isAtTop
    }

    func attach(to view: UIView) {
        if scrollView != nil { return }
        
        guard let foundScrollView = view.findListScrollView() else {
            return
        }
        
        self.scrollView = foundScrollView
        
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

struct ListScrollOffsetReader: UIViewRepresentable {
    @Binding var isAtTop: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attach(to: uiView)
        }
    }

    func makeCoordinator() -> ScrollDelegate {
        ScrollDelegate(isAtTop: $isAtTop)
    }
}

extension UIView {
    func findListScrollView() -> UIScrollView? {
        func searchSubviews(in view: UIView) -> UIScrollView? {
            if let scrollView = view as? UIScrollView {
                if view.bounds.height > 0 { return scrollView }
            }
            
            for subview in view.subviews {
                if let found = searchSubviews(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        var currentParent = self.superview
        var levels = 0
        
        while let parent = currentParent, levels < 10 {
            if let found = searchSubviews(in: parent) {
                return found
            }
            currentParent = parent.superview
            levels += 1
        }
        
        return nil
    }
}

extension UIView {
    func searchHierarchyForScrollView() -> UIScrollView? {
        if let found = self.findListScrollView() { return found }
        
        var current = self.superview
        while let p = current {
            for subview in p.subviews {
                if subview !== self, let found = subview.findListScrollView() {
                    return found
                }
            }
            current = p.superview
        }
        return nil
    }
}
