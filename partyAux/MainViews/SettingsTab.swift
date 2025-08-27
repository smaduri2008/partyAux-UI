import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject var userAuth: UserAuth
    @State private var showProfileSettings = false
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    // Profile picture section at the top
                    ProfilePictureHeader(userAuth: userAuth)
                    ProfileSettingsView2()
                }
                
                Section(header: Text("Actions")) {
                    // Logout button
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    userAuth.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

// Profile picture header (not a Form, just a View)
struct ProfilePictureHeader: View {
    var userAuth: UserAuth
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        VStack {
            Button {
                showImagePicker = true
            } label: {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 4)
                } else if let savedImage = ProfileImageStore.shared.load(for: userAuth.email) {
                    Image(uiImage: savedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
            }
            Text("Tap to change picture")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear {
            profileImage = ProfileImageStore.shared.load(for: userAuth.email)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }
}

// Profile view for the user's info
struct ProfileSettingsView2: View {
    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        Group {
            // Username row - display only (no editing)
            HStack {
                Text("Username")
                    .foregroundColor(.primary)
                Spacer()
                Text(userAuth.username)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Email")
                Spacer()
                Text(userAuth.email)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        Section(header: Text("Notifications")) {
            Text("Notifications Settings")
        }
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Section(header: Text("Appearance")) {
            Text("Appearance Settings")
        }
    }
}

struct AboutView: View {
    var body: some View {
        Section(header: Text("About")) {
            Text("PartyAux\nVersion 1.0.0")
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
