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
                        youtubePlayer: youtubePlayer,
                        queueManager: queueManager,
                        roomManager: roomManager
                    )
                }
            }
            .tabItem {
                Label("Room", systemImage: "music.note.house.fill")
            }
            .tag(0)
            
            // Library Tab (Placeholder)
            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)
            
            
            // Settings Tab (Placeholder)
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
                .environmentObject(auth)
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

// Placeholder Views for Library and Settings
/*
struct LibraryTab: View {
    var body: some View {
        VStack {
            Text("Library")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}
 

struct SettingsTab: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}
 */

#Preview {
    ContentView()
        .environmentObject(UserAuth())
}
