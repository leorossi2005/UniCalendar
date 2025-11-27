//
//  LessonDetailsView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 24/11/25.
//

import SwiftUI
import MapKit

struct LessonDetailsView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @Binding var selectedLesson: Lesson?
    @Binding var selectedDetent: PresentationDetent
    
    @State var title: String = ""
    
    // Stato per le coordinate e la posizione della camera
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isLoadingMap: Bool = false
    
    @State var safeAreas: UIEdgeInsets = .zero
    
    var body: some View {
        GeometryReader { proxy in
            let screenHeight = UIScreen.main.bounds.height
            
            if selectedLesson != nil {
                VStack {
                    Text(title)
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            if title == selectedLesson!.nomeInsegnamento {
                                title = selectedLesson!.nameOriginal
                            } else {
                                title = selectedLesson!.nomeInsegnamento
                            }
                        }
                    Spacer().frame(height: 20)
                    HStack {
                        Text(formatClassroom(classroom: selectedLesson!.aula))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color(white: 0.3))
                        Spacer()
                        Text(selectedLesson!.docente)
                    }
                    Spacer().frame(height: 20)
                    HStack {
                        Text(selectedLesson!.orario)
                        Spacer()
                        Text(selectedLesson!.data)
                    }
                    Spacer().frame(height: 40)
                    ZStack {
                        if let coordinate = coordinate {
                            Map(position: $mapPosition) {
                                Annotation(selectedLesson!.aula, coordinate: coordinate) {
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
                                    openMaps(coordinate: coordinate, name: selectedLesson!.aula)
                                }) {
                                    Image(systemName: "map.fill")
                                        .padding(8)
                                        .background(.thinMaterial)
                                        .clipShape(Circle())
                                        .padding(.deviceCornerRadius / 3.5)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 16))
                            .frame(maxHeight: .infinity)
                        } else if isLoadingMap {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 16))
                        } else {
                            ContentUnavailableView("Posizione non trovata", systemImage: "mappin.slash")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: .deviceCornerRadius - 16))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
                .padding(.bottom, -safeAreas.bottom + 16)
                .padding(.horizontal, 16)
                .frame(height: screenHeight - safeAreas.top - safeAreas.bottom)
                .multilineTextAlignment(.center)
                .onAppear {
                    //selectedLesson!.color = "CFRSCD"
                    title = selectedLesson!.nomeInsegnamento
                }
                .task(id: selectedLesson!.id) {
                    await findLocation()
                }
                .background {
                    ZStack {
                        Color.black.opacity(0.15)
                        LinearGradient(stops: [.init(color: (Color(hex: selectedLesson!.color) ?? .black).opacity(colorScheme == .light ? 0.6 : 0.3), location: 0), .init(color: (Color(hex: selectedLesson!.color) ?? .black).opacity(colorScheme == .light ? 0.1 : 0.05), location: 0.5)], startPoint: .top, endPoint: .bottom)
                    }
                    .frame(height: screenHeight)
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            safeAreas = UIApplication.shared.safeAreas
        }
    }
    
    private func formatClassroom(classroom: String) -> String {
        guard let bracketIndex = classroom.firstIndex(of: "[") else {
            return classroom
        }
        let index = classroom.index(bracketIndex, offsetBy: -2, limitedBy: classroom.startIndex) ?? classroom.startIndex
        return String(classroom[...index])
    }
    
    // Funzione per Geocodificare l'indirizzo
    private func findLocation() async {
        // Resetta stato
        self.coordinate = nil
        
        guard let address = selectedLesson!.indirizzoAula else {
            print("Nessun indirizzo trovato nel campo infoAulaHTML")
            return
        }
        
        self.isLoadingMap = true
        let geocoder = CLGeocoder()
        
        do {
            // Aggiungiamo "Verona, Italy" se non presente per aiutare il geocoder,
            // anche se nel tuo esempio "Verona" c'è già.
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
