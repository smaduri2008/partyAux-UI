//
//  PersistentMusicAppView.swift
//  partyAux
//
//  Created by Sansky Srivastava on 9/13/25.
//

import SwiftUI

struct PersistentMusicAppView: View {
    @ObservedObject var queueManager: QueueManager
    @ObservedObject var roomManager: RoomManager
    @State private var selectedTab: Int = 0
    @State private var showPlayerUI: Bool = true
    
    var body: some View {
        ZStack {
            // Persistent Music Player (Always Present)
            MusicPlayerView(
                queueManager: queueManager,
                roomManager: roomManager,
                showPlayerUI: $showPlayerUI
            )
            .zIndex(0)
            
            // Tab Content Overlay (Only when player UI is hidden)
            if !showPlayerUI {
                TabView(selection: $selectedTab) {
                    // Music Player Tab (shows the player UI)
                    Color.clear
                        .tabItem {
                            Image(systemName: "play.circle.fill")
                            Text("Player")
                        }
                        .tag(0)
                        .onAppear {
                            showPlayerUI = true
                        }
                    
                    // Settings Tab
                    SettingsTab()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(1)
                    
                    // Library/Playlists Tab
                    LibraryTab()
                        .environmentObject(roomManager)
                        .tabItem {
                            Image(systemName: "music.note.list")
                            Text("Library")
                        }
                        .tag(2)
                }
                .background(Color.black)
                .zIndex(1)
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Show player UI only for the player tab (tab 0)
            let wasShowingPlayer = showPlayerUI
            showPlayerUI = (newTab == 0)
            
            // Update background state in queue manager
            queueManager.isInBackground = (newTab != 0)
            
            // If switching back to room tab and music was playing, ensure it continues
            if newTab == 0 && !wasShowingPlayer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Post notification to resume playback if needed
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ResumePlaybackIfNeeded"),
                        object: nil
                    )
                }
            }
        }
    }
}
