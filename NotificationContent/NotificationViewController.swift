//
//  NotificationViewController.swift
//  NotificationContent
//
//  Created by Leonardo Rossi on 02/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UserNotifications
import UserNotificationsUI
import UnivrCore

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var hostingController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didReceive(_ notification: UNNotification) {
        if let oldController = hostingController {
            oldController.willMove(toParent: nil)
            oldController.view.removeFromSuperview()
            oldController.removeFromParent()
        }
        
        let eventName = notification.request.content.title
        
        var decodedItem: CalendarItem? = nil
        if let payload = notification.request.content.userInfo["itemPayload"] as? Data {
            decodedItem = try? JSONDecoder().decode(CalendarItem.self, from: payload)
        }
        
        let swiftUIView: AnyView
        if let item = decodedItem {
            swiftUIView = AnyView(CalendarItemPreview(item: item, internalItem: item.displayable, isNotificationContext: true))
        } else {
            swiftUIView = AnyView(FallbackNotificationPreviewView(eventName: eventName))
        }
        
        let newHostingController = UIHostingController(rootView: swiftUIView)
        hostingController = newHostingController
        
        addChild(newHostingController)
        view.addSubview(newHostingController.view)
        
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        newHostingController.view.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            newHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            newHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingExpandedSize.height)
        let fittingSize = newHostingController.sizeThatFits(in: targetSize)
        self.preferredContentSize = CGSize(width: view.bounds.width, height: fittingSize.height)
        
        newHostingController.didMove(toParent: self)
    }
}

struct FallbackNotificationPreviewView: View {
    let eventName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text(eventName)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Tocca per aprire i dettagli")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
