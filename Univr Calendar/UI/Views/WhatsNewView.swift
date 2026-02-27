//
//  WhatsNewView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/01/26.
//

import SwiftUI
import UnivrCore

// MARK: - WhatsNewView
struct WhatsNewView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var previousVersionIndex: Int = 0
    @State private var selectedVersionIndex: Int = 0
    @State private var expandedFeatures: Set<UUID> = []
    @State private var showAllExpanded: Bool = false
    @State private var dotWindowStart: Int = 0
    
    private var currentVersion: WhatsNewVersion? {
        guard AppConstants.WhatsNewData.versions.indices.contains(selectedVersionIndex) else { return nil }
        return AppConstants.WhatsNewData.versions[selectedVersionIndex]
    }
    
    private var canGoNewer: Bool {
        selectedVersionIndex > 0
    }
    
    private var canGoOlder: Bool {
        selectedVersionIndex < AppConstants.WhatsNewData.versions.count - 1
    }
    
    private let animation: Animation = .interactiveSpring(response: 0.25, dampingFraction: 1)
    
    @State var isScrolling: Bool = false
    @State private var scrollUpdateTask: Task<Void, Never>?
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(AppConstants.WhatsNewData.versions.enumerated()), id: \.element.id) { index, version in
                    if #available(iOS 18, *) {
                        versionContent(version)
                            .containerRelativeFrame(.horizontal)
                            .id(index)
                    } else {
                        GeometryReader { geo in
                            versionContent(version)
                                .onChange(of: geo.frame(in: .global).midX) { _, midX in
                                    let screenMid = UIScreen.main.bounds.width / 2
                                    if abs(midX - screenMid) < 50 {
                                        if index != selectedVersionIndex && !isScrolling {
                                            selectedVersionIndex = index
                                        }
                                    }
                                }
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { selectedVersionIndex },
            set: { newValue in
                if let val = newValue {
                    previousVersionIndex = selectedVersionIndex
                    selectedVersionIndex = val
                }
            }
        ))
        .background(Color(.systemGroupedBackground))
        .animation(animation, value: selectedVersionIndex)
        .onChange(of: selectedVersionIndex) {
            expandedFeatures.removeAll()
            showAllExpanded = false
            
            let count = AppConstants.WhatsNewData.versions.count
            let maxStart = max(0, count - 4)
            let posInWindow = selectedVersionIndex - dotWindowStart
            if posInWindow < 1 {
                dotWindowStart = max(0, selectedVersionIndex - 1)
            } else if posInWindow > 2 {
                dotWindowStart = min(selectedVersionIndex - 2, maxStart)
            }
            
            if #unavailable(iOS 18) {
                isScrolling = true
                scrollUpdateTask?.cancel()
                scrollUpdateTask = Task {
                    try? await Task.sleep(for: .seconds(0.2))
                    if !Task.isCancelled {
                        isScrolling = false
                    }
                }
            }
        }
        .onChange(of: expandedFeatures) {
            showAllExpanded = expandedFeatures.count == AppConstants.WhatsNewData.versions[selectedVersionIndex].features.count
        }
        .toolbar {
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
        .backgroundVisibility(Color(.systemGroupedBackground))
        .modify { view in
            if #available(iOS 26, *) {
                view
                    .safeAreaBar(edge: .top) {
                        headerView
                            .padding(.top, 70)
                            .padding(.bottom, 20)
                    }
            } else {
                view
                    .safeAreaInset(edge: .top) {
                        headerView
                            .padding(.top, 70)
                            .padding(.bottom, 20)
                            .background(Color(.systemGroupedBackground))
                    }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Novità")
                
                Text(" " + (currentVersion?.version ?? ""))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .animation(animation, value: selectedVersionIndex)
            }
            .font(.largeTitle)
            .fontWeight(.bold)
            
            Text(currentVersion?.headline ?? " ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(animation, value: selectedVersionIndex)
        }
        .frame(maxWidth: .infinity)
        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
    }
    
    // MARK: - Version Content
    
    private func versionContent(_ version: WhatsNewVersion) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                Button {
                    guard let version = currentVersion else { return }
                    
                    Haptics.play(.impact(flexibility: .soft, intensity: 0.6))
                    if showAllExpanded {
                        expandedFeatures.removeAll()
                    } else {
                        version.features.forEach {
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
                
                ForEach(version.features, id: \.id) { feature in
                    FeatureCard(
                        feature: feature,
                        isExpanded: expandedFeatures.contains(feature.id),
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
    
    @State var fixAppearWidth: Bool = true
    private var navigator: some View {
        ZStack {
            if let version = currentVersion, fixAppearWidth {
                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        ForEach(Array(AppConstants.WhatsNewData.versions.enumerated()), id: \.element.id) { index, _ in
                            let posInWindow = index - dotWindowStart
                            let isVisible = posInWindow >= 0 && posInWindow <= 3
                            let isEdgeSmall = (posInWindow == 0 && dotWindowStart > 0) || (posInWindow == 3 && dotWindowStart + 3 < AppConstants.WhatsNewData.versions.count - 1)
                            let dotSize: CGFloat = isVisible ? (isEdgeSmall ? 5 : 7) : 0
                            
                            Circle()
                                .fill(index == selectedVersionIndex ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: dotSize, height: dotSize)
                                .padding(.horizontal, isVisible ? 4 : 0)
                        }
                    }
                    .animation(animation, value: selectedVersionIndex)
                    .animation(animation, value: dotWindowStart)
                    
                    Text(version.date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
                        .animation(animation, value: selectedVersionIndex)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            Task { @MainActor in
                fixAppearWidth.toggle()
                try await Task.sleep(for: .seconds(0.01))
                fixAppearWidth.toggle()
            }

        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    @Namespace var namespace
    
    let feature: WhatsNewFeature
    let isExpanded: Bool
    let animation: Animation
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: isExpanded ? .center : .top, spacing: 14) {
                // Icon
                Image(systemName: feature.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(feature.accentColor.color)
                    .symbolEffect(.bounce, value: isExpanded)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(feature.accentColor.color.opacity(0.12))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !isExpanded {
                        Text(feature.shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .matchedGeometryEffect(id: "text", in: namespace, properties: .position, anchor: .topLeading)
                            .transition(.blurReplace.combined(with: .scale(2)))
                    }
                }
                
                Spacer(minLength: 0)
                
                // Expand indicator
                Image(systemName: "chevron.down.circle")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            // Expanded details
            if isExpanded {
                Text(feature.detailedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .matchedGeometryEffect(id: "text", in: namespace, properties: .position, anchor: .topLeading)
                    .transition(.blurReplace.combined(with: .scale(0.6)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onTapGesture {
            Haptics.play(.impact(flexibility: .soft, intensity: 0.6))
            onToggle()
        }
        .hoverEffect(.lift)
        .animation(animation, value: isExpanded)
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
