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
    @State public var queueManager = QueueManager(jwt_auth: "", room: "")
    @State private var albumArtURL: URL? = nil
    @State private var isSearching = false
    @State private var isQueueVisible = false

    @ObservedObject var roomManager: RoomManager
    
    @State private var isPlaying = true

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
        let darkPurple = Color(red: 123/255, green: 97/255, blue: 255/255)
        ZStack {
            // Search View Overlay
            VStack {
                if isSearching {
                    HStack {
                        Button(action: {
                            isSearching = false
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(darkPurple)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                SearchView()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
            }
            .opacity(isSearching ? 1 : 0)
            .animation(.easeInOut, value: isSearching)
            
            // Queue View Overlay
            VStack {
                if isQueueVisible {
                    HStack {
                        Button(action: {
                            isQueueVisible = false
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(darkPurple)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                QueueView()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
            }
            .opacity(isQueueVisible ? 1 : 0)
            .animation(.easeInOut, value: isQueueVisible)

            // Main Player View
            VStack(spacing: 20) {
                HStack {
                    Text("Room: \(roomManager.roomCode)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(darkPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(darkPurple.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: {
                        print("searching")
                        isSearching.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(darkPurple)
                    }
                    
                    Button(action: {
                        print("showing queue")
                        isQueueVisible.toggle()
                    }) {
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundColor(darkPurple)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                YouTubePlayerView(
                    videoID: currentVideoID,
                    playerVars: playerVars,
                    playerInstance: $youtubePlayer,
                    queueManager: $queueManager,
                    playerReady: $playerReady
                )
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(radius: 5)
                .onAppear {
                    roomManager.eventHandlers()
                    //roomManager.connect()
                    //roomManager.joinRoom()
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
                //make sure to only update the song if the first song is completed
                .onChange(of: roomManager.currentSong) { newSong in
                    print("song is changing in music player")
                    queueManager.queue[newSong.url] = newSong as? AnyHashable
                    print("queue \(queueManager.queue)")
                    if(queueManager.queue.count <= 1)
                    {
                        playCurrentSong()
                    }
                                                            
                    // Only play the current song if it's different from what's already playing
                    /*
                    if queueManager.queue.count == 1 {
                     playCurrentSong()
                        }
                    
                     if(newSong.url != queueManager.getCurrentSongID())
                     {
                     
                     }
                     */
                }
                .offset(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height)
                
                JFIFImageView(imageUrl: albumArtURL)
                    .frame(width: 200, height: 200)
                    .id(albumArtURL)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .transition(.opacity)
                    .animation(.easeInOut, value: albumArtURL).offset(y:-200)
                
                Text(queueManager.currentSong["title"] as? String ?? "Unknown Title")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center).offset(y:-200)
                
                Text(queueManager.currentSong["album"] as? String ?? "Unknown Album")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center).offset(y:-200)
                
                Text(queueManager.currentSong["artist"] as? String ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center).offset(y:-200)
                
                HStack(spacing: 30) {
                    Button("Refresh") {
                        playCurrentSong()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 60)
                    .background(darkPurple)
                    .cornerRadius(20)
                    .shadow(color: darkPurple.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Button("Skip") {
                        youtubePlayer?.seek(toSeconds: 1000, allowSeekAhead: false)
                        queueManager.nextSong {
                            playCurrentSong()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 60)
                    .background(darkPurple)
                    .cornerRadius(20)
                    .shadow(color: darkPurple.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .offset(y: -130)
                
                Button(action: {
                    togglePlayPause()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(darkPurple)
                        .shadow(color: darkPurple.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .offset(y: -140)
            }
            .padding()
            .opacity(isSearching || isQueueVisible ? 0 : 1)
            .animation(.easeInOut, value: isSearching || isQueueVisible)
        }
    }

    func togglePlayPause() {
        guard playerReady, let player = youtubePlayer else {
            print("Player not ready yet")
            return
        }
        if isPlaying {
            player.pauseVideo()
            isPlaying = false
        } else {
            player.playVideo()
            isPlaying = true
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
