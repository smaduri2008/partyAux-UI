import Foundation
import UIKit

class QueueManager: ObservableObject {
    @Published var currentSong: [String: Any] = [:]
    @Published var queue: [String: [String:Any]] = [:]
    @Published var queueOrder: [String] = []
    @Published var lastPlayedSong: [String: Any] = [:]
    
    @Published var songCurrentlyPlaying: Bool = false
    
    var jwt_auth: String
    var room: String
    public var isInBackground = false

    init(jwt_auth: String, room: String) {
        self.jwt_auth = jwt_auth
        self.room = room
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            print("App entered background")
            self.isInBackground = true
        }
                        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            print("App will enter foreground")
            self.isInBackground = false
        }
    }

    func fetchCurrentSong(completion: @escaping () -> Void) {
        self.currentSong = [:]
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/get-current-song") { result in
            if let result = result {
                DispatchQueue.main.async {
                    self.currentSong = result["song"] as? [String: Any] ?? [:]
                    completion()
                }
            } else {
                print("Failed to fetch current song")
                completion()
            }
        }
    }

    func getCurrentSongID() -> String {
        return currentSong["url"] as? String ?? ""
    }
    
    func updateSongDownvoteCount(songUuid: String, newDownvoteCount: Int, downvotesArray: [String]? = nil) {
        DispatchQueue.main.async {
            print("🔄 updateSongDownvoteCount called for \(songUuid) with count \(newDownvoteCount)")
            
            // Update the song in the queue without changing order
            if var songData = self.queue[songUuid] {
                // Update the downvote count
                songData["downvote_count"] = newDownvoteCount
                
                // Update downvotes array if provided
                if let downvotesArray = downvotesArray {
                    songData["downvotes"] = downvotesArray
                    print("✅ Updated downvotes array for song \(songUuid): \(downvotesArray)")
                } else {
                    print("⚠️ No downvotes array provided for song \(songUuid)")
                }
                
                self.queue[songUuid] = songData
                print("✅ Updated downvote count for song \(songUuid) to \(newDownvoteCount)")
            }
            
            // Also update current song if it matches
            if let currentSongUuid = self.currentSong["uuid"] as? String,
               currentSongUuid == songUuid {
                print("🔄 Updating current song downvote data")
                
                let oldDownvotes = self.currentSong["downvotes"] as? [String] ?? []
                self.currentSong["downvote_count"] = newDownvoteCount
                
                // Update downvotes array for current song if provided
                if let downvotesArray = downvotesArray {
                    self.currentSong["downvotes"] = downvotesArray
                    print("✅ Updated current song downvotes array: \(downvotesArray)")
                } else {
                    // If no downvotes array provided, fetch current song to get updated data
                    print("🔄 No downvotes array provided, fetching current song")
                    self.fetchCurrentSong {
                        print("✅ Current song refreshed in updateSongDownvoteCount")
                        // Force UI update by triggering objectWillChange
                        DispatchQueue.main.async {
                            self.objectWillChange.send()
                        }
                    }
                    return // Exit early since fetchCurrentSong will trigger the update
                }
                
                let newDownvotes = self.currentSong["downvotes"] as? [String] ?? []
                print("✅ Updated current song downvote count to \(newDownvoteCount)")
                print("🔍 Old downvotes: \(oldDownvotes)")
                print("🔍 New downvotes: \(newDownvotes)")
            }
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    func addSongToQueue(_ songData: [String: Any]) {
        DispatchQueue.main.async {
            if let uuid = songData["uuid"] as? String {
                // Only add if not already present to prevent duplicates
                if !self.queueOrder.contains(uuid) {
                    self.queue[uuid] = songData
                    self.queueOrder.append(uuid)
                    print("✅ Added song \(uuid) to queue at position \(self.queueOrder.count)")
                } else {
                    // Update existing song data but don't add to order again
                    self.queue[uuid] = songData
                    print("⚠️ Song \(uuid) already in queue, updating data only")
                }
                print("Current queue order: \(self.queueOrder)")
                self.objectWillChange.send()
            }
        }
    }
    
    func removeSongFromQueue(_ songUuid: String) {
        DispatchQueue.main.async {
            self.queue.removeValue(forKey: songUuid)
            if let index = self.queueOrder.firstIndex(of: songUuid) {
                self.queueOrder.remove(at: index)
                print("✅ Removed song \(songUuid) from queue at index \(index)")
            }
            print("Current queue order: \(self.queueOrder)")
            self.objectWillChange.send()
        }
    }
    
    func removeFirstSongFromQueue() {
        DispatchQueue.main.async {
            if let firstSongUuid = self.queueOrder.first,
               let songData = self.queue[firstSongUuid] {
                // Store the song before removing it
                self.lastPlayedSong = songData
                print("📀 Stored last played song: \(songData["title"] as? String ?? "Unknown")")
                
                self.queue.removeValue(forKey: firstSongUuid)
                self.queueOrder.removeFirst()
                print("✅ Removed first song \(firstSongUuid) from queue")
                print("Current queue order: \(self.queueOrder)")
                self.objectWillChange.send()
            }
        }
    }
    
    func fetchQueue(completion: @escaping () -> Void) {
        print("🔄 Fetching queue...")
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/get-queue") { result in
            if let result = result {
                DispatchQueue.main.async {
                    // Clear the existing queue and order
                    self.queue.removeAll()
                    self.queueOrder.removeAll()
                    
                    if let songList = result["queue"] as? [[String: Any]] {
                        print("📦 Received \(songList.count) songs from server")
                        
                        var seenIDs = Set<String>()
                        
                        for (index, song) in songList.enumerated() {
                            let uniqueID = song["uuid"] as? String ?? UUID().uuidString
                            
                            // Skip if we've already seen this ID (prevent duplicates)
                            if seenIDs.contains(uniqueID) {
                                print("⚠️ Skipping duplicate song ID: \(uniqueID)")
                                continue
                            }
                            seenIDs.insert(uniqueID)
                            
                            // Validate that we have essential song data
                            let title = song["title"] as? String ?? "Unknown Title"
                            let artist = song["artist"] as? String ?? "Unknown Artist"
                            
                            print("📝 Processing song \(index + 1): \(title) by \(artist) (ID: \(uniqueID))")
                            
                            self.queue[uniqueID] = song
                            self.queueOrder.append(uniqueID) // Maintain order
                        }
                        print("✅ Queue updated successfully with \(self.queue.count) songs")
                        print("🔗 Queue order: \(self.queueOrder)")
                        
                        // Debug: Check for any inconsistencies
                        self.validateQueueConsistency()
                    } else {
                        print("⚠️ No queue data received or invalid format")
                    }
                    
                    // Force UI update
                    self.objectWillChange.send()
                    completion()
                }
            } else {
                print("❌ Failed to fetch queue - no result received")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func nextSong(completion: @escaping () -> Void) {
        print("jwt: \(self.jwt_auth)")
        print("room code: \(self.room)")
        
        // Store current song as last played before transitioning
        if !currentSong.isEmpty {
            lastPlayedSong = currentSong
            print("💿 Stored last played song from nextSong: \(currentSong["title"] as? String ?? "Unknown")")
        }
        
        QueueManager.sendPostRequest(body: ["jwt": self.jwt_auth, "room": self.room], endpoint: "/next-song") { result in
            if let result = result {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
                print("Failed to go to next song")
                completion()
            }
        }
    }
    
    func nextSongWithAutoplayCheck(roomManager: RoomManager, completion: @escaping () -> Void) {
        print("⏭️ Skipping song with autoplay check")
        nextSong {
            // After skipping, check if we should trigger autoplay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkAndTriggerAutoplay(roomManager: roomManager)
            }
            completion()
        }
    }

    class func sendPostRequest(body: [String: String], endpoint: String, completion: @escaping ([String: Any]?) -> Void) {
        guard let url = URL(string: "https://api.partyaux.play" + endpoint) else {
            print("❌ Invalid URL: http://35.208.64.59\(endpoint)")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 🔥 Network Error
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // 🔍 HTTP Response (to get status code and headers)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Response Status Code: \(httpResponse.statusCode)")
                print("📦 Headers: \(httpResponse.allHeaderFields)")
            }

            // 📥 Check if data exists
            guard let data = data else {
                print("❌ No data received")
                completion(nil)
                return
            }

            // 🧪 Debug raw response body
            if let rawString = String(data: data, encoding: .utf8) {
                print("📄 Raw response body: \(rawString)")
            }

            // 🧠 Try JSON decoding
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Parsed JSON: \(json)")
                    completion(json)
                } else {
                    print("❌ JSON was not a dictionary")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing failed: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
    
    func triggerAutoplay(completion: @escaping (Bool) -> Void) {
        guard !lastPlayedSong.isEmpty else {
            print("❌ Cannot trigger autoplay: No last played song available")
            completion(false)
            return
        }
        
        // Create the request body with the complex structure
        let lastSongData: [String: Any] = [
            "artist": lastPlayedSong["artist"] as? String ?? "",
            "album": lastPlayedSong["album"] as? String ?? "",
            "title": lastPlayedSong["title"] as? String ?? "",
            "url": lastPlayedSong["url"] as? String ?? "",
            "album_art": lastPlayedSong["album_art"] as? String ?? "",
            "duration": lastPlayedSong["duration"] as? String ?? ""
        ]
        
        let requestBody: [String: Any] = [
            "jwt": self.jwt_auth,
            "room": self.room,
            "last_song": lastSongData
        ]
        
        QueueManager.sendComplexPostRequest(body: requestBody, endpoint: "/add-song-autoplay") { result in
            DispatchQueue.main.async {
                if let result = result {
                    print("🎵 AUTOPLAY API RESPONSE:")
                    print("🎵 Full response: \(result)")
                    
                    // Log specific fields if they exist
                    if let status = result["status"] as? String {
                        print("🎵 Status: \(status)")
                    }
                    if let message = result["message"] as? String {
                        print("🎵 Message: \(message)")
                    }
                    if let song = result["song"] as? [String: Any] {
                        print("🎵 Added song: \(song)")
                    }
                    
                    print("✅ Autoplay request successful")
                    completion(true)
                } else {
                    print("❌ AUTOPLAY API FAILED - No response received")
                    completion(false)
                }
            }
        }
    }
    
    class func sendComplexPostRequest(body: [String: Any], endpoint: String, completion: @escaping ([String: Any]?) -> Void) {
        guard let url = URL(string: "https://api.partyaux.play" + endpoint) else {
            print("❌ Invalid URL: http://35.208.64.59\(endpoint)")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Error encoding request body: \(error)")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 🔥 Network Error
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // 🔍 HTTP Response (to get status code and headers)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Response Status Code: \(httpResponse.statusCode)")
                print("📦 Headers: \(httpResponse.allHeaderFields)")
            }

            // 📥 Check if data exists
            guard let data = data else {
                print("❌ No data received")
                completion(nil)
                return
            }

            // 🧪 Debug raw response body
            if let rawString = String(data: data, encoding: .utf8) {
                print("📄 Raw response body: \(rawString)")
            }

            // 🧠 Try JSON decoding
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Parsed JSON: \(json)")
                    completion(json)
                } else {
                    print("❌ JSON was not a dictionary")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing failed: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
    
    // MARK: - Debug Helper
    private func validateQueueConsistency() {
        let queueKeys = Set(queue.keys)
        let orderSet = Set(queueOrder)
        
        if queueKeys != orderSet {
            print("⚠️ Queue consistency issue detected!")
            print("Queue keys count: \(queueKeys.count), Order count: \(queueOrder.count)")
            
            let missingFromOrder = queueKeys.subtracting(orderSet)
            let missingFromQueue = orderSet.subtracting(queueKeys)
            
            if !missingFromOrder.isEmpty {
                print("Missing from order: \(missingFromOrder)")
            }
            if !missingFromQueue.isEmpty {
                print("Missing from queue: \(missingFromQueue)")
            }
        }
        
        // Check for duplicates in order
        let duplicates = queueOrder.reduce(into: [String: Int]()) { counts, id in
            counts[id, default: 0] += 1
        }.filter { $0.value > 1 }
        
        if !duplicates.isEmpty {
            print("⚠️ Duplicate IDs found in queue order: \(duplicates)")
        }
    }
    // Add this method to be called when the app state changes
        func handleAppStateChange(isBackground: Bool) {
            self.isInBackground = isBackground
        }
    
    func checkAndTriggerAutoplay(roomManager: RoomManager) {
        // Only trigger autoplay if:
        // 1. Autoplay is enabled
        // 2. User is the host
        // 3. Queue is empty
        // 4. No song is currently playing
        
        print("🔄 Checking autoplay conditions...")
        print("🔄 - Autoplay enabled: \(roomManager.autoplayEnabled)")
        print("🔄 - Is host: \(roomManager.isCurrentUserHost)")
        print("🔄 - Queue empty: \(queueOrder.isEmpty) (count: \(queueOrder.count))")
        print("🔄 - Song playing: \(songCurrentlyPlaying)")
        print("🔄 - Current song empty: \(currentSong.isEmpty || (currentSong["title"] as? String ?? "").isEmpty)")
        print("🔄 - Last played song available: \(!lastPlayedSong.isEmpty)")
        if !lastPlayedSong.isEmpty {
            print("🔄 - Last played song: \(lastPlayedSong["title"] as? String ?? "Unknown")")
        }
        
        guard roomManager.autoplayEnabled else {
            print("🔄 Autoplay not enabled, skipping")
            return
        }
        
        guard roomManager.isCurrentUserHost else {
            print("🔄 User is not host, skipping autoplay")
            return
        }
        
        guard queueOrder.isEmpty else {
            print("🔄 Queue is not empty (\(queueOrder.count) songs), skipping autoplay")
            return
        }
        
        guard !songCurrentlyPlaying else {
            print("🔄 Song currently playing, skipping autoplay")
            return
        }
        
        guard currentSong.isEmpty || (currentSong["title"] as? String ?? "").isEmpty else {
            print("🔄 Current song exists, skipping autoplay")
            return
        }
        
        print("🎵 All conditions met, triggering autoplay...")
        triggerAutoplay { success in
            if success {
                print("✅ Autoplay triggered successfully")
                // Optionally refresh the queue after a short delay to see the new song
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.fetchQueue {
                        print("🔄 Queue refreshed after autoplay")
                    }
                }
            } else {
                print("❌ Autoplay failed")
            }
        }
    }
}
