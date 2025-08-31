//
//  SettingsView.swift
//  partyAux
//
//  Created by Sansky Srivastava on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var playOnHostOnly = false
    @State private var maxDownvotes = 3
    @State private var isUpdatingDownvotes = false
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var roomManager: RoomManager

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Audio")) {
                    Toggle(isOn: $playOnHostOnly) {
                        HStack {
                            Image(systemName: "speaker.3.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Play on Host Device Only")
                                Text("Audio will only play on the host's device")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("Room Controls")) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Maximum Downvotes")
                            Text("Songs will be skipped when it reach \(maxDownvotes) downvotes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        if isUpdatingDownvotes {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Stepper(value: $maxDownvotes, in: 1...100) {
                                Text("\(maxDownvotes)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .onChange(of: maxDownvotes) { newValue in
                                updateMaxDownvotes(newValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Room Settings")
            .onAppear {
                // Load current room's max downvotes when view appears
                maxDownvotes = roomManager.maxDownvotes
            }
        }
    }
    
    private func updateMaxDownvotes(_ newValue: Int) {
        guard !roomManager.roomCode.isEmpty else {
            print("Room code is empty")
            return
        }
        
        isUpdatingDownvotes = true
        
        guard let url = URL(string: "\(userAuth.url)/change-max-downvotes") else {
            isUpdatingDownvotes = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "room": roomManager.roomCode,
            "max_downvotes": newValue,
            "jwt": userAuth.jwt ?? ""
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error encoding request body: \(error)")
            isUpdatingDownvotes = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUpdatingDownvotes = false
            }
            
            if let error = error {
                print("Network error: \(error)")
                // Reset to previous value on error
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                // Reset to previous value on error
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let status = json["status"] as? String {
                        print("Max downvotes update: \(status)")
                        if status == "Max downvotes changed" {
                            // Update the room manager's max downvotes value
                            DispatchQueue.main.async {
                                roomManager.maxDownvotes = newValue
                            }
                        } else {
                            // Reset to previous value on failure
                            DispatchQueue.main.async {
                                maxDownvotes = roomManager.maxDownvotes
                            }
                        }
                    }
                }
            } catch {
                print("Error parsing response: \(error)")
                // Reset to previous value on error
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
            }
        }.resume()
    }
}

/*
 // MARK: - Preview
 #Preview {
 SettingsView().environmentObject(UserAuth()).environmentObject(RoomManager())
 }
 */
