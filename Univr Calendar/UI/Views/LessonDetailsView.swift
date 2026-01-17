//
//  LessonDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 24/11/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import MapKit
import CoreLocation
import UnivrCore
import EventKit

struct CalendarEventWrapper: Identifiable, Equatable {
    let id = UUID()
    let event: EKEvent
}

struct LessonDetailsView: View {
    @Binding var lesson: Lesson?
    @Binding var lockSheet: Bool
    
    @State private var showOriginalName: Bool = false
    @State private var calendarSheetWrapper: CalendarEventWrapper?
    @State private var eventStore = EKEventStore()
    @State private var currentLessonCoordinate: CLLocationCoordinate2D?
    @State private var eventSaved: Bool = false
    
    private var date: Date { lesson?.data.toDateModern() ?? Date() }
    private var backgroundColor: Color { Color(hex: lesson?.color ?? "") ?? Color(.systemGray6) }
    
    var body: some View {
        if let lesson = lesson {
            ZStack {
                if let wrapper = calendarSheetWrapper {
                    EventEditViewController(
                        event: wrapper.event,
                        eventStore: eventStore,
                        onSaved: {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.1))
                                eventSaved = true
                            }
                        },
                        onCanceled: {},
                        onDismiss: {
                            calendarSheetWrapper = nil
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        headerInfo(lesson: lesson)
                        detailRows(lesson: lesson)
                        StableMapView(
                            lesson: lesson,
                            externalCoordinate: $currentLessonCoordinate,
                            corderRadius: .deviceCornerRadius - 24 <= 0 ? 10 : .deviceCornerRadius - 24
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .ignoresSafeArea(edges: .bottom)
                    .onChange(of: lesson) {
                        showOriginalName = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                if !eventSaved {
                                    prepareAndShowEvent(for: lesson, coordinate: currentLessonCoordinate)
                                }
                            } label: {
                                Image(systemName: eventSaved ? "checkmark" : "calendar.badge.plus")
                                    .frame(width: 24, height: 24)
                                    .symbolReplace()
                                    .animation(.snappy, value: eventSaved)
                            }
                        }
                    }
                }
            }
            .onChange(of: calendarSheetWrapper) { _, newValue in
                lockSheet = newValue != nil
            }
            .task(id: eventSaved) {
                if eventSaved {
                    try? await Task.sleep(for: .seconds(2))
                    eventSaved = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    private func headerInfo(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(showOriginalName ? lesson.nameOriginal : lesson.cleanName)
                .font(.title2)
                .bold()
                .contentShape(.rect)
                .onTapGesture {
                    showOriginalName.toggle()
                }
            if !lesson.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(lesson.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(lesson.annullato ? Color(.secondarySystemBackground) : backgroundColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay {
                                    if lesson.annullato {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Color(white: 0.35), lineWidth: 0.5)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    private func detailRows(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            rowLabel(
                text: "\(date.getCurrentWeekdaySymbol(length: .wide)), \(date.day) \(date.getCurrentMonthSymbol(length: .wide)) \(date.yearSymbol)",
                icon: "calendar"
            )
            rowLabel(
                text: "\(lesson.orario) (\(lesson.durationCalculated))",
                icon: "clock.fill"
            )
            rowLabel(
                text: lesson.docente.isEmpty ? "Non specificato" : LocalizedStringKey(lesson.docente),
                icon: lesson.docente.contains(",") ? "person.2.fill" : "person.fill"
            )
            rowLabel(
                text: "\(lesson.formattedClassroom) \(lesson.capacity.map { "(\($0) \(String(localized: "posti")))" } ?? "")",
                icon: "mappin"
            )
        }
    }
    
    private func rowLabel(text: LocalizedStringKey, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.headline)
    }
    
    // MARK: - Logic
    private func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let calendar = Calendar.current
        
        let timeComponents = timeString.split(separator: ":").compactMap { Int($0) }
        
        if timeComponents.count >= 2 {
            return calendar.date(
                bySettingHour: timeComponents[0],
                minute: timeComponents[1],
                second: 0,
                of: date
            )
        }
        return date
    }
    
    private func prepareAndShowEvent(for lesson: Lesson, coordinate: CLLocationCoordinate2D? = nil) {
        let newEvent = EKEvent(eventStore: eventStore)
        
        newEvent.title = lesson.cleanName
        newEvent.notes = lesson.docente.contains(",") ? String(localized: "Docenti: \(lesson.docente)") : String(localized: "Docente: \(lesson.docente)")
        newEvent.availability = .busy
        
        if let coordinate = coordinate {
            let structuredLocation = EKStructuredLocation(title: lesson.formattedClassroom)
            structuredLocation.geoLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            newEvent.structuredLocation = structuredLocation
        } else {
            newEvent.location = lesson.formattedClassroom
        }
        
        let baseDate = lesson.data.toDateModern() ?? Date()
        let startTime = lesson.startTime
        let endTime = String(lesson.orario.split(separator: " - ").last ?? "")
        if let startDate = combineDateAndTime(date: baseDate, timeString: startTime), let endDate = combineDateAndTime(date: baseDate, timeString: endTime) {
            newEvent.startDate = startDate
            newEvent.endDate = endDate
        } else {
            newEvent.startDate = Date()
            newEvent.endDate = Date().addingTimeInterval(3600)
        }
        
        calendarSheetWrapper = CalendarEventWrapper(event: newEvent)
    }
}

// MARK: - Subviews
struct StableMapView: View {
    let lesson: Lesson
    @Binding var externalCoordinate: CLLocationCoordinate2D?
    
    @State var corderRadius: CGFloat
    @State private var isLoadingMap: Bool = false
    
    private var backgroundColor: Color { Color(hex: lesson.color) ?? Color(.systemGray6) }

    var body: some View {
        ZStack {
            if let coordinate = externalCoordinate {
                UIKitStaticMap(coordinate: coordinate, padding: corderRadius / 2, altitude: 600)
                mapAnnotationView(lesson: lesson)
                VStack {
                    HStack {
                        Spacer()
                        openInMapsButton(coordinate: coordinate, name: lesson.formattedClassroom, color: backgroundColor)
                    }
                    Spacer()
                }
            } else if isLoadingMap {
                ProgressView()
            } else {
                ContentUnavailableView("Posizione non trovata\n\n\(lesson.aula)", systemImage: "mappin.slash")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: corderRadius))
        .task(id: lesson.id) {
            await findLocation(for: lesson)
        }
    }
    
    private func mapAnnotationView(lesson: Lesson) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 2)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.black)
            }
            
