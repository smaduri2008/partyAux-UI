//
//  LibraryTab.swift
//  partyAux
//
//  Created by Sahas Maduri on 8/27/25.
//

import SwiftUI

struct LibraryTab: View {
    @EnvironmentObject var userData: UserAuth
    @EnvironmentObject var roomManager: RoomManager
    
    var body: some View {
        NavigationView {
            PlaylistsView(userData: userData)
                .environmentObject(roomManager) // Add this line
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
