import SwiftUI

struct CreateUsernameView: View {
    @EnvironmentObject var auth: UserAuth

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Choose a Username")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                TextField("Username", text: $auth.username)
                    .padding()
                    .background(Color(.darkGray))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .autocapitalization(.none)

                Button(action: {
                    auth.signUp()
                }) {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 123/255, green: 97/255, blue: 255/255))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Create Username")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CreateUsernameView()
        .environmentObject(UserAuth())
}
