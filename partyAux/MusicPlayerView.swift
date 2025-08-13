//
//  MusicPlayerView.swift
//  Test
//
//  Created by Ajay Avasi on 7/14/25.
//

/*
EXAMPLE USAGE:
 
 import SwiftUI
 import AVFoundation

 struct ContentView: View {
     var queueManager = QueueManager(jwt_auth: "", room: "")
     var body: some View {
         @State var youtubePlayer: YTPlayerView?
         MusicPlayerView(
             youtubePlayer: youtubePlayer,
             queueManager: queueManager
         )
     }

 }
 
 
 ALL INCOMING NETWORK REQUESTS SHOULD GO HERE
 
 VIDEO EVENTS FOUND IN YOUTUBEPLAYERVIEW.VIEW

*/

import SwiftUI
import AVFoundation

struct MusicPlayerView: View {
    @State private var playerReady = false
    @State public var currentVideoID = ""
    @State public var youtubePlayer: YTPlayerView?
    
    // Instead, receive it as a parameter and observe it
    @ObservedObject var queueManager: QueueManager
    
    @State private var albumArtURL: URL? = nil
    @State private var isSearching = false
    @State private var isQueueVisible = false
    @State private var isPlaying = true
    @State private var songCurrentlyPlaying = false
    @State private var showControls = true

    @ObservedObject var roomManager: RoomManager
    
    let playerVars: [String: Any] = [
        "playsinline": 1,
        "autoplay": 1,
        "controls": 1,
        "fs": 0,
        "rel": 0,
        "modestbranding": 1,
        "iv_load_policy": 3,
        "cc_load_policy": 0,
        "enablejsapi": 1,
        "origin": Bundle.main.bundleIdentifier ?? "com.yourapp.identifier"
    ]

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()
            
            // YouTube Player (Always Present, Hidden Off-Screen)
            YouTubePlayerView(
                videoID: currentVideoID,
                playerVars: playerVars,
                playerInstance: $youtubePlayer,
                queueManager: queueManager,
                playerReady: $playerReady,
                songCurrentlyPlaying: $songCurrentlyPlaying
            )
            .frame(height: 250)
            .cornerRadius(12)
            .shadow(radius: 5)
            .offset(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height)
            .zIndex(0)
            
            // Main Player View
            if !isSearching && !isQueueVisible {
                MainPlayerView(
                    albumArtURL: $albumArtURL,
                    isPlaying: $isPlaying,
                    isSearching: $isSearching,
                    isQueueVisible: $isQueueVisible,
                    showControls: $showControls,
                    queueManager: queueManager,
                    roomManager: roomManager,
                    togglePlayPause: togglePlayPause,
                    playCurrentSong: playCurrentSong,
                    skipToNext: skipToNext
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(1)
            }
            
            // Search View Overlay
            if isSearching {
                SearchOverlayView(isSearching: $isSearching)
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .zIndex(2)
            }
            
            // Queue View Overlay
            if isQueueVisible {
                QueueOverlayView(isQueueVisible: $isQueueVisible)
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(2)
            }
        }
        .animation(.springy, value: isSearching)
        .animation(.springy, value: isQueueVisible)
        .onAppear {
            setupPlayer()
        }
        .onChange(of: roomManager.currentSong["url"] as? String ?? "") { newVideoID in
            handleSongChange(newVideoID)
        }
        .onChange(of: queueManager.queue) { _ in
            handleQueueChange()
        }
        .onChange(of: songCurrentlyPlaying) { isPlaying in
            print("🎵 songCurrentlyPlaying changed to: \(isPlaying)")
        }
    }
    
    // MARK: - Setup Methods
    private func setupPlayer() {
        roomManager.eventHandlers()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
        
        queueManager.fetchCurrentSong {
            DispatchQueue.main.async {
                currentVideoID = queueManager.getCurrentSongID()
                if let urlString = queueManager.currentSong["album_art"] as? String,
                   let url = URL(string: urlString) {
                    albumArtURL = url
                }
            }
        }
        
        queueManager.fetchQueue {
            print(queueManager.queue)
        }
    }
    
    private func handleSongChange(_ newVideoID: String) {
        print("Current song URL changed: \(newVideoID)")
        if !newVideoID.isEmpty && newVideoID != currentVideoID && !songCurrentlyPlaying {
            queueManager.currentSong = roomManager.currentSong
            print("song changed in onChange")
            print("Updating currentVideoID to: \(newVideoID)")
            self.currentVideoID = newVideoID
            
            if let urlString = roomManager.currentSong["album_art"] as? String,
               let url = URL(string: urlString) {
                self.albumArtURL = url
            }
            
            print("Playing new song with ID: \(newVideoID)")
        }
    }
    
    private func handleQueueChange() {
        print("queue changed")
        print("current video id: \(currentVideoID)")
        print(songCurrentlyPlaying)
        if currentVideoID.isEmpty &&
            !songCurrentlyPlaying &&
            (roomManager.currentSong["url"] as? String ?? "").isEmpty,
           let firstSong = queueManager.queue.first,
           let firstID = queueManager.queue.first?.key as? String {
            print("queue changed, changing song")
            queueManager.currentSong = firstSong.value as! [String : Any]
            currentVideoID = firstID
        }
    }

    // MARK: - Control Methods
    func togglePlayPause() {
        guard playerReady, let player = youtubePlayer else {
            print("Player not ready yet")
            return
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if isPlaying {
            player.pauseVideo()
            isPlaying = false
        } else {
            player.playVideo()
            isPlaying = true
        }
    }
    
    func skipToNext() {
        youtubePlayer?.seek(toSeconds: 1000, allowSeekAhead: false)
        queueManager.nextSong {
            playCurrentSong()
        }
    }

    func playVideoFromJson(strData: String) {
        let json = jsonStringToDictionary(strData)
        currentVideoID = json?["url"] as? String ?? currentVideoID
    }
    
    func playCurrentSong() {
        currentVideoID = ""
        queueManager.fetchCurrentSong {
            DispatchQueue.main.async {
                currentVideoID = queueManager.getCurrentSongID()
                if let urlString = queueManager.currentSong["album_art"] as? String,
                   let url = URL(string: urlString) {
                    albumArtURL = url
                }
            }
        }
    }
    
    func jsonStringToDictionary(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return nil
        }

        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return dictionary
        } catch {
            print("JSON parsing error: \(error)")
            return nil
        }
    }
}

