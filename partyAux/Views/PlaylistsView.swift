//
//  PlaylistsView.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import SwiftUI

struct PlaylistsView: View {
    @StateObject private var playlistManager: PlaylistManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var showingCreatePlaylist = false
    @State private var searchText = ""
    @State private var selectedSegment = 0 // 0: My Playlists, 1: Discover
    @State private var animatedIndex: Int? = nil
    @State private var showingDeleteAlert = false
    @State private var playlistToDelete: Playlist? = nil
    @State private var isEditMode = false
    
    init(userData: UserAuth) {
        _playlistManager = StateObject(wrappedValue: PlaylistManager(userData: userData))
    }
    
    var body: some View {
        ZStack {
            // Premium background
            Color.deepNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Playlists")
                        .font(Font.premium(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Edit button (only show for My Playlists)
                    if selectedSegment == 0 && !playlistManager.userPlaylists.isEmpty {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditMode.toggle()
                            }
                        }) {
                                Text(isEditMode ? "Done" : "Edit")
                                    .font(Font.premium(size: 15, weight: .semibold))
                                .foregroundColor(isEditMode ? .green : .electricCyan)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        showingCreatePlaylist = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.electricCyan.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.electricCyan)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Custom Segment Control
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // My Playlists Button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSegment = 0
                                isEditMode = false
                            }
                            if selectedSegment != 0 {
                                searchText = ""
                                playlistManager.searchedPlaylists = []
                            }
                        }) {
                            VStack(spacing: 10) {
                                Text("My Playlists")
                                    .font(Font.premium(size: 15, weight: selectedSegment == 0 ? .semibold : .medium))
                                    .foregroundColor(selectedSegment == 0 ? .white : .white.opacity(0.4))
                                
                                Rectangle()
                                    .fill(
                                        selectedSegment == 0 ? 
                                            LinearGradient(colors: [.electricCyan, .softPurple], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Discover Button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSegment = 1
                                isEditMode = false
                            }
                            if selectedSegment != 1 {
                                searchText = ""
                                playlistManager.searchedPlaylists = []
                            }
                        }) {
                            VStack(spacing: 10) {
                                    Text("Discover")
                                        .font(Font.premium(size: 15, weight: selectedSegment == 1 ? .semibold : .medium))
                                    .foregroundColor(selectedSegment == 1 ? .white : .white.opacity(0.4))
                                
                                Rectangle()
                                    .fill(
                                        selectedSegment == 1 ? 
                                            LinearGradient(colors: [.electricCyan, .softPurple], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Divider line
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }
                
                // Search bar for discover tab
                if selectedSegment == 1 {
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                            
                            TextField("", text: $searchText)
                                .placeholder(when: searchText.isEmpty) {
                                    Text("Search playlists...")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                   .font(Font.premium(size: 15))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .onSubmit {
                                    searchPlaylists()
                                }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        Button(action: searchPlaylists) {
                            ZStack {
                                Circle()
                                    .fill(
                                        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                            Color.white.opacity(0.1) :
                                            Color.electricCyan
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.forward")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Content
                if playlistManager.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .electricCyan))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let errorMessage = playlistManager.errorMessage {
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.red)
                        }
                        
                        Text(errorMessage)
                               .font(Font.premium(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Retry") {
                            if selectedSegment == 0 {
                                playlistManager.fetchUserPlaylists()
                            } else {
                                searchPlaylists()
                            }
                        }
                        .font(Font.premium(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.electricCyan)
                        )
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                        if selectedSegment == 0 {
                            // My Playlists
                            if playlistManager.userPlaylists.isEmpty {
                                EmptyPlaylistsView()
                            } else {
                                // Show playlists in reversed order (most recent at the top)
                                ForEach(Array(playlistManager.userPlaylists.enumerated().reversed()), id: \.element.id) { index, playlist in
                                    HStack(spacing: 12) {
                                        // Only show NavigationLink when not in edit mode
                                        if !isEditMode {
                                            NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)
                                                .environmentObject(roomManager)) {
                                                PlaylistRowView(playlist: playlist, showArrow: true)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        } else {
                                            // In edit mode, just show the playlist info without navigation
                                            PlaylistRowView(playlist: playlist, showArrow: false)
                                            
                                            Spacer()
                                            
                                            // Delete button
                                            Button(action: {
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                playlistToDelete = playlist
                                                showingDeleteAlert = true
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red.opacity(0.15))
                                                        .frame(width: 36, height: 36)
                                                    
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 14))
                                                }
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                                }
                            }
                        } else {
                            // Discover Playlists
                            if playlistManager.searchedPlaylists.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.05))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "music.note.list")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    
                                    Text("No playlists found")
                                        .font(Font.premium(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Try a different search term")
                                        .font(Font.premium(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else if !playlistManager.searchedPlaylists.isEmpty {
                                // Show searched playlists
                                ForEach(Array(playlistManager.searchedPlaylists.enumerated().reversed()), id: \.element.id) { index, playlist in
                                    NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)
                                        .environmentObject(roomManager)) {
                                        PlaylistRowView(playlist: playlist, showArrow: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                                }
                            } else if searchText.isEmpty {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.electricCyan.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 32))
                                            .foregroundColor(.electricCyan.opacity(0.6))
                                    }
                                    
                                    Text("Discover Playlists")
                                        .font(Font.premium(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Search for public playlists created by other users")
                                        .font(Font.premium(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            playlistManager.fetchUserPlaylists()
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistView(playlistManager: playlistManager)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Playlist"),
                message: Text("Are you sure you want to delete this playlist? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let playlist = playlistToDelete {
                        playlistManager.deletePlaylist(playlistId: playlist.playlistId) { _ in
                            // Optionally handle error/UI updates here
                        }
                    }
                },
                secondaryButton: .cancel {
                    playlistToDelete = nil
                }
            )
        }
        }
    }
    
    private func searchPlaylists() {
        playlistManager.searchPlaylists(query: searchText)
    }
}

// Updated PlaylistRowView with premium styling
struct PlaylistRowView: View {
    let playlist: Playlist
    let showArrow: Bool
    
    init(playlist: Playlist, showArrow: Bool = true) {
        self.playlist = playlist
        self.showArrow = showArrow
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Playlist thumbnail with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.softPurple, .electricCyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            // Playlist info
            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name)
                    .font(Font.premium(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(playlist.songs.count) songs")
                        .font(Font.premium(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if playlist.isPublic {
                        HStack(spacing: 3) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                            Text("Public")
                                .font(Font.premium(size: 10))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Private")
                                .font(Font.premium(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct EmptyPlaylistsView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.softPurple.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.softPurple.opacity(0.6))
            }
            
            VStack(spacing: 10) {
                Text("No Playlists Yet")
                    .font(Font.premium(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Create your first playlist to organize your favorite songs")
                    .font(Font.premium(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}
