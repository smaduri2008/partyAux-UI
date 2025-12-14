//
//  MusicPlayerView.swift
//  Test
//
//  Created by Ajay Avasi on 7/14/25.
//

import SwiftUI
import AVFoundation

struct MusicPlayerView: View {
    @State private var playerReady = false
    @State public var currentVideoID = ""
    @State public var youtubePlayer: YTPlayerView?
   
    @ObservedObject var queueManager: QueueManager
    @State private var albumArtURL: URL? = nil
    @State private var isSearching = false
    @State private var isQueueVisible = false
    @State private var isMembersVisible = false
    @State private var isSettingsVisible = false
    @State private var isPlaying = true
    @State private var songCurrentlyPlaying = false
    @State private var showControls = true
    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var currentTime: Float = 0
    @State private var duration: Float = 0
    @State private var isBuffering = false
    @AppStorage("showYouTubeEmbed") private var showYouTubeEmbed = false

    @ObservedObject var roomManager: RoomManager
    
    @Binding var showPlayerUI: Bool
   
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
            if showPlayerUI {
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
            }
            
            if showYouTubeEmbed {
                VStack {
                    Spacer()
                    
                    YouTubePlayerView(
                        videoID: currentVideoID,
                        playerVars: playerVars,
                        playerInstance: $youtubePlayer,
                        queueManager: queueManager,
                        roomManager: roomManager,
                        playerReady: $playerReady,
                        songCurrentlyPlaying: $songCurrentlyPlaying,
                        currentTime: $currentTime,
                        duration: $duration,
                        isBuffering: $isBuffering
                    )
                    .frame(height: 250)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(10)
            } else {
                YouTubePlayerView(
                    videoID: currentVideoID,
                    playerVars: playerVars,
                    playerInstance: $youtubePlayer,
                    queueManager: queueManager,
                    roomManager: roomManager,
                    playerReady: $playerReady,
                    songCurrentlyPlaying: $songCurrentlyPlaying,
                    currentTime: $currentTime,
                    duration: $duration,
                    isBuffering: $isBuffering
                )
                .frame(height: 250)
                .offset(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height)
                .zIndex(0)
            }
            
            if showPlayerUI {
                if !isSearching && !isQueueVisible && !isMembersVisible && !isSettingsVisible {
                    MainPlayerView(
                        albumArtURL: $albumArtURL,
                        isPlaying: $isPlaying,
                        isSearching: $isSearching,
                        isQueueVisible: $isQueueVisible,
                        isMembersVisible: $isMembersVisible,
                        isSettingsVisible: $isSettingsVisible,
                        showControls: $showControls,
                        isLiked: $isLiked,
                        isDisliked: $isDisliked,
                        showYouTubeEmbed: $showYouTubeEmbed,
                        currentTime: $currentTime,
                        duration: $duration,
                        isBuffering: isBuffering,
                        queueManager: queueManager,
                        roomManager: roomManager,
                        youtubePlayer: youtubePlayer,
                        togglePlayPause: togglePlayPause,
                        playCurrentSong: playCurrentSong,
                        skipToNext: skipToNext,
                        toggleLike: toggleLike,
                        toggleDislike: toggleDislike
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(1)
                }
               
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
                
                if isMembersVisible {
                    MembersOverlayView(isMembersVisible: $isMembersVisible, roomManager: roomManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .zIndex(2)
                }
                
                if isSettingsVisible {
                    SettingsOverlayView(isSettingsVisible: $isSettingsVisible)
                        .environmentObject(roomManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .zIndex(2)
                }
            }
        }
        .animation(.springy, value: isSearching)
        .animation(.springy, value: isQueueVisible)
        .animation(.springy, value: isMembersVisible)
        .animation(.springy, value: isSettingsVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showYouTubeEmbed)
        .onAppear {
            setupPlayer()
        }
        .onChange(of: queueManager.currentSong["url"] as? String ?? "") { newVideoID in
            print("uuid: \(queueManager.currentSong["uuid"] ?? "nil") || added by: \(queueManager.currentSong["addedBy"] ?? "nil")")
            handleSongChange(newVideoID)
        }
        .onChange(of: queueManager.queueOrder) { _ in
            handleQueueChange()
        }
        .onChange(of: queueManager.currentSong["downvotes"] as? [String] ?? []) { downvotesArray in
            print("🔄 Downvotes array changed in onChange: \(downvotesArray)")
            updateDislikedState(downvotesArray: downvotesArray)
        }
        .onChange(of: queueManager.currentSong["downvote_count"] as? Int ?? 0) { newCount in
            print("🔄 Downvote count changed in onChange: \(newCount)")
            if let downvotesArray = queueManager.currentSong["downvotes"] as? [String] {
                updateDislikedState(downvotesArray: downvotesArray)
            }
        }
        .onChange(of: songCurrentlyPlaying) { isPlaying in
            print("🎵 songCurrentlyPlaying changed to: \(isPlaying)")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FirstSongAdded"))) { _ in
            print("🎵 First song added notification received")
            
            // Sync with queueManager's current song
            DispatchQueue.main.async {
                let newVideoID = self.queueManager.currentSong["url"] as? String ?? ""
                print("🎵 queueManager.currentSong url: '\(newVideoID)'")
                
                if !newVideoID.isEmpty && newVideoID != self.currentVideoID {
                    print("🎵 Updating currentVideoID from notification: \(newVideoID)")
                    self.currentVideoID = newVideoID
                    
                    // Update album art
                    if let urlString = self.queueManager.currentSong["album_art"] as? String,
                       let url = URL(string: urlString) {
                        self.albumArtURL = url
                    }
                }
                
                // Give a moment for the video to load, then ensure it plays
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let player = self.youtubePlayer, self.playerReady {
                        print("🎵 Triggering playback for first song")
                        player.playVideo()
                        self.isPlaying = true
                    } else {
                        print("🎵 Player not ready yet, will auto-play when ready")
                    }
                }
            }
        }
    }
    
    private func updateDislikedState(downvotesArray: [String]) {
        let userEmail = roomManager.userData.email
        let wasDisliked = isDisliked
        isDisliked = downvotesArray.contains(userEmail)
        
        if wasDisliked != isDisliked {
            print("🔄 Dislike state updated: \(wasDisliked) -> \(isDisliked) for user \(userEmail)")
            print("🔄 Downvotes array: \(downvotesArray)")
        }
    }
   
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
        if !newVideoID.isEmpty && newVideoID != currentVideoID {
            // queueManager.currentSong is already updated (it triggered this change)
            print("song changed in onChange")
            print("Updating currentVideoID to: \(newVideoID)")
            self.currentVideoID = newVideoID
            
            self.isLiked = false
            
            if let downvotesArray = queueManager.currentSong["downvotes"] as? [String] {
                self.isDisliked = downvotesArray.contains(roomManager.userData.email)
                print("🔄 Song changed - isDisliked set to: \(self.isDisliked) based on array: \(downvotesArray)")
            } else {
                self.isDisliked = false
                print("🔄 Song changed - no downvotes array found, isDisliked set to false")
            }
           
            if let urlString = queueManager.currentSong["album_art"] as? String,
               let url = URL(string: urlString) {
                self.albumArtURL = url
            }
           
            print("Playing new song with ID: \(newVideoID)")
        }
    }
   
