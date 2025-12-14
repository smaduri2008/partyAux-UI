//
//  PlaylistFeatureSummary.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/28/25.
//

import SwiftUI

struct PlaylistFeatureSummary: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            // Premium background
            Color.deepNavy
                .ignoresSafeArea()
            
            // Subtle gradient orbs
            Circle()
                .fill(Color.electricCyan.opacity(0.1))
                .frame(width: min(geometry.size.width * 0.5, 200), height: min(geometry.size.width * 0.5, 200))
                .blur(radius: 60)
                .offset(x: -geometry.size.width * 0.18, y: -geometry.size.height * 0.22)
            
            Circle()
                .fill(Color.softPurple.opacity(0.1))
                .frame(width: min(geometry.size.width * 0.4, 150), height: min(geometry.size.width * 0.4, 150))
                .blur(radius: 50)
                .offset(x: geometry.size.width * 0.18, y: geometry.size.height * 0.28)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.electricCyan.opacity(0.2), .softPurple.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Text("🎵")
                                .font(.system(size: 24))
                        }
                        
                        Text("Playlist Features")
                            .font(Font.premium(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "music.note.list",
                            title: "Create & Manage Playlists",
                            description: "Create your own playlists and manage their visibility (public/private)"
                        )
                        
                        FeatureRow(
                            icon: "magnifyingglass",
                            title: "Search Playlists",
                            description: "Discover public playlists created by other users in the search tab"
                        )
                        
                        FeatureRow(
                            icon: "hand.point.up.left",
                            title: "Long Press to Add",
                            description: "Long press any song in search results or queue to add it to your playlists"
                        )
                        
                        FeatureRow(
                            icon: "house",
                            title: "Home Integration",
                            description: "Access your playlists from the home screen when not in a room"
                        )
                        
                        FeatureRow(
                            icon: "books.vertical",
                            title: "Library Tab",
                            description: "Dedicated library tab for browsing and managing all your playlists"
                        )
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCardBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.electricCyan.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.electricCyan)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Font.premium(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(Font.premium(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PlaylistFeatureSummary()
}
