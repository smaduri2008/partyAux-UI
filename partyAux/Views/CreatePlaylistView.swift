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
    
    private var buttonBackground: some View {
        Group {
            if !isFormValid || isCreating {
                Color.gray.opacity(0.3)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
    
    private var buttonShadowColor: Color {
        isFormValid ? .purple.opacity(0.4) : .clear
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                // Title
                Text("Create Playlist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlist Name")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Enter playlist name", text: $playlistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            createPlaylist()
                        }
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Create button
                Button(action: createPlaylist) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Creating...")
                                .font(.headline)
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Create Playlist")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(buttonBackground)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: buttonShadowColor, radius: 12, x: 0, y: 6)
                }
                .disabled(!isFormValid || isCreating)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Create") {
                    createPlaylist()
                }
                .foregroundColor(isFormValid ? .white : .gray)
                .disabled(!isFormValid || isCreating)
            )
        }
        .onAppear {
            isTextFieldFocused = true
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
