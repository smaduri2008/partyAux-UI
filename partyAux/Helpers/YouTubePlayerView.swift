import SwiftUI

struct YouTubePlayerView: UIViewRepresentable {
    var videoID: String
    let playerVars: [String: Any]
    @Binding var playerInstance: YTPlayerView?
    @ObservedObject var queueManager: QueueManager
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
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            print("Player is ready - autoplay should start")
            parent.playerReady = true
            shouldBePlaying = true
            
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
                    
                    self.parent.queueManager.currentSong = [:]
                    self.parent.queueManager.nextSong {
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
                    playerView.playVideo()
                    
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
            shouldBePlaying = true
            print("🎵 Manual play - shouldBePlaying set to true")
        }
        
        // Method to apply mute state for audio control
        func applyMuteState(_ shouldMute: Bool, playerView: YTPlayerView) {
            isManuallyMuted = shouldMute
            // Since mute/unmute methods don't exist, we rely on AVAudioSession for audio control
            print("🔇 Audio control state set via coordinator: shouldMute = \(shouldMute)")
        }
        
        // Check if the player was manually paused (not by audio control)
        private func isManuallyPaused() -> Bool {
            // If we're muted due to audio control, don't consider it a manual pause
            return !shouldBePlaying && !isManuallyMuted
        }
    }
}
