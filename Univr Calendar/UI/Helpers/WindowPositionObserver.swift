//
//  WindowPositionObserver.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 13/12/25.
//

import SwiftUI

// MARK: - Window Accessor
struct WindowAccessor: UIViewRepresentable {
    let onWindow: (UIWindow) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let window = uiView.window {
                onWindow(window)
            }
        }
    }
}

// MARK: - Edge Detection
struct WindowEdges: Equatable {
    var touchesTop: Bool = false
    var touchesBottom: Bool = false
    var touchesLeft: Bool = false
    var touchesRight: Bool = false
    
    var isFullscreen: Bool {
        touchesTop && touchesBottom && touchesLeft && touchesRight
    }
    
    var isFloating: Bool {
        !touchesTop && !touchesBottom && !touchesLeft && !touchesRight
    }
    
    var topLeftSquare: Bool { touchesTop && touchesLeft }
    var topRightSquare: Bool { touchesTop && touchesRight }
    var bottomLeftSquare: Bool { touchesBottom && touchesLeft }
    var bottomRightSquare: Bool { touchesBottom && touchesRight }
}

@Observable
final class WindowPositionObserver {
    var edges = WindowEdges()
    var windowFrame: CGRect = .zero
    var screenBounds: CGRect = .zero
    
    private var displayLink: CADisplayLink?
    private weak var observedWindow: UIWindow?
    
    private let tolerance: CGFloat = 1.0
    
    func startObserving(window: UIWindow) {
        guard displayLink == nil else { return }
        observedWindow = window
        
        displayLink = CADisplayLink(target: self, selector: #selector(checkFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 15, preferred: 15)
        displayLink?.add(to: .main, forMode: .common)
        
        checkFrame()
    }
    
    func stopObserving() {
        displayLink?.invalidate()
        displayLink = nil
        observedWindow = nil
    }
    
    @objc private func checkFrame() {
        guard let window = observedWindow,
              let windowScene = window.windowScene else { return }
        
        let fixedSpace = windowScene.screen.fixedCoordinateSpace
        let frameInFixed = window.convert(window.bounds, to: fixedSpace)
        let screenFixed = fixedSpace.bounds
        
        guard frameInFixed != windowFrame || screenFixed != screenBounds else { return }
        
        windowFrame = frameInFixed
        screenBounds = screenFixed
        
        let touchesFixedTop = frameInFixed.minY <= tolerance
        let touchesFixedBottom = abs(frameInFixed.maxY - screenFixed.height) <= tolerance
        let touchesFixedLeft = frameInFixed.minX <= tolerance
        let touchesFixedRight = abs(frameInFixed.maxX - screenFixed.width) <= tolerance
        
        let orientation = windowScene.interfaceOrientation
        
        let newEdges: WindowEdges
        switch orientation {
        case .portrait:
            newEdges = WindowEdges(
                touchesTop: touchesFixedTop,
                touchesBottom: touchesFixedBottom,
                touchesLeft: touchesFixedLeft,
                touchesRight: touchesFixedRight
            )
        case .portraitUpsideDown:
            newEdges = WindowEdges(
                touchesTop: touchesFixedBottom,
                touchesBottom: touchesFixedTop,
                touchesLeft: touchesFixedRight,
                touchesRight: touchesFixedLeft
            )
        case .landscapeLeft:
            newEdges = WindowEdges(
                touchesTop: touchesFixedLeft,
                touchesBottom: touchesFixedRight,
                touchesLeft: touchesFixedBottom,
                touchesRight: touchesFixedTop
            )
        case .landscapeRight:
            newEdges = WindowEdges(
                touchesTop: touchesFixedRight,
                touchesBottom: touchesFixedLeft,
                touchesLeft: touchesFixedTop,
                touchesRight: touchesFixedBottom
            )
        default:
            newEdges = WindowEdges(
                touchesTop: touchesFixedTop,
                touchesBottom: touchesFixedBottom,
                touchesLeft: touchesFixedLeft,
                touchesRight: touchesFixedRight
            )
        }
        
        if newEdges != edges {
            edges = newEdges
        }
    }
}