    private func handleQueueChange() {
        print("🔄 queue changed")
        print("🔄 current video id: '\(currentVideoID)'")
        print("🔄 songCurrentlyPlaying: \(songCurrentlyPlaying)")
        print("🔄 queueManager.currentSong url: '\(queueManager.currentSong["url"] as? String ?? "")'")
        print("🔄 roomManager.currentSong url: '\(roomManager.currentSong["url"] as? String ?? "")'")
        print("🔄 queueOrder count: \(queueManager.queueOrder.count)")
        
        // Check if we need to set the current song
        let noCurrentVideo = currentVideoID.isEmpty
        let noSongPlaying = !songCurrentlyPlaying
        let noRoomSong = (roomManager.currentSong["url"] as? String ?? "").isEmpty
        let noQueueManagerSong = (queueManager.currentSong["url"] as? String ?? "").isEmpty
        let hasQueuedSongs = !queueManager.queueOrder.isEmpty
        
        if noCurrentVideo && noSongPlaying && noRoomSong && noQueueManagerSong && hasQueuedSongs {
            // Use queueOrder to get the actual first song (not random dictionary order)
            if let firstSongUuid = queueManager.queueOrder.first,
               let songDict = queueManager.queue[firstSongUuid],
               let firstID = songDict["url"] as? String,
               !firstID.isEmpty {
                
                print("🎵 Queue changed - setting first song as current")
                queueManager.currentSong = songDict
                currentVideoID = firstID
                
                // Update album art
                if let urlString = songDict["album_art"] as? String,
                   let url = URL(string: urlString) {
                    albumArtURL = url
                }
                
                // Ensure playback starts after video loads
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let player = self.youtubePlayer, self.playerReady {
                        print("🎵 Starting playback for first song in queue")
                        player.playVideo()
                        self.isPlaying = true
                    }
                }
            }
        }
    }
   
    func togglePlayPause() {
        guard playerReady, let player = youtubePlayer else {
            print("Player not ready yet")
            return
        }
       
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
       
        if isPlaying {
            player.pauseVideo()
            isPlaying = false
            // Inform the coordinator that this is a manual pause
            if let coordinator = player.delegate as? YouTubePlayerView.Coordinator {
                coordinator.manualPause()
            }
        } else {
            player.playVideo()
            isPlaying = true
            // Inform the coordinator that this is a manual play
            if let coordinator = player.delegate as? YouTubePlayerView.Coordinator {
                coordinator.manualPlay()
            }
        }
    }
   
    func skipToNext() {
        youtubePlayer?.seek(toSeconds: 1000, allowSeekAhead: false)
        queueManager.nextSongWithAutoplayCheck(roomManager: roomManager) {
            playCurrentSong()
        }
    }

    func toggleLike() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isLiked.toggle()
        if isLiked {
            isDisliked = false
        }
        print("Song \(isLiked ? "liked" : "unliked"): \(queueManager.currentSong["title"] as? String ?? "Unknown")")
    }

    func toggleDislike() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("🔽 toggleDislike called - current isDisliked: \(isDisliked)")
        
        if isDisliked {
            print("⚠️ User has already downvoted this song (checked isDisliked state)")
            return
        }
        
        guard let currentSongUuid = queueManager.currentSong["uuid"] as? String else {
            print("❌ No current song UUID found")
            return
        }
        
        print("🔍 User trying to downvote song UUID: \(currentSongUuid)")
        print("🔍 Current song title: \(queueManager.currentSong["title"] as? String ?? "Unknown")")
        
        let userEmail = roomManager.userData.email
        print("🔍 Checking downvotes for user: \(userEmail)")
        
        if let downvotesArray = queueManager.currentSong["downvotes"] as? [String] {
            print("🔍 Current downvotes array: \(downvotesArray)")
            if downvotesArray.contains(userEmail) {
                print("⚠️ User has already downvoted this song (checked downvotes array)")
                self.isDisliked = true
                return
            }
        } else {
            print("⚠️ No downvotes array found - proceeding with downvote")
        }
        
        print("📤 Sending downvote request for song: \(currentSongUuid)")
        roomManager.downvoteSong(songUuid: currentSongUuid) { success, message in
            DispatchQueue.main.async {
                if success {
                    print("✅ Downvote successful: \(message)")
                    self.isDisliked = true
                    self.isLiked = false
                    
                    let currentCount = self.queueManager.currentSong["downvote_count"] as? Int ?? 0
                    self.queueManager.currentSong["downvote_count"] = currentCount + 1
                    
                    if var downvotesArray = self.queueManager.currentSong["downvotes"] as? [String] {
                        if !downvotesArray.contains(self.roomManager.userData.email) {
                            downvotesArray.append(self.roomManager.userData.email)
                            self.queueManager.currentSong["downvotes"] = downvotesArray
                            print("✅ Updated local downvotes array: \(downvotesArray)")
                        }
                    } else {
                        self.queueManager.currentSong["downvotes"] = [self.roomManager.userData.email]
                        print("✅ Created new downvotes array: [\(self.roomManager.userData.email)]")
                    }
                    
                    print("✅ Local UI updated - isDisliked: \(self.isDisliked)")
                } else {
                    print("❌ Downvote failed: \(message)")
                }
            }
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
            OverlayHeader(title: "Search", isVisible: $isSearching)
           
            SearchView()
                .environmentObject(queueManager)
                .environmentObject(roomManager)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Queue Overlay View
struct QueueOverlayView: View {
    @Binding var isQueueVisible: Bool
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
   
    var body: some View {
        VStack(spacing: 0) {
            OverlayHeader(title: "Queue", isVisible: $isQueueVisible)
           
            QueueView()
                .environmentObject(queueManager)
                .environmentObject(roomManager)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}



// MARK: - Settings Overlay View
struct SettingsOverlayView: View {
    @Binding var isSettingsVisible: Bool
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var roomManager: RoomManager
    
    var body: some View {
        VStack(spacing: 0) {
            OverlayHeader(title: "Settings", isVisible: $isSettingsVisible)
           
            SettingsView()
                .environmentObject(userAuth)
                .environmentObject(roomManager)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Overlay Header
struct OverlayHeader: View {
    let title: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
               
                withAnimation(.springy) {
                    isVisible = false
                }
            }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.labelLarge)
                }
                .foregroundColor(.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.appElevated)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            Text(title)
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Invisible placeholder for centering
            Color.clear
                .frame(width: 80, height: 36)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            Color.appBackground
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Main Player View
struct MainPlayerView: View {
    @Binding var albumArtURL: URL?
    @Binding var isPlaying: Bool
    @Binding var isSearching: Bool
    @Binding var isQueueVisible: Bool
    @Binding var isMembersVisible: Bool
    @Binding var isSettingsVisible: Bool
    @Binding var showControls: Bool
    @Binding var isLiked: Bool
    @Binding var isDisliked: Bool
    @Binding var showYouTubeEmbed: Bool
    @Binding var currentTime: Float
    @Binding var duration: Float
    let isBuffering: Bool
   
    @ObservedObject var queueManager: QueueManager
    @ObservedObject var roomManager: RoomManager
    var youtubePlayer: YTPlayerView?
    let togglePlayPause: () -> Void
    let playCurrentSong: () -> Void
    let skipToNext: () -> Void
    let toggleLike: () -> Void
    let toggleDislike: () -> Void
   
    var body: some View {
        VStack(spacing: 0) {
            TopHeaderView(
                roomCode: roomManager.roomCode,
                isSearching: $isSearching,
                isQueueVisible: $isQueueVisible,
                isMembersVisible: $isMembersVisible,
                isSettingsVisible: $isSettingsVisible,
                roomManager: roomManager
            )
           
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)
                    
                    AlbumArtView(albumArtURL: albumArtURL)
                    SongInfoView(currentSong: queueManager.currentSong)
                    
                    // Progress Slider
                    ProgressSliderView(
                        currentTime: $currentTime,
                        duration: duration,
                        isHost: roomManager.isCurrentUserHost,
                        youtubePlayer: youtubePlayer
                    )
                    
                    PlayerControlsView(
                        isPlaying: isPlaying,
                        isHost: roomManager.isCurrentUserHost,
                        isLiked: isLiked,
                        isDisliked: isDisliked,
                        isBuffering: isBuffering,
                        queueManager: queueManager,
                        roomManager: roomManager,
                        togglePlayPause: togglePlayPause,
                        onSkip: skipToNext,
                        toggleLike: toggleLike,
                        toggleDislike: toggleDislike
                    )
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: UIScreen.main.bounds.height - 200)
            }
        }
    }
}

// MARK: - Top Header View
struct TopHeaderView: View {
    let roomCode: String
    @Binding var isSearching: Bool
    @Binding var isQueueVisible: Bool
    @Binding var isMembersVisible: Bool
    @Binding var isSettingsVisible: Bool
    let roomManager: RoomManager
   
    @State private var showLeaveAlert = false
   
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Room info badge
            HStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(roomManager.isCurrentUserHost ? Color.warning.opacity(0.2) : Color.brandPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: roomManager.isCurrentUserHost ? "crown.fill" : "music.note.house.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(roomManager.isCurrentUserHost ? .warning : .brandPrimary)
                }
               
                VStack(alignment: .leading, spacing: 2) {
                    Text("Room Code")
                        .font(.labelSmall)
                        .foregroundColor(.textTertiary)
                    Text(roomCode)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                }
               
                Spacer()
                
                if roomManager.isCurrentUserHost {
                    Text("HOST")
                        .font(.labelSmall)
                        .foregroundColor(.warning)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.warning.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(Spacing.sm)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(
                        roomManager.isCurrentUserHost ? Color.warning.opacity(0.3) : Color.textMuted.opacity(0.2),
                        lineWidth: 1
                    )
            )
           
            // Action buttons row
            HStack(spacing: Spacing.sm) {
                HeaderActionButton(icon: "person.2.fill", action: { isMembersVisible.toggle() })
                HeaderActionButton(icon: "magnifyingglass", action: { isSearching.toggle() })
                HeaderActionButton(icon: "music.note.list", action: { isQueueVisible.toggle() })
                HeaderActionButton(icon: "gearshape.fill", action: { isSettingsVisible.toggle() })
                
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showLeaveAlert = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.error.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.error)
                    }
                }
                .alert("Leave Room", isPresented: $showLeaveAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Leave", role: .destructive) {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.warning)
                        roomManager.leaveRoom()
                    }
                } message: {
                    Text("Are you sure you want to leave this room? You'll need the room code to rejoin.")
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}

