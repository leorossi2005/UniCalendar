//
//  NotificationProvider.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

public struct NotificationProvider: Sendable {
    public var requestPermission: @Sendable () async -> Bool
    public var schedule: @Sendable (SavedNotification) async -> Bool
    public var cancel: @Sendable (String) -> Void
    
    public init(
        requestPermission: @escaping @Sendable () async -> Bool,
        schedule: @escaping @Sendable (SavedNotification) async -> Bool,
        cancel: @escaping @Sendable (String) -> Void
    ) {
        self.requestPermission = requestPermission
        self.schedule = schedule
        self.cancel = cancel
    }
}
