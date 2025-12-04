//
//  AboutView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 15) {
                    Image("InternalIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 100 * 0.275, style: .continuous))
                    
                    VStack(spacing: 5) {
                        Text("UniVR Calendar")
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
                HStack {
                    Label("Leonardo Rossi", systemImage: "person")
                        .foregroundStyle(.primary)
                    //Image(systemName: "arrow.up.forward.square")
                    //    .foregroundStyle(.gray)
                    Spacer()
                    Text("Sviluppatore")
                        .foregroundStyle(.gray)
                }
                .onTapGesture {
                    // Dovrai aprire il tuo portfolio
                }
                HStack {
                    Label("Gaia", systemImage: "person")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Aiuto Sviluppo")
                        .foregroundStyle(.gray)
                }
                HStack {
                    Label("Nicola", systemImage: "person")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Aiuto Testing")
                        .foregroundStyle(.gray)
                }
                HStack {
                    Label("Edoardo", systemImage: "person")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Aiuto Testing")
                        .foregroundStyle(.gray)
                }
            } header: {
                Text("Crediti")
            } footer: {
                VStack(alignment: .leading) {
                    Text("Ci tengo a ringraziare immensamente tutte le persone che hanno collaborato in un qualsiasi modo alla creazione e allo sviluppo di questo progetto.")
                    Spacer()
                    Text("Grazie amore mio, ti amo tanto.")
                        .opacity(0.1)
                }
            }
        }
        .navigationTitle("Informazioni")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
