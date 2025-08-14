import Foundation
import SocketIO

class RoomManager: ObservableObject{
    
    @Published var userData: UserAuth
    @Published var queueManager: QueueManager?
    @Published var downvotes: Int = 5
    @Published var roomCode: String = ""
    @Published var currentSong: [String: Any] = [:]
    @Published var joinedRoom: Bool = false
    
    private var manager: SocketManager
    private var socket : SocketIOClient
    
    
    init(userData: UserAuth) {
        self.userData = userData
        self.queueManager = nil
        manager = SocketManager(socketURL: URL(string: "http://35.208.64.59")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
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
                    self.createQueueManager()
                    self.connect()
                    
                } else {
                    print("❌ Room could not be created: \(status)")
                }
            }
        }.resume()
    }
    
    func getRoomInfo() {
        print("ROOMCODE: \(roomCode)")
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
                print("response: \(json)")
                
                if let status = json["status"] as? String {
                    if status == "Room info retrieved" {
                        print("room info: \(json["room_info"] ?? "No room_info field")")
                    } else {
                        print("server could not get room info: \(status)")
                    }
                } else {
                    print("data was not retreived")
                }
            } else {
                print("failed to parse JSON")
                if let rawString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawString)")
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
        
        
    }
    
    func joinExistingRoom(code: String) {
        print("🚪 Joining existing room with code: \(code)")
        self.roomCode = code
        createQueueManager()
        connect()
    
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
        
        socket.onAny { event in
            print("🔍 Socket event: \(event.event), data: \(event.items)")
        }
    }
}
