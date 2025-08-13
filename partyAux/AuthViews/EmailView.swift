import SwiftUI

struct EmailView: View {
    @EnvironmentObject var auth: UserAuth
    @State private var isLoading = false
    @State private var showError = false
    @State private var isEmailValid = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Hero Section
                    VStack(spacing: 16) {
                        Text("Welcome to")
                            .font(.title3)
                            .foregroundColor(.textSecondary)
                            .opacity(0.8)
                        
                        Text("PartyAux")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    .animation(.smooth.delay(0.2), value: true)
                    
                    // Subtitle
                    VStack(spacing: 8) {
                        Text("Share music, create memories")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Enter your email to get started")
                            .font(.subheadline)
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .animation(.smooth.delay(0.4), value: true)
                    
                    // Email Input Section
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.appPrimary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Email Address")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                                    .fontWeight(.medium)
                            }
                            
                            TextField("Enter your email", text: $auth.email)
                                .textFieldStyle(ModernTextFieldStyle())
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isEmailFocused ? LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing) : 
                                            LinearGradient(gradient: Gradient(colors: [Color.clear]), startPoint: .leading, endPoint: .trailing),
                                            lineWidth: isEmailFocused ? 2 : 1
                                        )
                                        .animation(.smooth, value: isEmailFocused)
                                )
                            
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.bouncy, value: showError)
                            }
                        }
                        
                        // Send OTP Button
                        Button(action: {
                            if isEmailValid {
                                isLoading = true
                                isEmailFocused = false
                                
                                // Add haptic feedback
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
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Sending...")
                                        .font(.headline)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Send OTP")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if isEmailValid && !isLoading {
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
                            .foregroundColor(isEmailValid && !isLoading ? .black : .textTertiary)
                            .cornerRadius(12)
                            .shadow(
                                color: isEmailValid ? Color.white.opacity(0.3) : Color.clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(isLoading ? 0.98 : 1.0)
                            .animation(.bouncy, value: isLoading)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    .animation(.smooth.delay(0.6), value: true)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            // Hidden Navigation Link
            NavigationLink(destination: OTPView(), isActive: $auth.showOTPView) {
                EmptyView()
            }
            .hidden()
        }
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
