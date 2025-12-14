//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import SwiftUI

struct OTPView: View {
    @EnvironmentObject var auth: UserAuth
    @FocusState private var isTextFieldFocused: Bool
    @State private var isLoading = false
    @State private var showError = false
    @State private var bounceIndices: [Bool] = Array(repeating: false, count: 6)
    private let otpLength = 6
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: 40)
                    
                    // Header Section
                    VStack(spacing: Spacing.lg) {
                        // Icon
                        LogoView(size: 88, hasBackground: false)
                        
                        // Title and subtitle
                        VStack(spacing: Spacing.sm) {
                            Text("Verification Code")
                                .font(.headlineMedium)
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: Spacing.xxs) {
                                Text("Enter the 6-digit code sent to")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                
                                Text(auth.email)
                                    .font(.bodyMedium)
                                    .foregroundStyle(LinearGradient.brandGradient)
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    
                    // OTP Input Section
                    VStack(spacing: Spacing.lg) {
                        ZStack {
                            // Hidden TextField for input
                            TextField("", text: $auth.otp)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .foregroundColor(.clear)
                                .accentColor(.clear)
                                .frame(width: 0, height: 0)
                                .focused($isTextFieldFocused)
                                .onChange(of: auth.otp) { newValue in
                                    handleOTPChange(newValue)
                                }
                            
                            // Visual OTP boxes
                            HStack(spacing: Spacing.sm) {
                                ForEach(0..<otpLength, id: \.self) { index in
                                    OTPDigitView(
                                        digit: auth.otp.digits[safe: index] ?? "",
                                        isActive: index == auth.otp.count,
                                        isFilled: index < auth.otp.count,
                                        bounce: bounceIndices[index]
                                    )
                                }
                            }
                        }
                        .onTapGesture {
                            isTextFieldFocused = true
                        }
                        
                        // Error message
                        if showError {
                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.error)
                                    .font(.labelSmall)
                                
                                Text("Invalid verification code. Please try again.")
                                    .font(.labelSmall)
                                    .foregroundColor(.error)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Login Button
                        Button(action: {
                            login()
                        }) {
                            HStack(spacing: Spacing.sm) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Verifying...")
                                        .font(.titleSmall)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Verify Code")
                                        .font(.titleSmall)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                auth.otp.count == otpLength && !isLoading
                                    ? LinearGradient.brandGradient
                                    : LinearGradient(colors: [.appElevated], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(auth.otp.count == otpLength && !isLoading ? .white : .textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .shadow(
                                color: auth.otp.count == otpLength ? .brandPrimary.opacity(0.4) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(auth.otp.count != otpLength || isLoading)
                        .scaleEffect(isLoading ? 0.98 : 1.0)
                        .animation(.snappy, value: isLoading)
                        
                        // Resend Code Section
                        VStack(spacing: Spacing.xs) {
                            Text("Didn't receive the code?")
                                .font(.labelMedium)
                                .foregroundColor(.textTertiary)
                            
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                auth.sendOTP()
                            }) {
                                Text("Resend Code")
                                    .font(.labelLarge)
                                    .foregroundStyle(LinearGradient.brandGradient)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    private func handleOTPChange(_ newValue: String) {
        let filteredValue = String(newValue.prefix(otpLength).filter { $0.isNumber })
        
        if filteredValue != auth.otp {
            auth.otp = filteredValue
            
            // Animate bounce effect for new digits
            if filteredValue.count > 0 && filteredValue.count <= otpLength {
                let lastIndex = filteredValue.count - 1
                withAnimation(.bouncy) {
                    bounceIndices[lastIndex] = true
                }
                
                // Reset bounce after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounceIndices[lastIndex] = false
                }
            }
            
            // Auto-submit when OTP is complete
            if filteredValue.count == otpLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    login()
                }
            }
        }
        
        withAnimation(.smooth) {
            showError = false
        }
    }
    
    private func login() {
        guard auth.otp.count == otpLength else { return }
        
        isLoading = true
        isTextFieldFocused = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        auth.login()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            if !auth.authenticated {
                withAnimation(.bouncy) {
                    showError = true
                }
            }
        }
    }
}

struct OTPDigitView: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool
    let bounce: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(isFilled ? Color.brandPrimary.opacity(0.1) : Color.appElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .strokeBorder(
                            isActive ? LinearGradient.brandGradient :
                            isFilled ? LinearGradient(colors: [.brandPrimary.opacity(0.5)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.textMuted.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 48, height: 58)
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(.bouncy, value: bounce)
            
            Text(digit)
                .font(.headlineSmall)
                .foregroundColor(isFilled ? .brandPrimary : .textSecondary)
            
            // Cursor animation
            if isActive && digit.isEmpty {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
            }
        }
    }
}

#Preview {
    OTPView()
        .environmentObject(UserAuth())
}
