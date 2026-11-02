//
//  CalendarSheetContent.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 16/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct CalendarSheetContent: View {
    @Environment(GlobalSheetManager.self) private var sheetManager
    
    @Bindable var router: CalendarSheetRouter
    @Binding var selectedWeek: Date
    
    var body: some View {
        let windowHeight = UIApplication.shared.windowSize.height
        let largeHeight = CustomSheetDetent.large.value
        let mediumHeightHigh = CustomSheetDetent.medium.value * 1.05
        let mediumHeightLow = CustomSheetDetent.medium.value * 0.95
        let smallHeight = CustomSheetDetent.small.value
        let fadeRange: CGFloat = windowHeight * 0.05
        
        GeometryReader { proxy in
            let currentHeight = proxy.size.height
            
            let rawLargeOpacity = 1.0 - (Double(largeHeight - currentHeight) / Double(fadeRange))
            let rawMediumOpacity = 1.0 - ((currentHeight < mediumHeightHigh ? Double(mediumHeightLow - currentHeight) : Double(currentHeight - mediumHeightHigh)) / Double(fadeRange))
            let rawSmallOpacity = 1.0 - (Double(currentHeight - smallHeight) / Double(fadeRange))
            
            let isAnimatingDirectlyToLarge = sheetManager.previousDetent != .large && sheetManager.selectedDetent == .large && !sheetManager.isDragging
            let smallIsHidden = currentHeight > smallHeight + fadeRange || isAnimatingDirectlyToLarge
            let mediumIsHidden = currentHeight > mediumHeightHigh + fadeRange || isAnimatingDirectlyToLarge
            
            let finalSmallOpacity = smallIsHidden ? 0.0 : min(max(rawSmallOpacity, 0.0), 1.0)
            let finalMediumOpacity = mediumIsHidden ? 0.0 : min(max(rawMediumOpacity, 0.0), 1.0)
            let finalLargeOpacity = min(max(rawLargeOpacity, 0.0), 1.0)
            
            ZStack(alignment: .top) {
                FractionDatePickerContainer(selectedWeek: $selectedWeek)
                    .frame(height: smallHeight)
                    .opacity(finalSmallOpacity)
                    .allowsHitTesting(sheetManager.selectedDetent == .small)
                    .accessibilityHidden(sheetManager.selectedDetent != .small)
                
                DatePickerContainer(selectedWeek: $selectedWeek)
                    .opacity(finalMediumOpacity)
                    .allowsHitTesting(sheetManager.selectedDetent == .medium)
                    .accessibilityHidden(sheetManager.selectedDetent != .medium)
                
                NavigationStack {
                    if let notices = router.openAppNotices {
                       AppNoticeView(notices: notices) {
                           sheetManager.setDetent(.small)
                       }
                    } else if router.openWhatsNew {
                        WhatsNewView()
                    } else if router.openSettings {
                        Settings(tempSettings: $router.tempSettings)
                            .ignoresSafeArea(.keyboard)
                    } else if router.openAddPersonalEvent {
                        ManagePersonalEventView(selectedDate: selectedWeek, editingEvent: router.editingPersonalEvent) { newEvent in
                            if let newEvent = newEvent, router.selectedItem != nil {
                                router.selectedItem = .personal(newEvent)
                            }
                            
                            if router.selectedItem == nil {
                                sheetManager.setDetent(.small)
                            }
                            router.openAddPersonalEvent = false
                            router.editingPersonalEvent = nil
                        }
                    } else if let item = router.selectedItem {
                        CalendarItemDetailsView(item: item, internalItem: item.displayable, openAddToCalendar: router.openAddToCalendar, onDismiss: {
                            sheetManager.setDetent(.small)
                            router.selectedItem = nil
                            router.openAddToCalendar = false
                        }, onEdit: {
                            if case .personal(let event) = item {
                                router.routeToAddPersonalEvent(editing: event)
                            }
                        })
                    } else if let room = router.selectedRoom {
                        RoomDetailsView(room: room, selectedDate: selectedWeek)
                    }
                }
                .id(router.openSettings)
                .frame(height: largeHeight)
                .opacity(finalLargeOpacity)
                .allowsHitTesting(sheetManager.selectedDetent == .large)
                .accessibilityHidden(sheetManager.selectedDetent != .large)
            }
        }
    }
}
