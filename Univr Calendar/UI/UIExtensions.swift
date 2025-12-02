//
//  UIExtensions.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/11/25.
//

import SwiftUI

@MainActor
class ColorCache {
    static let shared = ColorCache()
    private var cache: [String: Color] = [:]
    
    func color(for hex: String) -> Color? {
        if let cached = cache[hex] { return cached }
        
        if let color = Color.parseHex(hex) {
            cache[hex] = color
            return color
        }
        return nil
    }
}

extension Color {
    static func parseHex(_ hex: String) -> Color? {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            a = Double(rgb & 0xFF) / 255.0
        } else {
            return nil
        }

        return Color(red: r, green: g, blue: b, opacity: a)
    }
    
    init?(hex: String) {
        guard let c = ColorCache.shared.color(for: hex) else { return nil }
        self = c
    }
}

extension View {
    @ViewBuilder
    func shimmeringPlaceholder() -> some View {
        self.overlay {
            GeometryReader { geometry in
                let width = geometry.size.width
                let extraOffset = width * 1.5
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.2), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: extraOffset, height: geometry.size.height)
                    .offset(x: -width)
                    // Animazione continua
                    .phaseAnimator([false, true]) { content, phase in
                        content
                            .offset(x: phase ? width * 2 : -width)
                    } animation: { _ in
                        .linear(duration: 1.5).repeatForever(autoreverses: false)
                    }
            }
            .mask(self)
            .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func keyboardPadding(_ value: CGFloat) -> some View {
        self.safeAreaPadding(.bottom, value)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: Fallback iOS 18
    @ViewBuilder
    func glassProminentIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glassProminent)
        } else {
            self
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            
        }
    }
    
    @ViewBuilder
    func glassIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            
        }
    }
    
    @ViewBuilder
    func sheetDesign(_ namespace: Namespace.ID, detent: Binding<PresentationDetent>) -> some View {
        if #available(iOS 26, *) {
            self
                .navigationTransition(
                    .zoom(sourceID: "calendar", in: namespace)
                )
                .presentationCornerRadius(detent.wrappedValue != .large ? .deviceCornerRadius - 8 : .deviceCornerRadius)
                .animation(.easeInOut, value: detent.wrappedValue)
        } else {
            self
                .presentationCornerRadius(.deviceCornerRadius)
            
        }
    }
    
    @ViewBuilder
    func scrollViewTopPadding() -> some View {
        if #available(iOS 26, *) {
            self
        } else if #available(iOS 18, *) {
            self
                .padding(.top, 15)
            
        } else {
            self
        }
    }
    
    @ViewBuilder
    func onScrollGeometry(openCalendar: Binding<Bool>, selectedDetent: Binding<PresentationDetent>, firstLoading: Binding<Bool>) -> some View {
        if #available(iOS 26, *) {
            self
                .onScrollGeometryChange(for: ScrollGeometry.self, of: { geometry in
                    geometry
                }) { oldValue, newValue in
                    if !firstLoading.wrappedValue {
                        let offset = newValue.contentOffset.y + newValue.contentInsets.top
                        let isLarge = selectedDetent.wrappedValue == .large
                        
                        if offset <= 0 && !openCalendar.wrappedValue {
                            DispatchQueue.main.async {
                                withAnimation {
                                    openCalendar.wrappedValue = true
                                }
                            }
                        } else if offset > 10 && !isLarge && openCalendar.wrappedValue {
                            DispatchQueue.main.async {
                                withAnimation {
                                    openCalendar.wrappedValue = false
                                }
                            }
                        }
                    }
                }
        } else {
            self
        }
    }
    
    @ViewBuilder
    func toolbarTitleShadow(_ colorScheme: ColorScheme) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            self
                .shadow(color: colorScheme == .light ? .white : .black, radius: 5)
                .shadow(color: colorScheme == .light ? .white : .black, radius: 10)
                .shadow(color: colorScheme == .light ? .white : .black, radius: 20)
        }
    }
    
    @ViewBuilder
    func hideTabBarCompatible() -> some View {
        if #available(iOS 18.0, *) {
            self
                .tabViewStyle(.tabBarOnly)
                .toolbarVisibility(.hidden, for: .tabBar)
        } else {
            self
                .toolbar(.hidden, for: .tabBar)
        }
    }
    
    @ViewBuilder
    func removeTopSafeArea() -> some View {
        if #available(iOS 17, *) {
            if #unavailable(iOS 18.0) {
                self
                    .ignoresSafeArea(edges: .top)
            } else {
                self
            }
        } else {
            self
        }
    }
}

