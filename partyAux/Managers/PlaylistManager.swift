//
//  PlaylistManager.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import Foundation
import SwiftUI

class PlaylistManager: ObservableObject {
    @Published var userPlaylists: [Playlist] = []
    @Published var searchedPlaylists: [Playlist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://35.208.64.59"
    var userData: UserAuth
    
    var userEmail: String {
        return userData.email
    }
    
    init(userData: UserAuth) {
        self.userData = userData
    }
    
    // MARK: - Create Playlist
    func createPlaylist(name: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/create-playlist") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": userData.jwt,
            "name": name
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false, "Failed to encode request")
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    completion(false, "No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String,
                       status.contains("successfully") {
                        completion(true, nil)
                        self.fetchUserPlaylists()
                    } else {
                        completion(false, "Failed to create playlist")
                    }
                } catch {
                    completion(false, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch User Playlists
    func fetchUserPlaylists() {
        guard let url = URL(string: "\(baseURL)/get-user-playlists") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": userData.jwt
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        request.httpBody = data
        
        isLoading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let playlistsArray = json["playlists"] as? [[String: Any]] {
                        self.userPlaylists = playlistsArray.map { Playlist(from: $0) }
                        self.errorMessage = nil
                    }
                } catch {
                    self.errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    // MARK: - Search Playlists
    func searchPlaylists(query: String) {
        guard !query.isEmpty,
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/search-playlists/\(encodedQuery)") else { return }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let playlistsArray = json["playlists"] as? [[String: Any]] {
                        self.searchedPlaylists = playlistsArray.map { Playlist(from: $0) }
                        self.errorMessage = nil
                    }
                } catch {
                    self.errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    // MARK: - Get Playlist Info
    func getPlaylistInfo(playlistId: String, completion: @escaping (Playlist?) -> Void) {
        guard let url = URL(string: "\(baseURL)/get-playlist-info") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": userData.jwt,
            "playlist_id": playlistId
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    completion(nil)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let playlistDict = json["playlist"] as? [String: Any] {
                        let playlist = Playlist(from: playlistDict)
                        completion(playlist)
                    } else {
                        completion(nil)
                    }
                } catch {
                    self.errorMessage = "Failed to parse response"
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Update Playlist
    func updatePlaylist(playlistId: String, songs: [PlaylistSong], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/update-playlist") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let songsArray = songs.map { $0.toDict() }
        
        let requestBody: [String: Any] = [
            "jwt": userData.jwt,
            "playlist_id": playlistId,
            "songs": songsArray
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false)
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String,
                       status.contains("successfully") {
                        completion(true)
                        self.fetchUserPlaylists()
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - Add Song to Playlist
    func addSongToPlaylist(playlistId: String, song: [String: Any], completion: @escaping (Bool) -> Void) {
        getPlaylistInfo(playlistId: playlistId) { [weak self] playlist in
            guard let self = self, let playlist = playlist else {
                completion(false)
                return
            }
            
            let newSong = PlaylistSong(from: song)
            var updatedSongs = playlist.songs
            
            // Check if song already exists in playlist
            if !updatedSongs.contains(newSong) {
                updatedSongs.append(newSong)
                self.updatePlaylist(playlistId: playlistId, songs: updatedSongs, completion: completion)
            } else {
                completion(true) // Song already exists, consider it success
            }
        }
    }
    
    // MARK: - Change Playlist Visibility
    func changePlaylistVisibility(playlistId: String, isPublic: Bool, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/change-playlist-visibility") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": userData.jwt,
            "playlist_id": playlistId,
            "public": isPublic
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false)
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String,
                       status.contains("successfully") {
                        completion(true)
                        self.fetchUserPlaylists()
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            }
        }.resume()
    }
}
