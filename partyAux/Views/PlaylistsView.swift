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
    @State private var isEditMode = false // Add edit mode state
    
    init(userData: UserAuth) {
        _playlistManager = StateObject(wrappedValue: PlaylistManager(userData: userData))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Edit button (only show for My Playlists)
                if selectedSegment == 0 && !playlistManager.userPlaylists.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditMode.toggle()
                        }
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    .padding(.trailing, 8)
                }
                
                Button(action: {
                    showingCreatePlaylist = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Custom Segment Control at the top
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // My Playlists Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedSegment = 0
                            isEditMode = false // Reset edit mode when switching tabs
                        }
                        if selectedSegment != 0 {
                            searchText = ""
                            playlistManager.searchedPlaylists = []
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("My Playlists")
                                .font(.headline)
                                .fontWeight(selectedSegment == 0 ? .semibold : .regular)
                                .foregroundColor(selectedSegment == 0 ? .white : .gray)
                            
                            Rectangle()
                                .fill(selectedSegment == 0 ? Color.purple : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    
                    // Discover Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedSegment = 1
                            isEditMode = false // Reset edit mode when switching tabs
                        }
                        if selectedSegment != 1 {
                            searchText = ""
                            playlistManager.searchedPlaylists = []
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Discover")
                                .font(.headline)
                                .fontWeight(selectedSegment == 1 ? .semibold : .regular)
                                .foregroundColor(selectedSegment == 1 ? .white : .gray)
                            
                            Rectangle()
                                .fill(selectedSegment == 1 ? Color.purple : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Divider line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal)
            }
            
            // Search bar for discover tab
            if selectedSegment == 1 {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search playlists...", text: $searchText)
                            .foregroundColor(.black)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search playlists...")
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .autocapitalization(.none)
                            .onSubmit {
                                searchPlaylists()
                            }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Button(action: searchPlaylists) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .purple)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .scaleEffect(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                }
                .padding(.horizontal)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = playlistManager.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        if selectedSegment == 0 {
                            playlistManager.fetchUserPlaylists()
                        } else {
                            searchPlaylists()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                Spacer()
            } else {
                List {
                    if selectedSegment == 0 {
                        // My Playlists
                        if playlistManager.userPlaylists.isEmpty {
                            EmptyPlaylistsView()
                        } else {
                            // Show playlists in reversed order (most recent at the top) with delete buttons
                            ForEach(Array(playlistManager.userPlaylists.enumerated().reversed()), id: \.element.id) { index, playlist in
                                HStack {
                                    // Only show NavigationLink when not in edit mode
                                    if !isEditMode {
                                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)
                                            .environmentObject(roomManager)) {
                                            PlaylistRowView(playlist: playlist, showArrow: false) // Don't show arrow in PlaylistRowView
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        // In edit mode, just show the playlist info without navigation
                                        PlaylistRowView(playlist: playlist, showArrow: false)
                                    }
                                    
                                    // Delete button (only show in edit mode)
                                    if isEditMode {
                                        Button(action: {
                                            playlistToDelete = playlist
                                            showingDeleteAlert = true
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 18))
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .padding(.leading, 12)
                                        .scaleEffect(1.1)
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .listRowBackground(Color.black)
                                .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                                .padding(.vertical, 6)
                            }
                        }
                    } else {
                        // Discover Playlists
                        if playlistManager.searchedPlaylists.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("No playlists found")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                
                                Text("Try a different search term")
                                    .font(.subheadline)
                                    .foregroundColor(.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                            .listRowBackground(Color.black)
                        } else if !playlistManager.searchedPlaylists.isEmpty {
                            // Show searched playlists in reversed order (most recent at the top)
                            ForEach(Array(playlistManager.searchedPlaylists.enumerated().reversed()), id: \.element.id) { index, playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)
                                    .environmentObject(roomManager)) {
                                    PlaylistRowView(playlist: playlist, showArrow: false) // Don't show arrow in PlaylistRowView
                                }
                                .listRowBackground(Color.black)
                                .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                            }
                        } else if searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("Discover Playlists")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                
                                Text("Search for public playlists created by other users")
                                    .font(.subheadline)
                                    .foregroundColor(.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                            .listRowBackground(Color.black)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .background(Color.black.ignoresSafeArea())
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
    
    private func searchPlaylists() {
        playlistManager.searchPlaylists(query: searchText)
    }
}

// Updated PlaylistRowView with optional arrow
struct PlaylistRowView: View {
    let playlist: Playlist
    let showArrow: Bool
    
    // Default parameter for backwards compatibility
    init(playlist: Playlist, showArrow: Bool = true) {
        self.playlist = playlist
        self.showArrow = showArrow
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Playlist thumbnail/icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(playlist.songs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    if playlist.isPublic {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Only show arrow if showArrow is true
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyPlaylistsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Playlists Yet")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Create your first playlist to organize your favorite songs")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .listRowBackground(Color.black)
    }
}
