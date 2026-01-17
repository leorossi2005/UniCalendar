//
//  EventEditView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/01/26.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import EventKitUI

struct EventEditViewController: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    var onSaved: () -> Void
    var onCanceled: () -> Void
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: EventEditViewController
        
        init(_ parent: EventEditViewController) {
            self.parent = parent
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true) {
                switch action {
                case .saved:
                    self.parent.onSaved()
                case .canceled:
                    self.parent.onCanceled()
                case .deleted:
                    break
                @unknown default:
                    break
                }
                
                self.parent.onDismiss()
            }
        }
    }
}