// MARK: - Search Overlay View
struct SearchOverlayView: View {
    @Binding var isSearching: Bool
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.springy) {
                        isSearching = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            SearchView()
                .environmentObject(queueManager)
                .environmentObject(roomManager)
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Queue Overlay View
struct QueueOverlayView: View {
    @Binding var isQueueVisible: Bool
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.springy) {
                        isQueueVisible = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            QueueView()
                .environmentObject(queueManager)
                .environmentObject(roomManager)
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Main Player View
struct MainPlayerView: View {
    @Binding var albumArtURL: URL?
    @Binding var isPlaying: Bool
    @Binding var isSearching: Bool
    @Binding var isQueueVisible: Bool
    @Binding var showControls: Bool
    
    @ObservedObject var queueManager: QueueManager
    @ObservedObject var roomManager: RoomManager
    let togglePlayPause: () -> Void
    let playCurrentSong: () -> Void
    let skipToNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Header with Room Code and Actions
            TopHeaderView(
                roomCode: roomManager.roomCode,
                isSearching: $isSearching,
                isQueueVisible: $isQueueVisible
            )
            
            Spacer()
            
            // Main Player Content
            VStack(spacing: 24) {
                // Album Art with Glow Effect
                AlbumArtView(albumArtURL: albumArtURL)
                
                // Song Information
                SongInfoView(currentSong: queueManager.currentSong)
                
                // Player Controls
                PlayerControlsView(
                    isPlaying: isPlaying,
                    togglePlayPause: togglePlayPause,
                    onRefresh: playCurrentSong,
                    onSkip: skipToNext
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Top Header View
struct TopHeaderView: View {
    let roomCode: String
    @Binding var isSearching: Bool
    @Binding var isQueueVisible: Bool
    
    var body: some View {
        HStack {
            // Room Code Badge
            HStack {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Room: \(roomCode)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing), lineWidth: 1)
            )
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.springy) {
                        isSearching.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.appCardBackground)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.appSurface, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.springy) {
                        isQueueVisible.toggle()
                    }
                }) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.appCardBackground)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.appSurface, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Album Art View
struct AlbumArtView: View {
    let albumArtURL: URL?
    
    var body: some View {
        ZStack {
            // Glow Effect
            Circle()
                .fill(LinearGradient.primaryGradient)
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .opacity(0.3)
            
            // Album Art Container
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .frame(width: 200, height: 200)
                .overlay(
                    Group {
                        if let albumArtURL = albumArtURL {
                            JFIFImageView(imageUrl: albumArtURL)
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            VStack {
                                Image(systemName: "music.note")
                                    .font(.system(size: 40))
                                    .foregroundColor(.textTertiary)
                                Text("No Artwork")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                )
                .shadow(color: Color.white.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .id(albumArtURL)
        .transition(.scale.combined(with: .opacity))
        .animation(.springy, value: albumArtURL)
    }
}

// MARK: - Song Info View
struct SongInfoView: View {
    let currentSong: [String: Any]
    
    var body: some View {
        VStack(spacing: 8) {
            Text(currentSong["title"] as? String ?? "No Song Playing")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(currentSong["artist"] as? String ?? "Unknown Artist")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            if let album = currentSong["album"] as? String, !album.isEmpty {
                Text(album)
                    .font(.footnote)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .animation(.smooth, value: currentSong["title"] as? String ?? "")
    }
}

// MARK: - Player Controls View
struct PlayerControlsView: View {
    let isPlaying: Bool
    let togglePlayPause: () -> Void
    let onRefresh: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Secondary Controls
            HStack(spacing: 40) {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onRefresh()
                }) {
                    VStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 50, height: 50)
                            .background(Color.appCardBackground)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.appSurface, lineWidth: 1)
                            )
                        
                        Text("Refresh")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                }
                
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onSkip()
                }) {
                    VStack {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 50, height: 50)
                            .background(Color.appCardBackground)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.appSurface, lineWidth: 1)
                            )
                        
                        Text("Skip")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            
            // Main Play/Pause Button
            Button(action: togglePlayPause) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.white.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon visual balance
                }
                .scaleEffect(1.0)
                .animation(.bouncy, value: isPlaying)
            }
        }
        .animation(.smooth, value: isPlaying)
    }
}
