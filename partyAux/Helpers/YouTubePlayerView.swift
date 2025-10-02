import SwiftUI

struct YouTubePlayerView: UIViewRepresentable {
    var videoID: String
    let playerVars: [String: Any]
    @Binding var playerInstance: YTPlayerView?
    @ObservedObject var queueManager: QueueManager
    @ObservedObject var roomManager: RoomManager
    @Binding var playerReady: Bool
    @Binding var songCurrentlyPlaying: Bool
    var onPlayerReady: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.delegate = context.coordinator
        return playerView
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        DispatchQueue.main.async {
            playerInstance = uiView
        }
        
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            uiView.load(withVideoId: videoID, playerVars: playerVars)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, YTPlayerViewDelegate {
        var parent: YouTubePlayerView
        var currentVideoID: String = ""
        var shouldBePlaying: Bool = false
        var isManuallyMuted: Bool = false
        var isHostPlayingOnlyPaused: Bool = false
        var isManuallyPausedByUser: Bool = false // NEW: Track manual user pauses
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
            super.init()
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleHostPlayingOnlyChanged),
                name: NSNotification.Name("HostPlayingOnlyChanged"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc private func handleHostPlayingOnlyChanged(_ notification: Notification) {
            guard let playerView = parent.playerInstance else { return }
            
            if let hostPlayingOnly = notification.userInfo?["hostPlayingOnly"] as? Bool {
                print("🎵 [YouTubePlayerView] Host playing only changed to: \(hostPlayingOnly)")
                print("🎵 [YouTubePlayerView] Current user is host: \(parent.roomManager.isCurrentUserHost)")
                
                DispatchQueue.main.async {
                    self.updatePlayerForHostOnlyMode(playerView: playerView, hostPlayingOnly: hostPlayingOnly)
                }
            }
        }
        
        private func updatePlayerForHostOnlyMode(playerView: YTPlayerView, hostPlayingOnly: Bool) {
            let isHost = parent.roomManager.isCurrentUserHost
            
            if hostPlayingOnly && !isHost {
                print("🎵 [YouTubePlayerView] Pausing player for non-host (host-only mode active)")
                isHostPlayingOnlyPaused = true
                playerView.pauseVideo()
            } else {
                if isHostPlayingOnlyPaused {
                    print("🎵 [YouTubePlayerView] Resuming player (host-only mode off or user is host)")
                    isHostPlayingOnlyPaused = false
                    if shouldBePlaying && !isManuallyPausedByUser {
                        playerView.playVideo()
                    }
                }
            }
        }
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            print("Player is ready - autoplay should start")
            parent.playerReady = true
            shouldBePlaying = true
            isManuallyPausedByUser = false // Reset manual pause on new video
            
            updatePlayerForHostOnlyMode(
                playerView: playerView,
                hostPlayingOnly: parent.roomManager.hostPlayingOnly
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.parent.onPlayerReady?()
            }
        }
        
        func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
            DispatchQueue.main.async {
                switch state {
                case .playing:
                    print("✅ Video is playing")
                    self.parent.songCurrentlyPlaying = true
                    self.shouldBePlaying = true
                    self.isManuallyPausedByUser = false // Clear manual pause when playing starts
                    self.parent.onPlayerReady?()
                    
                case .paused:
                    print("⏸️ Video paused")
                    self.parent.songCurrentlyPlaying = true
                    
                    // Don't auto-resume if paused due to host-only mode
                    if self.isHostPlayingOnlyPaused {
                        print("🎵 Staying paused due to host-only mode")
                        return
                    }
                    
                    // Don't auto-resume if manually paused by user
                    if self.isManuallyPausedByUser {
                        print("🎵 Staying paused - manually paused by user")
                        return
                    }
                    
                    // Auto-resume if we should be playing and wasn't manually paused
                    if self.shouldBePlaying {
                        print("🔄 Auto-resuming paused video (shouldBePlaying = true)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            playerView.playVideo()
                        }
                    }
                    
                case .ended:
                    print("🏁 Video ended")
                    self.parent.songCurrentlyPlaying = false
                    self.shouldBePlaying = false
                    self.isManuallyPausedByUser = false // Reset for next song
                    
                    if !self.parent.queueManager.currentSong.isEmpty {
                        self.parent.queueManager.lastPlayedSong = self.parent.queueManager.currentSong
                        print("💿 Stored last played song from video end: \(self.parent.queueManager.currentSong["title"] as? String ?? "Unknown")")
                    }
                    
                    self.parent.queueManager.currentSong = [:]
                    self.parent.queueManager.nextSongWithAutoplayCheck(roomManager: self.parent.roomManager) {
                        print("Song Skip Attempted")
                    }
                    
                case .buffering:
                    print("⏳ Video buffering")
                    self.parent.songCurrentlyPlaying = true
                    
                case .cued:
                    print("📋 Video cued")
                    self.parent.songCurrentlyPlaying = false
                    
                case .unstarted:
                    print("⭕ Video unstarted")
                    self.parent.songCurrentlyPlaying = false
                    self.shouldBePlaying = true
                    self.isManuallyPausedByUser = false // Reset for new video
                    
                    if !self.parent.roomManager.hostPlayingOnly || self.parent.roomManager.isCurrentUserHost {
                        playerView.playVideo()
                    } else {
                        print("🎵 Not auto-starting video - host-only mode active and user is not host")
                        self.isHostPlayingOnlyPaused = true
                    }
                    
                default:
                    print("❓ Unknown state")
                    self.parent.songCurrentlyPlaying = false
                }
            }
        }
        
        func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
            print("❌ Player error: \(error)")
            parent.songCurrentlyPlaying = false
            shouldBePlaying = false
            isManuallyPausedByUser = false
        }
        
        // Called when user manually pauses
        func manualPause() {
            shouldBePlaying = false
            isManuallyPausedByUser = true // Set the manual pause flag
            print("🎵 Manual pause - shouldBePlaying set to false, isManuallyPausedByUser = true")
        }
        
        // Called when user manually plays
        func manualPlay() {
            guard let playerView = parent.playerInstance else { return }
            
            if parent.roomManager.hostPlayingOnly && !parent.roomManager.isCurrentUserHost {
                print("🎵 Manual play blocked - host-only mode active and user is not host")
                return
            }
            
            shouldBePlaying = true
            isManuallyPausedByUser = false // Clear the manual pause flag
            print("🎵 Manual play - shouldBePlaying set to true, isManuallyPausedByUser = false")
            playerView.playVideo()
        }
        
        // Method to apply mute state for audio control
        func applyMuteState(_ shouldMute: Bool, playerView: YTPlayerView) {
            isManuallyMuted = shouldMute
            print("🔇 Audio control state set via coordinator: shouldMute = \(shouldMute)")
        }
    }
}
