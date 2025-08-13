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
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 40)
                    
                    // Header Section
                    VStack(spacing: 20) {
                        // Back Button
                        HStack {
                            Button(action: {
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Navigate back - this will be handled by NavigationView
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Back")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                            }
                            Spacer()
                        }
                        
                        // Title and subtitle
                        VStack(spacing: 12) {
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            
                            Text("Verification Code")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 4) {
                                Text("Enter the 6-digit code sent to")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                
                                Text(auth.email)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    .animation(.smooth.delay(0.2), value: true)
                    
                    // OTP Input Section
                    VStack(spacing: 24) {
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
                            HStack(spacing: 12) {
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
                        .animation(.smooth.delay(0.4), value: true)
                        
                        // Error message
                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                
                                Text("Invalid verification code. Please try again.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.bouncy, value: showError)
                        }
                        
                        // Login Button
                        Button(action: {
                            login()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Verifying...")
                                        .font(.headline)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Verify Code")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if auth.otp.count == otpLength && !isLoading {
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
                            .foregroundColor(auth.otp.count == otpLength && !isLoading ? .black : .textTertiary)
                            .cornerRadius(12)
                            .shadow(
                                color: auth.otp.count == otpLength ? Color.white.opacity(0.3) : Color.clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(isLoading ? 0.98 : 1.0)
                            .animation(.bouncy, value: isLoading)
                        }
                        .disabled(auth.otp.count != otpLength || isLoading)
                        
                        // Resend Code Section
                        VStack(spacing: 8) {
                            Text("Didn't receive the code?")
                                .font(.footnote)
                                .foregroundColor(.textTertiary)
                            
                            Button(action: {
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                auth.sendOTP()
                                
                                // Show success feedback
                                withAnimation(.bouncy) {
                                    // Add some visual feedback here if needed
                                }
                            }) {
                                Text("Resend Code")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                        .animation(.smooth.delay(0.6), value: true)
                    }
                    .padding(.horizontal, 24)
                    
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
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        auth.login()
        
        // Simulate loading time (remove this in production)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Show error if login failed (add proper error handling here)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isFilled ? Color.white.opacity(0.1) : Color.appCardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isActive ? LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing) : 
                            LinearGradient(
                                gradient: Gradient(colors: [isFilled ? Color.white : Color.appSurface]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 45, height: 55)
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(.bouncy, value: bounce)
            
            Text(digit)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isFilled ? .white : .textSecondary)
            
            // Cursor animation
            if isActive && digit.isEmpty {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: 20)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
            }
        }
    }
}

#Preview {
    OTPView()
        .environmentObject(UserAuth())
}
