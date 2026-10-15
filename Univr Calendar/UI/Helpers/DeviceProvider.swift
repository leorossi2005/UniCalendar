//
//  DeviceProvider.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import UIKit
import UnivrCore

final class IOSDeviceService: Sendable {
    static func info() -> Device.Info {        
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        let osName = UIDevice.current.systemName
        
        let deviceModel: String = {
            #if targetEnvironment(simulator)
            if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return "\(sim); Simulator"
            }
            return "Simulator"
            #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let model = withUnsafeBytes(of: &systemInfo.machine) { rawBuffer in
                let bytes = rawBuffer.prefix(while: { $0 != 0 })
                return String(decoding: bytes, as: UTF8.self)
            }
            return model.isEmpty ? UIDevice.current.model : model
            #endif
        }()
        
        return Device.Info(
            model: deviceModel,
            os: Device.OS(name: osName, version: osVersion)
        )
    }
}