// MARK: - Header Action Button
struct HeaderActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            withAnimation(.springy) { action() }
        }) {
            ZStack {
                Circle()
                    .fill(Color.appElevated)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.textMuted.opacity(0.2), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

// MARK: - Album Art View
struct AlbumArtView: View {
    let albumArtURL: URL?
    @State private var isAnimating = false
   
    var body: some View {
        ZStack {
            // Animated background glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .brandPrimary.opacity(0.5),
                            .brandSecondary.opacity(0.3),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .opacity(isAnimating ? 0.8 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: isAnimating
                )
           
            // Album art container
            RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous)
                .fill(Color.appCardBackground)
                .frame(width: 260, height: 260)
                .overlay(
                    Group {
                        if let albumArtURL = albumArtURL {
                            JFIFImageView(imageUrl: albumArtURL)
                                .frame(width: 260, height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous))
                        } else {
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.brandGradient.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "music.note")
                                        .font(.system(size: 36, weight: .medium))
                                        .foregroundStyle(LinearGradient.brandGradient)
                                }
                                Text("No Song Playing")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xLarge, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .brandPrimary.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .id(albumArtURL)
        .transition(.scale.combined(with: .opacity))
        .animation(.springy, value: albumArtURL)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Song Info View
struct SongInfoView: View {
    let currentSong: [String: Any]
   
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(currentSong["title"] as? String ?? "No Song Playing")
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
           
            Text(currentSong["artist"] as? String ?? "Unknown Artist")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
           
            if let album = currentSong["album"] as? String, !album.isEmpty {
                Text(album)
                    .font(.bodySmall)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            
            if let addedBy = currentSong["added_by"] as? String, !addedBy.isEmpty {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 12))
                    Text("Added by \(addedBy)")
                        .font(.labelSmall)
                }
                .foregroundColor(.brandPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.brandPrimary.opacity(0.15))
                .clipShape(Capsule())
                .padding(.top, Spacing.xxs)
            }
        }
        .animation(.smooth, value: currentSong["title"] as? String ?? "")
    }
}

