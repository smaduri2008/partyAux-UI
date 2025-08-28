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
            
            // Segment Control
            Picker("", selection: $selectedSegment) {
                Text("My Playlists").tag(0)
                Text("Discover").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .onChange(of: selectedSegment) { _ in
                if selectedSegment == 1 {
                    searchText = ""
                    playlistManager.searchedPlaylists = []
                }
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
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    
                    Button(action: searchPlaylists) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .purple)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
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
                            ForEach(playlistManager.userPlaylists.indices, id: \.self) { index in
                                let playlist = playlistManager.userPlaylists[index]
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)) {
                                    PlaylistRowView(playlist: playlist)
                                }
                                .listRowBackground(Color.black)
                                .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
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
                            ForEach(playlistManager.searchedPlaylists.indices, id: \.self) { index in
                                let playlist = playlistManager.searchedPlaylists[index]
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)) {
                                    PlaylistRowView(playlist: playlist)
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
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            playlistManager.fetchUserPlaylists()
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistView(playlistManager: playlistManager)
        }
    }
    
    private func searchPlaylists() {
        playlistManager.searchPlaylists(query: searchText)
    }
}

struct PlaylistRowView: View {
    let playlist: Playlist
    
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
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
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
