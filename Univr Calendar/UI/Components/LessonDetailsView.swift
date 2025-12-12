//
//  LessonDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 24/11/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UnivrCore

struct LessonDetailsView: View {
    @Environment(\.safeAreaInsets) var safeAreas
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selectedLesson: Lesson?
    @Binding var selectedDetent: PresentationDetent
    
    @State private var title: String = ""
    @State private var date: Date = .distantFuture
    
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isLoadingMap: Bool = false
    
    var body: some View {
        if let lesson = selectedLesson {
            VStack(alignment: .leading, spacing: 20) {
                headerInfo(lesson: lesson)
                detailRows(lesson: lesson)
                mapSection(lesson: lesson)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            .padding(.bottom, -safeAreas.bottom + 24)
            .frame(height: UIApplication.shared.screenSize.height - safeAreas.top - safeAreas.bottom)
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                setupInitialData(lesson: lesson)
            }
            .task(id: lesson.id) {
                await findLocation(for: lesson)
            }
        }
    }
    
    // MARK: - Subviews
    private func headerInfo(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2)
                .bold()
                .contentShape(.rect)
                .onTapGesture {
                    title = (title == lesson.cleanName) ? lesson.nameOriginal : lesson.cleanName
                }
            if !lesson.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(lesson.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: lesson.color).opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay {
                                    if Color(hex: lesson.color) == .white && colorScheme == .light {
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
    
    private func mapSection(lesson: Lesson) -> some View {
        ZStack {
            if let coordinate = coordinate {
                Map(position: $mapPosition) {
                    Annotation(lesson.aula, coordinate: coordinate) {
                        mapAnnotationView(lesson: lesson)
                    }
                }
                .mapControlVisibility(.hidden)
                .safeAreaPadding((.deviceCornerRadius - 24) / 2)
                .overlay(alignment: .topTrailing) {
                    openInMapsButton(coordinate: coordinate, name: lesson.formattedClassroom, color: Color(hex: lesson.color) ?? .clear)
                }
            } else if isLoadingMap {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            } else {
                ContentUnavailableView("Posizione non trovata\n\n\(lesson.aula)", systemImage: "mappin.slash")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 24))
    }
    
    private func mapAnnotationView(lesson: Lesson) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: lesson.color) ?? .black)
                .frame(width: 30, height: 30)
                .shadow(radius: 2)
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 10))
                .foregroundStyle(.black)
        }
    }
    
    private func openInMapsButton(coordinate: CLLocationCoordinate2D, name: String, color: Color) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: {
                    openMaps(coordinate: coordinate, name: name)
                }) {
                    Image(systemName: "map.fill")
                        .frame(width: 50, height: 50)
                }
                .tint(.black)
                .glassEffect(.clear.interactive().tint(color.opacity(0.5)))
                .buttonBorderShape(.circle)
                .padding((.deviceCornerRadius - 24) / 2)
            } else {
                Button(action: {
                    openMaps(coordinate: coordinate, name: name)
                }) {
                    Image(systemName: "map.fill")
                        .frame(width: 50, height: 50)
                }
                .tint(.black)
                .background(.ultraThinMaterial)
                .background(color.opacity(0.4))
                .clipShape(.circle)
                .padding((.deviceCornerRadius - 24) / 2)
            }
        }
    }
    
    // MARK: - Logic
    private func setupInitialData(lesson: Lesson) {
        if date == .distantFuture {
            date = lesson.data.toDateModern() ?? Date()
        }
        if title.isEmpty {
            title = lesson.cleanName
        }
    }
    
    private func findLocation(for lesson: Lesson) async {
        guard let address = lesson.indirizzoAula, !address.isEmpty else { return }
        
        if let cachedCoord = await CoordinateCache.shared.coordinate(for: address) {
            let clCoord = CLLocationCoordinate2D(latitude: cachedCoord.latitude, longitude: cachedCoord.longitude)
            await MainActor.run {
                updateMap(with: clCoord)
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
                    updateMap(with: coord)
                }
            } else {
                await MainActor.run {
                    self.isLoadingMap = false
                }
            }
        } catch {
            print("Errore geocoding: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingMap = false
            }
        }
    }
    
    @MainActor
    private func updateMap(with coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.mapPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        self.isLoadingMap = false
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
    @Previewable @State var selectedDetent: PresentationDetent = .large
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            LessonDetailsView(selectedLesson: $lesson, selectedDetent: $selectedDetent)
                .presentationDetents([.medium, .large], selection: $selectedDetent)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .sheetDesign(transition, sourceID: "", detent: $selectedDetent)
        }
}
