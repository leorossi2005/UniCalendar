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
    
    @Binding var selectedWeek: Date
    @Binding var selectedLesson: Lesson?
    @Binding var selectedRoom: String?
    @Binding var openAddToCalendar: Bool
    @Binding var openSettings: Bool
    @Binding var openWhatsNew: Bool
    @Binding var tempSettings: TempSettingsState
    
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
                    if openWhatsNew {
                        WhatsNewView()
                    } else if openSettings {
                        Settings(
                            selectedYear: $tempSettings.selectedYear,
                            selectedCourse: $tempSettings.selectedCourse,
                            selectedAcademicYear: $tempSettings.selectedAcademicYear,
                            matricola: $tempSettings.matricola
                        )
                        .ignoresSafeArea(.keyboard)
                    } else if selectedLesson != nil {
                        LessonDetailsView(lesson: $selectedLesson, openAddToCalendar: openAddToCalendar) {
                            sheetManager.setDetent(.small)
                            selectedLesson = nil
                            openAddToCalendar = false
                        }
                    } else {
                        RoomDetailsView() {
                            sheetManager.setDetent(.small)
                            selectedLesson = nil
                            openAddToCalendar = false
                        }
                    }
                }
                .id(openSettings)
                .opacity(min(max(largeOpacity, 0), 1))
                .allowsHitTesting(sheetManager.selectedDetent == .large)
                .frame(height: CustomSheetDetent.large.value)
            }
        }
    }
}
