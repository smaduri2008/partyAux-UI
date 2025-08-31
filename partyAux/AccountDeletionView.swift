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
            // Dark background to match OTP view
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Warning icon and text
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Delete Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("This action is permanent and cannot be undone. All your data, playlists, and account information will be permanently deleted.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                if !otpSent {
                    // Initial warning and send OTP button
                    VStack(spacing: 16) {
                        Text("To proceed, we'll send a verification code to your email address: \(userAuth.email)")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: sendDeletionOTP) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "envelope.fill")
                                }
                                Text(isLoading ? "Sending..." : "Send Verification Code")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                    }
                } else {
                    // OTP input and delete button
                    VStack(spacing: 32) {
                        Text("Enter the verification code sent to your email:")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        // OTP Input Section (same as OTP view)
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
                            
                            // Visual OTP boxes
                            HStack(spacing: 16) {
                                ForEach(0..<otpLength, id: \.self) { index in
                                    OTPDigitView(
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
                            showingConfirmation = true
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(isLoading ? "Deleting..." : "Delete Account Permanently")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        otpCode.count == otpLength && !isLoading ? Color.red : Color.gray.opacity(0.5),
                                        otpCode.count == otpLength && !isLoading ? Color.red.opacity(0.8) : Color.gray.opacity(0.5)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: otpCode.count == otpLength ? Color.red.opacity(0.3) : Color.clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(otpCode.count != otpLength || isLoading)
                        .padding(.horizontal)
                        
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
        
        guard let url = URL(string: "\(userAuth.url)/send-account-deletion-otp") else {
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
        
        guard let url = URL(string: "\(userAuth.url)/delete-account") else {
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

/*
// Reuse the same OTPDigitView from the OTP view
struct OTPDigitView: View {
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
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isFilled ? Color.purple.opacity(0.5) : Color.gray.opacity(0.3)
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
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
            }
        }
    }
}

// Extension to safely access string characters by index
extension String {
    var digits: [String] {
        return self.map { String($0) }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}*/

#Preview {
    AccountDeletionView()
        .environmentObject(UserAuth())
}
