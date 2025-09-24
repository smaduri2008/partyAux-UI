import Foundation
import SocketIO

class RoomManager: ObservableObject{
    
    @Published var userData: UserAuth
    @Published var queueManager: QueueManager?
    @Published var downvotes: Int = 5
    @Published var maxDownvotes: Int = 5  // Track the room's max downvotes setting
    @Published var roomCode: String = ""
    @Published var currentSong: [String: Any] = [:]
    @Published var joinedRoom: Bool = false
    @Published var roomHost: String = ""
    @Published var hostPlayingOnly: Bool = false {
        didSet {
            if oldValue != hostPlayingOnly {
                print("🔄 hostPlayingOnly changed from \(oldValue) to \(hostPlayingOnly)")
                // Post notification for UI updates
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("HostPlayingOnlyChanged"),
                        object: nil,
                        userInfo: ["hostPlayingOnly": self.hostPlayingOnly]
                    )
                }
            }
        }
    }
    
    @Published var roomMembers: [String] = [] {
        didSet {
            print("🔄 roomMembers updated: \(roomMembers)")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    @Published var roomMembersUsernames: [String: String] = [:] {
        didSet {
            print("🔄 roomMembersUsernames updated: \(roomMembersUsernames)")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var isCurrentUserHost: Bool = false {
        didSet {
            if oldValue != isCurrentUserHost {
                print("🔄 isCurrentUserHost changed from \(oldValue) to \(isCurrentUserHost)")
                // Post notification for audio control updates
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("HostStatusChanged"),
                        object: nil,
                        userInfo: ["isCurrentUserHost": self.isCurrentUserHost]
                    )
                }
            }
        }
    }
    
    private var manager: SocketManager
    private var socket : SocketIOClient
    
    
    init(userData: UserAuth) {
        self.userData = userData
        self.queueManager = nil
        manager = SocketManager(socketURL: URL(string: "http://35.208.64.59")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
        
        updateHostStatus()
    }
    
    private func createQueueManager() {
        guard let jwt = userData.jwt else {
            print("❌ Cannot create QueueManager: JWT is nil")
            return
        }
        
        guard !roomCode.isEmpty else {
            print("❌ Cannot create QueueManager: roomCode is empty")
            return
        }
        
        print("✅ Creating QueueManager with room: '\(roomCode)'")
        self.queueManager = QueueManager(jwt_auth: jwt, room: roomCode)
    }
    
    func createRoom() {
        let url = userData.url + "/create-room"
        guard let urlRequest = URL(string: url) else {return}
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["jwt": userData.jwt, "max_downvotes": downvotes])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = response["status"] as? String,
                  let code = response["code"] as? String else {
                print("❌ Could not create room")
                return
            }
            
            DispatchQueue.main.async {
                if status == "Room created successfully" {
                    print("✅ Room created with code: \(code)")
                    self.roomCode = code
                    
                    // Immediately set host status since we created the room
                    self.roomHost = self.userData.email
                    self.isCurrentUserHost = true
                    print("🎉 Set as host immediately: \(self.userData.email)")
                    
                    self.createQueueManager()
                    self.connect()
                    
                } else {
                    print("❌ Room could not be created: \(status)")
                }
            }
        }.resume()
    }
    
    private func updateHostStatus() {
        let newHostStatus = !roomHost.isEmpty && !userData.email.isEmpty && roomHost == userData.email
            
        if newHostStatus != isCurrentUserHost {
            print("🔄 Host status changing from \(isCurrentUserHost) to \(newHostStatus)")
            print("   roomHost: '\(roomHost)'")
            print("   userData.email: '\(userData.email)'")
        }
            
        DispatchQueue.main.async {
            self.isCurrentUserHost = newHostStatus
        }
    }
    
    func getRoomInfo() {
        print("🔍 Getting room info for room: \(roomCode)")
        print("📧 Current user: \(userData.email)")
        
        let url = userData.url + "/get-room-info"
        guard let urlRequest = URL(string: url) else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["room": roomCode, "jwt": userData.jwt])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("❌ No data returned from getRoomInfo")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Raw room info response: \(jsonString)")
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let status = json["status"] as? String {
                    print("📊 Room info status: \(status)")
                    
                    if status == "Room info retrieved" {
                        if let roomInfo = json["room_info"] as? [String: Any] {
                            DispatchQueue.main.async {
                                if let hostDict = roomInfo["host"] as? [String: Any],
                                   let hostUser = hostDict["email"] as? String {
                                    let previousHost = self.roomHost
                                    self.roomHost = hostUser
                                    self.updateHostStatus()
                                    print("🏠 Host updated to: \(hostUser)")
                                }
                                
                                if let usersArray = roomInfo["users"] as? [[String: Any]] {
                                    var memberEmails: [String] = []
                                    var emailToUsername: [String: String] = [:]
                                    
                                    for userDict in usersArray {
                                        if let email = userDict["email"] as? String,
                                           let username = userDict["username"] as? String {
                                            memberEmails.append(email)
                                            emailToUsername[email] = username
                                        }
                                    }
                                    
                                    self.roomMembers.removeAll()
                                    self.roomMembersUsernames.removeAll()
                                    
                                    self.roomMembers = memberEmails
                                    self.roomMembersUsernames = emailToUsername
                                    self.objectWillChange.send()
                                }
                                
                                if let maxDownvotesValue = roomInfo["max_downvotes"] as? Int {
                                    self.maxDownvotes = maxDownvotesValue
                                    print("🎯 Max downvotes set to: \(maxDownvotesValue)")
                                }
                                
                                // Parse host playing only setting
                                if let hostOnly = roomInfo["host_playing_only"] as? Bool {
                                    let previousValue = self.hostPlayingOnly
                                    self.hostPlayingOnly = hostOnly
                                    print("🎵 Host playing only updated: \(previousValue) -> \(hostOnly)")
                                }
                            }
                        }
                    }
                }
            }
        }.resume()
    }
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    private func joinRoom() {
        guard !roomCode.isEmpty else {
            print("❌ Cannot join room: roomCode is empty")
            return
        }
        
        guard let jwt = userData.jwt else {
            print("❌ Cannot join room: JWT is nil")
            return
        }
        
        let body: [String: Any] = ["room": roomCode, "jwt": jwt]
        socket.emit("join_room", body)
        print("✅ Joining room: \(roomCode)")
        self.joinedRoom = true
        self.getRoomInfo()
    }
    
    func joinExistingRoom(code: String) {
        print("🚪 Joining existing room with code: \(code)")
        self.roomCode = code
        self.roomHost = ""
        self.isCurrentUserHost = false
        createQueueManager()
        connect()
        self.getRoomInfo()
    }
     
    func leaveRoom() {
        guard let jwt = userData.jwt else { return }
        
        let body: [String: Any] = ["jwt": jwt]
        socket.emit("leave_room", body)
        
        self.joinedRoom = false
        self.queueManager = nil
        self.currentSong = [:]
        self.roomCode = ""
        self.hostPlayingOnly = false
        disconnect()
    }
    
    func downvoteSong(songUuid: String, completion: @escaping (Bool, String) -> Void) {
        let url = userData.url + "/add-downvote"
        guard let urlRequest = URL(string: url) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "jwt": userData.jwt ?? "",
            "room": roomCode,
            "song_uuid": songUuid
        ])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false, "No response from server")
                }
                return
            }
            
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if let status = jsonData["status"] as? String {
                        if status == "Downvote added" {
                            let downvoteCount = jsonData["downvotes"] as? Int ?? 0
                            completion(true, "Downvoted! (\(downvoteCount)/\(self.maxDownvotes))")
                        } else {
                            completion(false, status)
                        }
                    } else {
                        completion(false, "Unknown response")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    private func updateCurrentSongDownvoteData(downvotes: Int) {
        // Update current song downvote count
        self.currentSong["downvote_count"] = downvotes
        self.queueManager?.currentSong["downvote_count"] = downvotes
        
        // Always refresh current song data to get accurate downvotes array
        // since socket events don't always provide the full user list
        print("🔄 Refreshing current song to get updated downvotes array")
        self.queueManager?.fetchCurrentSong {
            print("✅ Current song data refreshed after downvote")
            DispatchQueue.main.async {
                // Update our current song reference
                self.currentSong = self.queueManager?.currentSong ?? [:]
                // Force UI update
                self.queueManager?.objectWillChange.send()
            }
        }
        
        print("🔄 Current song downvote count updated via socket")
    }
    
    func eventHandlers() {
        print("Setting up event handlers")
        
        socket.on(clientEvent: .connect) { data, ack in
            print("✅ Socket connected")
            if !self.roomCode.isEmpty {
                self.joinRoom()
            }
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("❌ Socket disconnected")
            DispatchQueue.main.async {
                self.joinedRoom = false
            }
        }
        
        // Listen for host playing only changes
        socket.on("host_playing_only_changed") { data, ack in
            print("🎵 host_playing_only_changed event received")
            print("🎵 Raw socket data: \(data)")
            
            if let payload = data.first as? [String: Any] {
                print("🎵 Socket payload: \(payload)")
                
                if let newValue = payload["host_playing_only"] as? Bool {
                    print("🎵 Parsed host_playing_only: \(newValue)")
                    DispatchQueue.main.async {
                        let previousValue = self.hostPlayingOnly
                        self.hostPlayingOnly = newValue
                        print("🎵 Updated hostPlayingOnly: \(previousValue) -> \(newValue)")
                        
                        // Force UI update
                        self.objectWillChange.send()
                        
                        // Post notification for immediate audio control update
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AudioControlUpdateRequired"),
                            object: nil,
                            userInfo: [
                                "hostPlayingOnly": newValue,
                                "isCurrentUserHost": self.isCurrentUserHost
                            ]
                        )
                    }
                } else {
                    print("❌ Could not parse host_playing_only from payload")
                }
            } else {
                print("❌ Could not parse socket payload for host_playing_only_changed")
            }
        }
        
        socket.on("server_message") { data, ack in
            if let message = data.first as? [String: Any],
               let msg = message["message"] as? String {
                print("📨 Server message: \(msg)")
            }
        }
        
        socket.on("current_song") { data, ack in
            print("🎵 Current song changed from server")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.queueManager?.fetchQueue {
                        print("🔄 Queue refreshed after current song change")
                    }
                    self.currentSong = songDict
                    self.queueManager?.currentSong = songDict
                    print("✅ Updated current song: \(songDict)")
                }
            }
        }
        
        socket.on("delete_head_song") { data, ack in
            print("🗑️ Head song deleted from queue")
            DispatchQueue.main.async {
                // Remove first song from queue without full refresh
                self.queueManager?.removeFirstSongFromQueue()
                print("🔄 Removed head song from queue")
            }
        }
        
        socket.on("add_song") { data, ack in
            print("➕ Song added to queue")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any] {
                DispatchQueue.main.async {
                    // Add song to queue without changing order of existing songs
                    self.queueManager?.addSongToQueue(songDict)
                    
                    // If this is the first song and no current song, set as current
                    if self.currentSong.isEmpty {
                        self.currentSong = songDict
                        self.queueManager?.currentSong = songDict
                        print("✅ Set as current song since queue was empty")
                    }
                }
            }
        }
        
        socket.on("remove_song") { data, ack in
            print("➖ Song removed from queue")
            if let payload = data.first as? [String: Any],
               let removedUuid = payload["song"] as? String {
                DispatchQueue.main.async {
                    // Remove specific song without affecting order of other songs
                    self.queueManager?.removeSongFromQueue(removedUuid)
                    print("🔄 Removed song \(removedUuid) from queue")
                }
            } else {
                // Fallback to full refresh if we don't have the UUID
                self.queueManager?.fetchQueue {
                    print("🔄 Queue updated after song removal (fallback)")
                }
            }
        }
        
        socket.on("downvote") { data, ack in
            print("👎 Song downvoted - socket event received")
            if let payload = data.first as? [String: Any],
               let songUuid = payload["song"] as? String,
               let downvotes = payload["downvotes"] as? Int {
                print("📊 Song \(songUuid) now has \(downvotes) downvotes")
                
                // Try to get downvotes array from payload if available
                let downvotesArray = payload["downvotes_array"] as? [String]
                print("🔍 Downvotes array from socket: \(downvotesArray ?? [])")
                print("🔍 Full socket payload: \(payload)")
                
                DispatchQueue.main.async {
                    // Check if this is the current song
                    let currentSongUuid = self.currentSong["uuid"] as? String
                    let queueManagerCurrentSongUuid = self.queueManager?.currentSong["uuid"] as? String
                    let isCurrentSong = (currentSongUuid == songUuid) || (queueManagerCurrentSongUuid == songUuid)
                    
                    print("🔍 RoomManager current song UUID: \(currentSongUuid ?? "nil")")
                    print("🔍 QueueManager current song UUID: \(queueManagerCurrentSongUuid ?? "nil")")
                    print("🔍 Socket event song UUID: \(songUuid)")
                    print("🔍 Is current song: \(isCurrentSong)")
                    
                    if downvotesArray != nil {
                        // If we have the complete downvotes array, update immediately
                        self.queueManager?.updateSongDownvoteCount(songUuid: songUuid, newDownvoteCount: downvotes, downvotesArray: downvotesArray)
                        
                        if isCurrentSong {
                            print("🎯 Updating current song data with array")
                            self.updateCurrentSongDownvoteData(downvotes: downvotes)
                        }
                    } else {
                        // Socket event doesn't include downvotes array - need to fetch fresh data
                        print("⚠️ No downvotes array in socket event - fetching fresh data")
                        
                        if isCurrentSong {
                            // For current song, fetch current song data to get the downvotes array
                            print("🔄 Fetching current song data to get accurate downvotes array")
                            self.queueManager?.fetchCurrentSong {
                                DispatchQueue.main.async {
                                    // Update current song references
                                    self.currentSong = self.queueManager?.currentSong ?? [:]
                                    self.queueManager?.objectWillChange.send()
                                    print("✅ Current song data refreshed with downvotes array")
                                }
                            }
                        } else {
                            // For queue songs, fetch the full queue to get updated downvotes arrays
                            print("🔄 Fetching queue data to get accurate downvotes arrays")
                            self.queueManager?.fetchQueue {
                                print("✅ Queue data refreshed with downvotes arrays")
                            }
                        }
                    }
                }
            } else {
                print("❌ Invalid downvote socket event payload")
                print("❌ Raw data: \(data)")
            }
        }
        
        socket.on("delete_song_from_queue") { data, ack in
            print("🗑️ Song deleted from queue due to downvotes")
            if let payload = data.first as? [String: Any],
               let deletedUuid = payload["uuid"] as? String {
                print("🗑️ Deleted song UUID: \(deletedUuid)")
                
                DispatchQueue.main.async {
                    // Remove specific song without affecting order of other songs
                    self.queueManager?.removeSongFromQueue(deletedUuid)
                    print("🔄 Removed song \(deletedUuid) due to downvotes")
                }
            }
        }
        
        socket.on("someone_left") { data, ack in
            print("👋 Someone left the room")
            if let payload = data.first as? [String: Any],
               let leftEmail = payload["email"] as? String {
                
                print("User left: \(leftEmail)")
                
                // Add a small delay to ensure server state is updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.getRoomInfo()
                }
            }
        }
        
        socket.on("someone_joined") { data, ack in
            print("👋 Someone joined the room")
            if let payload = data.first as? [String: Any],
               let joinedEmail = payload["email"] as? String {
                
                print("User joined: \(joinedEmail)")
                
                // Add a small delay to ensure server state is updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.getRoomInfo()
                }
            }
        }
        
        socket.onAny { event in
            print("🔍 Socket event: \(event.event), data: \(event.items)")
            print("isCurrentUserHost: \(self.isCurrentUserHost)")
        }
    }
}
