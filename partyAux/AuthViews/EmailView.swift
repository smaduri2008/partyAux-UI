//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import SwiftUI

struct EmailView: View {
    @EnvironmentObject var auth: UserAuth
    @State private var isLoading = false
    @State private var showError = false
    @State private var isEmailValid = false
    @FocusState private var isEmailFocused: Bool
    @State private var animateGlow = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
            // Background with gradient
            Color.appBackground
                .ignoresSafeArea()
            
            // Animated glow effect
            // Animated glow effect sized relative to device width so it doesn't overflow smaller screens
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .brandPrimary.opacity(0.3),
                            .brandSecondary.opacity(0.1),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                // Keep background glow circle within screen to prevent horizontal overflow
                .frame(width: min(geometry.size.width * 0.9, 500), height: min(geometry.size.width * 0.9, 500))
                .offset(x: 0, y: -min(geometry.size.height * 0.22, 220))
                .scaleEffect(animateGlow ? 1.2 : 1.0)
                .opacity(animateGlow ? 0.8 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateGlow
                )

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    Spacer(minLength: max(geometry.size.height * 0.06, 48))
                    
                    // Logo/Icon (uses bundled `PartyAux_transparent` PNG if available; otherwise the fallback circle icon)
                    LogoView(size: min(geometry.size.width * 0.28, 120), hasBackground: false)
                    
                    // Hero Section
                    VStack(spacing: Spacing.sm) {
                        Text("Welcome to")
                            .font(.bodyLarge)
                            .foregroundColor(.textSecondary)
                        
                        Text("PartyAux")
                            .font(.displaySmall)
                            .foregroundColor(.brandSecondary)
                        
                        Text("Share music, create memories")
                            .font(.bodyMedium)
                            .foregroundColor(.textTertiary)
                            .padding(.top, Spacing.xs)
                    }
                    
                    // Email Input Section
                    VStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(LinearGradient.brandGradient)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("Email Address")
                                    .font(.labelLarge)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            HStack {
                                TextField("", text: $auth.email)
                                    .placeholder(when: auth.email.isEmpty) {
                                        Text("Enter your email")
                                            .foregroundColor(.textMuted)
                                    }
                                    .font(.bodyLarge)
                                    .foregroundColor(.textPrimary)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($isEmailFocused)
                                    .onChange(of: auth.email) { newValue in
                                        withAnimation(.smooth) {
                                            isEmailValid = isValidEmail(newValue)
                                            showError = false
                                        }
                                    }
                                
                                if isEmailValid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.success)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(Spacing.md)
                            .background(Color.appElevated)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                    .strokeBorder(
                                        isEmailFocused ? LinearGradient.brandGradient : LinearGradient(colors: [.textMuted.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                                        lineWidth: isEmailFocused ? 2 : 1
                                    )
                            )
                            .animation(.smooth, value: isEmailFocused)
                            
                            if showError {
                                HStack(spacing: Spacing.xxs) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.error)
                                        .font(.labelSmall)
                                    
                                    Text("Please enter a valid email address")
                                        .font(.labelSmall)
                                        .foregroundColor(.error)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        // Send OTP Button
                        Button(action: {
                            if isEmailValid {
                                isLoading = true
                                isEmailFocused = false
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                auth.sendOTP()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isLoading = false
                                    auth.showOTPView = true
                                }
                            } else {
                                withAnimation(.bouncy) {
                                    showError = true
                                }
                                let notificationFeedback = UINotificationFeedbackGenerator()
                                notificationFeedback.notificationOccurred(.error)
                            }
                        }) {
                            HStack(spacing: Spacing.sm) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Sending...")
                                        .font(.titleSmall)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Continue")
                                        .font(.titleSmall)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                isEmailValid && !isLoading
                                    ? LinearGradient.brandGradient
                                    : LinearGradient(colors: [.appElevated], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(isEmailValid && !isLoading ? .white : .textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .shadow(
                                color: isEmailValid && !isLoading ? .brandPrimary.opacity(0.4) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(isLoading)
                        .scaleEffect(isLoading ? 0.98 : 1.0)
                        .animation(.snappy, value: isLoading)
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    Spacer(minLength: max(geometry.size.height * 0.06, 48))
                }
                .padding()
            }
            
            // Hidden Navigation Link
            NavigationLink(destination: OTPView(), isActive: $auth.showOTPView) {
                EmptyView()
            }
            .hidden()
            }
        }
        .onAppear { animateGlow = true }
        .onTapGesture {
            isEmailFocused = false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    EmailView()
        .environmentObject(UserAuth())
}
