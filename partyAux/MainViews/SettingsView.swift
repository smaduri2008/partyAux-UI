//
//  SettingsView.swift
//  partyAux
//
//  Created by Sansky Srivastava on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var playOnHostOnly = false
    @State private var showProfileSettings = false
    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Profile")) {
                    Button {
                        showProfileSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                            Text("Profile Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("Audio")) {
                    Toggle(isOn: $playOnHostOnly) {
                        HStack {
                            Image(systemName: "speaker.3.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Play on Host Device Only")
                                Text("Audio will only play on the host’s device")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Room Settings")

        }
    }
}





/*
 // MARK: - Preview
 #Preview {
 SettingsView().environmentObject(UserAuth())
 }
 */
