//
//  LessonDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 24/11/25.
//

import SwiftUI
import MapKit
import UnivrCore

struct LessonDetailsView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @Binding var selectedLesson: Lesson?
    @Binding var selectedDetent: PresentationDetent
    
    @State var title: String = ""
    @State private var cleanText: String = ""
    @State private var tags: [String] = []
    @State private var date: Date = .now
    
    // Stato per le coordinate e la posizione della camera
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isLoadingMap: Bool = false
    
    @State var safeAreas: UIEdgeInsets = .zero
    
    var body: some View {
        if let lesson = selectedLesson {
            GeometryReader { proxy in
                let screenHeight = UIScreen.main.bounds.height
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(title)
                        .font(.title2)
                        .bold()
                        .onTapGesture {
                            if title == cleanText {
                                title = lesson.nameOriginal
                            } else {
                                title = cleanText
                            }
                        }
                    if !tags.isEmpty {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background {
                                        Color(hex: lesson.color)
                                            .opacity(0.2)
                                    }
                                    .cornerRadius(7)
                            }
                        }
                    }
                    Label("\(date.getCurrentWeekdaySymbol(length: .full)), \(date.day) \(date.getCurrentMonthSymbol(length: .full)) \(date.yearSymbol)", systemImage: "calendar")
                        .font(.headline)
                    Label("\(lesson.orario) (\(lesson.durationCalculated))", systemImage: "clock.fill")
                        .font(.headline)
                    Label("\(lesson.docente.isEmpty ? String(localized: "Non specificato") : lesson.docente)", systemImage: lesson.docente.contains(",") ? "person.2.fill" : "person.fill")
                        .font(.headline)
                    Label("\(lesson.formattedClassroom) \(lesson.capacity != nil ? "(\(lesson.capacity!) \(String(localized: "posti")))" : "")", systemImage: "mappin")
                        .font(.headline)
                    ZStack {
                        if let coordinate = coordinate {
                            Map(position: $mapPosition) {
                                Annotation(lesson.aula, coordinate: coordinate) {
                                    ZStack {
                                        Circle().fill(.white)
                                            .frame(width: 30, height: 30)
                                            .shadow(radius: 2)
                                        Image(systemName: "graduationcap.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.blue)
                                            .background(.white)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            // Aggiunge un controllo per aprire nelle mappe di Apple
                            .safeAreaPadding(.deviceCornerRadius / 3.5)
                            .overlay(alignment: .topTrailing) {
                                Button(action: {
                                    openMaps(coordinate: coordinate, name: lesson.aula)
                                }) {
                                    Image(systemName: "map.fill")
                                        .padding(8)
                                        .background(.thinMaterial)
                                        .clipShape(Circle())
                                        .padding(.deviceCornerRadius / 3.5)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 24))
                            .frame(maxHeight: .infinity)
                        } else if isLoadingMap {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 24))
                        } else {
                            ContentUnavailableView("Posizione non trovata\n\n\(lesson.aula)", systemImage: "mappin.slash")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 24))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .padding(.bottom, -safeAreas.bottom + 24)
                .padding(.horizontal, 24)
                .frame(height: screenHeight - safeAreas.top - safeAreas.bottom)
                .multilineTextAlignment(.leading)
                .onAppear {
                    if cleanText.isEmpty {
                        if let lesson = selectedLesson {
                            let result = LessonNameFormatter.format(lesson.nomeInsegnamento)
                            cleanText = result.cleanText
                            tags = result.tags
                            
                            date = lesson.data.date(format: "dd-MM-yyyy") ?? Date()
                        }
                    }
                    
                    //lesson.color = "CFRSCD"
                    title = cleanText
                }
                .task(id: lesson.id) {
                    await findLocation()
                }
                .ignoresSafeArea()
            }
            .onAppear {
                safeAreas = UIApplication.shared.safeAreas
            }
        }
    }
    
    // Funzione per Geocodificare l'indirizzo
    private func findLocation() async {
        // Resetta stato
        self.coordinate = nil
        
        guard let lesson = selectedLesson, let address = lesson.indirizzoAula else {
            print("No address found")
            return
        }
        
        self.isLoadingMap = true
        let geocoder = CLGeocoder()
        
        do {
            let searchString = address
            
            let placemarks = try await geocoder.geocodeAddressString(searchString)
            
            if let location = placemarks.first?.location {
                withAnimation {
                    self.coordinate = location.coordinate
                    self.mapPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                    self.isLoadingMap = false
                }
            }
        } catch {
            print("Errore geocoding: \(error.localizedDescription)")
            self.isLoadingMap = false
        }
    }
    
    // Helper per aprire Mappe di Apple
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
                .sheetDesign(transition, detent: $selectedDetent)
        }
}
