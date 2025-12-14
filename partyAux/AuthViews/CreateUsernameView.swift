//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//
import SwiftUI

struct CreateUsernameView: View {
    @EnvironmentObject var auth: UserAuth
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUsernameValid = false
    @FocusState private var isUsernameFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
            // Premium animated background
            Color.deepNavy
                .ignoresSafeArea()
            
            // Subtle gradient orbs sized relative to screen width
            Circle()
                .fill(Color.electricCyan.opacity(0.1))
                .frame(width: min(geometry.size.width * 0.8, 300), height: min(geometry.size.width * 0.8, 300))
                .blur(radius: 80)
                .offset(x: -geometry.size.width * 0.12, y: -geometry.size.height * 0.06)

            Circle()
                .fill(Color.softPurple.opacity(0.1))
                .frame(width: min(geometry.size.width * 0.7, 250), height: min(geometry.size.width * 0.7, 250))
                .blur(radius: 60)
                .offset(x: geometry.size.width - geometry.size.width * 0.12, y: geometry.size.height - geometry.size.height * 0.12)

            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Header Section
                    VStack(spacing: 24) {
                        // Animated Profile Icon with premium styling
                        LogoView(size: min(geometry.size.width * 0.14, 64), hasBackground: true)
                        
                        VStack(spacing: 10) {
                            Text("Almost There!")
                                .font(Font.premium(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Choose a unique username to complete your profile")
                                .font(Font.premium(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .animation(.smooth.delay(0.2), value: true)
                    
                    // Username Input Section
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "at")
                                    .foregroundColor(.electricCyan)
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Username")
                                    .font(Font.premium(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                            
                            // Premium text field
                            TextField("", text: $auth.username)
                                .placeholder(when: auth.username.isEmpty) {
                                    Text("Choose your username")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .font(Font.premium(size: 16))
                                .foregroundColor(.white)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .focused($isUsernameFocused)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    isUsernameFocused ? 
                                                        Color.electricCyan.opacity(0.6) : 
                                                        Color.white.opacity(0.1),
                                                    lineWidth: isUsernameFocused ? 2 : 1
                                                )
                                        )
                                )
                                .shadow(color: isUsernameFocused ? Color.electricCyan.opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
                                .onChange(of: auth.username) { newValue in
                                    validateUsername(newValue)
                                    withAnimation(.smooth) {
                                        showError = false
                                    }
                                }
                            
                            // Username validation indicators with premium styling
                            VStack(alignment: .leading, spacing: 8) {
                                UsernameValidationRow(
                                    text: "At least 3 characters",
                                    isValid: auth.username.count >= 3
                                )
                                UsernameValidationRow(
                                    text: "Only letters, numbers, and underscores",
                                    isValid: auth.username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
                                )
                                UsernameValidationRow(
                                    text: "No spaces or special characters",
                                    isValid: !auth.username.contains(" ") && auth.username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
                                )
                            }
                            .padding(.top, 4)
                            .animation(.smooth, value: auth.username)
                            
                            if showError {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.coralPink)
                                        .font(.system(size: 12))
                                    
                                    Text(errorMessage)
                                        .font(Font.premium(size: 12))
                                        .foregroundColor(.coralPink)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.coralPink.opacity(0.15))
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.bouncy, value: showError)
                            }
                        }
                        
                        // Create Account Button with premium styling
                        Button(action: {
                            createAccount()
                        }) {
                            ZStack {
                                // Glow effect when valid
                                if isUsernameValid && !isLoading {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.electricCyan)
                                        .blur(radius: 15)
                                        .opacity(0.4)
                                }
                                
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Creating Account...")
                                            .font(Font.premium(size: 16, weight: .semibold))
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Create Account")
                                            .font(Font.premium(size: 16, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if isUsernameValid && !isLoading {
                                            LinearGradient(
                                                colors: [.electricCyan, .softPurple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.white.opacity(0.1)
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isUsernameValid && !isLoading ? 
                                                Color.clear : 
                                                Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .shadow(
                                color: isUsernameValid && !isLoading ? Color.electricCyan.opacity(0.4) : Color.clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                            .scaleEffect(isLoading ? 0.98 : 1.0)
                            .animation(.bouncy, value: isLoading)
                        }
                        .disabled(!isUsernameValid || isLoading)
                    }
                    .padding(.horizontal, 24)
                    .animation(.smooth.delay(0.4), value: true)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            }
        }
        .navigationTitle("Create Username")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.deepNavy, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture {
            isUsernameFocused = false
        }
    }
    
    private func validateUsername(_ username: String) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let isLongEnough = trimmed.count >= 3
        let hasValidCharacters = trimmed.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        let hasNoSpaces = !trimmed.contains(" ")
        
        withAnimation(.smooth) {
            isUsernameValid = isLongEnough && hasValidCharacters && hasNoSpaces && !trimmed.isEmpty
        }
    }
    
    private func createAccount() {
        guard isUsernameValid else {
            withAnimation(.bouncy) {
                showError = true
                errorMessage = "Please enter a valid username"
            }
            return
        }
        
        isLoading = true
        isUsernameFocused = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        auth.signUp()
        
        // Simulate loading time (remove this in production)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Show error if signup failed (add proper error handling here)
            if !auth.authenticated {
                withAnimation(.bouncy) {
                    showError = true
                    errorMessage = "Username might be taken. Please try another."
                }
            }
        }
    }
}

struct UsernameValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(isValid ? Color.green : Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                
                if isValid {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(text)
                .font(Font.premium(size: 12))
                .foregroundColor(isValid ? .white.opacity(0.7) : .white.opacity(0.4))
        }
        .animation(.smooth, value: isValid)
    }
}

#Preview {
    CreateUsernameView()
        .environmentObject(UserAuth())
}
