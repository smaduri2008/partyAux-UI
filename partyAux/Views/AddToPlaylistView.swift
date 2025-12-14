//
//  AddToPlaylistView.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import SwiftUI

struct AddToPlaylistView: View {
    let song: [String: Any]
    @ObservedObject var playlistManager: PlaylistManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPlaylists: Set<String> = []
    @State private var isAdding = false
    @State private var showingCreatePlaylist = false
    
    var songTitle: String {
        song["title"] as? String ?? "Unknown Song"
    }
    
    var songArtist: String {
        song["artist"] as? String ?? "Unknown Artist"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                Color.deepNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Song info header
                    VStack(spacing: 16) {
                        // Song thumbnail with premium styling
                        ZStack {
                            // Glow effect
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.electricCyan)
                                .frame(width: 90, height: 90)
                                .blur(radius: 20)
                                .opacity(0.3)
                            
                            if let imageUrlString = song["album_art"] as? String,
                               let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            ProgressView()
                                                .tint(.electricCyan)
                                        )
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.softPurple, .electricCyan.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // Song details
                        VStack(spacing: 6) {
                            Text(songTitle)
                                .font(Font.premium(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text(songArtist)
                                .font(Font.premium(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 24)
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .electricCyan.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // Playlists list
                    if playlistManager.userPlaylists.isEmpty {
                        Spacer()
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            
                            VStack(spacing: 8) {
                                Text("No Playlists")
                                    .font(Font.premium(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Create a playlist to add this song to")
                                    .font(Font.premium(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                showingCreatePlaylist = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        Text("Create Playlist")
                                        .font(Font.premium(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.electricCyan, .softPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .electricCyan.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Section header
                                HStack(spacing: 8) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 12))
                                        .foregroundColor(.electricCyan)
                                    
                                    Text("Select playlists to add to")
                                        .font(Font.premium(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }
                                .padding(.horizontal, 4)
                                
                                // Playlists
                                VStack(spacing: 10) {
                                    ForEach(playlistManager.userPlaylists, id: \.id) { playlist in
                                        PlaylistSelectionRow(
                                            playlist: playlist,
                                            isSelected: selectedPlaylists.contains(playlist.playlistId),
                                            onToggle: { togglePlaylistSelection(playlist.playlistId) }
                                        )
                                    }
                                }
                                
                                // Create new playlist button
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    showingCreatePlaylist = true
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.electricCyan.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.electricCyan)
                                        }
                                        
                                        Text("Create New Playlist")
                                            .font(Font.premium(size: 15, weight: .semibold))
                                            .foregroundColor(.electricCyan)
                                        
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.electricCyan.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color.electricCyan.opacity(0.05))
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.deepNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                    .font(Font.premium(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7)),
                trailing: Button("Add") {
                    addToSelectedPlaylists()
                }
                .font(Font.premium(size: 15, weight: .semibold))
                .foregroundColor(selectedPlaylists.isEmpty || isAdding ? .white.opacity(0.3) : .electricCyan)
                .disabled(selectedPlaylists.isEmpty || isAdding)
            )
        }
        .onAppear {
            playlistManager.fetchUserPlaylists()
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistView(playlistManager: playlistManager)
        }
    }
    
    private func togglePlaylistSelection(_ playlistId: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if selectedPlaylists.contains(playlistId) {
            selectedPlaylists.remove(playlistId)
        } else {
            selectedPlaylists.insert(playlistId)
        }
    }
    
    private func addToSelectedPlaylists() {
        guard !selectedPlaylists.isEmpty else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        isAdding = true
        let totalPlaylists = selectedPlaylists.count
        var completedCount = 0
        var hasError = false
        
        for playlistId in selectedPlaylists {
            playlistManager.addSongToPlaylist(playlistId: playlistId, song: song) { success in
                completedCount += 1
                if !success {
                    hasError = true
                }
                
                if completedCount == totalPlaylists {
                    isAdding = false
                    if !hasError {
                        generator.notificationOccurred(.success)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        generator.notificationOccurred(.error)
                    }
                }
            }
        }
    }
}

struct PlaylistSelectionRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Playlist icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.softPurple, .electricCyan.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                // Playlist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(Font.premium(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(playlist.songs.count) songs")
                        .font(Font.premium(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