// MARK: - Progress Slider View
struct ProgressSliderView: View {
    @Binding var currentTime: Float
    let duration: Float
    let isHost: Bool
    var youtubePlayer: YTPlayerView?
    
    @State private var isDragging = false
    @State private var dragValue: Float = 0
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        let time = isDragging ? dragValue : currentTime
        return Double(time) / Double(duration)
    }
    
    private var displayTime: Float {
        isDragging ? dragValue : currentTime
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appElevated)
                        .frame(height: 8)
                    
                    // Progress track with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.brandGradient)
                        .frame(width: max(0, geometry.size.width * CGFloat(progress)), height: 8)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 22 : 16, height: isDragging ? 22 : 16)
                        .shadow(color: .brandPrimary.opacity(0.5), radius: isDragging ? 8 : 4, x: 0, y: 2)
                        .offset(x: max(0, min(geometry.size.width - 16, geometry.size.width * CGFloat(progress) - 8)))
                        .animation(.snappy, value: isDragging)
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isHost, duration > 0 else { return }
                            
                            if !isDragging {
                                isDragging = true
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                            
                            let percentage = Float(value.location.x / geometry.size.width)
                            dragValue = max(0, min(duration, percentage * duration))
                        }
                        .onEnded { _ in
                            guard isHost, duration > 0 else { return }
                            
                            isDragging = false
                            
                            // Seek to the new position
                            youtubePlayer?.seek(toSeconds: dragValue, allowSeekAhead: true)
                            currentTime = dragValue
                            
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                )
            }
            .frame(height: 22)
            .opacity(duration > 0 ? 1 : 0.5)
            
            // Time labels
            HStack {
                Text(formatTime(displayTime))
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Spacing.xxs)
    }
    
    private func formatTime(_ seconds: Float) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Player Controls View
