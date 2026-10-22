//
//  SheetDragger.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 16/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UIKit.UIGestureRecognizerSubclass

enum CustomSheetDraggingDirection {
    case up, down, none
}

final class SheetPanGestureRecognizer: UIPanGestureRecognizer {
    var onTouchBegan: ((UITouch) -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible, let touch = touches.first {
            onTouchBegan?(touch)
        }
        super.touchesBegan(touches, with: event)
    }
}

struct SheetDragger: UIViewRepresentable {
    var direction: CustomSheetDraggingDirection = .none
    
    var onDrag: (CGFloat, CustomSheetDraggingDirection) -> Void
    var onEnded: (CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassThroughView()
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

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

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: SheetDragger
        weak var targetView: UIView?
        weak var window: UIWindow?
        weak var trackedScrollView: UIScrollView?
        
        var isDraggingSheet: Bool = false
        var canHandoffToSheet: Bool = false
        var gesture: SheetPanGestureRecognizer?
        
        init(parent: SheetDragger) {
            self.parent = parent
        }
        
        func setupGesture(on window: UIWindow, targetedTo view: UIView) {
            removeGesture()
            self.window = window
            self.targetView = view
            
            let gesture = SheetPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            gesture.delegate = self
            gesture.cancelsTouchesInView = false
            
            gesture.onTouchBegan = { [weak self] touch in
                self?.captureInitialScrollState(for: touch)
            }
            
            window.addGestureRecognizer(gesture)
            self.gesture = gesture
        }
        
        func removeGesture() {
            if let gesture = gesture {
                window?.removeGestureRecognizer(gesture)
            }
        }
        
        private func captureInitialScrollState(for touch: UITouch) {
            guard let window = window, let targetView = targetView else { return }
            
            let locationInTarget = touch.location(in: targetView)
            guard targetView.bounds.contains(locationInTarget) else {
                trackedScrollView = nil
                canHandoffToSheet = false
                return
            }
            
            let locationInWindow = touch.location(in: window)
            var viewToCheck = window.hitTest(locationInWindow, with: nil)
            var foundScrollView: UIScrollView? = nil
            
            while let view = viewToCheck {
                if let sv = view as? UIScrollView {
                    if !sv.isPagingEnabled && sv.isScrollEnabled {
                        foundScrollView = sv
                        break
                    }
                }
                viewToCheck = view.superview
                if view == window { break }
            }
            
            self.trackedScrollView = foundScrollView
            self.isDraggingSheet = false
            
            if let sv = foundScrollView {
                let topOffset = -sv.adjustedContentInset.top
                let deltaFromTop = sv.contentOffset.y - topOffset
                
                let isNearOrBouncingAtTop = (deltaFromTop >= -30.0 && deltaFromTop <= 6.0)
                self.canHandoffToSheet = isNearOrBouncingAtTop
            } else {
                self.canHandoffToSheet = true
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let targetView = targetView else { return }
            var translation = gesture.translation(in: targetView)
            let velocity = gesture.velocity(in: targetView)
            
            if let scrollView = trackedScrollView {
                let topOffset = -scrollView.adjustedContentInset.top
                
                if gesture.state == .began {
                    isDraggingSheet = false
                }
                
                if !isDraggingSheet {
                    if scrollView.contentOffset.y <= topOffset + 6.0 && translation.y > 0 {
                        isDraggingSheet = true
                        scrollView.showsVerticalScrollIndicator = false
                        
                        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: topOffset), animated: false)
                        
                        gesture.setTranslation(.zero, in: targetView)
                        translation = .zero
                    } else {
                        gesture.setTranslation(.zero, in: targetView)
                        translation = .zero
                    }
                } else {
                    if translation.y <= 0 {
                        isDraggingSheet = false
                        scrollView.showsVerticalScrollIndicator = true
                        
                        parent.onDrag(0, parent.direction)
                        
                        gesture.setTranslation(.zero, in: targetView)
                        translation = .zero
                    } else {
                        scrollView.contentOffset.y = topOffset
                    }
                }
            }
            
            if gesture.state == .changed {
                if trackedScrollView == nil || isDraggingSheet {
                    parent.onDrag(translation.y, parent.direction)
                }
            } else if gesture.state == .ended || gesture.state == .cancelled {
                parent.direction = .none
                let wasDraggingSheet = (trackedScrollView == nil) || isDraggingSheet
                
                if let scrollView = trackedScrollView {
                    scrollView.showsVerticalScrollIndicator = true
                    if wasDraggingSheet {
                        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.adjustedContentInset.top), animated: false)
                    }
                }
                
                trackedScrollView = nil
                isDraggingSheet = false
                canHandoffToSheet = false
                
                if wasDraggingSheet {
                    let decelerationRate = 0.994
                    let extra = (velocity.y / 1000.0) * decelerationRate / (1 - decelerationRate)
                    let predictedEndTranslation = translation.y + extra
                    
                    parent.onEnded(translation.y, predictedEndTranslation)
                } else {
                    parent.onEnded(0, 0)
                }
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let targetView = targetView else { return false }
            
            let location = pan.location(in: targetView)
            if !targetView.bounds.contains(location) {
                return false
            }
            
            let velocity = pan.velocity(in: targetView)
            if abs(velocity.x) > abs(velocity.y) {
                return false
            }
            
            if trackedScrollView != nil && !canHandoffToSheet {
                return false
            }
            
            if parent.direction == .none {
                let translation = pan.translation(in: targetView)
                if translation.y < 0 {
                    parent.direction = .up
                } else if translation.y > 0 {
                    parent.direction = .down
                }
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
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            let otherClass = String(describing: type(of: otherGestureRecognizer))
            let viewClass = otherGestureRecognizer.view.map { String(describing: type(of: $0)) } ?? ""
            
            let isStageManagerDrag = otherClass.contains("WindowScene") || otherClass.contains("DragInteraction") || otherClass.contains("SystemGesture")
            let isNavBarGesture = viewClass.contains("NavigationBar")
            
            if isStageManagerDrag || isNavBarGesture {
                return true
            }
            
            return false
        }
    }
}
