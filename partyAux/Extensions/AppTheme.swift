//
//  AppTheme.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/13/25.
//

import SwiftUI

// MARK: - Design System Colors
extension Color {
    // Premium Brand Colors
    static let deepNavy = Color(red: 33/255, green: 33/255, blue: 33/255) // #212121 (primary gray from logo)
    static let electricCyan = Color(red: 251/255, green: 190/255, blue: 213/255) // #fbbed5 (secondary pink from logo)
    static let coralPink = Color(red: 251/255, green: 190/255, blue: 213/255) // #fbbed5 (secondary pink from logo)
    static let softPurple = Color(red: 251/255, green: 190/255, blue: 213/255) // #fbbed5 (secondary pink from logo)
    
    // Primary Brand Colors
    static let brandPrimary = Color(red: 33/255, green: 33/255, blue: 33/255) // #212121 (primary gray from logo)
    static let brandSecondary = Color(red: 251/255, green: 190/255, blue: 213/255) // #fbbed5 (secondary pink from logo)
    static let brandAccent = Color(red: 251/255, green: 190/255, blue: 213/255) // #fbbed5 (secondary pink from logo)
    
    // Background Colors
    static let appBackground = Color(red: 33/255, green: 33/255, blue: 33/255) // #212121 (primary gray from logo)
    static let appSurface = Color(red: 45/255, green: 45/255, blue: 45/255) // Slightly lighter
    static let appCardBackground = Color(red: 50/255, green: 50/255, blue: 50/255) // Card bg
    static let appElevated = Color(red: 60/255, green: 60/255, blue: 60/255) // Elevated surface
    
    // Legacy compatibility
    static let appPrimary = brandPrimary
    static let appSecondary = Color(red: 113/255, green: 113/255, blue: 122/255)
    static let appAccent = brandAccent
    
    // Semantic Colors
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let warning = Color(red: 250/255, green: 204/255, blue: 21/255)
    static let error = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let info = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 161/255, green: 161/255, blue: 170/255)
    static let textTertiary = Color(red: 113/255, green: 113/255, blue: 122/255)
    static let textMuted = Color(red: 82/255, green: 82/255, blue: 91/255)
    
    // Gradient Colors
    static let gradientStart = brandPrimary
    static let gradientMiddle = Color(red: 168/255, green: 85/255, blue: 247/255)
    static let gradientEnd = brandSecondary
}

// MARK: - Typography
extension Font {
    static func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    /// Premium font style for modern UI elements
    static func premium(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    // Type Scale
    static let displayLarge = appFont(57, weight: .bold)
    static let displayMedium = appFont(45, weight: .bold)
    static let displaySmall = appFont(36, weight: .bold)
    
    static let headlineLarge = appFont(32, weight: .bold)
    static let headlineMedium = appFont(28, weight: .semibold)
    static let headlineSmall = appFont(24, weight: .semibold)
    
    static let titleLarge = appFont(22, weight: .semibold)
    static let titleMedium = appFont(18, weight: .semibold)
    static let titleSmall = appFont(16, weight: .semibold)
    
    static let bodyLarge = appFont(16, weight: .regular)
    static let bodyMedium = appFont(14, weight: .regular)
    static let bodySmall = appFont(12, weight: .regular)
    
    static let labelLarge = appFont(14, weight: .medium)
    static let labelMedium = appFont(12, weight: .medium)
    static let labelSmall = appFont(11, weight: .medium)
}

// MARK: - Gradients
extension LinearGradient {
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [.brandPrimary, .brandSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [.brandPrimary, .gradientMiddle, .brandSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleGradient = LinearGradient(
        gradient: Gradient(colors: [.brandPrimary.opacity(0.8), .brandSecondary.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.appCardBackground,
            Color.appCardBackground.opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.appBackground,
            Color(red: 15/255, green: 10/255, blue: 25/255),
            Color.appBackground
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glowGradient = LinearGradient(
        gradient: Gradient(colors: [
            .brandPrimary.opacity(0.6),
            .brandSecondary.opacity(0.4),
            .clear
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Radial Gradients
extension RadialGradient {
    static let spotlightGlow = RadialGradient(
        gradient: Gradient(colors: [
            .brandPrimary.opacity(0.3),
            .brandSecondary.opacity(0.1),
            .clear
        ]),
        center: .top,
        startRadius: 0,
        endRadius: 400
    )
}

// MARK: - Animations
extension Animation {
    static let springy = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let smooth = Animation.easeInOut(duration: 0.25)
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    static let gentle = Animation.easeOut(duration: 0.4)
}

// MARK: - Corner Radius
struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Spacing
struct Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Shadow Styles
struct AppShadow {
    static func small(_ color: Color = .black) -> some View {
        Color.clear
            .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    static func medium(_ color: Color = .black) -> some View {
        Color.clear
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    static func large(_ color: Color = .black) -> some View {
        Color.clear
            .shadow(color: color.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    static func glow(_ color: Color = .brandPrimary) -> some View {
        Color.clear
            .shadow(color: color.opacity(0.5), radius: 20, x: 0, y: 0)
    }
}

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.titleSmall)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient.brandGradient
                    } else {
                        Color.appElevated
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .shadow(color: isEnabled ? .brandPrimary.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1 : 0.6)
            .animation(.snappy, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.titleSmall)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.appElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(Color.textMuted.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundColor(.brandPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(configuration.isPressed ? Color.brandPrimary.opacity(0.1) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            .animation(.snappy, value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let background: Color
    
    init(size: CGFloat = 44, background: Color = .appElevated) {
        self.size = size
        self.background = background
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(background)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

// Legacy support
struct ModernButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let shadowColor: Color
    
    init(gradient: LinearGradient = .brandGradient, shadowColor: Color = .brandPrimary) {
        self.gradient = gradient
        self.shadowColor = shadowColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.titleSmall)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .shadow(color: shadowColor.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

// MARK: - Text Field Styles
struct ModernTextFieldStyle: TextFieldStyle {
    var isFocused: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.bodyLarge)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.appElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(
                        isFocused ? LinearGradient.brandGradient : LinearGradient(colors: [.textMuted.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .foregroundColor(.textPrimary)
    }
}

// MARK: - Card Styles
struct CardModifier: ViewModifier {
    let padding: CGFloat
    
    init(padding: CGFloat = Spacing.md) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.08), .white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct GlassMorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Blur Effect
struct BlurEffect: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - View Extensions
extension View {
    func card(padding: CGFloat = Spacing.md) -> some View {
        modifier(CardModifier(padding: padding))
    }
    
    func glassMorphism() -> some View {
        modifier(GlassMorphismModifier())
    }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func ghostButton() -> some View {
        buttonStyle(GhostButtonStyle())
    }
    
    func modernButton(gradient: LinearGradient = .brandGradient, shadowColor: Color = .brandPrimary) -> some View {
        buttonStyle(ModernButtonStyle(gradient: gradient, shadowColor: shadowColor))
    }
    
    func backdrop<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        background(content())
    }
    
    func shimmer(active: Bool = true) -> some View {
        self
    }
    
    func glow(color: Color = .brandPrimary, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Placeholder Extension for TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
