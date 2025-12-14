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
        // Don't clear currentSong here to prevent UI flashing
        NetworkManager.shared.post(endpoint: "/get-current-song", body: ["jwt": self.jwt_auth, "room": self.room]) { result in
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
            var shouldNotify = false
            
            // Update the song in the queue without changing order
            if var songData = self.queue[songUuid] {
                // Update the downvote count
                songData["downvote_count"] = newDownvoteCount
                
                // Update downvotes array if provided
                if let downvotesArray = downvotesArray {
                    songData["downvotes"] = downvotesArray
                }
                
                self.queue[songUuid] = songData
                shouldNotify = true
            }
            
            // Also update current song if it matches
            if let currentSongUuid = self.currentSong["uuid"] as? String,
               currentSongUuid == songUuid {
                
                self.currentSong["downvote_count"] = newDownvoteCount
                
                // Update downvotes array for current song if provided
                if let downvotesArray = downvotesArray {
                    self.currentSong["downvotes"] = downvotesArray
                    shouldNotify = true
                }
            }
            
            // Single notification at the end if any changes were made
            if shouldNotify {
                self.objectWillChange.send()
            }
        }
    }
    
    func addSongToQueue(_ songData: [String: Any]) {
        DispatchQueue.main.async {
            if let uuid = songData["uuid"] as? String {
                // Only add if not already present to prevent duplicates
                if !self.queueOrder.contains(uuid) {
                    self.queue[uuid] = songData
                    self.queueOrder.append(uuid)
                    self.objectWillChange.send()
                } else {
                    // Update existing song data but don't add to order again
                    self.queue[uuid] = songData
                }
            }
        }
    }
    
    func removeSongFromQueue(_ songUuid: String) {
        DispatchQueue.main.async {
            self.queue.removeValue(forKey: songUuid)
            if let index = self.queueOrder.firstIndex(of: songUuid) {
                self.queueOrder.remove(at: index)
            }
            self.objectWillChange.send()
        }
    }
    
    func removeFirstSongFromQueue() {
        DispatchQueue.main.async {
            if let firstSongUuid = self.queueOrder.first,
               let songData = self.queue[firstSongUuid] {
                // Store the song before removing it
                self.lastPlayedSong = songData
                
                self.queue.removeValue(forKey: firstSongUuid)
                self.queueOrder.removeFirst()
                self.objectWillChange.send()
            }
        }
    }
    
    func fetchQueue(completion: @escaping () -> Void) {
        NetworkManager.shared.post(endpoint: "/get-queue", body: ["jwt": self.jwt_auth, "room": self.room]) { result in
            if let result = result {
                DispatchQueue.main.async {
                    if let songList = result["queue"] as? [[String: Any]] {
                        var newQueue: [String: [String: Any]] = [:]
                        var newQueueOrder: [String] = []
                        var seenIDs = Set<String>()
                        
                        for song in songList {
                            let uniqueID = song["uuid"] as? String ?? UUID().uuidString
                            
                            // Skip duplicates
                            if seenIDs.contains(uniqueID) {
                                continue
                            }
                            seenIDs.insert(uniqueID)
                            
                            newQueue[uniqueID] = song
                            newQueueOrder.append(uniqueID)
                        }
                        
                        // Atomically update the published properties
                        self.queue = newQueue
                        self.queueOrder = newQueueOrder
                    }
                    
                    // Force UI update
                    self.objectWillChange.send()
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func nextSong(completion: @escaping () -> Void) {
        print("⏭️ Requesting next song from server")
        print("jwt: \(self.jwt_auth.prefix(20))...")
        print("room code: \(self.room)")
        
        // Store current song as last played before transitioning
        if !currentSong.isEmpty {
            lastPlayedSong = currentSong
            print("💿 Stored last played song from nextSong: \(currentSong["title"] as? String ?? "Unknown")")
        }
        
        NetworkManager.shared.post(endpoint: "/next-song", body: ["jwt": self.jwt_auth, "room": self.room]) { result in
            if let result = result {
                print("✅ Server responded to next-song request: \(result)")
                DispatchQueue.main.async {
                    // Fetch both current song and queue to ensure proper sync
                    let group = DispatchGroup()
                    
                    group.enter()
                    self.fetchCurrentSong {
                        print("✅ Current song fetched after next-song")
                        group.leave()
                    }
                    
                    group.enter()
                    self.fetchQueue {
                        print("✅ Queue fetched after next-song")
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        // Force UI update after both fetches complete
                        self.objectWillChange.send()
                        completion()
                    }
                }
            } else {
                print("❌ Failed to go to next song")
                DispatchQueue.main.async {
                    completion()
                }
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
        
        NetworkManager.shared.post(endpoint: "/add-song-autoplay", body: requestBody) { result in
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
