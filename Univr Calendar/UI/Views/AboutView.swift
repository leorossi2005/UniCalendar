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

// In AboutView.swift

struct AboutView: View {
    private static let iconSize: CGFloat = 100
    
    // Filtriamo la lista per rimuoverti dai crediti generici, visto che avrai la tua sezione
    private var contributorsList: [AppConstants.Contributor] {
        AppConstants.Credits.contributors.filter { $0.name != "Leonardo Rossi" }
    }

    var body: some View {
        List {
            // MARK: - Header App
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
            
            // MARK: - Nuova Sezione Sviluppatore
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Leonardo Rossi")
                                .font(.headline)
                            Text("Sviluppatore")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Avatar o Memoji opzionale qui
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                    }
                    
                    Divider()
                    
                    // Pulsanti Azione
                    HStack(spacing: 20) {
                        linkButton(title: "Sito Web", icon: "globe", url: AppConstants.URLs.portfolio)
                        linkButton(title: "Contattami", icon: "envelope.fill", url: AppConstants.URLs.email)
                        linkButton(title: "Seguimi", icon: "at", url: AppConstants.URLs.twitter)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Sviluppato da")
            }
            
            // MARK: - Sezione Feedback Rapido
            Section {
                Button {
                    UIApplication.shared.open(AppConstants.URLs.feedback)
                } label: {
                    Label("Invia Feedback o Segnalazione", systemImage: "ladybug.fill")
                }
            }
            
            // MARK: - Sezione Crediti (Filtrata)
            Section {
                ForEach(contributorsList) { credit in
                    infoRow(
                        name: LocalizedStringKey(credit.name),
                        role: LocalizedStringKey(credit.role),
                        link: credit.url // Riabilitato il link se presente
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
    
    private func linkButton(title: String, icon: String, url: URL) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func infoRow(name: LocalizedStringKey, role: LocalizedStringKey, link: URL? = nil) -> some View {
        HStack {
            Label(name, systemImage: "person")
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(role)
                    .foregroundStyle(.secondary)
                
                if link != nil {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle()) // Rende tutta la riga cliccabile
        .onTapGesture {
            if let link {
                UIApplication.shared.open(link)
            }
        }
    }
}
