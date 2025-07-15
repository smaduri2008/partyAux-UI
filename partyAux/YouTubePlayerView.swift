import SwiftUI

struct YouTubePlayerView: UIViewRepresentable {
    var videoID: String
    let playerVars: [String: Any]
    @Binding var playerInstance: YTPlayerView?
    @Binding var queueManager: QueueManager

    @Binding var playerReady: Bool
    
    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.delegate = context.coordinator
        return playerView
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        DispatchQueue.main.async {
                    playerInstance = uiView
                }
        uiView.load(withVideoId: videoID, playerVars: playerVars)
       
        
    }
    
   
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    
    class Coordinator: NSObject, YTPlayerViewDelegate {
        var parent: YouTubePlayerView
        
        init(_ parent: YouTubePlayerView) {
            self.parent = parent
        }
        
        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            print("Player is ready - autoplay should start")
            parent.playerReady = true
        }
        
        func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
            switch state {
            case .playing:
                print("✅ Video is playing")
            case .paused:
                print("⏸️ Video paused")
                if self.parent.queueManager.isInBackground
                {
                    playerView.playVideo()
                }
            case .ended:
               
                    print("🏁 Video ended")
                self.parent.queueManager.currentSong = [:]
                self.parent.videoID = ""
                    self.parent.queueManager.nextSong {
                        print("Song Skip Attempted")
                    }
                
                
            case .buffering:
                print("⏳ Video buffering")
            case .cued:
                print("📋 Video cued")
            case .unstarted:
                print("⭕ Video unstarted")
                playerView.playVideo()
            default:
                print("❓ Unknown state")
            }
        }
        
        func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
            print("❌ Player error: \(error)")
        }
    }
}
