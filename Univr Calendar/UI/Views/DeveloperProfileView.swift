//
//  DeveloperProfileView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/01/26.
//

import SwiftUI
import UnivrCore

// MARK: - Stella Scintillante (Componente Indipendente)
struct TwinklingStar: View {
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

struct ProfileView: View {
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
                ForEach(0..<ProfileView.starPositions.count, id: \.self) { index in
                    TwinklingStar(
                        position: ProfileView.starPositions[index].0,
                        size: ProfileView.starPositions[index].1
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
                            Text("LEONARDO ROSSI")
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
                    
                    // --- DASHBOARD GRID ---
                    Grid {
                        GridRow {
                            Button(action: { open(AppConstants.URLs.portfolio) }) {
                                HUDCard(title: "PORTFOLIO", icon: "globe.europe.africa.fill", color: .cyan) {
                                    HStack {
                                        Text("I miei lavori")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    Text("Work in Progress")
                                        .font(.custom("Noteworthy-Bold", size: 14))
                                        .foregroundStyle(.red)
                                        .rotationEffect(.degrees(10))
                                        .offset(x: 10, y: -15)
                                }
                            }
                            .gridCellColumns(2)
                        }
                        
                        GridRow {
                            Button(action: { open(AppConstants.URLs.twitter) }) {
                                HUDCard(title: "X / TWITTER", icon: "at", color: .white) {
                                    HStack {
                                        Text("Seguimi")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                }
                            }
                            
                            Button(action: { open(AppConstants.URLs.email) }) {
                                HUDCard(title: "CONTATTAMI", icon: "envelope.fill", color: .purple) {
                                    HStack {
                                        Text("Mandami una mail")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                }
                                .overlay(alignment: .topLeading) {
                                    Text("Scrivimi!")
                                        .font(.custom("Noteworthy-Light", size: 14))
                                        .foregroundStyle(accentHand)
                                        .rotationEffect(.degrees(-15))
                                        .offset(x: -5, y: -12)
                                }
                            }
                        }
                    }
                    .gridCellColumns(2)
                    .padding(.horizontal, 20)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appear)
                    
                    // --- DONATION BAR ---
                    Button(action: { open(AppConstants.URLs.donation) }) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                    
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fammi un regalino")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                    
                                Text("Dona qualcosina se vuoi aiutare")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        .padding()
                        .background(glassBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .overlay(alignment: .topTrailing) {
                        Text("Grazie ❤️")
                            .font(.custom("Noteworthy-Bold", size: 14))
                            .foregroundStyle(accentHand)
                            .rotationEffect(.degrees(5))
                            .offset(x: -20, y: -10)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appear)
                    
                    // Footer
                    Button(action: { open(AppConstants.URLs.feedback) }) {
                        Text("Segnala un problema")
                            .font(.caption)
                            .underline()
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.bottom, 30)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 50)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appear)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            appear = true
            rotateRings = true
        }
    }
    
    func open(_ url: URL) {
        //Haptics.play(.impact(.light))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIApplication.shared.open(url)
    }
}

// MARK: - Componente Card "Vetro" (HUD)
struct HUDCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .blur(radius: 5)
                    
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 18, weight: .bold))
                }
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            content()
        }
        .padding(16)
        .background(
            Color.black.opacity(0.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.4), .clear, .clear, color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProfileView()
}
