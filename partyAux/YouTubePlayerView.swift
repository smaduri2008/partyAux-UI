import SwiftUI

struct YouTubePlayerView: UIViewRepresentable {
    var videoID: String
    let playerVars: [String: Any]
    @Binding var playerInstance: YTPlayerView?
    @ObservedObject var queueManager: QueueManager
    @Binding var playerReady: Bool
    @Binding var songCurrentlyPlaying: Bool
    
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
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            print("Player is ready - autoplay should start")
            parent.playerReady = true
        }
        
        func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
            DispatchQueue.main.async {
                switch state {
                case .playing:
                    print("✅ Video is playing")
                    self.parent.songCurrentlyPlaying = true
                    
                case .paused:
                    print("⏸️ Video paused")
                    self.parent.songCurrentlyPlaying = true
                    
                    if self.parent.queueManager.isInBackground {
                        playerView.playVideo()
                    }
                    
                case .ended:
                    print("🏁 Video ended")
                    self.parent.songCurrentlyPlaying = false
                    
                    self.parent.queueManager.currentSong = [:]
                    self.parent.queueManager.nextSong {
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
        }
    }
}