extension ToolbarItem {
    @ToolbarContentBuilder
    func toolbarBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        if #available(iOS 26, *) {
            self
                .sharedBackgroundVisibility(visibility)
        } else {
            self
        }
    }
}

extension UIApplication {
    /// Ritorna le dimensioni della safe area attuale (se disponibili)
    var safeAreas: UIEdgeInsets {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets ?? .zero
    }
    
    var screenSize: CGRect {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds ?? .zero
    }
}

extension CGFloat {
    static var deviceCornerRadius: CGFloat = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let radii: [String: CGFloat] = [
            // iPhone 17 Series
            "iPhone18,2": 62.0,  // 17 Pro Max
            "iPhone18,1": 62.0,  // 17 Pro
            "iPhone18,3": 62.0,  // 17
            
            // iPhone 16 Series
            "iPhone17,2": 62.0,  // 16 Pro Max
            "iPhone17,1": 62.0,  // 16 Pro
            "iPhone17,4": 55.0,  // 16 Plus
            "iPhone17,3": 55.0,  // 16
            "iPhone17,5": 47.33, // 16e
            
            // iPhone 15 Series
            "iPhone16,2": 55.0,  // 15 Pro Max
            "iPhone16,1": 55.0,  // 15 Pro
            "iPhone15,5": 55.0,  // 15 Plus
            "iPhone15,4": 55.0,  // 15

            // iPhone 14 Series
            "iPhone15,3": 55.0,  // 14 Pro Max
            "iPhone15,2": 55.0,  // 14 Pro
            "iPhone14,8": 53.33, // 14 Plus
            "iPhone14,7": 47.33, // 14
            
            // iPhone 13 Series
            "iPhone14,3": 53.33, // 13 Pro Max
            "iPhone14,2": 47.33, // 13 Pro
            "iPhone14,5": 47.33, // 13
            "iPhone14,4": 44.0,  // 13 Mini

            // iPhone 12 Series
            "iPhone13,4": 53.33, // 12 Pro Max
            "iPhone13,3": 47.33, // 12 Pro
            "iPhone13,2": 47.33, // 12
            "iPhone13,1": 44.0,  // 12 Mini
            
            // iPhone 11 Series
            "iPhone12,5": 39.0, // 11 Pro Max
            "iPhone12,3": 39.0, // 11 Pro
            "iPhone12,1": 41.5, // 11
            
            // iPhone XR Series
            "iPhone11,8": 41.5,  // XR
            
            // iPhone XS Series
            "iPhone11,6": 39.0,  // XS Max Global
            "iPhone11,4": 39.0,  // XS Max
            "iPhone11,2": 39.0,  // XS
            
            // iPhone X Series
            "iPhone10,6": 39.0,  // X GSM
            "iPhone10,3": 39.0,  // X Global
            
            // iPhone Air Series
            "iPhone18,4": 62.0,  // Air
            
            // iPad Air
            "iPad15,6": 18.0,    // iPad Air 13-inch 7th Gen (WiFi+Cellular)
            "iPad15,5": 18.0,    // iPad Air 13-inch 7th Gen (WiFi)
            "iPad15,4": 18.0,    // iPad Air 11-inch 7th Gen (WiFi+Cellular)
            "iPad15,3": 18.0,    // iPad Air 11-inch 7th Gen (WiFi)
            "iPad14,11": 18.0,   // iPad Air 13 inch 6th Gen (WiFi+Cellular)
            "iPad14,10": 18.0,   // iPad Air 13 inch 6th Gen (WiFi)
            "iPad14,9": 18.0,    // iPad Air 11 inch 6th Gen (WiFi+Cellular)
            "iPad14,8": 18.0,    // iPad Air 11 inch 6th Gen (WiFi)
            "iPad13,17": 18.0,   // iPad Air 5th Gen (WiFi+Cellular)
            "iPad13,16": 18.0,   // iPad Air 5th Gen (WiFi)
            "iPad13,2": 18.0,    // iPad Air 4th Gen (WiFi+Cellular)
            "iPad13,1": 18.0,    // iPad Air 4th Gen (WiFi)
            "iPad11,4": 18.0,    // iPad Air 3rd Gen (WiFi+Cellular)
            "iPad11,3": 18.0,    // iPad Air 3rd Gen (WiFi)
            "iPad5,4": 18.0,     // iPad Air 2 (Cellular)
            "iPad5,3": 18.0,     // iPad Air 2 (WiFi)
            "iPad4,3": 18.0,     // 1st Gen iPad Air (China)
            "iPad4,2": 18.0,     // iPad Air (GSM+CDMA)
            "iPad4,1": 18.0,     // iPad Air (WiFi)
            
            // iPad Pro
            "iPad16,6": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi+Cellular)
            "iPad16,5": 18.0,    //iPad Pro 12.9 inch 7th Gen (WiFi)
            "iPad14,6": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi+Cellular)
            "iPad14,5": 18.0,    //iPad Pro 12.9 inch 6th Gen (WiFi)
            "iPad13,11": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,10": 18.0,   //iPad Pro 12.9 inch 5th Gen
            "iPad13,9": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad13,8": 18.0,    //iPad Pro 12.9 inch 5th Gen
            "iPad16,4": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi+Cellular)
            "iPad16,3": 18.0,    //iPad Pro 11 inch 5th Gen (WiFi)
            "iPad13,7": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,6": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,5": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad13,4": 18.0,    //iPad Pro 11 inch 5th Gen
            "iPad8,12": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
            "iPad8,11": 18.0,    //iPad Pro 12.9 inch 4th Gen (WiFi)
            "iPad14,4": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad14,3": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,10": 18.0,    //iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad8,9": 18.0,     //iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,8": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,7": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
            "iPad8,6": 18.0,     //iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
            "iPad8,5": 18.0,     //iPad Pro 12.9 inch 3rd Gen (WiFi)
            "iPad8,4": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,3": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
            "iPad8,2": 18.0,     //iPad Pro 11 inch 3rd Gen (1TB, WiFi)
            "iPad8,1": 18.0,     //iPad Pro 11 inch 3rd Gen (WiFi)
            "iPad7,4": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi+Cellular)
            "iPad7,3": 18.0,     //iPad Pro 10.5-inch 2nd Gen (WiFi)
            "iPad7,2": 18.0,     //iPad Pro 2nd Gen (WiFi+Cellular)
            "iPad7,1": 18.0,     //iPad Pro 2nd Gen (WiFi)
            "iPad6,8": 18.0,     //iPad Pro (12.9 inch, WiFi+LTE)
            "iPad6,7": 18.0,     //iPad Pro (12.9 inch, WiFi)
            "iPad6,4": 18.0,     //iPad Pro (9.7 inch, WiFi+LTE)
            "iPad6,3": 18.0,     //iPad Pro (9.7 inch, WiFi)
        ]
        
        if let radius = radii[modelIdentifier] {
            return radius
        }
        
        let bottomSafeArea = UIApplication.shared.safeAreas.bottom
        return bottomSafeArea > 0 ? 47.33 : 0
    }()
}

