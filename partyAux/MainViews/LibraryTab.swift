//
//  LibraryTab.swift
//  partyAux
//
//  Created by Sahas Maduri on 8/27/25.
//

import SwiftUI

struct LibraryTab: View {
    @EnvironmentObject var userData: UserAuth
    
    var body: some View {
        NavigationView {
            PlaylistsView(userData: userData)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

/*
 #Preview {
 LibraryTab()
 }
 */
