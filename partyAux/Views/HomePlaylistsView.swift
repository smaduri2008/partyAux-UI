//
//  HomePlaylistsView.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//
/*
import SwiftUI

struct HomePlaylistsView: View {
    @StateObject private var playlistManager: PlaylistManager
    @State private var showingCreatePlaylist = false
    @State private var animatedIndex: Int? = nil
    @State private var showingDeleteAlert = false
    @State private var playlistToDelete: Playlist? = nil

    init(userData: UserAuth) {
        _playlistManager = StateObject(wrappedValue: PlaylistManager(userData: userData))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("My Playlists")
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
                            playlistManager.fetchUserPlaylists()
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
                        if playlistManager.userPlaylists.isEmpty {
                            HomeEmptyPlaylistsView()
                        } else {
                            // Show playlists in reversed order (most recent at the top)
                            ForEach(Array(playlistManager.userPlaylists.enumerated().reversed()), id: \.element.id) { index, playlist in
                                HStack {
                                    NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager)) {
                                        HomePlaylistRowView(playlist: playlist)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowBackground(Color.black)
                                    .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
                                    /*
                                    // Delete button
                                    Button(action: {
                                        playlistToDelete = playlist
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .padding(.leading, 8)
                                     */
                                }
                                .padding(.vertical, 4)
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
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HomePlaylistRowView: View {
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

struct HomeEmptyPlaylistsView: View {
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
}*/
