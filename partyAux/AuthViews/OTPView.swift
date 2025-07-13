import SwiftUI

struct OTPView: View {
    @EnvironmentObject var auth: UserAuth
    @FocusState private var isTextFieldFocused: Bool
    private let otpLength = 6
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Enter the OTP code sent to your email")
                    .foregroundColor(.white)
                    .font(.headline)

                ZStack {
                    TextField("", text: $auth.otp)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .foregroundColor(.clear)
                        .accentColor(.clear)
                        .frame(width: 0, height: 0)
                        .focused($isTextFieldFocused)
                        .onChange(of: auth.otp) { newValue in
                            if newValue.count > otpLength {
                                auth.otp = String(newValue.prefix(otpLength))
                            }
                        }
                    
                    HStack(spacing: 12) {
                        ForEach(0..<otpLength, id: \.self) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 123/255, green: 97/255, blue: 255/255), lineWidth: 2)
                                    .frame(width: 45, height: 55)
                                
                                Text(auth.otp.digits[safe: index] ?? "")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .onTapGesture {
                    isTextFieldFocused = true
                }

                Button("Login") {
                    auth.login()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(red: 123/255, green: 97/255, blue: 255/255))
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .padding(20)
        }
    }
}

#Preview {
    OTPView()
        .environmentObject(UserAuth())
}
