//
//  CustomSheet.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 13/06/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore
import CustomSheet

struct MainView: View {
    @State private var sheetManager = GlobalSheetManager()
    @State var isPresented: Bool = true
    
    @State var detents: [CustomSheetDetent] = [.small, .medium]
    
    // Test
    @State var selectedWeek: Date = Date()
    @State var selectedLesson: Lesson? = nil
    @State var openAddToCalendar: Bool = false
    @State var openSettings: Bool = true
    @State var openWhatsNew: Bool = false
    @State var tempSettings: TempSettingsState = .init()
    
    @State private var networkObserver = NetworkStateObserver(
        provider: IOSNetworkMonitor.createProvider()
    )
    
    var body: some View {
        NavigationStack {
            List {
                Toggle(isOn: $isPresented) {
                    Label("Open sheet", systemImage: "iphone")
                }
                Button {
                    openSettings = true
                    detents = [.small, .medium, .large]
                    sheetManager.setDetent(.large)
                } label: {
                    Label("Open Settings", systemImage: "gearshape.fill")
                }
                Button {
                    openWhatsNew = true
                    detents = [.small, .medium, .large]
                    sheetManager.setDetent(.large)
                } label: {
                    Label("Open News", systemImage: "sparkles")
                }
                Button {
                    selectedLesson = .sample
                    openAddToCalendar = true
                    detents = [.small, .medium, .large]
                    sheetManager.setDetent(.large)
                } label: {
                    Label("Open Calendar", systemImage: "calendar")
                }
                Button {
                    selectedLesson = .sample
                    detents = [.small, .medium, .large]
                    sheetManager.setDetent(.large)
                } label: {
                    Label("Open Lesson", systemImage: "graduationcap.fill")
                }
            }
            .navigationTitle("Sheet Testing View")
            .onChange(of: sheetManager.selectedDetent) { _, newDetent in
                if newDetent != .large {
                    openSettings = false
                    openWhatsNew = false
                    openAddToCalendar = false
                    selectedLesson = nil
                    detents = [.small, .medium]
                }
            }
        }
        .customSheet(isPresented: $isPresented, manager: sheetManager, detents: detents) {
            DynamicSheetContent(
                selectedWeek: $selectedWeek,
                selectedLesson: $selectedLesson,
                openAddToCalendar: $openAddToCalendar,
                openSettings: $openSettings,
                openWhatsNew: $openWhatsNew,
                tempSettings: $tempSettings
            )
        }
        .environment(networkObserver)
        .environment(UserSettings.shared)
    }
}

// MARK: - Subviews
struct DynamicSheetContent: View {
    @Environment(GlobalSheetManager.self) private var sheetManager
    
    @Binding var selectedWeek: Date
    @Binding var selectedLesson: Lesson?
    @Binding var openAddToCalendar: Bool
    @Binding var openSettings: Bool
    @Binding var openWhatsNew: Bool
    @Binding var tempSettings: TempSettingsState
    
    var padding: CGFloat {
        if #available(iOS 26, *) {
            8
        } else {
            0
        }
    }
    
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
            
            let smallIsHidden = currentHeight > smallHeight + fadeRange
            let mediumIsHidden = currentHeight > mediumHeightHigh + fadeRange
            ZStack(alignment: .top) {
                FractionDatePickerContainer(selectedWeek: $selectedWeek)
                    .opacity(smallIsHidden ? 0 : min(max(smallOpacity, 0), 1))
                    .allowsHitTesting(sheetManager.selectedDetent == .small)
                    .frame(maxWidth: 580 - padding * 2)
                
                DatePickerContainer(selectedWeek: $selectedWeek)
                    .opacity(mediumIsHidden ? 0 : min(max(mediumOpacity, 0), 1))
                    .allowsHitTesting(sheetManager.selectedDetent == .medium)
                    .frame(maxWidth: 580 - padding * 2)
                
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
                    } else {
                        LessonDetailsView(lesson: $selectedLesson, openAddToCalendar: openAddToCalendar) {
                            sheetManager.setDetent(.small)
                            selectedLesson = nil
                            openAddToCalendar = false
                        }
                        .opacity(min(max(largeOpacity, 0), 1))
                        .allowsHitTesting(sheetManager.selectedDetent == .large)
                    }
                }
                .id(openSettings)
                .opacity(min(max(largeOpacity, 0), 1))
                .allowsHitTesting(sheetManager.selectedDetent == .large)
                .frame(height: CustomSheetDetent.large.value)
                .frame(maxWidth: 580)
            }
        }
    }
}

#Preview {
    MainView()
}
