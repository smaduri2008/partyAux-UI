//
//  SettingsView.swift
//  partyAux
//
//  Created by Sansky Srivastava on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var playOnHostOnly = false
    @State private var showProfileSettings = false
    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Profile")) {
                    Button {
                        showProfileSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                            Text("Profile Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("Audio")) {
                    Toggle(isOn: $playOnHostOnly) {
                        HStack {
                            Image(systemName: "speaker.3.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Play on Host Device Only")
                                Text("Audio will only play on the host’s device")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $showProfileSettings) {
                ProfileSettingsView()
                    .environmentObject(userAuth)
            }
        }
    }
}

// MARK: - Profile Settings
struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userAuth: UserAuth

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        Form {
            // Profile Picture
            Section {
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
            }

            // Account Info
            Section(header: Text("Account Information")) {
                TextField("Username", text: $username)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
            }

            // Save
            Section {
                Button("Save Changes") {
                    userAuth.username = username
                    userAuth.email = email
                    if let profileImage = profileImage {
                        ProfileImageStore.shared.save(profileImage, for: email)
                    }
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Profile Settings")
        .onAppear {
            username = userAuth.username
            email = userAuth.email
            profileImage = ProfileImageStore.shared.load(for: userAuth.email)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
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

// MARK: - Preview
#Preview {
    SettingsView().environmentObject(UserAuth())
}
