//
//  WhatsNewView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/01/26.
//

import SwiftUI

// MARK: - Models

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let shortDescription: String
    let detailedDescription: String?
    
    init(icon: String, iconColor: Color, title: String, shortDescription: String, detailedDescription: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
    }
    
    var hasDetails: Bool {
        detailedDescription != nil && !detailedDescription!.isEmpty
    }
}

struct WhatsNewVersion: Identifiable {
    let id = UUID()
    let version: String
    let date: Date
    let headline: String?
    let features: [WhatsNewFeature]
    
    init(version: String, date: String, headline: String? = nil, features: [WhatsNewFeature]) {
        self.version = version
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.date(from: date) ?? Date()
        self.headline = headline
        self.features = features
    }
}

// MARK: - Version History

enum WhatsNewData {
    static let versions: [WhatsNewVersion] = [
        WhatsNewVersion(
            version: "0.9",
            date: "2026-01-15",
            headline: "iPad, Offline e un look tutto nuovo",
            features: [
                WhatsNewFeature(
                    icon: "ipad.landscape",
                    iconColor: .blue,
                    title: "Supporto Nativo per iPad",
                    shortDescription: "Esperienza ottimizzata per schermi grandi con layout adattivi e split view.",
                    detailedDescription: "Univr Calendar ora è completamente ottimizzato per iPad! Goditi un'esperienza fluida con layout adattivi, split view per visualizzare le settimane in landscape e interfaccia pensata appositamente per schermi più grandi. Ogni elemento è stato ripensato per sfruttare al meglio lo spazio disponibile."
                ),
                WhatsNewFeature(
                    icon: "wifi.slash",
                    iconColor: .orange,
                    title: "Modalità Offline",
                    shortDescription: "Consulta le tue lezioni anche senza connessione, sincronizzazione automatica.",
                    detailedDescription: "Niente più preoccupazioni per la connessione! L'app rileva automaticamente quando sei offline e ti permette di consultare le tue lezioni salvate localmente. Appena torni online, tutto si sincronizza automaticamente in background senza alcun intervento da parte tua."
                ),
                WhatsNewFeature(
                    icon: "sparkles",
                    iconColor: .purple,
                    title: "Interfaccia Rinnovata",
                    shortDescription: "Sheet personalizzate, animazioni fluide ed effetti liquid glass.",
                    detailedDescription: "Abbiamo sostituito i componenti standard con sheet personalizzate che offrono animazioni fluide, effetti liquid glass migliorati e un controllo totale sull'esperienza utente. Il risultato? Un'app ancora più bella e piacevole da usare, con transizioni morbide e feedback visivi eleganti."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .green,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Bug fix, performance migliorate e supporto per iOS 17/18.",
                    detailedDescription: "• Nuovo stile per le lezioni cancellate, più chiaro e intuitivo\n• Hover effects su iPad per un'interazione più naturale\n• Picker data e ora completamente ridisegnati con performance migliorate\n• Risolti numerosi bug legati alle animazioni e alla navigazione\n• Supporto ottimizzato per iOS 17, 18 e iPadOS\n• Miglioramenti alla visualizzazione dei dettagli delle lezioni e della mappa\n• Performance generali notevolmente migliorate"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.8",
            date: "2025-11-01",
            headline: "Calendario e notifiche ripensati",
            features: [
                WhatsNewFeature(
                    icon: "calendar",
                    iconColor: .red,
                    title: "Nuova Vista Calendario",
                    shortDescription: "Vista settimanale più intuitiva e leggibile.",
                    detailedDescription: "Visualizza le tue lezioni in una nuova vista calendario settimanale completamente ripensata. Navigazione più fluida, indicatori visivi migliorati e supporto per gesture intuitive."
                ),
                WhatsNewFeature(
                    icon: "bell.badge",
                    iconColor: .yellow,
                    title: "Notifiche Migliorate",
                    shortDescription: "Notifiche precise e personalizzabili.",
                    detailedDescription: "Ricevi notifiche più precise e personalizzabili per le tue lezioni. Scegli quando riceverle, personalizza il suono e gestisci le notifiche per singolo corso."
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.7",
            date: "2025-10-01",
            headline: "Calendario e notifiche ripensati",
            features: [
                WhatsNewFeature(
                    icon: "calendar",
                    iconColor: .red,
                    title: "Nuova Vista Calendario",
                    shortDescription: "Vista settimanale più intuitiva e leggibile.",
                    detailedDescription: "Visualizza le tue lezioni in una nuova vista calendario settimanale completamente ripensata. Navigazione più fluida, indicatori visivi migliorati e supporto per gesture intuitive."
                ),
                WhatsNewFeature(
                    icon: "bell.badge",
                    iconColor: .yellow,
                    title: "Notifiche Migliorate",
                    shortDescription: "Notifiche precise e personalizzabili.",
                    detailedDescription: "Ricevi notifiche più precise e personalizzabili per le tue lezioni. Scegli quando riceverle, personalizza il suono e gestisci le notifiche per singolo corso."
                )
            ]
        )
    ]
    
    static var latestVersion: WhatsNewVersion? {
        versions.first
    }
}

// MARK: - WhatsNewView

struct WhatsNewView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var previousVersionIndex: Int = 0
    @State private var selectedVersionIndex: Int = 0 {
        didSet { previousVersionIndex = oldValue }
    }
    @State private var expandedFeatures: Set<UUID> = []
    @State private var showAllExpanded: Bool = false
    
    private var currentVersion: WhatsNewVersion? {
        guard WhatsNewData.versions.indices.contains(selectedVersionIndex) else { return nil }
        return WhatsNewData.versions[selectedVersionIndex]
    }
    
    private var canGoNewer: Bool {
        selectedVersionIndex > 0
    }
    
    private var canGoOlder: Bool {
        selectedVersionIndex < WhatsNewData.versions.count - 1
    }
    
    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.05)
    }
    
    private let animation: Animation = .interactiveSpring(response: 0.25, dampingFraction: 1)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(WhatsNewData.versions.enumerated()), id: \.element.id) { index, version in
                    versionContent(version)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { selectedVersionIndex },
            set: { newValue in
                if let val = newValue {
                    selectedVersionIndex = val
                }
            }
        ))
        .animation(animation, value: selectedVersionIndex)
        .onChange(of: selectedVersionIndex) {
            expandedFeatures.removeAll()
            showAllExpanded = false
        }
        .onChange(of: expandedFeatures) {
            showAllExpanded = expandedFeatures.count == WhatsNewData.versions[selectedVersionIndex].features.count
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerView
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigatorArrow(direction: .left)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigator
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigatorArrow(direction: .right)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Novità ")
                
                Text(currentVersion?.version ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.largeTitle)
            .fontWeight(.bold)
            
            Text(currentVersion?.headline ?? " ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 70)
        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
        .animation(animation, value: selectedVersionIndex)
    }
    
    // MARK: - Version Content
    
    private func versionContent(_ version: WhatsNewVersion) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                Button {
                    guard let version = currentVersion else { return }
                    
                    Haptics.play(.selection)
                    if showAllExpanded {
                        expandedFeatures.removeAll()
                    } else {
                        version.features.filter { $0.hasDetails }.forEach {
                            expandedFeatures.insert($0.id)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showAllExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .symbolReplace()
                        
                        Text(showAllExpanded ? "Comprimi tutto" : "Espandi tutto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(
                        Capsule()
                            .fill(cardBackground)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                ForEach(version.features, id: \.id) { feature in
                    FeatureCard(
                        feature: feature,
                        isExpanded: expandedFeatures.contains(feature.id),
                        cardBackground: cardBackground,
                        animation: animation,
                        onToggle: {
                            if expandedFeatures.contains(feature.id) {
                                expandedFeatures.remove(feature.id)
                            } else {
                                expandedFeatures.insert(feature.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .animation(animation, value: expandedFeatures)
    }
    
    // MARK: - Version Navigator
    enum ArrowDirection {
        case left
        case right
    }
    
    private func navigatorArrow(direction: ArrowDirection) -> some View {
        Button {
            selectedVersionIndex -= direction == .left ? 1 : -1
        } label: {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .fontWeight(.semibold)
                .frame(width: 36, height: 36)
        }
        .opacity(direction == .left ? canGoNewer ? 1 : 0.3 : canGoOlder ? 1 : 0.3)
        .disabled(direction == .left ? !canGoNewer : !canGoOlder)
        .sensoryFeedback(.selection, trigger: selectedVersionIndex)
    }
    
    private var navigator: some View {
        ZStack {
            if let version = currentVersion {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ForEach(Array(WhatsNewData.versions.enumerated()), id: \.element.id) { index, v in
                            Circle()
                                .fill(index == selectedVersionIndex ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: index == selectedVersionIndex ? 8 : 6, height: index == selectedVersionIndex ? 8 : 6)
                        }
                    }
                    
                    Text(version.date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(animation, value: selectedVersionIndex)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: WhatsNewFeature
    let isExpanded: Bool
    let cardBackground: Color
    let animation: Animation
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Icon
                Image(systemName: feature.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(feature.iconColor)
                    .symbolEffect(.bounce, value: isExpanded)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(feature.iconColor.opacity(0.12))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(feature.shortDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                // Expand indicator
                if feature.hasDetails {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            // Expanded details
            if isExpanded, let details = feature.detailedDescription {
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)
                    
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            if feature.hasDetails {
                Haptics.play(.impact(flexibility: .soft))
                onToggle()
            }
        }
        .hoverEffect(.lift)
        .animation(animation, value: isExpanded)
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
