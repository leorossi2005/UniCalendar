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
import EventKit
import UnivrCore
import CustomSheet

struct LessonDetailsView: View {
    @Environment(GlobalSheetManager.self) private var sheetManager
    
    @Binding var lesson: Lesson?
    
    @State private var showOriginalName: Bool = false
    @State private var calendarEvent: EKEvent?
    @State private var eventStore = EKEventStore()
    @State private var eventSaved: Bool = false
    
    let openAddToCalendar: Bool
    var onDismiss: (() -> Void)?
    
    var body: some View {
        if let lesson = lesson {
            ZStack {
                if let event = calendarEvent {
                    EventEditViewController(
                        event: event,
                        eventStore: eventStore,
                        onSaved: {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.1))
                                eventSaved = !openAddToCalendar
                            }
                        },
                        onDismiss: {
                            calendarEvent = nil
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        headerInfo(lesson: lesson)
                        detailRows(lesson: lesson)
                        StableMapView(
                            lesson: lesson,
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
                                    prepareAndShowEvent(for: lesson)
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
            .onChange(of: calendarEvent) { _, newValue in
                sheetManager.setLock(newValue != nil)
                if openAddToCalendar, newValue == nil, let onDismiss = onDismiss {
                    onDismiss()
                }
            }
            .task(id: eventSaved) {
                if eventSaved {
                    try? await Task.sleep(for: .seconds(2))
                    eventSaved = false
                }
            }
            .onAppear {
                if openAddToCalendar {
                    prepareAndShowEvent(for: lesson)
                }
            }
        }
    }
    
    // MARK: - Subviews
    private func headerInfo(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text((showOriginalName ? lesson.name : lesson.cleanName) ?? "")
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
                                .background(lesson.isCanceled ? Color(.systemBackground) : lesson.uiColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay {
                                    if lesson.isCanceled {
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
                text: "\(lesson.startTime.getCurrentWeekdaySymbol(length: .wide)), \(lesson.startTime.day) \(lesson.startTime.getCurrentMonthSymbol(length: .wide)) \(lesson.startTime.yearSymbol)",
                icon: "calendar"
            )
            rowLabel(
                text: "\(lesson.startTime.formatted(.dateTime.hour().minute())) - \(lesson.endTime.formatted(.dateTime.hour().minute())) (\(Duration.seconds(lesson.durationMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))))",
                icon: "clock.fill"
            )
            rowLabel(
                text: lesson.teachers.isEmpty ? "Non specificato" : LocalizedStringKey(lesson.teachers.joined(separator: ", ")),
                icon: !lesson.teachers.isEmpty && lesson.teachers.count > 1 ? "person.2.fill" : "person.fill"
            )
            rowLabel(
                text: "\(lesson.location?.classroom ?? "") \(lesson.location?.capacity.map { "(\($0) \(String(localized: "posti")))" } ?? "")",
                icon: "mappin"
            )
        }
    }
    
    private func rowLabel(text: LocalizedStringKey, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.headline)
    }
    
    // MARK: - Logic
    private func prepareAndShowEvent(for lesson: Lesson) {
        let newEvent = EKEvent(eventStore: eventStore)
        
        newEvent.title = lesson.cleanName
        if !lesson.teachers.isEmpty {
            newEvent.notes = lesson.teachers.count > 1 ? String(localized: "Docenti: \(lesson.teachers.joined(separator: ", "))") : String(localized: "Docente: \(lesson.teachers.joined(separator: ", "))")
        }
        newEvent.availability = .busy
        
        if let location = lesson.location {
            if let coords = location.coordinates {
                let structuredLocation = EKStructuredLocation(title: location.classroom)
                structuredLocation.geoLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
                newEvent.structuredLocation = structuredLocation
            } else {
                newEvent.location = location.classroom
            }
        }
        
        newEvent.startDate = lesson.startTime
        newEvent.endDate = lesson.endTime
        
        calendarEvent = newEvent
    }
}

// MARK: - Subviews
struct StableMapView: View {
    let lesson: Lesson
    @State var externalCoordinate: CLLocationCoordinate2D?
    @State var corderRadius: CGFloat
    @State private var isLoadingMap: Bool = false
    
    var body: some View {
        ZStack {
            if let coordinate = externalCoordinate {
                UIKitStaticMap(coordinate: coordinate, padding: corderRadius / 2, altitude: 600)
                mapAnnotationView(lesson: lesson)
                VStack {
                    HStack {
                        Spacer()
                        openInMapsButton(coordinate: coordinate, name: lesson.location?.classroom ?? "", color: lesson.uiColor)
                    }
                    Spacer()
                }
            } else if isLoadingMap {
                ProgressView()
            } else {
                ContentUnavailableView("Posizione non trovata\n\n\(lesson.location?.address ?? "")", systemImage: "mappin.slash")
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
                    .fill(lesson.uiColor)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 2)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.black)
            }
            
            Text(lesson.location?.address ?? "")
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
                GlassContainer(radii: .init(all: 25), tint: color.opacity(0.4)) {
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
        if let latitude = lesson.location?.coordinates?.latitude, let longitude = lesson.location?.coordinates?.longitude {
            await MainActor.run {
                self.externalCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.isLoadingMap = false
            }
            return
        }
        
        guard let address = lesson.location?.address, !address.isEmpty else { return }
        
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
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            LessonDetailsView(lesson: $lesson, openAddToCalendar: false)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
}
