//
//  CreatePlaylistView.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import SwiftUI

struct CreatePlaylistView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @Environment(\.presentationMode) var presentationMode
    @State private var playlistName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    private var isFormValid: Bool {
        !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                Color.deepNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section with playlist icon
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Premium playlist icon
                        ZStack {
                            // Glow effect
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.brandSecondary.opacity(0.3))
                                .frame(width: 150, height: 150)
                                .blur(radius: 30)
                                .opacity(0.4)
                            
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.appElevated)
                                .frame(width: 140, height: 140)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.brandSecondary.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .brandSecondary.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            LogoView(size: 70, hasBackground: false)
                        }
                        
                        VStack(spacing: 10) {
                            Text("Create New Playlist")
                                .font(Font.premium(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Organize your favorite songs")
                                .font(Font.premium(size: 15))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Form section
                    VStack(spacing: 24) {
                        // Name input with premium styling
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 12))
                                    .foregroundColor(.electricCyan)
                                
                                Text("Playlist Name")
                                    .font(Font.premium(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.softPurple)
                                    .font(.system(size: 16))
                                
                                TextField("", text: $playlistName)
                                    .placeholder(when: playlistName.isEmpty) {
                                        Text("Enter playlist name")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .font(Font.premium(size: 16))
                                    .foregroundColor(.white)
                                    .focused($isTextFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        createPlaylist()
                                    }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                isTextFieldFocused ? Color.electricCyan.opacity(0.6) : Color.white.opacity(0.1),
                                                lineWidth: isTextFieldFocused ? 2 : 1
                                            )
                                    )
                            )
                            .shadow(color: isTextFieldFocused ? Color.electricCyan.opacity(0.2) : .clear, radius: 10)
                        }
                        
                        // Error message
                        if let errorMessage = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.coralPink)
                                    .font(.system(size: 14))
                                Text(errorMessage)
                                    .foregroundColor(.coralPink)
                                    .font(Font.premium(size: 13))
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.coralPink.opacity(0.15))
                            )
                        }
                        
                        // Create button with premium styling
                        Button(action: createPlaylist) {
                            ZStack {
                                // Glow effect when valid
                                if isFormValid && !isCreating {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.electricCyan)
                                        .blur(radius: 15)
                                        .opacity(0.4)
                                }
                                
                                HStack(spacing: 10) {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                        Text("Creating...")
                                            .font(Font.premium(size: 16, weight: .semibold))
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Create Playlist")
                                            .font(Font.premium(size: 16, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if isFormValid && !isCreating {
                                            LinearGradient(
                                                colors: [.electricCyan, .softPurple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.white.opacity(0.1)
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isFormValid && !isCreating ? Color.clear : Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .shadow(
                                color: isFormValid && !isCreating ? .electricCyan.opacity(0.4) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(!isFormValid || isCreating)
                        .scaleEffect(isFormValid && !isCreating ? 1.0 : 0.98)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.deepNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(Font.premium(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .font(Font.premium(size: 15, weight: .semibold))
                    .foregroundColor(isFormValid && !isCreating ? .electricCyan : .white.opacity(0.3))
                    .disabled(!isFormValid || isCreating)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func createPlaylist() {
        guard isFormValid else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        isCreating = true
        
        playlistManager.createPlaylist(name: trimmedName) { success, error in
            isCreating = false
            
            if success {
                let successGenerator = UINotificationFeedbackGenerator()
                successGenerator.notificationOccurred(.success)
                presentationMode.wrappedValue.dismiss()
            } else {
                let errorGenerator = UINotificationFeedbackGenerator()
                errorGenerator.notificationOccurred(.error)
                errorMessage = error ?? "Failed to create playlist"
            }
        }
    }
}
