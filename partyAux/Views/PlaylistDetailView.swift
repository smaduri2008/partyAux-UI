//
//  PlaylistDetailView.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import SwiftUI

struct PlaylistDetailView: View {
    @State var playlist: Playlist
    @ObservedObject var playlistManager: PlaylistManager
    @EnvironmentObject var roomManager: RoomManager
    @EnvironmentObject var queueManager: QueueManager
    @State private var showingDeleteAlert = false
    @State private var showingVisibilityAlert = false
    @State private var songToDelete: PlaylistSong?
    @State private var animatedIndex: Int? = nil
    @State private var editMode: EditMode = .inactive
    @Environment(\.presentationMode) var presentationMode
    
    var isOwner: Bool {
        return playlist.owner == playlistManager.userEmail
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with playlist info
            VStack(spacing: 16) {
                // Playlist artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                // Playlist details
                VStack(spacing: 8) {
                    Text(playlist.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Text("\(playlist.songs.count) songs")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: playlist.isPublic ? "globe" : "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(playlist.isPublic ? .green : .gray)
                            
                            Text(playlist.isPublic ? "Public" : "Private")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if !isOwner {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                
                                Text("by \(playlist.owner)")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                
                // Action buttons
                if isOwner {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingVisibilityAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: playlist.isPublic ? "lock.fill" : "globe")
                                    .font(.system(size: 14))
                                Text(playlist.isPublic ? "Make Private" : "Make Public")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            editMode = editMode == .active ? .inactive : .active
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: editMode == .active ? "checkmark" : "pencil")
                                    .font(.system(size: 14))
                                Text(editMode == .active ? "Done" : "Edit")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.black)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Songs list
            if playlist.songs.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No Songs Yet")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Add songs to this playlist from the search tab")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(playlist.songs.indices, id: \.self) { index in
                        let song = playlist.songs[index]
                        PlaylistSongRowView(
                            song: song,
                            index: index,
                            canEdit: isOwner && editMode == .active,
                            onDelete: {
                                songToDelete = song
                                showingDeleteAlert = true
                            },
                            onAddToQueue: {
                                addSongToQueue(song: song, index: index)
                            }
                        )
                        .listRowBackground(Color.black)
                        .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                    }
                    .onMove(perform: isOwner && editMode == .active ? moveSongs : nil)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, $editMode)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Song", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let songToDelete = songToDelete {
                    deleteSong(songToDelete)
                }
            }
        } message: {
            Text("Are you sure you want to remove this song from the playlist?")
        }
        .alert("Change Visibility", isPresented: $showingVisibilityAlert) {
            Button("Cancel", role: .cancel) { }
            Button(playlist.isPublic ? "Make Private" : "Make Public") {
                toggleVisibility()
            }
        } message: {
            Text(playlist.isPublic ? "This will make your playlist private. Only you will be able to see it." : "This will make your playlist public. Everyone will be able to discover and view it.")
        }
    }
    
    private func addSongToQueue(song: PlaylistSong, index: Int) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animation
        withAnimation(.easeInOut(duration: 0.2)) {
            animatedIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animatedIndex = nil
            }
        }
        
        // Convert PlaylistSong to the format expected by the API
        let songDict: [String: Any] = [
            "title": song.title,
            "artist": song.artist,
            "duration": song.duration,
            "album_art": song.thumbnail,
            "url": song.videoId
        ]
        
        // Add to queue
        guard let urlRequest = URL(string: "http://35.208.64.59/add-song-to-queue") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "room": roomManager.roomCode,
            "jwt": roomManager.userData.jwt,
            "song": songDict
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { _, _, _ in
            queueManager.fetchQueue { }
        }.resume()
    }
    
    private func deleteSong(_ song: PlaylistSong) {
        var updatedSongs = playlist.songs
        updatedSongs.removeAll { $0.id == song.id }
        
        playlistManager.updatePlaylist(playlistId: playlist.playlistId, songs: updatedSongs) { success in
            if success {
                playlist.songs = updatedSongs
            }
        }
    }
    
    private func moveSongs(from source: IndexSet, to destination: Int) {
        var updatedSongs = playlist.songs
        updatedSongs.move(fromOffsets: source, toOffset: destination)
        
        playlistManager.updatePlaylist(playlistId: playlist.playlistId, songs: updatedSongs) { success in
            if success {
                playlist.songs = updatedSongs
            }
        }
    }
    
    private func toggleVisibility() {
        playlistManager.changePlaylistVisibility(playlistId: playlist.playlistId, isPublic: !playlist.isPublic) { success in
            if success {
                playlist = Playlist(from: [
                    "_id": playlist.id,
                    "playlist_id": playlist.playlistId,
                    "name": playlist.name,
                    "owner": playlist.owner,
                    "public": !playlist.isPublic,
                    "songs": playlist.songs.map { $0.toDict() }
                ])
            }
        }
    }
}

struct PlaylistSongRowView: View {
    let song: PlaylistSong
    let index: Int
    let canEdit: Bool
    let onDelete: () -> Void
    let onAddToQueue: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Song number or thumbnail
            if let imageUrl = URL(string: song.thumbnail) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 2)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                    
                    if !song.duration.isEmpty {
                        Text("• \(formatDuration(song.duration))")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                if canEdit {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: onAddToQueue) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ durationString: String) -> String {
        var minutes = 0
        var seconds = 0
        let lowercased = durationString.lowercased()

        if let minMatch = lowercased.range(of: #"(\d+)\s*minute"#, options: .regularExpression) {
            let minStr = String(lowercased[minMatch])
            let digits = minStr.filter("0123456789".contains)
            minutes = Int(digits) ?? 0
        }

        if let secMatch = lowercased.range(of: #"(\d+)\s*second"#, options: .regularExpression) {
            let secStr = String(lowercased[secMatch])
            let digits = secStr.filter("0123456789".contains)
            seconds = Int(digits) ?? 0
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}