#Preview {
    testView()
}

struct testView: View {
    @State var text = "Elementi di architettura e sistemi operativi ELEMENTI DI ARCHITETTURE Laboratorio Matricole pari"
    //@State var text = "Analisi matematica Matricole pari ANALISI I"
    //@State var text = "Algebra e matematica di base Matricole pari"
    //@State var text = "Algebra lineare Matricole pari"
    //@State var text = "Programmazione I Matricole pari Laboratorio 1"
    //@State var text = "Fisica teorica"
    //@State var text = "Inglese B2 - Abilità produttive (GRUPPO 2)"
    //@State var text = "Chimica generale ed inorganica esercitazioni"
    //@State var text = "Biologia generale e cellulare BIOLOGIA GENERALE E CELLULARE: I"
    //@State var text = "P?????? ?????????? 2 (Letteratura russa 2)"
    @State var formattedText = ""
    @State var tags: [String] = []
    
    var body: some View {
        VStack {
            Text(formattedText)
                .multilineTextAlignment(.center)
                .padding()
                .onAppear {
                    formattedText = formatText(text)
                }
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
    
    func formatText(_ txt: String) -> String {
        var formattedTxt = txt
            .replacingOccurrences(of: "Matricole pari", with: "")
            .replacingOccurrences(of: "Matricole dispari", with: "")
        
        let keywords = ["Laboratorio", "Teoria", "Esercitazioni"]

        // 1. Costruiamo la Regex: cercherà la parola chiave seguita da zero o più caratteri
        // non-lettera (come spazio, numeri, parentesi) all'inizio o alla fine della stringa.
        let pattern = "(?:" + keywords.joined(separator: "|") + ")" + "\\s*[^A-Za-zÀ-ÖØ-Þa-zà-öø-þ]*"

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsFormattedTxt = formattedTxt as NSString
            let fullRange = NSRange(location: 0, length: nsFormattedTxt.length)
            
            // Trova la prima corrispondenza
            if let match = regex.firstMatch(in: formattedTxt, range: fullRange) {
                
                // Estrai l'intera porzione che corrisponde al pattern (es. "Laboratorio 1")
                if let rangeToRemove = Range(match.range, in: formattedTxt) {
                    
                    // 2. Determina la parola chiave effettiva (Laboratorio/Teoria/Esercitazioni)
                    // Lavoriamo con la stringa rimossa per trovare la parola chiave esatta
                    let matchedPart = String(formattedTxt[rangeToRemove])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    tags.append(matchedPart)
                    // Trova quale delle parole chiave è contenuta nella parte trovata
                    //if let foundKeyword = keywords.first(where: { matchedPart.contains($0) }) {
                    //    tags.append(foundKeyword) // Aggiungi solo la parola chiave (es. "Laboratorio")
                    //}

                    // 3. Rimuovi l'intera corrispondenza dalla stringa
                    formattedTxt.removeSubrange(rangeToRemove)
                }
            }
        }
        
        if formattedTxt.contains("??") {
            let upperCasePattern = "\\((.*?)\\)"
            
            if let regex = try? NSRegularExpression(pattern: upperCasePattern) {
                let matches = regex.matches(in: formattedTxt, range: NSRange(formattedTxt.startIndex..., in: formattedTxt))
                
                for match in matches {
                    if let range = Range(match.range, in: formattedTxt) {
                        var upperCasePart = String(formattedTxt[range])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        
                        if upperCasePart.contains("Letteratura russa") {
                            let number = upperCasePart[upperCasePart.index(upperCasePart.endIndex, offsetBy: -2)]
                            formattedTxt = "Русская литература \(number) \(upperCasePart)"
                        } else {
                            upperCasePart.removeFirst()
                            upperCasePart.removeLast()
                            
                            formattedTxt = upperCasePart
                        }
                    }
                }
            }
        } else if formattedTxt.contains("(") {
            let upperCasePattern = "\\((.*?)\\)"
            
            if let regex = try? NSRegularExpression(pattern: upperCasePattern) {
                let matches = regex.matches(in: formattedTxt, range: NSRange(formattedTxt.startIndex..., in: formattedTxt))
                
                for match in matches {
                    if let range = Range(match.range, in: formattedTxt) {
                        var upperCasePart = String(formattedTxt[range])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        formattedTxt.removeSubrange(range)
                        upperCasePart.removeFirst()
                        upperCasePart.removeLast()
                        
                        tags.append(upperCasePart)
                    }
                }
            }
        } else {
            let upperCasePattern = "[A-ZÀ-ÖØ-Þ\\s]{5,}"
            
            if let regex = try? NSRegularExpression(pattern: upperCasePattern) {
                let matches = regex.matches(in: formattedTxt, range: NSRange(location: 0, length: formattedTxt.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range, in: formattedTxt) {
                        var upperCasePart = String(formattedTxt[range])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if upperCasePart.count >= 5 {
                            // Safely check if there's a colon immediately after the matched uppercase range
                            if range.upperBound < formattedTxt.endIndex {
                                let nextIndex = formattedTxt.index(range.upperBound, offsetBy: 3)
                                let colonRange = range.upperBound..<nextIndex
                                if formattedTxt[colonRange].first == ":" {
                                    upperCasePart.append(" " + formattedTxt[formattedTxt.index(before: nextIndex)..<nextIndex])
                                    
                                    formattedTxt.removeSubrange(colonRange)
                                }
                            }
                            
                            formattedTxt.removeSubrange(range)
                            tags.append(upperCasePart)
                        }
                    }
                }
            }
        }
        
        return formattedTxt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