            Text(lesson.aula)
                .frame(height: 10)
                .font(.caption)
                .bold()
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 1)
        }
        .offset(y: 10)
    }

    
    private func openInMapsButton(coordinate: CLLocationCoordinate2D, name: String, color: Color) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassContainer(radii: .init(tl: 25, tr: 25, bl: 25, br: 25), tint: color.opacity(0.4), lockGesture: true) {
                    Button(action: {
                        Haptics.play(.impact(weight: .light))
                        openMaps(coordinate: coordinate, name: name)
                    }) {
                        Image(systemName: "map.fill")
                    }
                    .tint(.black)
                    .buttonBorderShape(.circle)
                }
                .frame(width: 50, height: 50)
                .padding(corderRadius / 2)
            } else {
                Button(action: {
                    Haptics.play(.impact(weight: .light))
                    openMaps(coordinate: coordinate, name: name)
                }) {
                    Image(systemName: "map.fill")
                        .frame(width: 50, height: 50)
                }
                .tint(.black)
                .background(.ultraThinMaterial)
                .background(color.opacity(0.4))
                .clipShape(.circle)
                .padding(corderRadius / 2)
            }
        }
        .contentShape(.hoverEffect, .circle.inset(by: 7))
        .hoverEffect(.highlight)
    }
    
    private func findLocation(for lesson: Lesson) async {
        guard let address = lesson.indirizzoAula, !address.isEmpty else { return }
        
        if let cachedCoord = await CoordinateCache.shared.coordinate(for: address) {
            let clCoord = CLLocationCoordinate2D(latitude: cachedCoord.latitude, longitude: cachedCoord.longitude)
            await MainActor.run {
                self.externalCoordinate = clCoord
                self.isLoadingMap = false
            }
            return
        }
        
        self.isLoadingMap = true
        
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.geocodeAddressString(address)
            
            if let location = placemarks.first?.location {
                let coord = location.coordinate
                let cacheCoord = Coordinate(latitude: coord.latitude, longitude: coord.longitude)
                
                await CoordinateCache.shared.save(cacheCoord, for: address)
                await MainActor.run {
                    self.externalCoordinate = coord
                    self.isLoadingMap = false
                }
            } else {
                await MainActor.run { self.isLoadingMap = false }
            }
        } catch {
            print("Errore geocoding: \(error.localizedDescription)")
            await MainActor.run { self.isLoadingMap = false }
        }
    }
    
    private func openMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps()
    }
}

#Preview {
    @Previewable @Namespace var transition
    @Previewable @State var lesson: Lesson? = Lesson.sample
    @Previewable @State var lockSheet: Bool = false
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            LessonDetailsView(lesson: $lesson, lockSheet: $lockSheet)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
}
