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
    
    // Quali angoli sono "contro il bordo" (quindi squadrati)?
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
    
    // Tolleranza per il confronto (per gestire piccole imprecisioni)
    private let tolerance: CGFloat = 1.0
    
    func startObserving(window: UIWindow) {
        guard displayLink == nil else { return }
        observedWindow = window
        
        displayLink = CADisplayLink(target: self, selector: #selector(checkFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 15, preferred: 15)
        displayLink?.add(to: .main, forMode: .common)
        
        // Check iniziale
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
        
        // Prendi il frame in coordinate fisse (fisiche)
        let fixedSpace = windowScene.screen.fixedCoordinateSpace
        let frameInFixed = window.convert(window.bounds, to: fixedSpace)
        let screenFixed = fixedSpace.bounds
        
        // Aggiorna solo se cambiato
        guard frameInFixed != windowFrame || screenFixed != screenBounds else { return }
        
        windowFrame = frameInFixed
        screenBounds = screenFixed
        
        // Calcola i bordi in coordinate fisiche
        let touchesFixedTop = frameInFixed.minY <= tolerance
        let touchesFixedBottom = abs(frameInFixed.maxY - screenFixed.height) <= tolerance
        let touchesFixedLeft = frameInFixed.minX <= tolerance
        let touchesFixedRight = abs(frameInFixed.maxX - screenFixed.width) <= tolerance
        
        // Mappa alle coordinate UI in base all'orientamento
        let orientation = windowScene.interfaceOrientation
        
        let newEdges: WindowEdges
        switch orientation {
        case .portrait:
            // Dritto: nessuna trasformazione
            newEdges = WindowEdges(
                touchesTop: touchesFixedTop,
                touchesBottom: touchesFixedBottom,
                touchesLeft: touchesFixedLeft,
                touchesRight: touchesFixedRight
            )
        case .portraitUpsideDown:
            // Sottosopra: tutto invertito
            newEdges = WindowEdges(
                touchesTop: touchesFixedBottom,
                touchesBottom: touchesFixedTop,
                touchesLeft: touchesFixedRight,
                touchesRight: touchesFixedLeft
            )
        case .landscapeLeft:
            // Home button a sinistra
            newEdges = WindowEdges(
                touchesTop: touchesFixedLeft,
                touchesBottom: touchesFixedRight,
                touchesLeft: touchesFixedBottom,
                touchesRight: touchesFixedTop
            )
        case .landscapeRight:
            // Home button a destra
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
            print("📐 Window edges changed:")
            print("   Top: \(newEdges.touchesTop), Bottom: \(newEdges.touchesBottom)")
            print("   Left: \(newEdges.touchesLeft), Right: \(newEdges.touchesRight)")
            print("   Corners - TL: \(newEdges.topLeftSquare), TR: \(newEdges.topRightSquare)")
            print("            BL: \(newEdges.bottomLeftSquare), BR: \(newEdges.bottomRightSquare)")
        }
    }
}
