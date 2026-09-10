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
        GeometryReader { proxy in
            let currentHeight = proxy.size.height
            let windowHeight = UIApplication.shared.windowSize.height
            
            let largeHeight = CustomSheetDetent.large.value
            let mediumHeightHigh = CustomSheetDetent.medium.value * 1.05
            let mediumHeightLow = CustomSheetDetent.medium.value * 0.95
            let smallHeight = CustomSheetDetent.small.value
            let fadeRange: CGFloat = windowHeight * 0.05
            
            let largeOpacity = 1.0 - (Double(largeHeight - currentHeight) / Double(fadeRange))
            let mediumOpacity = 1.0 - ((currentHeight < mediumHeightHigh ? Double(mediumHeightLow - currentHeight) : Double(currentHeight - mediumHeightHigh)) / Double(fadeRange))
            let smallOpacity = 1.0 - (Double(currentHeight - smallHeight) / Double(fadeRange))
            
            let smallIsHidden = currentHeight > smallHeight + fadeRange || sheetManager.previousDetent != .large && sheetManager.selectedDetent == .large && !sheetManager.isDragging
            let mediumIsHidden = currentHeight > mediumHeightHigh + fadeRange || sheetManager.previousDetent != .large && sheetManager.selectedDetent == .large && !sheetManager.isDragging
            ZStack(alignment: .top) {
                FractionDatePickerContainer(selectedWeek: $selectedWeek)
                    .opacity(smallIsHidden ? 0 : min(max(smallOpacity, 0), 1))
                    .allowsHitTesting(sheetManager.selectedDetent == .small)
                    .frame(height: CustomSheetDetent.small.value)
                
                DatePickerContainer(selectedWeek: $selectedWeek)
                    .opacity(mediumIsHidden ? 0 : min(max(mediumOpacity, 0), 1))
                    .allowsHitTesting(sheetManager.selectedDetent == .medium)
                
                NavigationStack {
                    if router.openWhatsNew {
                        WhatsNewView()
                    } else if router.openSettings {
                        Settings(
                            selectedYear: $router.tempSettings.selectedYear,
                            selectedCourse: $router.tempSettings.selectedCourse,
                            selectedAcademicYear: $router.tempSettings.selectedAcademicYear,
                            matricola: $router.tempSettings.matricola
                        )
                        .ignoresSafeArea(.keyboard)
                    } else if let lesson = router.selectedLesson {
                        LessonDetailsView(lesson: lesson, openAddToCalendar: router.openAddToCalendar) {
                            sheetManager.setDetent(.small)
                            router.selectedLesson = nil
                            router.openAddToCalendar = false
                        }
                    } else if let room = router.selectedRoom {
                        RoomDetailsView(room: room, selectedDate: selectedWeek)
                    }
                }
                .id(router.openSettings)
                .opacity(min(max(largeOpacity, 0), 1))
                .allowsHitTesting(sheetManager.selectedDetent == .large)
                .frame(height: CustomSheetDetent.large.value)
            }
        }
    }
}
