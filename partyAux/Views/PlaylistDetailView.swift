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
    @State private var showingDeleteAlert = false
    @State private var showingVisibilityAlert = false
    @State private var songToDelete: PlaylistSong?
    @State private var animatedIndex: Int? = nil
    @State private var editMode: EditMode = .inactive
    @State private var showingAddSongsSheet: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var isOwner: Bool {
        return playlist.owner == playlistManager.userEmail
    }
    
    var isInRoom: Bool {
        return roomManager.joinedRoom && !roomManager.roomCode.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
                        
                        // Room status indicator
                        if isInRoom {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note.house.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)

                                Text("Connected to room \(roomManager.roomCode)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
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
                                isInRoom: isInRoom,
                                animatedIndex: $animatedIndex,
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

            // Floating "plus" button in bottom trailing corner
            if isOwner {
                Button(action: {
                    showingAddSongsSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 65, height: 65)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
                        .padding(.trailing, 28)
                        .padding(.bottom, 28)
                }
                .sheet(isPresented: $showingAddSongsSheet) {
                    PlaylistAddSongView(playlistManager: playlistManager, playlist: playlist)
                        .onDisappear {
                            // Refresh the playlist data when sheet closes
                            refreshPlaylistData()
                        }
                }
            }
        }
        .onAppear {
            // Refresh playlist data when view appears
            refreshPlaylistData()
        }
    }

    private func refreshPlaylistData() {
        playlistManager.getPlaylistInfo(playlistId: playlist.playlistId) { updatedPlaylist in
            if let updatedPlaylist = updatedPlaylist {
                DispatchQueue.main.async {
                    self.playlist = updatedPlaylist
                }
            }
        }
    }

    private func deleteSong(_ song: PlaylistSong) {
        // Immediately update the local state for instant UI feedback
        var updatedSongs = playlist.songs
        updatedSongs.removeAll { $0.id == song.id }
        
        // Update the local playlist immediately
        self.playlist.songs = updatedSongs
        
        // Make the API call to update the server without using playlistManager.updatePlaylist
        // to avoid any side effects that might trigger navigation
        updatePlaylistOnServer(songs: updatedSongs)
    }
    
    // Custom function to update playlist on server without side effects
    private func updatePlaylistOnServer(songs: [PlaylistSong]) {
        guard let url = URL(string: "http://api.partyaux.party/update-playlist") else {
            print("❌ Invalid URL for update-playlist")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let songsArray = songs.map { $0.toDict() }
        
        let requestBody: [String: Any] = [
            "jwt": playlistManager.userData.jwt,
            "playlist_id": playlist.playlistId,
            "songs": songsArray
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("❌ Failed to serialize request body")
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error updating playlist: \(error.localizedDescription)")
                // Optionally revert the local changes on error
                DispatchQueue.main.async {
                    self.refreshPlaylistData()
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data returned from server")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    print("✅ Playlist update response: \(status)")
                    
                    if !status.contains("successfully") {
                        // If server update failed, refresh to get the correct state
                        DispatchQueue.main.async {
                            self.refreshPlaylistData()
                        }
                    }
                } else {
                    print("❌ Unexpected response format")
                    // Refresh on unexpected response
                    DispatchQueue.main.async {
                        self.refreshPlaylistData()
                    }
                }
            } catch {
                print("❌ Failed to parse response: \(error.localizedDescription)")
                // Refresh on parse error
                DispatchQueue.main.async {
                    self.refreshPlaylistData()
                }
            }
        }.resume()
    }

    private func moveSongs(from source: IndexSet, to destination: Int) {
        var updatedSongs = playlist.songs
        updatedSongs.move(fromOffsets: source, toOffset: destination)

        // Update local state immediately
        self.playlist.songs = updatedSongs
        
        // Update server without side effects
        updatePlaylistOnServer(songs: updatedSongs)
    }

    private func toggleVisibility() {
        playlistManager.changePlaylistVisibility(playlistId: playlist.playlistId, isPublic: !playlist.isPublic) { success in
            DispatchQueue.main.async {
                if success {
                    // Update the local playlist state directly
                    self.playlist = Playlist(from: [
                        "_id": self.playlist.id,
                        "playlist_id": self.playlist.playlistId,
                        "name": self.playlist.name,
                        "owner": self.playlist.owner,
                        "public": !self.playlist.isPublic,
                        "songs": self.playlist.songs.map { $0.toDict() }
                    ])
                    // Don't call fetchUserPlaylists here - just update local state
                }
            }
        }
    }
    
    // Add song to queue function (copied from SearchView)
    private func addSongToQueue(song: PlaylistSong, index: Int) {
        // Trigger animation and haptic feedback
        triggerAddToQueueAnimation(index: index)
        
        guard let urlRequest = URL(string: "http://api.partyaux.party/add-song-to-queue") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert PlaylistSong to the format expected by the API
        let songDict: [String: Any] = [
            "title": song.title,
            "artist": song.artist,
            "duration": song.duration,
            "video_id": song.videoId,
            "album_art": song.thumbnail
        ]
        
        let requestBody: [String: Any] = [
            "room": roomManager.roomCode,
            "jwt": roomManager.userData.jwt ?? "",
            "song": songDict
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                // Refresh the queue after adding (only if queueManager exists)
                if let queueManager = roomManager.queueManager {
                    queueManager.fetchQueue { }
                }
            }
        }.resume()
    }
    
    private func triggerAddToQueueAnimation(index: Int) {
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
    }
}

struct PlaylistSongRowView: View {
    let song: PlaylistSong
    let index: Int
    let canEdit: Bool
    let isInRoom: Bool
    @Binding var animatedIndex: Int?
    let onDelete: () -> Void
    let onAddToQueue: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Always try to display the thumbnail if available
            if let imageUrl = URL(string: song.thumbnail), !song.thumbnail.isEmpty {
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
                // If no thumbnail, show the number as fallback
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
                // Add to Queue button (only show if in room and not in edit mode)
                if isInRoom && !canEdit {
                    Button(action: onAddToQueue) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                // Delete button (only show if can edit)
                if canEdit {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .contentShape(Rectangle()) // Make entire row tappable
        .onTapGesture {
            // Only allow tapping to add to queue if in room and not in edit mode
            if isInRoom && !canEdit {
                onAddToQueue()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Only show press animation if in room and not in edit mode
                    if isInRoom && !canEdit {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if isInRoom && !canEdit {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPressed = false
                        }
                    }
                }
        )
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
