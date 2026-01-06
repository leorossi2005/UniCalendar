//
//  AboutView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
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
                        link: /*credit.url*/ nil
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
    private func infoRow(name: LocalizedStringKey, role: LocalizedStringKey, link: URL? = nil) -> some View {
        HStack {
            Label(name, systemImage: "person")
                .foregroundStyle(.primary)
            if link != nil {
                Image(systemName: "arrow.up.forward.square")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(role)
                .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
        .onTapGesture {
            if let link {
                UIApplication.shared.open(link)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
