//
//  VerticalDragger.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 16/12/25.
//

import SwiftUI
import UIKit

enum CustomSheetDraggingDirection {
    case up, down, none
}

struct VerticalDragger: UIViewRepresentable {
    var direction: CustomSheetDraggingDirection = .none
    
    var onDrag: (CGFloat, CustomSheetDraggingDirection) -> Void
    var onEnded: (CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassThroughView()
        view.backgroundColor = .clear
        
        view.coordinator = context.coordinator
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Custom View per il "Pass Through"
    class PassThroughView: UIView {
        weak var coordinator: Coordinator?
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return nil
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window = window {
                coordinator?.setupGesture(on: window, targetedTo: self)
            } else {
                coordinator?.removeGesture()
            }
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: VerticalDragger
        weak var targetView: UIView?
        weak var window: UIWindow?
        weak var trackedScrollView: UIScrollView?
        var initialIsAtTop: Bool?
        var gesture: UIPanGestureRecognizer?
        
        init(parent: VerticalDragger) {
            self.parent = parent
        }
        
        func setupGesture(on window: UIWindow, targetedTo view: UIView) {
            self.window = window
            self.targetView = view
            
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            gesture.cancelsTouchesInView = false
            
            window.addGestureRecognizer(gesture)
            self.gesture = gesture
        }
        
        func removeGesture() {
            if let gesture = gesture {
                window?.removeGestureRecognizer(gesture)
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let targetView = targetView else { return }
            let translation = gesture.translation(in: targetView)
            let velocity = gesture.velocity(in: targetView)
            
            if let scrollView = trackedScrollView {
                if initialIsAtTop == nil {
                    initialIsAtTop = scrollView.contentOffset.y <= 0
                }
                let isPullingDown = translation.y > 0
                
                if isPullingDown && initialIsAtTop! {
                    scrollView.panGestureRecognizer.isEnabled = false
                }
            }
            
            if gesture.state == .changed {
                parent.onDrag(translation.y, parent.direction)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                if let scrollView = trackedScrollView {
                    scrollView.panGestureRecognizer.isEnabled = true
                    trackedScrollView = nil
                    initialIsAtTop = nil
                }
                
                let decelerationRate = 0.994
                let extra = (velocity.y / 1000.0) * decelerationRate / (1 - decelerationRate)
                let predictedEndTranslation = translation.y + extra
                
                parent.onEnded(translation.y, predictedEndTranslation)
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let window = window,
                  let targetView = targetView else { return false }
            
            let location = pan.location(in: targetView)
            if !targetView.bounds.contains(location) {
                return false
            }
            
            let velocity = pan.velocity(in: targetView)
            
            if abs(velocity.x) > abs(velocity.y) {
                return false
            }
            
            let locationInWindow = pan.location(in: window)
            
            var viewToCheck = window.hitTest(locationInWindow, with: nil)
            var foundScrollView: UIScrollView? = nil
            
            while let view = viewToCheck {
                if let sv = view as? UIScrollView {
                    if !sv.isPagingEnabled {
                        foundScrollView = sv
                        break
                    }
                }
                viewToCheck = view.superview
                
                if view == window { break }
            }
            
            if let scrollView = foundScrollView {
                self.trackedScrollView = scrollView
                
                if scrollView.contentOffset.y + scrollView.adjustedContentInset.top > 0 {
                    return false
                }
            }
            
            if parent.direction == .none {
                let translation = pan.translation(in: targetView)
                
                let isDraggingUp = translation.y > 0
                let isDraggingDown = translation.y < 0
                
                if isDraggingUp {
                    parent.direction = .up
                } else if isDraggingDown {
                    parent.direction = .down
                }
            }
            
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let touchedView = touch.view else { return true }
            
            if touchedView.tag == 422 {
                return false
            }
            
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if otherGestureRecognizer.view is UIControl {
                return true
            }
            
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                if scrollView.isPagingEnabled { return false }
                
                return true
            }
            return false
        }
    }
}
