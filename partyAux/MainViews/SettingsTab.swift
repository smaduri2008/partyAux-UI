import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject var userAuth: UserAuth
    @State private var showProfileSettings = false
    @State private var showingLogoutAlert = false
    @State private var showingAccountDeletion = false

    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                Color.deepNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Section
                        ProfilePictureHeader(userAuth: userAuth)
                            .padding(.top, 20)
                        
                        // Account Section
                        SettingsTabSection(title: "Account", icon: "person.fill", iconColor: .electricCyan) {
                            VStack(spacing: 0) {
                                SettingsInfoRow(label: "Username", value: userAuth.username)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                SettingsInfoRow(label: "Email", value: userAuth.email)
                            }
                        }
                        
                        // Actions Section
                        SettingsTabSection(title: "Actions", icon: "hand.tap.fill", iconColor: .coralPink) {
                            VStack(spacing: 12) {
                                // Logout button
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    showingLogoutAlert = true
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "arrow.backward.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Text("Log Out")
                                            .font(Font.premium(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.03))
                                    )
                                }
                                
                                // Delete account button
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    showingAccountDeletion = true
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.red)
                                        }
                                        
                                        Text("Delete Account")
                                            .font(Font.premium(size: 15, weight: .medium))
                                            .foregroundColor(.red)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.05))
                                    )
                                }
                            }
                        }

                        // About Section
                        SettingsTabSection(title: "About", icon: "info.circle.fill", iconColor: .softPurple) {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("PartyAux")
                                        .font(Font.premium(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("Version 1.0.0")
                                        .font(Font.premium(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                // Privacy Policy Link
                                Link(destination: URL(string: "https://www.termsfeed.com/live/15f4c5b4-9fdc-4b6a-966a-b25d21eeecc5")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.electricCyan)
                                        
                                        Text("Privacy Policy")
                                            .font(Font.premium(size: 15, weight: .medium))
                                            .foregroundColor(.electricCyan)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitle("Settings", displayMode: .large)
            .toolbarBackground(Color.deepNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    userAuth.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .sheet(isPresented: $showingAccountDeletion) {
                AccountDeletionView()
                    .environmentObject(userAuth)
            }
        }
    }
}

// MARK: - Settings Tab Section
struct SettingsTabSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(Font.premium(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.leading, 4)
            
            // Content card
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.premium(size: 14))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(Font.premium(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
    }
}

// Profile picture header
struct ProfilePictureHeader: View {
    var userAuth: UserAuth
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        VStack(spacing: 16) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showImagePicker = true
            } label: {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.electricCyan)
                        .frame(width: 130, height: 130)
                        .blur(radius: 25)
                        .opacity(0.3)
                    
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.electricCyan, .softPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: .electricCyan.opacity(0.3), radius: 12, x: 0, y: 6)
                    } else if let savedImage = ProfileImageStore.shared.load(for: userAuth.email) {
                        Image(uiImage: savedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.electricCyan, .softPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: .electricCyan.opacity(0.3), radius: 12, x: 0, y: 6)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.softPurple.opacity(0.3), .electricCyan.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    }
                    
                    // Edit badge
                    Circle()
                        .fill(Color.electricCyan)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .electricCyan.opacity(0.4), radius: 6, x: 0, y: 3)
                        .offset(x: 42, y: 42)
                }
            }
            
            Text("Tap to change picture")
                .font(Font.premium(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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
