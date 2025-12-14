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
        
        // Configure Tab Bar appearance for premium look
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.deepNavy)
        tabBarAppearance.shadowColor = .clear
        
        // Unselected state
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.4),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.electricCyan)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.electricCyan),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        ZStack {
            // Premium Background
            Color.deepNavy
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
        .environmentObject(roomManager)
        .onAppear {
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
                .environmentObject(roomManager)
            
            // Settings Tab
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
                .environmentObject(auth)
                .environmentObject(roomManager)
        }
        .onChange(of: selectedTab) { newTab in
            // Control player UI visibility and background state
            showPlayerUI = (newTab == 0)
            
            // Tell the queue manager about background state
            if let queueManager = roomManager.queueManager {
                queueManager.isInBackground = (newTab != 0)
                
                if newTab == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("Returned to room tab - music should continue playing")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func LoadingView() -> some View {
        GeometryReader { geometry in
            ZStack {
                // Subtle gradient orbs sized relative to width
                Circle()
                    .fill(Color.electricCyan.opacity(0.15))
                    .frame(width: min(geometry.size.width * 0.65, 250), height: min(geometry.size.width * 0.65, 250))
                    .blur(radius: 60)
                    .offset(x: -geometry.size.width * 0.12, y: -geometry.size.height * 0.12)

                Circle()
                    .fill(Color.softPurple.opacity(0.15))
                    .frame(width: min(geometry.size.width * 0.5, 200), height: min(geometry.size.width * 0.5, 200))
                    .blur(radius: 50)
                    .offset(x: geometry.size.width * 0.2, y: geometry.size.height * 0.18)
            
            VStack(spacing: 30) {
                // Premium logo area
                    ZStack {
                        Circle()
                            .fill(Color.electricCyan)
                            .frame(width: 80, height: 80)
                            .blur(radius: 30)
                            .opacity(0.4)

                        LogoView(size: 88, hasBackground: true)
                    }
                
                Text("PartyAux")
                    .font(Font.premium(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .electricCyan))
                    .scaleEffect(1.2)
            }
            }
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
