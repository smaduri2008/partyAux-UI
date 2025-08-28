//
//  PlaylistFeatureSummary.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/28/25.
//

import SwiftUI

struct PlaylistFeatureSummary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🎵 Playlist Features")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
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
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PlaylistFeatureSummary()
}
