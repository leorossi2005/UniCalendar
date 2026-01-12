//
//  AboutView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct AboutView: View {
    private static let iconSize: CGFloat = 100
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 15) {
                    Image("InternalIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Self.iconSize, height: Self.iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: Self.iconSize * 0.225, style: .continuous))
                    
                    VStack(spacing: 5) {
                        Text(AppConstants.AppInfo.appName)
                            .font(.title2)
                            .bold()
                        
                        Text(Bundle.main.appVersion)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)
            
            Section {
                ForEach(AppConstants.Credits.contributors) { credit in
                    infoRow(
                        name: LocalizedStringKey(credit.name),
                        role: LocalizedStringKey(credit.role),
                        link: credit.url,
                        image: credit.image
                    )
                }
            } header: {
                Text("Crediti")
            } footer: {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Ci tengo a ringraziare immensamente tutte le persone che hanno collaborato in un qualsiasi modo alla creazione e allo sviluppo di questo progetto.")
                    Text("Grazie amore mio, ti amo tanto.")
                        .font(.caption2)
                        .opacity(0.15)
                }
            }
        }
        .navigationTitle("Informazioni")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    private func infoRow(name: LocalizedStringKey, role: LocalizedStringKey, link: URL?, image: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if image.isEmpty {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
            } else {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
