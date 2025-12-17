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
    
    @State private var title: String = ""
    @State private var date: Date = .distantFuture
    
    var body: some View {
        if let lesson = selectedLesson {
            VStack(alignment: .leading, spacing: 20) {
                headerInfo(lesson: lesson)
                detailRows(lesson: lesson)
                StableMapView(lesson: lesson)
            }
            .frame(
                width: UIApplication.shared.screenSize.width - 48,
                height: UIApplication.shared.screenSize.height - safeAreas.top - safeAreas.bottom - 40,
            )
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .onAppear {
                setupInitialData(lesson: lesson)
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
    
    // MARK: - Logic
    private func setupInitialData(lesson: Lesson) {
        if date == .distantFuture {
            date = lesson.data.toDateModern() ?? Date()
        }
        if title.isEmpty || title != lesson.cleanName {
            title = lesson.cleanName
        }
    }
}

// MARK: - Subviews
struct StableMapView: View {
    let lesson: Lesson
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isLoadingMap: Bool = false

    var body: some View {
        ZStack {
            if let coordinate = coordinate {
                UIKitStaticMap(coordinate: coordinate, padding: (.deviceCornerRadius - 24) / 2)
                mapAnnotationView(lesson: lesson)
                VStack {
                    HStack {
                        Spacer()
                        openInMapsButton(coordinate: coordinate, name: lesson.formattedClassroom, color: Color(hex: lesson.color) ?? .clear)
                    }
                    Spacer()
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
        .task(id: lesson.id) {
            await findLocation(for: lesson)
        }
    }
    
    private func mapAnnotationView(lesson: Lesson) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: lesson.color) ?? .black)
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
                Button(action: {
                    openMaps(coordinate: coordinate, name: name)
                }) {
                    Image(systemName: "map.fill")
                        .frame(width: 50, height: 50)
                }
                .tint(.black)
                .background {
                    GlassContainer(radii: .init(tl: 25, tr: 25, bl: 25, br: 25), style: .clear, tint: color.opacity(0.4))
                }
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
    
    private func findLocation(for lesson: Lesson) async {
        guard let address = lesson.indirizzoAula, !address.isEmpty else { return }
        
        if let cachedCoord = await CoordinateCache.shared.coordinate(for: address) {
            let clCoord = CLLocationCoordinate2D(latitude: cachedCoord.latitude, longitude: cachedCoord.longitude)
            await MainActor.run {
                self.coordinate = clCoord
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
                    self.coordinate = coord
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
    //@Previewable @State var selectedDetent: PresentationDetent = .large
    
    Text("")
        .sheet(isPresented: .constant(true)) {
            LessonDetailsView(selectedLesson: $lesson)
                //.presentationDetents([.medium, .large], selection: $selectedDetent)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                //.sheetDesign(transition, sourceID: "", detent: $selectedDetent)
        }
}
