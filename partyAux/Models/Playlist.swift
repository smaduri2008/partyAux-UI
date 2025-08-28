//
//  Playlist.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    let id: String
    let playlistId: String
    let name: String
    let owner: String
    let isPublic: Bool
    var songs: [PlaylistSong]
    
    init(from dict: [String: Any]) {
        self.id = dict["_id"] as? String ?? ""
        self.playlistId = dict["playlist_id"] as? String ?? ""
        self.name = dict["name"] as? String ?? ""
        self.owner = dict["owner"] as? String ?? ""
        self.isPublic = dict["public"] as? Bool ?? false
        
        if let songsArray = dict["songs"] as? [[String: Any]] {
            self.songs = songsArray.map { PlaylistSong(from: $0) }
        } else {
            self.songs = []
        }
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PlaylistSong: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: String
    let thumbnail: String
    let videoId: String
    
    init(from dict: [String: Any]) {
        self.title = dict["title"] as? String ?? ""
        self.artist = dict["artist"] as? String ?? ""
        self.duration = dict["duration"] as? String ?? ""
        self.thumbnail = dict["thumbnail"] as? String ?? ""
        self.videoId = dict["video_id"] as? String ?? ""
    }
    
    // Convert to API format
    func toDict() -> [String: Any] {
        return [
            "title": title,
            "artist": artist,
            "duration": duration,
            "thumbnail": thumbnail,
            "video_id": videoId
        ]
    }
    
    static func == (lhs: PlaylistSong, rhs: PlaylistSong) -> Bool {
        return lhs.videoId == rhs.videoId
    }
}
