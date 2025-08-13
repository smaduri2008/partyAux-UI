import SwiftUI

struct CreateUsernameView: View {
    @EnvironmentObject var auth: UserAuth
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUsernameValid = false
    @FocusState private var isUsernameFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Header Section
                    VStack(spacing: 20) {
                        // Animated Profile Icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.white.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Almost There!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Choose a unique username to complete your profile")
                                .font(.callout)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .animation(.smooth.delay(0.2), value: true)
                    
                    // Username Input Section
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "at")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Username")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                    .fontWeight(.medium)
                            }
                            
                            TextField("Choose your username", text: $auth.username)
                                .textFieldStyle(ModernTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .focused($isUsernameFocused)
                                .onChange(of: auth.username) { newValue in
                                    validateUsername(newValue)
                                    withAnimation(.smooth) {
                                        showError = false
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isUsernameFocused ? LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing) : 
                                            LinearGradient(gradient: Gradient(colors: [Color.clear]), startPoint: .leading, endPoint: .trailing),
                                            lineWidth: isUsernameFocused ? 2 : 1
                                        )
                                        .animation(.smooth, value: isUsernameFocused)
                                )
                            
                            // Username validation indicators
                            VStack(alignment: .leading, spacing: 4) {
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
                            .animation(.smooth, value: auth.username)
                            
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.bouncy, value: showError)
                            }
                        }
                        
                        // Create Account Button
                        Button(action: {
                            createAccount()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating Account...")
                                        .font(.headline)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if isUsernameValid && !isLoading {
                                        LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing)
                                    } else {
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.3)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .foregroundColor(isUsernameValid && !isLoading ? .black : .textTertiary)
                            .cornerRadius(12)
                            .shadow(
                                color: isUsernameValid ? Color.white.opacity(0.3) : Color.clear,
                                radius: 8,
                                x: 0,
                                y: 4
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
        .navigationTitle("Create Username")
        .navigationBarTitleDisplayMode(.inline)
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
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isValid ? .green : .textTertiary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .textSecondary : .textTertiary)
        }
        .animation(.smooth, value: isValid)
    }
}

#Preview {
    CreateUsernameView()
        .environmentObject(UserAuth())
}
