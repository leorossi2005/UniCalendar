//
//  NotificationProvider.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 10/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation
import UserNotifications
import UnivrCore

final class IOSNotificationService: Sendable {
    static func createProvider() -> NotificationProvider {
        return NotificationProvider(
            requestPermission: {
                do {
                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                    if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional { return true }
                    return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                } catch {
                    return false
                }
            },
            schedule: { notification in
                let content = UNMutableNotificationContent()
                content.title = notification.lessonName
                if notification.offsetMinutes == 0 {
                    content.body = "La lezione sta iniziando ora"
                } else {
                    content.body = "La lezione inizia tra \(notification.offsetMinutes) minuti"
                }
                content.sound = .default
                
                let triggerDate = notification.date.addingTimeInterval(TimeInterval(-notification.offsetMinutes * 60))
                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    return true
                } catch {
                    return false
                }
            },
            cancel: { id in
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
            }
        )
    }
}
