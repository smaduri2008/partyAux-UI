//
//  ContentView.swift
//  partyAux
//
//  Created by Sahas Maduri on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var auth = UserAuth()

    
    var body: some View {
        NavigationView{
            if auth.authenticated {
                //Text("you are authenticated")
                var roomManager = RoomManager(userData: self.auth)
                var queueManager = QueueManager(jwt_auth: auth.jwt ?? "", room: "006998")
                @State var youtubePlayer: YTPlayerView?
                VStack{
                    MusicPlayerView(
                        youtubePlayer: youtubePlayer,
                        queueManager: queueManager,
                        roomManager: roomManager
                    )
                }
                
            }
            else if auth.needsUser{
                CreateUsernameView()
            }
            else{
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
