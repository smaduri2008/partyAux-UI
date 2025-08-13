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
                        AuthenticatedContentView()
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
    
    @ViewBuilder
    private func AuthenticatedContentView() -> some View {
        VStack(spacing: 0) {
            if !roomManager.joinedRoom {
                RoomCreateJoinView()
                    .environmentObject(roomManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if roomManager.joinedRoom, let queueManager = roomManager.queueManager {
                MusicPlayerView(
                    youtubePlayer: youtubePlayer,
                    queueManager: queueManager,
                    roomManager: roomManager
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.springy, value: roomManager.joinedRoom)
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
