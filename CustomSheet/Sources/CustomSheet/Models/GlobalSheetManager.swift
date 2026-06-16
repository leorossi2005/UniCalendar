//
//  GlobalSheetManager.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

@MainActor
public enum CustomSheetDetent {
    case small, medium, large

    public var value: CGFloat {
        switch self {
        case .small:  return (((500 - 70) / 7) * 1.35) + 50
        case .medium: return 350 + 75
        case .large:
            let windowHeight = UIApplication.shared.windowSize.height
            let topSafeArea = UIApplication.shared.safeAreas.top
            let topMargin = topSafeArea > 0 ? topSafeArea : 20
            
            if UIDevice.isIpad {
                return windowHeight - 108
            } else {
                return windowHeight - topMargin
            }
        }
    }
}

@MainActor
@Observable
public class GlobalSheetManager {
    // MARK: - Sensori (Stati in sola lettura per l'utente)
    public internal(set) var isDragging: Bool = false
    public private(set) var locked: Bool = false
    public private(set) var selectedDetent: CustomSheetDetent
    public internal(set) var previousDetent: CustomSheetDetent?
    
    // MARK: - Motore Interno (Chiusure collegate dalla CustomSheet)
    var actionDismiss: (() -> Void)?
        
    // MARK: - Comandi Pubblici (Quelli che userai nella tua app)
    public func setDetent(_ detent: CustomSheetDetent) {
        selectedDetent = detent
    }
    
    public func dismiss() {
        actionDismiss?()
    }
    
    public func setLock(_ lock: Bool) {
        locked = lock
    }
    
    public init(initialDetent: CustomSheetDetent = .small) {
        self.selectedDetent = initialDetent
    }
}
