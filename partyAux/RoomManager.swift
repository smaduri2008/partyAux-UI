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
    
    @Published var autoplayEnabled: Bool = false {
        didSet {
            if oldValue != autoplayEnabled {
                print("🔄 autoplayEnabled changed from \(oldValue) to \(autoplayEnabled)")
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
    private var syncTimer: Timer?
    
    
    init(userData: UserAuth) {
        self.userData = userData
        self.queueManager = nil
        manager = SocketManager(socketURL: URL(string: "https://api.partyaux.party")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
        
        updateHostStatus()
    }
    
    deinit {
        stopPeriodicSync()
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
        NetworkManager.shared.post(endpoint: "/create-room", body: ["jwt": userData.jwt ?? "", "max_downvotes": downvotes]) { response in
            guard let response = response,
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
        }
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
    
    private func startPeriodicSync() {
        stopPeriodicSync()
        
        DispatchQueue.main.async {
            self.syncTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                // Sync queue and members data
                self.queueManager?.fetchQueue {
                    print("🔄 Periodic sync: Queue updated")
                }
                
                self.getRoomInfo()
            }
            
            print("✅ Started periodic sync (every 3 seconds)")
        }
    }
    
    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏹️ Stopped periodic sync")
    }
    
    func getRoomInfo() {
        print("🔍 Getting room info for room: \(roomCode)")
        print("📧 Current user: \(userData.email)")
        
        NetworkManager.shared.post(endpoint: "/get-room-info", body: ["room": roomCode, "jwt": userData.jwt ?? ""]) { json in
            guard let json = json else {
                print("❌ No data returned from getRoomInfo")
                return
            }
            
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
        
        // Start periodic sync
        startPeriodicSync()
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
        
        // Stop periodic sync
        stopPeriodicSync()
        
        disconnect()
    }
    
    func downvoteSong(songUuid: String, completion: @escaping (Bool, String) -> Void) {
        NetworkManager.shared.post(endpoint: "/add-downvote", body: [
            "jwt": userData.jwt ?? "",
            "room": roomCode,
            "song_uuid": songUuid
        ]) { jsonData in
            guard let jsonData = jsonData else {
                DispatchQueue.main.async {
                    completion(false, "No response from server")
                }
                return
            }
            
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
        }
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
                    self.currentSong = songDict
                    self.queueManager?.currentSong = songDict
                    print("✅ Updated current song: \(songDict["title"] as? String ?? "Unknown")")
                    
                    // Force UI update
                    self.objectWillChange.send()
                    self.queueManager?.objectWillChange.send()
                    
                    // Immediately refresh queue to ensure sync
                    self.queueManager?.fetchQueue {
                        print("🔄 Queue refreshed after current song change")
                    }
                }
            } else {
                // If no song data (empty/null song), store current song as last played before clearing
                DispatchQueue.main.async {
                    // Store current song as last played if it exists
                    if let queueManager = self.queueManager, !queueManager.currentSong.isEmpty {
                        queueManager.lastPlayedSong = queueManager.currentSong
                        print("📀 Stored last played song from current_song event: \(queueManager.currentSong["title"] as? String ?? "Unknown")")
                    }
                    
                    self.currentSong = [:]
                    self.queueManager?.currentSong = [:]
                    print("✅ Cleared current song")
                    
                    // Force UI update
                    self.objectWillChange.send()
                    self.queueManager?.objectWillChange.send()
                    
                    // Refresh queue and check autoplay
                    self.queueManager?.fetchQueue {
                        print("🔄 Queue refreshed after song cleared")
                        if let queueManager = self.queueManager {
                            queueManager.checkAndTriggerAutoplay(roomManager: self)
                        }
                    }
                }
            }
        }
        
        socket.on("delete_head_song") { data, ack in
            print("🗑️ Head song deleted from queue")
            DispatchQueue.main.async {
                // Immediately refresh both current song and queue
                self.queueManager?.fetchCurrentSong {
                    self.currentSong = self.queueManager?.currentSong ?? [:]
                    self.objectWillChange.send()
                }
                
                self.queueManager?.fetchQueue {
                    print("🔄 Queue refreshed after head song deleted")
                    // Check autoplay after queue is updated
                    if let queueManager = self.queueManager {
                        queueManager.checkAndTriggerAutoplay(roomManager: self)
                    }
                }
            }
        }
        
        socket.on("add_song") { data, ack in
            print("➕ Song added to queue")
            
            // Check if there's currently no song playing
            let currentSongEmpty = self.currentSong.isEmpty || (self.currentSong["url"] as? String ?? "").isEmpty
            let queueManagerSongEmpty = self.queueManager?.currentSong.isEmpty ?? true || 
                (self.queueManager?.currentSong["url"] as? String ?? "").isEmpty
            let wasEmpty = currentSongEmpty && queueManagerSongEmpty
            
            print("🔍 add_song: currentSongEmpty=\(currentSongEmpty), queueManagerSongEmpty=\(queueManagerSongEmpty), wasEmpty=\(wasEmpty)")
            
            // First fetch current song from server - it may have been auto-set
            self.queueManager?.fetchCurrentSong {
                DispatchQueue.main.async {
                    // Update local current song reference
                    if let queueManager = self.queueManager {
                        self.currentSong = queueManager.currentSong
                    }
                    
                    // Then fetch queue
                    self.queueManager?.fetchQueue {
                        DispatchQueue.main.async {
                            // If there was no song before and server didn't set one, set it ourselves
                            if wasEmpty {
                                let serverSetSong = !(self.queueManager?.currentSong.isEmpty ?? true) && 
                                    !(self.queueManager?.currentSong["url"] as? String ?? "").isEmpty
                                
                                if serverSetSong {
                                    print("✅ Server already set current song")
                                    self.currentSong = self.queueManager?.currentSong ?? [:]
                                } else if let firstSongUuid = self.queueManager?.queueOrder.first,
                                          let firstSong = self.queueManager?.queue[firstSongUuid] {
                                    // Server didn't set it, so we set it from queue
                                    self.currentSong = firstSong
                                    self.queueManager?.currentSong = firstSong
                                    print("✅ Set first queue song as current since queue was empty")
                                }
                                
                                // Post notification to trigger playback
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("FirstSongAdded"),
                                    object: nil
                                )
                            }
                            
                            // Force UI update
                            self.objectWillChange.send()
                            self.queueManager?.objectWillChange.send()
                        }
                    }
                }
            }
        }
        
        socket.on("remove_song") { data, ack in
            print("➖ Song removed from queue")
            // Immediately refresh queue
            self.queueManager?.fetchQueue {
                print("🔄 Queue refreshed after song removed")
                if let queueManager = self.queueManager {
                    queueManager.checkAndTriggerAutoplay(roomManager: self)
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
                
                DispatchQueue.main.async {
                    // Check if this is the current song
                    let currentSongUuid = self.currentSong["uuid"] as? String
                    let isCurrentSong = currentSongUuid == songUuid
                    
                    if let downvotesArray = downvotesArray {
                        // If we have the complete downvotes array, update immediately
                        self.queueManager?.updateSongDownvoteCount(songUuid: songUuid, newDownvoteCount: downvotes, downvotesArray: downvotesArray)
                        
                        if isCurrentSong {
                            self.updateCurrentSongDownvoteData(downvotes: downvotes)
                        }
                    }
                    // If no downvotes array, periodic sync will handle the update
                }
            }
        }
        
        socket.on("delete_song_from_queue") { data, ack in
            print("🗑️ Song deleted from queue due to downvotes")
            // Immediately refresh queue and current song
            self.queueManager?.fetchCurrentSong {
                self.currentSong = self.queueManager?.currentSong ?? [:]
            }
            self.queueManager?.fetchQueue {
                print("🔄 Queue refreshed after song deleted from downvotes")
                if let queueManager = self.queueManager {
                    queueManager.checkAndTriggerAutoplay(roomManager: self)
                }
            }
        }
        
        socket.on("someone_left") { data, ack in
            print("👋 Someone left the room")
            if let payload = data.first as? [String: Any],
               let leftEmail = payload["email"] as? String {
                print("User left: \(leftEmail)")
                // Periodic sync will handle member list update
            }
        }
        
        socket.on("someone_joined") { data, ack in
            print("👋 Someone joined the room")
            if let payload = data.first as? [String: Any],
               let joinedEmail = payload["email"] as? String {
                print("User joined: \(joinedEmail)")
                // Periodic sync will handle member list update
            }
        }
        
        socket.onAny { event in
            print("🔍 Socket event: \(event.event), data: \(event.items)")
            print("isCurrentUserHost: \(self.isCurrentUserHost)")
        }
    }
}
