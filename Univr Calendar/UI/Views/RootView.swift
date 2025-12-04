//
//  RootView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 03/12/25.
//

import SwiftUI
import UnivrCore

struct RootView: View {
    @Environment(UserSettings.self) var settings
    
    @State private var showSplash: Bool = true
    
    @Namespace var animation
    
    var body: some View {
        ZStack {
            ContentView(animation: animation, showSplash: $showSplash)
                .zIndex(0)
            
            if showSplash {
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeIn(duration: 0.2)))
                    
                    Image("InternalIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 200 * 0.225, style: .continuous))
                        .matchedGeometryEffect(id: "appIcon", in: animation, isSource: true)
                        .frame(width: 200, height: 200)
                }
                .zIndex(1)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            if settings.onboardingCompleted {
                withAnimation(nil) {
                    showSplash = false
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(UserSettings.shared)
}
