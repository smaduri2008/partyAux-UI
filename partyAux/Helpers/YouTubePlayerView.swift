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
        var shouldBePlaying: Bool = false // Track intended playing state
        var isManuallyMuted: Bool = false // Track if muted by audio control
        var isHostPlayingOnlyPaused: Bool = false // Track if paused due to host-only mode
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
            super.init()
            
            // Listen for hostPlayingOnly changes
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
                // Non-host and host-only mode is active: pause the player
                print("🎵 [YouTubePlayerView] Pausing player for non-host (host-only mode active)")
                isHostPlayingOnlyPaused = true
                playerView.pauseVideo()
            } else {
                // Host or host-only mode is off: resume if previously paused by host-only mode
                if isHostPlayingOnlyPaused {
                    print("🎵 [YouTubePlayerView] Resuming player (host-only mode off or user is host)")
                    isHostPlayingOnlyPaused = false
                    if shouldBePlaying {
                        playerView.playVideo()
                    }
                }
            }
        }
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            print("Player is ready - autoplay should start")
            parent.playerReady = true
            shouldBePlaying = true
            
            // Check if we need to apply host-only mode restrictions
            updatePlayerForHostOnlyMode(
                playerView: playerView, 
                hostPlayingOnly: parent.roomManager.hostPlayingOnly
            )
            
            // Apply any pending audio control settings
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
                    self.parent.onPlayerReady?()
                    
                case .paused:
                    print("⏸️ Video paused")
                    self.parent.songCurrentlyPlaying = true
                    
                    // Don't auto-resume if paused due to host-only mode
                    if self.isHostPlayingOnlyPaused {
                        print("🎵 Staying paused due to host-only mode")
                        return
                    }
                    
                    // Always try to resume if we should be playing, unless manually paused
                    if self.shouldBePlaying && !self.isManuallyPaused() {
                        print("🔄 Auto-resuming paused video (shouldBePlaying = true)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            playerView.playVideo()
                        }
                    }
                    
                case .ended:
                    print("🏁 Video ended")
                    self.parent.songCurrentlyPlaying = false
                    self.shouldBePlaying = false
                    
                    // Store current song as last played before clearing it
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
                    // Don't change shouldBePlaying during buffering
                    
                case .cued:
                    print("📋 Video cued")
                    self.parent.songCurrentlyPlaying = false
                    // Don't change shouldBePlaying when cued
                    
                case .unstarted:
                    print("⭕ Video unstarted")
                    self.parent.songCurrentlyPlaying = false
                    self.shouldBePlaying = true
                    
                    // Don't auto-start if in host-only mode and user is not host
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
        }
        
        // Method to manually pause (called by user interaction)
        func manualPause() {
            shouldBePlaying = false
            print("🎵 Manual pause - shouldBePlaying set to false")
        }
        
        // Method to manually play (called by user interaction)
        func manualPlay() {
            guard let playerView = parent.playerInstance else { return }
            
            // Don't allow manual play if we're in host-only mode and user is not host
            if parent.roomManager.hostPlayingOnly && !parent.roomManager.isCurrentUserHost {
                print("🎵 Manual play blocked - host-only mode active and user is not host")
                return
            }
            
            shouldBePlaying = true
            print("🎵 Manual play - shouldBePlaying set to true")
            playerView.playVideo()
        }
        
        // Method to apply mute state for audio control
        func applyMuteState(_ shouldMute: Bool, playerView: YTPlayerView) {
            isManuallyMuted = shouldMute
            // Since mute/unmute methods don't exist, we rely on AVAudioSession for audio control
            print("🔇 Audio control state set via coordinator: shouldMute = \(shouldMute)")
        }
        
        // Check if the player was manually paused (not by audio control or host-only mode)
        private func isManuallyPaused() -> Bool {
            // If we're muted due to audio control or paused due to host-only mode, don't consider it a manual pause
            return !shouldBePlaying && !isManuallyMuted && !isHostPlayingOnlyPaused
        }
    }
}
