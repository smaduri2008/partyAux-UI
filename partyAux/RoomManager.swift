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
    @Published var downvotes: Int = 5
    @Published var roomCode: String = "006998"
    @Published var currentSong: Song = Song(from: [:])
    @Published var joinedRoom: Bool = false
    
    private var manager: SocketManager
    private var socket : SocketIOClient
    
    
    init(userData: UserAuth) {
        self.userData = userData
        manager = SocketManager(socketURL: URL(string: "http://35.208.64.59")!, config: [.log(true), .compress, .reconnects(true)])
        socket = manager.defaultSocket
        print("RoomManager initialized")
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
        
    }
     
    
    func leaveRoom()
    {
        var body: [String: Any] = ["jwt": userData.jwt]
        socket.emit("leave_room", body)
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
        
        socket.on("add_song") { data, ack in
            print("song changed")
            if let payload = data.first as? [String: Any],
               let songDict = payload["song"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.currentSong = Song(from: songDict)
                }
            }
        }
        
        socket.onAny { event in
            print("Got event: \(event.event), data: \(event.items)")
        }

        
        
    }
}
