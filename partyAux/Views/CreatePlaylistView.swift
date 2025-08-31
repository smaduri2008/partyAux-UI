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
            VStack(spacing: 0) {
                // Header section with playlist icon
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Large playlist icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 140, height: 140)
                            .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 56))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Create New Playlist")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Organize your favorite songs")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .background(Color.black)
                
                // Form section
                VStack(spacing: 24) {
                    // Name input with modern styling
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playlist Name")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.purple)
                                .font(.system(size: 16))
                            
                            TextField("Enter playlist name", text: $playlistName)
                                .foregroundColor(.white)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    createPlaylist()
                                }
                        }
                        .padding(16)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTextFieldFocused ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Create button
                    Button(action: createPlaylist) {
                        HStack(spacing: 12) {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                                Text("Creating...")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Create Playlist")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Group {
                                if isFormValid && !isCreating {
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(
                            color: isFormValid && !isCreating ? .purple.opacity(0.4) : .clear,
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
                .background(Color.black)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .foregroundColor(isFormValid && !isCreating ? .purple : .gray)
                    .disabled(!isFormValid || isCreating)
                    .font(.headline)
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
        
        let trimmedName = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        isCreating = true
        
        playlistManager.createPlaylist(name: trimmedName) { success, error in
            isCreating = false
            
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = error ?? "Failed to create playlist"
            }
        }
    }
}
