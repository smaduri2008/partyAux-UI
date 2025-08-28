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
            VStack(spacing: 0) {
                // Song info header
                VStack(spacing: 12) {
                    // Song thumbnail
                    if let imageUrlString = song["album_art"] as? String,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Song details
                    VStack(spacing: 4) {
                        Text(songTitle)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(songArtist)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Playlists list
                if playlistManager.userPlaylists.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("No Playlists")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Create a playlist to add this song to")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Create Playlist") {
                            showingCreatePlaylist = true
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(8)
                    }
                    Spacer()
                } else {
                    List {
                        Section {
                            ForEach(playlistManager.userPlaylists, id: \.id) { playlist in
                                PlaylistSelectionRow(
                                    playlist: playlist,
                                    isSelected: selectedPlaylists.contains(playlist.playlistId),
                                    onToggle: { togglePlaylistSelection(playlist.playlistId) }
                                )
                                .listRowBackground(Color.black)
                            }
                        } header: {
                            Text("Select playlists to add to:")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .textCase(nil)
                        }
                        
                        Section {
                            Button(action: {
                                showingCreatePlaylist = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                    
                                    Text("Create New Playlist")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                    
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Add") {
                    addToSelectedPlaylists()
                }
                .foregroundColor(selectedPlaylists.isEmpty || isAdding ? .gray : .white)
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
        if selectedPlaylists.contains(playlistId) {
            selectedPlaylists.remove(playlistId)
        } else {
            selectedPlaylists.insert(playlistId)
        }
    }
    
    private func addToSelectedPlaylists() {
        guard !selectedPlaylists.isEmpty else { return }
        
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
                        presentationMode.wrappedValue.dismiss()
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
            HStack(spacing: 12) {
                // Playlist icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                // Playlist info
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(playlist.songs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
