import SwiftUI

struct AccountDeletionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userAuth: UserAuth
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingConfirmation = false
    @State private var otpSent = false
    @State private var bounceIndices: [Bool] = Array(repeating: false, count: 6)
    @FocusState private var isTextFieldFocused: Bool
    private let otpLength = 6
    
    var body: some View {
        ZStack {
            // Premium dark background
            Color.deepNavy
                .ignoresSafeArea()
            
            // Subtle gradient orbs
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.coralPink.opacity(0.1))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: 120, y: 300)
            
            VStack(spacing: 28) {
                // Warning icon and text
                VStack(spacing: 20) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color.red)
                            .frame(width: 90, height: 90)
                            .blur(radius: 25)
                            .opacity(0.3)
                        
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                            )
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                    }
                    
                    Text("Delete Account")
                        .font(Font.premium(size: 28, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("This action is permanent and cannot be undone. All your data, playlists, and account information will be permanently deleted.")
                        .font(Font.premium(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                }
                
                if !otpSent {
                    // Initial warning and send OTP button
                    VStack(spacing: 20) {
                            Text("To proceed, we'll send a verification code to your email address: \(userAuth.email)")
                            .font(Font.premium(size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 24)
                        
                        Button(action: sendDeletionOTP) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                }
                                Text(isLoading ? "Sending..." : "Send Verification Code")
                                        .font(Font.premium(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.red, .coralPink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 24)
                    }
                } else {
                    // OTP input and delete button
                    VStack(spacing: 28) {
                            Text("Enter the verification code sent to your email:")
                                .font(Font.premium(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        // OTP Input Section
                        ZStack {
                            // Hidden TextField for input
                            TextField("", text: $otpCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .foregroundColor(.clear)
                                .accentColor(.clear)
                                .frame(width: 0, height: 0)
                                .focused($isTextFieldFocused)
                                .onChange(of: otpCode) { newValue in
                                    handleOTPChange(newValue)
                                }
                            
                            // Visual OTP boxes with premium styling
                            HStack(spacing: 12) {
                                ForEach(0..<otpLength, id: \.self) { index in
                                    DeletionOTPDigitView(
                                        digit: otpCode.digits[safe: index] ?? "",
                                        isActive: index == otpCode.count,
                                        isFilled: index < otpCode.count,
                                        bounce: bounceIndices[index]
                                    )
                                }
                            }
                        }
                        .onTapGesture {
                            isTextFieldFocused = true
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            showingConfirmation = true
                        }) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14))
                                }
                                Text(isLoading ? "Deleting..." : "Delete Account Permanently")
                                            .font(Font.premium(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Group {
                                    if otpCode.count == otpLength && !isLoading {
                                        LinearGradient(colors: [.red, .coralPink], startPoint: .leading, endPoint: .trailing)
                                    } else {
                                        Color.white.opacity(0.1)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        otpCode.count == otpLength && !isLoading ? Color.clear : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: otpCode.count == otpLength ? Color.red.opacity(0.4) : Color.clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(otpCode.count != otpLength || isLoading)
                        .padding(.horizontal, 24)
                        
                        Button("Resend Code") {
                            sendDeletionOTP()
                        }
                        .foregroundColor(.blue)
                        .disabled(isLoading)
                    }
                }
                
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("Delete Account", displayMode: .inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.blue)
        )
        .alert("Final Confirmation", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This is your final warning. Your account and all associated data will be permanently deleted. This action cannot be undone.")
        }
        .onAppear {
            if otpSent {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleOTPChange(_ newValue: String) {
        let filteredValue = String(newValue.prefix(otpLength).filter { $0.isNumber })
        
        if filteredValue != otpCode {
            otpCode = filteredValue
            
            // Animate bounce effect for new digits
            if filteredValue.count > 0 && filteredValue.count <= otpLength {
                let lastIndex = filteredValue.count - 1
                withAnimation(.bouncy(duration: 0.3)) {
                    bounceIndices[lastIndex] = true
                }
                
                // Reset bounce after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounceIndices[lastIndex] = false
                }
            }
        }
        
        withAnimation(.smooth) {
            errorMessage = ""
        }
    }
    
    private func sendDeletionOTP() {
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/send-account-deletion-otp") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "jwt": userAuth.jwt ?? ""
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            errorMessage = "Failed to create request"
            isLoading = false
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No response from server"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        if message.contains("successfully") {
                            otpSent = true
                            errorMessage = ""
                            // Clear any existing OTP and focus the text field
                            otpCode = ""
                            isTextFieldFocused = true
                        } else {
                            errorMessage = message
                        }
                    } else {
                        errorMessage = "Invalid response format"
                    }
                } catch {
                    errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    private func deleteAccount() {
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/delete-account") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "jwt": userAuth.jwt ?? "",
            "otp": otpCode
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            errorMessage = "Failed to create request"
            isLoading = false
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No response from server"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        if message.contains("successfully") {
                            // Account deleted successfully, log out user
                            userAuth.logout()
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            errorMessage = message
                            // Clear OTP on error
                            otpCode = ""
                            isTextFieldFocused = true
                        }
                    } else {
                        errorMessage = "Invalid response format"
                    }
                } catch {
                    errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
}

// MARK: - Deletion OTP Digit View
struct DeletionOTPDigitView: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool
    let bounce: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isActive ?
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.coralPink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isFilled ? Color.red.opacity(0.5) : Color.gray.opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 48, height: 56)
                .scaleEffect(bounce ? 1.05 : 1.0)
                .animation(.bouncy(duration: 0.3), value: bounce)
            
            // Digit text
            Text(digit)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isFilled ? .white : .gray.opacity(0.5))
            
            // Cursor animation
            if isActive && digit.isEmpty {
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.coralPink]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
            }
        }
    }
}

// NOTE: `digits` and `subscript(safe:)` are defined in `Helpers.swift` for global use.
// We no longer redeclare them here to avoid duplicate-symbol compile errors.

#Preview {
    AccountDeletionView()
        .environmentObject(UserAuth())
}
