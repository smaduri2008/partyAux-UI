import Foundation
import SwiftUI

class PlaylistManager: ObservableObject {
    @Published var userPlaylists: [Playlist] = []
    @Published var searchedPlaylists: [Playlist] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://api.partyaux.party"
    var userData: UserAuth
    
    /// Safe JWT accessor - returns empty string if not available
    private var jwt: String {
        userData.jwt ?? ""
    }
    
    var userEmail: String {
        return userData.email
    }
    
    init(userData: UserAuth) {
        self.userData = userData
    }
    
    // MARK: - Create Playlist
    func createPlaylist(name: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/create-playlist") else {
            print("could not create")
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": jwt,
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
                        print("created playlist")
                    } else {
                        completion(false, "Failed to create playlist")
                        print("did not create")
                    }
                } catch {
                    completion(false, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Playlist
    func deletePlaylist(playlistId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/delete-playlist") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": jwt,
            "playlist_id": playlistId
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(false)
            return
        }
        
        request.httpBody = data
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting playlist \(playlistId): \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    print("No data received for delete playlist")
                    completion(false)
                    return
                }
                
                do {
                    if let json2 = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json2["status"] as? String,
                       status.contains("successfully") {
                        print("Successfully deleted playlist \(playlistId)")
                        completion(true)
                        self.fetchUserPlaylists()
                    } else {
                        print("Failed to delete playlist - server response:")
                        completion(false)
                    }
                } catch {
                    print("JSON parsing error for delete playlist: \(error)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch User Playlists
    func fetchUserPlaylists() {
        guard let url = URL(string: "\(baseURL)/get-user-playlists") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jwt": jwt
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to encode request")
            return
        }
        request.httpBody = data
        
        print("Starting fetchUserPlaylists...")
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    self.isLoading = false
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Response is not a valid JSON object")
                        self.isLoading = false
                        self.errorMessage = "Invalid response format"
                        return
                    }
                    
                    if let playlistIds = json["playlist_ids"] as? [String] {
                        print("Found \(playlistIds.count) playlist IDs")
                        self.fetchPlaylistDetails(for: playlistIds)
                    } else {
                        print("No 'playlist_ids' found in response")
                        self.isLoading = false
                        self.errorMessage = "No playlists found"
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    self.isLoading = false
                    self.errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Playlist Details
    private func fetchPlaylistDetails(for playlistIds: [String]) {
        guard !playlistIds.isEmpty else {
            self.userPlaylists = []
            self.isLoading = false
            print("No playlists to fetch")
            return
        }
        
        var fetchedPlaylists: [Playlist] = []
        let dispatchGroup = DispatchGroup()
        
        for playlistId in playlistIds {
            dispatchGroup.enter()
            getPlaylistInfo(playlistId: playlistId) { playlist in
                if let playlist = playlist {
                    fetchedPlaylists.append(playlist)
                    print("Fetched playlist: \(playlist.name)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.userPlaylists = fetchedPlaylists
            self.isLoading = false
            self.errorMessage = nil
            print("Successfully loaded \(fetchedPlaylists.count) playlists")
            print("got user playlists")
        }
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
            "jwt": jwt,
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
                    print("Error fetching playlist \(playlistId): \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("No data for playlist \(playlistId)")
                    completion(nil)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let playlistDict = json["playlist"] as? [String: Any] {
                            let playlist = Playlist(from: playlistDict)
                            print("Successfully parsed playlist: \(playlist.name)")
                            completion(playlist)
                        } else if let message = json["message"] as? String {
                            print("Server message for playlist \(playlistId): \(message)")
                            completion(nil)
                        } else {
                            print("No playlist data found for ID \(playlistId)")
                            completion(nil)
                        }
                    } else {
                        print("Invalid JSON for playlist \(playlistId)")
                        completion(nil)
                    }
                } catch {
                    print("JSON parsing error for playlist \(playlistId): \(error)")
                    completion(nil)
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
            "jwt": jwt,
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
            "jwt": jwt,
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
