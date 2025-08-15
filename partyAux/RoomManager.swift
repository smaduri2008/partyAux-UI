import Foundation
import SocketIO

class RoomManager: ObservableObject{
    
    @Published var userData: UserAuth
    @Published var queueManager: QueueManager?
    @Published var downvotes: Int = 5
    @Published var roomCode: String = ""
    @Published var currentSong: [String: Any] = [:]
    @Published var joinedRoom: Bool = false
    @Published var roomHost: String = ""
    
    @Published var roomMembers: [String] = [] // Array of email addresses
    @Published var roomMembersUsernames: [String: String] = [:] // Map email to username
    
    @Published var isCurrentUserHost: Bool = false
    
    private var manager: SocketManager
    private var socket : SocketIOClient
    
    
    init(userData: UserAuth) {
        self.userData = userData
        self.queueManager = nil
        manager = SocketManager(socketURL: URL(string: "http://35.208.64.59")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
        
        //userData.clearUserData()
        
        print("ROOMCODE: \(roomCode)")
        print("EMAIL: \(userData.email)")
        print("USERNAME: \(userData.username)")
        print("JWT: \(userData.jwt)")
        
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
            print("ROOMCODE: \(roomCode)")
            print("EMAIL: \(userData.email)")
            print("USERNAME: \(userData.username)")
            print("JWT: \(userData.jwt)")
            let url = userData.url + "/get-room-info"
            guard let urlRequest = URL(string: url) else { return }
            var request = URLRequest(url: urlRequest)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["room": roomCode, "jwt": userData.jwt])
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    print("no data returned")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let status = json["status"] as? String {
                        if status == "Room info retrieved" {
                            if let roomInfo = json["room_info"] as? [String: Any] {
                                DispatchQueue.main.async {
                                    // Parse host information
                                    if let hostDict = roomInfo["host"] as? [String: Any],
                                       let hostUser = hostDict["email"] as? String {
                                        let previousHost = self.roomHost
                                        self.roomHost = hostUser
                                        
                                        // Update host status after setting roomHost
                                        self.updateHostStatus()
                                        
                                        if previousHost != hostUser && !previousHost.isEmpty {
                                            print("🔄 Host changed from \(previousHost) to \(hostUser)")
                                            if self.isCurrentUserHost {
                                                print("🎉 You are now the host!")
                                            }
                                        } else {
                                            print("room host is \(hostUser)")
                                        }
                                    }
                                    
                                    // Parse users list (rest of your existing code)
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
                                        
                                        self.roomMembers = memberEmails
                                        self.roomMembersUsernames = emailToUsername
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
        self.roomHost = "" // Reset host status when joining existing room
        self.isCurrentUserHost = false
        createQueueManager()
        connect()
        self.getRoomInfo()
    }
     
    func leaveRoom() {
        guard let jwt = userData.jwt else { return }
        
        let body: [String: Any] = ["jwt": jwt]
        socket.emit("leave_room", body)
        
        // Clean up when leaving room
        self.joinedRoom = false
        self.queueManager = nil
        self.currentSong = [:]
        self.roomCode = ""
        
        // Disconnect socket
        disconnect()
    }
    

        
    func eventHandlers() {
        print("Setting up event handlers")
        
        socket.on(clientEvent: .connect) { data, ack in
            print("✅ Socket connected")
            // Automatically join room when connected (if we have a room code)
            if !self.roomCode.isEmpty {
                self.joinRoom()
                //self.getRoomInfo()
            } else {
                print("⚠️ Connected but no room code available")
            }
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("❌ Socket disconnected")
            DispatchQueue.main.async {
                self.joinedRoom = false
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
            self.queueManager?.fetchQueue {
                print("🔄 Queue refreshed after head song deletion")
            }
        }
        
        socket.on("add_song") { data, ack in
            print("➕ Song added to queue")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any] {
                if self.currentSong.isEmpty {
                    DispatchQueue.main.async {
                        self.currentSong = songDict
                        self.queueManager?.currentSong = songDict
                        print("✅ Set as current song since queue was empty")
                    }
                }
            }
        }
        
        socket.on("remove_song") { data, ack in
            print("➖ Song removed from queue")
            self.queueManager?.fetchQueue {
                print("🔄 Queue updated after song removal")
            }
        }
        
        socket.on("downvote") { data, ack in
            print("👎 Song downvoted")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any],
               let downvotes = payload["downvotes"] as? Int {
                print("📊 Song \(songDict) now has \(downvotes) downvotes")
            }
        }
        
        socket.on("someone_left") { data, ack in
                print("👋 Someone left the room")
                if let payload = data.first as? [String: Any],
                   let leftEmail = payload["email"] as? String {
                    
                    print("User left: \(leftEmail)")
                    
                    // If the person who left was the host, refresh room info
                    if leftEmail == self.roomHost {
                        print("🔄 Host left, refreshing room info...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.getRoomInfo()
                        }
                    }
                }
            }
        
        socket.onAny { event in
            print("🔍 Socket event: \(event.event), data: \(event.items)")
            print("isCurrentUserHost: \(self.isCurrentUserHost)")
        }
    }
}
