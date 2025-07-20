//
//  RoomManager.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/13/25.
//

import Foundation
import SocketIO

class RoomManager: ObservableObject{
    
    @Published var userData: UserAuth
    @Published var queueManager: QueueManager?
    @Published var downvotes: Int = 5
    @Published var roomCode: String = "006998"
    @Published var currentSong: [String: Any] = [:]
    @Published var joinedRoom: Bool = false
    
    private var manager: SocketManager
    private var socket : SocketIOClient
    
    
    init(userData: UserAuth) {
        self.userData = userData
        self.queueManager = nil // Initialize as nil, will be created when joining room
        manager = SocketManager(socketURL: URL(string: "http://35.208.64.59")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
    }
    
    private func createQueueManager() {
        guard let jwt = userData.jwt else { return }
        self.queueManager = QueueManager(jwt_auth: jwt, room: roomCode)
    }
    
    func createRoom()
    {
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
                print("could not join room)")
                return
            }
            DispatchQueue.main.async {
                if status == "Room created successfully"{
                    print("room created")
                    self.roomCode = code
                    // Create QueueManager after room is created
                    self.createQueueManager()
                }
                else
                {
                    print("room could not be created")
                }
            }
        }.resume()
                
    }
    
    func connect()
    {
        socket.connect()
    }
    
    func disconnect()
    {
        socket.disconnect()
    }
    
    func joinRoom()
    {
        var body: [String: Any] = ["room": roomCode, "jwt": userData.jwt ?? ""] //can directly pass a dictionary to a socket endpoint
        socket.emit("join_room", body)
        print("joined room")
        self.joinedRoom = true
        
        // Create QueueManager when joining room
        self.createQueueManager()
    }
    
    func joinRoom(code: String) {
        self.roomCode = code
        joinRoom()
    }
     
    
    func leaveRoom()
    {
        var body: [String: Any] = ["jwt": userData.jwt]
        socket.emit("leave_room", body)
        
        // Clean up when leaving room
        self.joinedRoom = false
        self.queueManager = nil
        self.currentSong = [:]
    }
        
    func eventHandlers()
    {
        print("test")
        socket.on(clientEvent: .connect) {data, ack in
            print("connected")
            self.joinRoom()
        }
        socket.on(clientEvent: .disconnect){data, ack in
            print("disconnected")
        }
        
        socket.on("server_message"){ data, ack in
            if let message = data.first as? [String: Any],
            let msg = message["message"] as? String{
                print("server_message \(msg)")
            }
        }
        
        socket.on("current_song"){ data, ack in
            print("Current song changed from server")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.queueManager?.fetchQueue {
                        print("Queue refreshed after head song deletion")
                    }
                    self.currentSong = songDict
                    self.queueManager?.currentSong = songDict
                    print("Updated current song: \(songDict)")
                }
            }
        }
        
        socket.on("delete_head_song") { data, ack in
            print("Head song deleted from queue")
            self.queueManager?.fetchQueue {
                print("Queue refreshed after head song deletion")
            }
        }
        
        socket.on("add_song") { data, ack in
            print("song added to queue")
            //self.queueManager?.fetchQueue {
                print("updating queue after song addition")
                if let payload = data.first as? [String: Any],
                   let songDict = payload["song"] as? [String: Any] {
                    if self.currentSong.isEmpty {
                        DispatchQueue.main.async {
                            self.currentSong = songDict
                            self.queueManager?.currentSong = songDict
                        }
                    }
                }
            //}
        }
        
        socket.on("remove_song") { data, ack in
            print("song removed from queue")
            self.queueManager?.fetchQueue {
                print("updating queue after song removal")
            }
        }
        
        socket.on("downvote") { data, ack in
            print("Song downvoted")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any],
               let downvotes = payload["downvotes"] as? Int {
                print("Song \(songDict) now has \(downvotes) downvotes")
            }
        }
        
        socket.onAny { event in
            print("Got event: \(event.event), data: \(event.items)")
        }
    }
}
