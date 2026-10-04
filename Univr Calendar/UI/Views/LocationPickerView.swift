//
//  LocationPickerView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 01/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import MapKit
import UnivrCore

@Observable
class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private var completer = MKLocalSearchCompleter()
    var completions: [MKLocalSearchCompletion] = []
    
    var queryFragment: String = "" {
        didSet {
            if queryFragment.isEmpty {
                completions = []
            } else {
                completer.queryFragment = queryFragment
            }
        }
    }
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed: \(error.localizedDescription)")
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = LocationSearchService()
    @State private var searchText = ""
    @Binding var selectedLocation: EventLocation?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        List {
            Section {
                TextField("Cerca un indirizzo o luogo...", text: $searchText)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        service.queryFragment = newValue
                    }
                    .autocorrectionDisabled()
            }
            
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    Button(action: {
                        selectedLocation = EventLocation(name: searchText.trimmingCharacters(in: .whitespacesAndNewlines), coordinates: nil)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "mappin.slash")
                                .foregroundColor(.blue)
                            Text("Usa \"\(searchText)\" come luogo personalizzato")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            if !service.completions.isEmpty {
                Section("Risultati") {
                    ForEach(service.completions, id: \.self) { completion in
                        Button(action: {
                            resolve(completion)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Seleziona Luogo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isSearchFocused = true
        }
    }
    
    private func resolve(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let name = completion.title
        
        Task {
            do {
                let response = try await MKLocalSearch(request: request).start()
                if let item = response.mapItems.first, let location = item.placemark.location {
                    let coords = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    await MainActor.run {
                        selectedLocation = EventLocation(name: name, coordinates: coords)
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        selectedLocation = EventLocation(name: name, coordinates: nil)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    selectedLocation = EventLocation(name: name, coordinates: nil)
                    dismiss()
                }
            }
        }
    }
}
