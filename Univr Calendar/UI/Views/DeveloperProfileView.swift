//
//  DeveloperProfileView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/01/26.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI
import UnivrCore

struct DeveloperProfileView: View {
    // Animazioni
    @State private var appear = false
    @State private var rotateRings = false
    
    // Colori
    let deepBg = Color(red: 0.02, green: 0.02, blue: 0.08)
    let glassBg = Color.white.opacity(0.08)
    let glassBorder = Color.white.opacity(0.2)
    let accentTech = Color.cyan
    let accentHand = Color(red: 1.0, green: 0.9, blue: 0.4)
    
    // Generazione posizioni stelle (statiche ma con animazione interna)
    private static let starPositions: [(CGPoint, CGFloat)] = (0..<60).map { _ in
        (
            CGPoint(x: CGFloat.random(in: 0...400), y: CGFloat.random(in: 0...900)),
            CGFloat.random(in: 1.5...3.5)
        )
    }

    var body: some View {
        ZStack {
            // MARK: - 1. BACKGROUND (SPAZIO PROFONDO)
            deepBg.ignoresSafeArea()
            
            // Stelle Scintillanti
            GeometryReader { _ in
                ForEach(0..<DeveloperProfileView.starPositions.count, id: \.self) { index in
                    TwinklingStar(
                        position: DeveloperProfileView.starPositions[index].0,
                        size: DeveloperProfileView.starPositions[index].1
                    )
                }
            }
            .ignoresSafeArea()
            
            // Nebulose Ambientali
            ZStack {
                Circle() // Blu in basso a destra
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: 150, y: 350)
            
                Circle() // Viola in alto a sinistra
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: -150, y: -300)
            }
            
            // MARK: - 2. CONTENUTO (HUD STYLE)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // --- SEZIONE PROFILE ---
                    ZStack {
                        Group {
                            Circle()
                                .strokeBorder(LinearGradient(colors: [.clear, accentTech.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                                .frame(width: 170, height: 170)
                                .rotationEffect(.degrees(rotateRings ? 360 : 0))
                                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: rotateRings)
                            
                            Circle()
                                .strokeBorder(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5, 10]))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(rotateRings ? -360 : 0))
                                .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: rotateRings)
                        }
                        
                        Image("DeveloperPhoto")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .clipShape(.circle)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: accentTech.opacity(0.5), radius: 20)
                            .onTapGesture {
                                //Haptics.play(.impact(.medium))
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        
                        
                        VStack(spacing: 4) {
                            Text(AppConstants.AppInfo.developerName.uppercased())
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                            
                            Text("SVILUPPATORE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(accentTech)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.4))
                                .clipShape(.capsule)
                        }
                        .offset(y: 120)
                        
                        Text("Questo sono io ↓")
                            .font(.custom("Noteworthy-Light", size: 14))
                            .foregroundStyle(accentHand)
                            .rotationEffect(.degrees(-15))
                            .offset(x: -55, y: -70)
                            .opacity(appear ? 1 : 0)
                            .animation(.spring().delay(0.5), value: appear)
                    }

                    Spacer(minLength: 40)
                    
                    // --- UNIFIED DASHBOARD PANEL ---
                    CustomList(customListItems: [
                        CustomListItem(
                            url: AppConstants.URLs.portfolio,
                            icon: "globe.europe.africa.fill",
                            color: .cyan,
                            title: "Portfolio",
                            subtitle: "I miei lavori",
                            overlayText: HandWrittenOverlayText(
                                text: "WIP",
                                rotation: 10,
                                offset: .init(width: -10, height: 8),
                                font: "Noteworthy-Bold",
                                fontSize: 10,
                                color: .red
                            )
                        ),
                        CustomListItem(
                            url: AppConstants.URLs.twitter,
                            icon: "at",
                            color: .white,
                            title: "X / Twitter",
                            subtitle: "Seguimi per aggiornamenti"
                        ),
                        CustomListItem(
                            url: AppConstants.URLs.email,
                            icon: "envelope.fill",
                            color: .purple,
                            title: "Contattami",
                            subtitle: "Mandami una mail",
                            overlayText: HandWrittenOverlayText(
                                text: "Scrivimi!",
                                rotation: -15,
                                offset: .init(width: 10, height: 5),
                                alignment: .topLeading,
                                fontSize: 12
                            )
                        )
                    ])
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appear)
                    
                    // --- DONATION BAR ---
                    CustomList(
                        important: true,
                        customListItems: [
                            CustomListItem(
                                url: AppConstants.URLs.donation,
                                icon: "cup.and.saucer.fill",
                                color: .orange,
                                title: "Fammi un regalino",
                                subtitle: "Dona qualcosina se vuoi aiutare",
                                overlayText: HandWrittenOverlayText(
                                    text: "Grazie ❤️",
                                    rotation: 5,
                                    offset: .init(width: -5, height: 2),
                                    alignment: .topTrailing,
                                    font: "Noteworthy-Bold"
                                )
                            )
                        ]
                    )
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appear)
                    
                    // Footer
                    Button(action: { UIApplication.shared.open(AppConstants.URLs.feedback) }) {
                        Text("Segnala un problema")
                            .font(.caption)
                            .underline()
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appear)
                }
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            appear = true
            rotateRings = true
        }
    }
}

private struct TwinklingStar: View {
    let position: CGPoint
    let size: CGFloat
    @State private var isGlowing = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(position)
            .opacity(isGlowing ? 1.0 : 0.2)
            .shadow(color: .white, radius: isGlowing ? 2 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.0...3.0))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2.0))
                ) {
                    isGlowing = true
                }
            }
    }
}

private struct CustomList: View {
    var important: Bool = false
    var glassBg = Color.white.opacity(0.08)
    let customListItems: [CustomListItem]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(customListItems) { item in
                Button(action: { if let url = item.url { open(url) } }) {
                    HStack(spacing: 15) {
                        if important {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(.orange)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(item.color.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(item.color)
                            }
                            .frame(width: 32, height: 32)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                            
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .tint(.primary)
                .textOverlay(
                    text: item.overlayText.text,
                    rotation: item.overlayText.rotation,
                    offset: item.overlayText.offset,
                    alignment: item.overlayText.alignment,
                    font: item.overlayText.font,
                    fontSize: item.overlayText.fontSize,
                    color: item.overlayText.color
                )
            }
        }
        .background(glassBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(important ? customListItems.first?.color.opacity(0.3) ?? Color.white.opacity(0.1) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .drawingGroup()
    }
    
    func open(_ url: URL) {
        //Haptics.play(.impact(.light))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIApplication.shared.open(url)
    }
}

private struct CustomListItem: Identifiable {
    let id: UUID = UUID()
    
    var url: URL?
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var overlayText: HandWrittenOverlayText = HandWrittenOverlayText(text: "", rotation: 0, offset: .init(width: 0, height: 0))
}

private struct HandWrittenOverlayText {
    let text: String
    let rotation: Double
    let offset: CGSize
    var alignment: Alignment = .topTrailing
    var font: String = "Noteworthy-Light"
    var fontSize: CGFloat = 14
    var color: Color = Color(red: 1.0, green: 0.9, blue: 0.4)
}

#Preview {
    DeveloperProfileView()
}
