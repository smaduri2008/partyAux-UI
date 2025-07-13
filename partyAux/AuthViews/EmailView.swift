import SwiftUI

struct EmailView: View {
    @EnvironmentObject var auth: UserAuth

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Welcome to PartyAux")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
        /*
                AsyncImage(url: URL(string: "https://lh3.googleusercontent.com/q_oaNMGsrAW0fnrdyYWj7C9Mw-ZMCmCn-mf4EH8VPc3AAkN9fV58RF7jKk4Heb0OS_csYolODGPsZwyboA=w500-h500-l90-rj")) { phase in
                                   if let image = phase.image {
                                       image
                                           .resizable()
                                           .scaledToFit()
                                           .frame(width: 150, height: 150)
                                           .clipShape(RoundedRectangle(cornerRadius: 12))
                                   } else if phase.error != nil {
                                       Text("Failed to load image")
                                           .foregroundColor(.red)
                                   } else {
                                       ProgressView()
                                   }
                               }
         */

                Text("Enter your email to get started")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                TextField("Email", text: $auth.email)
                    .padding()
                    .background(Color(.darkGray))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .autocapitalization(.none)

                Button(action: {
                    auth.sendOTP()
                    auth.showOTPView = true
                }) {
                    Text("Send OTP")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 123/255, green: 97/255, blue: 255/255))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                
                NavigationLink(destination: OTPView(), isActive: $auth.showOTPView) {
                                    EmptyView()
                                }
                                .hidden()
/*
                if auth.showOTPView {
                    OTPView()
                        .transition(.slide)
                }
 */
            }
            .padding()
        }
    }
}

#Preview {
    EmailView()
        .environmentObject(UserAuth())
}
