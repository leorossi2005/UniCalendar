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
        let deviceName = UIDevice.current.model
        
        #if targetEnvironment(simulator)
        let isSimulator = true
        let deviceModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        let isSimulator = false
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafeBytes(of: &systemInfo.machine) { rawBuffer in
            let bytes = rawBuffer.prefix(while: { $0 != 0 })
            return String(decoding: bytes, as: UTF8.self)
        }
        let deviceModel = model.isEmpty ? deviceName : model
        #endif
        
        return Device.Info(
            name: deviceName,
            model: deviceModel,
            isSimulator: isSimulator,
            os: Device.OS(name: osName, version: osVersion)
        )
    }
}
