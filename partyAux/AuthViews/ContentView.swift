//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = UserAuth()
    @StateObject private var roomManager: RoomManager
    @State private var youtubePlayer: YTPlayerView?
    @State private var currentView: ContentViewState = .loading
    @State private var selectedTab: Int = 0 // Added for TabView
    @State private var showPlayerUI: Bool = true // Add this line
    
    enum ContentViewState {
        case loading
        case email
        case username
        case authenticated
    }
    
    init() {
        let authInstance = UserAuth()
        _auth = StateObject(wrappedValue: authInstance)
        _roomManager = StateObject(wrappedValue: RoomManager(userData: authInstance))
    }
    
    var body: some View {
        ZStack {
            // Animated Background
            LinearGradient.backgroundGradient
                .ignoresSafeArea()
                .animation(.smooth, value: currentView)
            
            NavigationView {
                Group {
                    switch currentView {
                    case .loading:
                        LoadingView()
                    case .email:
                        EmailView()
                    case .username:
                        CreateUsernameView()
                    case .authenticated:
                        AuthenticatedTabView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.springy, value: currentView)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .environmentObject(auth)
        .environmentObject(roomManager) // Add this line to provide RoomManager to all views
        .onAppear {
            auth.loadJWT()
            updateViewState()
        }
        .onChange(of: auth.authenticated) { _ in
            withAnimation(.springy.delay(0.1)) {
                updateViewState()
            }
        }
        .onChange(of: auth.needsUser) { _ in
            withAnimation(.springy.delay(0.1)) {
                updateViewState()
            }
        }
    }
    
    // MARK: - Tab Bar for Authenticated State
    @ViewBuilder
    private func AuthenticatedTabView() -> some View {
        TabView(selection: $selectedTab) {
            // Room (Home) Tab
            VStack(spacing: 0) {
                if !roomManager.joinedRoom {
                    RoomCreateJoinView()
                        .environmentObject(roomManager)
                }
                if roomManager.joinedRoom, let queueManager = roomManager.queueManager {
                    MusicPlayerView(
                        queueManager: queueManager,
                        roomManager: roomManager,
                        showPlayerUI: $showPlayerUI
                    )
                }
            }
            .tabItem {
                Label("Room", systemImage: "music.note.house.fill")
            }
            .tag(0)
            
            // Library Tab (Playlist functionality)
            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)
                .environmentObject(auth)
                .environmentObject(roomManager) // Add this line
            
            
            // Settings Tab (Placeholder)
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
                .environmentObject(auth)
                .environmentObject(roomManager) // Add this line if needed
        }
        .onChange(of: selectedTab) { newTab in
            // Control player UI visibility and background state
            showPlayerUI = (newTab == 0)
            
            // Tell the queue manager about background state
            if let queueManager = roomManager.queueManager {
                queueManager.isInBackground = (newTab != 0)
                
                // When returning to room tab, ensure music continues
                if newTab == 0 {
                    // Small delay to ensure UI is ready, then check if we need to resume
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // The YouTube player should auto-resume if it was paused
                        // This is handled by the YouTubePlayerView delegate
                        print("Returned to room tab - music should continue playing")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack(spacing: 24) {
            Text("PartyAux")
                .font(.largeTitle)
                .foregroundColor(.textPrimary)
                .shimmer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                .scaleEffect(1.2)
        }
    }
    
    private func updateViewState() {
        if auth.authenticated {
            currentView = .authenticated
        } else if auth.needsUser {
            currentView = .username
        } else {
            currentView = .email
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserAuth())
}
