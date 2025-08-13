//
//  AppTheme.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/13/25.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let appPrimary = Color.white
    static let appSecondary = Color.gray
    static let appAccent = Color.white
    static let appBackground = Color.black
    static let appSurface = Color(red: 20/255, green: 20/255, blue: 20/255) // Very dark gray
    static let appCardBackground = Color(red: 30/255, green: 30/255, blue: 30/255) // Dark gray
    
    // Gradient Colors (now grayscale)
    static let gradientStart = Color.white
    static let gradientMiddle = Color.gray
    static let gradientEnd = Color(red: 200/255, green: 200/255, blue: 200/255)
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 180/255, green: 180/255, blue: 180/255)
    static let textTertiary = Color(red: 120/255, green: 120/255, blue: 120/255)
}

// MARK: - Font Extensions
extension Font {
    static func spaceGrotesk(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Space Grotesk", size: size).weight(weight)
    }
    
    // Predefined sizes
    static let largeTitle = Font.spaceGrotesk(34, weight: .bold)
    static let title1 = Font.spaceGrotesk(28, weight: .bold)
    static let title2 = Font.spaceGrotesk(22, weight: .bold)
    static let title3 = Font.spaceGrotesk(20, weight: .semibold)
    static let headline = Font.spaceGrotesk(17, weight: .semibold)
    static let body = Font.spaceGrotesk(17, weight: .regular)
    static let callout = Font.spaceGrotesk(16, weight: .regular)
    static let subheadline = Font.spaceGrotesk(15, weight: .regular)
    static let footnote = Font.spaceGrotesk(13, weight: .regular)
    static let caption = Font.spaceGrotesk(12, weight: .regular)
    static let caption2 = Font.spaceGrotesk(11, weight: .regular)
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white, Color.gray]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [Color.appCardBackground, Color.appSurface]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [Color.black, Color.black]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Animation Extensions
extension Animation {
    static let springy = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
}

// MARK: - View Modifiers
struct GlassMorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .backdrop {
                        BlurEffect(style: .systemUltraThinMaterialDark)
                    }
            )
    }
}

struct ModernButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let shadowColor: Color
    
    init(gradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing), shadowColor: Color = .white) {
        self.gradient = gradient
        self.shadowColor = shadowColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: shadowColor.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.bouncy, value: configuration.isPressed)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient.primaryGradient, lineWidth: 1)
            )
            .foregroundColor(.textPrimary)
    }
}

// MARK: - BlurEffect for Backdrop
struct BlurEffect: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - View Extensions
extension View {
    func glassMorphism() -> some View {
        modifier(GlassMorphismModifier())
    }
    
    func modernButton(gradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing), shadowColor: Color = .white) -> some View {
        buttonStyle(ModernButtonStyle(gradient: gradient, shadowColor: shadowColor))
    }
    
    func backdrop<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        background(content())
    }
    
    func shimmer(active: Bool = true) -> some View {
        // Remove shimmer effect - just return self without any shimmer
        self
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .opacity(active ? 1 : 0)
                    .animation(
                        active ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : .default,
                        value: phase
                    )
            )
            .onAppear {
                if active {
                    phase = 300
                }
            }
    }
}
