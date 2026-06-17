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
    public static var deviceCornerRadius: CGFloat = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
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
        
        let radii: [String: CGFloat] = [
            // iPhone 17 Series
            "iPhone18,2": 62.0,  // 17 Pro Max
            "iPhone18,1": 62.0,  // 17 Pro
            "iPhone18,3": 62.0,  // 17
            
            // iPhone 16 Series
            "iPhone17,2": 62.0,  // 16 Pro Max
            "iPhone17,1": 62.0,  // 16 Pro
            "iPhone17,4": 55.0,  // 16 Plus
            "iPhone17,3": 55.0,  // 16
            "iPhone17,5": 47.33, // 16e
            
            // iPhone 15 Series
            "iPhone16,2": 55.0,  // 15 Pro Max
            "iPhone16,1": 55.0,  // 15 Pro
            "iPhone15,5": 55.0,  // 15 Plus
            "iPhone15,4": 55.0,  // 15

            // iPhone 14 Series
            "iPhone15,3": 55.0,  // 14 Pro Max
            "iPhone15,2": 55.0,  // 14 Pro
            "iPhone14,8": 53.33, // 14 Plus
            "iPhone14,7": 47.33, // 14
            
            // iPhone 13 Series
            "iPhone14,3": 53.33, // 13 Pro Max
            "iPhone14,2": 47.33, // 13 Pro
            "iPhone14,5": 47.33, // 13
            "iPhone14,4": 44.0,  // 13 Mini

            // iPhone 12 Series
            "iPhone13,4": 53.33, // 12 Pro Max
            "iPhone13,3": 47.33, // 12 Pro
            "iPhone13,2": 47.33, // 12
            "iPhone13,1": 44.0,  // 12 Mini
            
            // iPhone 11 Series
            "iPhone12,5": 39.0, // 11 Pro Max
            "iPhone12,3": 39.0, // 11 Pro
            "iPhone12,1": 41.5, // 11
            
            // iPhone XR Series
            "iPhone11,8": 41.5,  // XR
            
            // iPhone XS Series
            "iPhone11,6": 39.0,  // XS Max Global
            "iPhone11,4": 39.0,  // XS Max
            "iPhone11,2": 39.0,  // XS
            
            // iPhone X Series
            "iPhone10,6": 39.0,  // X GSM
            "iPhone10,3": 39.0,  // X Global
            
            // iPhone Air Series
            "iPhone18,4": 62.0,  // Air
            
            // iPad Air
            "iPad15,6": 18.0,    // iPad Air 13-inch 7th Gen (WiFi+Cellular)
            "iPad15,5": 18.0,    // iPad Air 13-inch 7th Gen (WiFi)
            "iPad15,4": 18.0,    // iPad Air 11-inch 7th Gen (WiFi+Cellular)
            "iPad15,3": 18.0,    // iPad Air 11-inch 7th Gen (WiFi)
            "iPad14,11": 18.0,   // iPad Air 13 inch 6th Gen (WiFi+Cellular)
            "iPad14,10": 18.0,   // iPad Air 13 inch 6th Gen (WiFi)
            "iPad14,9": 18.0,    // iPad Air 11 inch 6th Gen (WiFi+Cellular)
            "iPad14,8": 18.0,    // iPad Air 11 inch 6th Gen (WiFi)
            "iPad13,17": 18.0,   // iPad Air 5th Gen (WiFi+Cellular)
            "iPad13,16": 18.0,   // iPad Air 5th Gen (WiFi)
            "iPad13,2": 18.0,    // iPad Air 4th Gen (WiFi+Cellular)
            "iPad13,1": 18.0,    // iPad Air 4th Gen (WiFi)
            "iPad11,4": 18.0,    // iPad Air 3rd Gen (WiFi+Cellular)
            "iPad11,3": 18.0,    // iPad Air 3rd Gen (WiFi)
            "iPad5,4": 18.0,     // iPad Air 2 (Cellular)
            "iPad5,3": 18.0,     // iPad Air 2 (WiFi)
            "iPad4,3": 18.0,     // 1st Gen iPad Air (China)
            "iPad4,2": 18.0,     // iPad Air (GSM+CDMA)
            "iPad4,1": 18.0,     // iPad Air (WiFi)
            
            // iPad Pro
            "iPad16,6": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi+Cellular)
            "iPad16,5": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi)
            "iPad14,6": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi+Cellular)
            "iPad14,5": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi)
            "iPad13,11": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,10": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,9": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad13,8": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad16,4": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi+Cellular)
            "iPad16,3": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi)
            "iPad13,7": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,6": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,5": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,4": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad8,12": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
            "iPad8,11": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi)
            "iPad14,4": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad14,3": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,10": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad8,9": 18.0,     //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,8": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,7": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
            "iPad8,6": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
            "iPad8,5": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi)
            "iPad8,4": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,3": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
            "iPad8,2": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi)
            "iPad8,1": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi)
            "iPad7,4": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi+Cellular)
            "iPad7,3": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi)
            "iPad7,2": 18.0,     //iPad Pro 2nd Gen (WiFi+Cellular)
            "iPad7,1": 18.0,     //iPad Pro 2nd Gen (WiFi)
            "iPad6,8": 18.0,     //iPad Pro (12.9 inch, WiFi+LTE)
            "iPad6,7": 18.0,     //iPad Pro (12.9 inch, WiFi)
            "iPad6,4": 18.0,     //iPad Pro (9.7 inch, WiFi+LTE)
            "iPad6,3": 18.0,     //iPad Pro (9.7 inch, WiFi)
        ]
        
        if let radius = radii[modelIdentifier] {
            return radius
        }
        
        let bottomSafeArea = UIApplication.shared.safeAreas.bottom
        return bottomSafeArea > 0 ? 47.33 : 0
    }()
}
