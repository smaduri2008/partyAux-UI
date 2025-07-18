//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = UserAuth()
    @StateObject private var roomManager: RoomManager
    @State private var youtubePlayer: YTPlayerView?
    
    init() {
        let authInstance = UserAuth()
        _auth = StateObject(wrappedValue: authInstance)
        _roomManager = StateObject(wrappedValue: RoomManager(userData: authInstance))
    }
    
    var body: some View {
        NavigationView {
            if auth.authenticated {
                VStack {
                    if !roomManager.joinedRoom{
                        RoomCreateJoinView()
                            .environmentObject(roomManager)
                    }
                    
                    if roomManager.joinedRoom {
                        let queueManager = QueueManager(jwt_auth: auth.jwt ?? "", room: roomManager.roomCode)
                        
                        MusicPlayerView(
                            youtubePlayer: youtubePlayer,
                            queueManager: queueManager,
                            roomManager: roomManager
                        )
                    }
                }
            }
            else if auth.needsUser {
                CreateUsernameView()
            }
            else {
                EmailView()
            }
        }
        .environmentObject(auth)

    }
}

#Preview {
    ContentView()
        .environmentObject(UserAuth())
}