struct PlayerControlsView: View {
    let isPlaying: Bool
    let isHost: Bool
    let isLiked: Bool
    let isDisliked: Bool
    let isBuffering: Bool
    let queueManager: QueueManager
    let roomManager: RoomManager
    let togglePlayPause: () -> Void
    let onSkip: () -> Void
    let toggleLike: () -> Void
    let toggleDislike: () -> Void
    
    private var currentSongDownvotes: Int {
        guard let downvotesArray = queueManager.currentSong["downvotes"] as? [String] else {
            return queueManager.currentSong["downvote_count"] as? Int ?? 0
        }
        return downvotesArray.count
    }
    
    private var hasUserDownvoted: Bool {
        guard let downvotesArray = queueManager.currentSong["downvotes"] as? [String] else {
            print("🔍 hasUserDownvoted: No downvotes array found")
            return false
        }
        let result = downvotesArray.contains(roomManager.userData.email)
        print("🔍 hasUserDownvoted: \(result) for user \(roomManager.userData.email) in array \(downvotesArray)")
        return result
    }
   
    var body: some View {
        VStack(spacing: Spacing.lg) {
            if !isHost {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                    Text("Listening Mode - Only the host can control playback")
                        .font(.labelSmall)
                }
                .foregroundColor(.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.appElevated)
                .clipShape(Capsule())
            }
            
            if !queueManager.currentSong.isEmpty {
                CurrentSongDownvoteInfo(
                    downvotes: currentSongDownvotes,
                    maxDownvotes: roomManager.maxDownvotes,
                    hasUserDownvoted: hasUserDownvoted
                )
            }
            
            // Main controls row
            HStack(spacing: Spacing.xl) {
                // Downvote button
                Button(action: toggleDislike) {
                    ZStack {
                        Circle()
                            .fill(hasUserDownvoted ? Color.error.opacity(0.2) : Color.appElevated)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        hasUserDownvoted ? Color.error.opacity(0.5) : Color.textMuted.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: hasUserDownvoted ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(hasUserDownvoted ? .error : .textSecondary)
                            .scaleEffect(hasUserDownvoted ? 1.1 : 1.0)
                    }
                }
                .disabled(hasUserDownvoted)
                .animation(.bouncy, value: hasUserDownvoted)
                
                // Play/Pause button
                Button(action: {
                    if isHost && !isBuffering {
                        togglePlayPause()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                isHost ? LinearGradient.brandGradient : LinearGradient(colors: [.appElevated], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: 88, height: 88)
                            .shadow(
                                color: isHost ? .brandPrimary.opacity(0.5) : .clear,
                                radius: 20,
                                x: 0,
                                y: 8
                            )
                       
                        if isBuffering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: isPlaying ? 0 : 3)
                        }
                    }
                    .scaleEffect(1.0)
                    .animation(.bouncy, value: isPlaying)
                    .animation(.smooth, value: isBuffering)
                    .opacity(isHost ? 1.0 : 0.5)
                }
                .disabled(!isHost || isBuffering)
                
                // Skip button
                Button(action: {
                    if isHost {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onSkip()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.appElevated)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.textMuted.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isHost ? .textPrimary : .textTertiary)
                    }
                    .opacity(isHost ? 1.0 : 0.5)
                }
                .disabled(!isHost)
            }
        }
        .animation(.smooth, value: isPlaying)
    }
}

// MARK: - Current Song Downvote Info
struct CurrentSongDownvoteInfo: View {
    let downvotes: Int
    let maxDownvotes: Int
    let hasUserDownvoted: Bool
    
    private var progress: Double {
        guard maxDownvotes > 0 else { return 0 }
        return Double(downvotes) / Double(maxDownvotes)
    }
    
    private var warningLevel: Int {
        switch progress {
        case 0..<0.5:
            return 0
        case 0.5..<0.8:
            return 1
        default:
            return 2
        }
    }
    
    private var statusColor: Color {
        switch warningLevel {
        case 2: return .error
        case 1: return .warning
        default: return .brandPrimary
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: warningLevel == 2 ? "exclamationmark.triangle.fill" :
                             warningLevel == 1 ? "exclamationmark.circle.fill" : "hand.thumbsdown.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text("Skip Votes")
                        .font(.labelMedium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(downvotes)/\(maxDownvotes)")
                        .font(.labelMedium)
                        .foregroundColor(statusColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.appElevated)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [statusColor, statusColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                            .animation(.smooth, value: progress)
                    }
                }
                .frame(height: 6)
            }
            
            if hasUserDownvoted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.success)
            }
        }
        .padding(Spacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}
