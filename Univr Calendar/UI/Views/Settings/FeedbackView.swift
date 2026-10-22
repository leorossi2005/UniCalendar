//
//  FeedbackView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 22/10/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import PhotosUI
import ImageIO
import UnivrCore
import CustomSheet

private struct Attachment {
    let data: Data
    let preview: Image
}

struct FeedbackView: View {
    @Environment(GlobalSheetManager.self) private var sheetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var details = ""
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var attachment: Attachment?
    @State private var isLoadingImage = false
    
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    private let device = FeedbackDeviceInfo.current
    
    private var isOffline: Bool { NetworkStatusMonitor.shared.status == .disconnected }
    private var isServerDown: Bool { ServerStatusCenter.shared.isUnreachable }
    
    private var lockSheet: Bool { attachment != nil || !title.isEmpty || !details.isEmpty }
    
    private var canSend: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= FeedbackLimits.titleMin
        && details.trimmingCharacters(in: .whitespacesAndNewlines).count >= FeedbackLimits.detailsMin
        && !isSending && !isLoadingImage && !isOffline && !isServerDown
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Es. Le aule non si aggiornano", text: $title)
                    .onChange(of: title) {
                        if title.count > FeedbackLimits.titleMax {
                            title = String(title.prefix(FeedbackLimits.titleMax))
                        }
                    }
            } header: {
                Text("Titolo")
            } footer: {
                counter(title.count, max: FeedbackLimits.titleMax)
            }
            
            Section {
                TextField("Descrivi il problema o il consiglio", text: $details, axis: .vertical)
                    .lineLimit(5...12)
                    .onChange(of: details) {
                        if details.count > FeedbackLimits.detailsMax {
                            details = String(details.prefix(FeedbackLimits.detailsMax))
                        }
                    }
            } header: {
                Text("Descrizione")
            } footer: {
                counter(details.count, max: FeedbackLimits.detailsMax)
            }
            
            Section {
                HStack(spacing: 12) {
                    Image(systemName: .deviceSymbol)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.deviceName)
                        Text(device.deviceIdentifier)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("App", value: "\(device.appVersion) (\(device.build))")
                LabeledContent("Sistema", value: "\(device.osName) \(device.osVersion)")
                attachmentRow
            } header: {
                Text("Allegati")
            } footer: {
                Text("Le informazioni sul dispositivo vengono incluse automaticamente per aiutarmi a riprodurre il problema. Lo screenshot è facoltativo.")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isSending)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Feedback")
                        .font(.headline)
                    if isOffline || isServerDown {
                        Section {
                            Label(
                                isOffline ? "Sei offline: non puoi inviare feedback." : "Server non raggiungibile, riprova più tardi.",
                                systemImage: isOffline ? "wifi.slash" : "network.slash"
                            )
                            .font(.caption2)
                            .foregroundStyle(isOffline ? .yellow : .orange)
                            .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if isSending {
                    ProgressView()
                } else {
                    Button {
                        Task { await send() }
                    } label: {
                        Label("Invia", systemImage: "paperplane.fill")
                    }
                    .labelStyle(.iconOnly)
                    .disabled(!canSend)
                }
            }
        }
        .task(id: pickerItem) {
            await loadAttachment()
        }
        .onChange(of: lockSheet) {
            sheetManager.setLock(lockSheet)
        }
        .onDisappear {
            sheetManager.setLock(false)
        }
        .alert("Grazie!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Il tuo feedback è stato inviato.")
        }
        .alert("Invio non riuscito", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var attachmentRow: some View {
        if let attachment {
            HStack {
                attachment.preview
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Screenshot allegato")
                    .foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive) {
                    pickerItem = nil
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images) { [isLoadingImage] in
                HStack {
                    Label("Aggiungi uno screenshot", systemImage: "photo.badge.plus")
                        .foregroundStyle(.primary)
                    Spacer()
                    if isLoadingImage { ProgressView() }
                }
            }
        }
    }
    
    private func counter(_ count: Int, max: Int) -> some View {
        Text("\(count)/\(max)")
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Logic
    
    private func send() async {
        guard canSend else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await FeedbackManager.submit(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                attachment: attachment?.data
            )
            Haptics.play(.success)
            showSuccess = true
        } catch is CancellationError {
            // niente da mostrare
        } catch let error as FeedbackError {
            Haptics.play(.error)
            switch error {
            case .rateLimited:
                errorMessage = String(localized: "Hai inviato troppi feedback in poco tempo. Riprova tra qualche minuto.")
            case .attachmentRejected:
                errorMessage = String(localized: "Il server ha rifiutato lo screenshot. Rimuovilo o scegline un altro.")
            }
        } catch {
            Haptics.play(.error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadAttachment() async {
        guard let item = pickerItem else {
            attachment = nil
            return
        }
        isLoadingImage = true
        defer { isLoadingImage = false }
        
        let jpeg = await Task.detached(priority: .userInitiated) { () -> Data? in
            guard let raw = try? await item.loadTransferable(type: Data.self) else { return nil }
            return Self.makeJPEG(from: raw)
        }.value
        
        guard !Task.isCancelled else { return }
        
        guard let jpeg, let uiImage = UIImage(data: jpeg) else {
            pickerItem = nil
            errorMessage = String(localized: "Impossibile usare questa immagine: non è leggibile o è troppo pesante.")
            return
        }
        
        attachment = Attachment(data: jpeg, preview: Image(uiImage: uiImage))
    }
    
    /// Ridimensiona (orientamento corretto) e comprime in JPEG, riducendo prima la qualità e poi
    /// la risoluzione finché non rientra in `FeedbackLimits.attachmentMaxBytes`.
    private nonisolated static func makeJPEG(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        for maxPixel in [1600, 1280, 1024, 800] {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            let image = UIImage(cgImage: cgImage)
            for quality in [0.7, 0.5, 0.35] {
                if let jpeg = image.jpegData(compressionQuality: quality),
                   jpeg.count <= FeedbackLimits.attachmentMaxBytes {
                    return jpeg
                }
            }
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
