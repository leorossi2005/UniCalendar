//
//  Extensions.swift
//  CustomSheet
//
//  Created by Leonardo Rossi on 14/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

@MainActor
extension UIApplication {
    public var safeAreas: UIEdgeInsets {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets ?? .zero
    }
    
    public var windowSize: CGRect {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.bounds ?? .zero
    }
}

@MainActor
extension UIDevice {
    public static var isIpad: Bool {
        current.userInterfaceIdiom == .pad
    }
}

@MainActor
extension CGFloat {
    public static let deviceCornerRadius: CGFloat = {
        let modelIdentifier: String = {
            if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return simulatorModel
            }
            
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            return machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        }()
        
        if let radius = DeviceCornerRadii.all[modelIdentifier] {
            return radius
        }
        
        let bottomSafeArea = UIApplication.shared.safeAreas.bottom
        guard bottomSafeArea > 0 else { return 0 }
        return UIDevice.isIpad ? 18.0 : 55.0
    }()
}
