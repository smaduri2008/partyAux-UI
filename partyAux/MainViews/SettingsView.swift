import SwiftUI

struct SettingsView: View {
    @State private var playOnHostOnly = false
    @State private var autoplayEnabled = false
    @State private var maxDownvotes = 3
    @State private var isUpdatingDownvotes = false
    @State private var isUpdatingHostOnly = false
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var roomManager: RoomManager

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Audio Settings")) {
                    VStack(spacing: 12) {
                        Toggle(isOn: $playOnHostOnly) {
                            HStack {
                                Image(systemName: "speaker.3.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Play on Host Device Only")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    Text("When enabled, audio will only play on the host's device. Other members will see the interface but won't hear audio.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .disabled(!roomManager.isCurrentUserHost || isUpdatingHostOnly)
                        .onChange(of: playOnHostOnly) { newValue in
                            updateHostPlayingOnly(newValue)
                        }
                        
                        if !roomManager.isCurrentUserHost {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Only the host can change this setting")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Current audio status indicator
                        if playOnHostOnly {
                            HStack {
                                Image(systemName: roomManager.isCurrentUserHost ? "checkmark.circle.fill" : "speaker.slash.fill")
                                    .foregroundColor(roomManager.isCurrentUserHost ? .green : .orange)
                                    .font(.caption)
                                
                                Text(roomManager.isCurrentUserHost ? "You can hear audio as the host" : "Audio is disabled for your device")
                                    .font(.caption)
                                    .foregroundColor(roomManager.isCurrentUserHost ? .green : .orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(roomManager.isCurrentUserHost ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Toggle(isOn: $autoplayEnabled) {
                            HStack {
                                Image(systemName: "repeat.circle.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Autoplay")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    Text("Automatically add similar songs when the queue is empty.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .disabled(!roomManager.isCurrentUserHost)
                        .onChange(of: autoplayEnabled) { newValue in
                            updateAutoplay(newValue)
                        }
                        
                        if !roomManager.isCurrentUserHost {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Only the host can change this setting")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Room Controls")) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Maximum Downvotes")
                            Text("Songs will be skipped when they reach \(maxDownvotes) downvotes")
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
                            .disabled(!roomManager.isCurrentUserHost)
                            .onChange(of: maxDownvotes) { newValue in
                                updateMaxDownvotes(newValue)
                            }
                        }
                    }
                    
                    if !roomManager.isCurrentUserHost {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Only the host can change this setting")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Room Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Host:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(roomManager.isCurrentUserHost ? "You" : "Other member")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Room Code:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(roomManager.roomCode)
                                .foregroundColor(.secondary)
                                .fontDesign(.monospaced)
                        }
                        
                        HStack {
                            Text("Members:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(roomManager.roomMembers.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Room Settings")
            .onAppear {
                // Load current room's settings when view appears
                maxDownvotes = roomManager.maxDownvotes
                playOnHostOnly = roomManager.hostPlayingOnly
                autoplayEnabled = roomManager.autoplayEnabled
                print("🔧 Settings loaded: maxDownvotes=\(maxDownvotes), hostPlayingOnly=\(playOnHostOnly), autoplay=\(autoplayEnabled)")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HostPlayingOnlyChanged"))) { notification in
                if let hostPlayingOnly = notification.userInfo?["hostPlayingOnly"] as? Bool {
                    print("🔧 Settings received hostPlayingOnly notification: \(hostPlayingOnly)")
                    playOnHostOnly = hostPlayingOnly
                }
            }
        }
    }
    
    private func updateHostPlayingOnly(_ newValue: Bool) {
        guard !roomManager.roomCode.isEmpty else {
            print("❌ Room code is empty")
            return
        }
        
        guard roomManager.isCurrentUserHost else {
            print("❌ Only host can change this setting")
            // Revert the toggle
            playOnHostOnly = roomManager.hostPlayingOnly
            return
        }
        
        print("🔧 Updating host playing only to: \(newValue)")
        isUpdatingHostOnly = true
        
        // Update local state immediately for responsive UI
        let previousValue = roomManager.hostPlayingOnly
        roomManager.hostPlayingOnly = newValue
        
        guard let url = URL(string: "\(userAuth.url)/change-host-playing-only") else {
            print("❌ Invalid URL for host playing only update")
            roomManager.hostPlayingOnly = previousValue
            isUpdatingHostOnly = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "room_code": roomManager.roomCode,
            "host_playing_only": newValue,
            "jwt": userAuth.jwt ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Error encoding request body: \(error)")
            roomManager.hostPlayingOnly = previousValue
            isUpdatingHostOnly = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUpdatingHostOnly = false
            }
            
            // Log the HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Host playing only HTTP response status: \(httpResponse.statusCode)")
                print("🌐 Response headers: \(httpResponse.allHeaderFields)")
            }
            
            if let error = error {
                print("❌ Network error updating host playing only: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                // Revert UI if there was an error
                DispatchQueue.main.async {
                    roomManager.hostPlayingOnly = previousValue
                    playOnHostOnly = previousValue
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received from host playing only update")
                // Revert UI if there was an error
                DispatchQueue.main.async {
                    roomManager.hostPlayingOnly = previousValue
                    playOnHostOnly = previousValue
                }
                return
            }
            
            // Log the raw response data
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("📄 Raw response from host playing only update:")
                print("📄 \(rawResponse)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Parsed JSON response from host playing only update:")
                    print("✅ \(json)")
                    
                    if let status = json["status"] as? String {
                        print("📊 Host playing only update status: '\(status)'")
                        if status.contains("successfully") {
                            print("✅ Host playing only setting updated successfully")
                            // The socket event will handle updating other clients
                            // and our own UI will be updated via the notification system
                        } else {
                            print("❌ Server rejected host playing only change: \(status)")
                            // Revert UI if the server didn't accept the change
                            DispatchQueue.main.async {
                                roomManager.hostPlayingOnly = previousValue
                                playOnHostOnly = previousValue
                            }
                        }
                    } else {
                        print("⚠️ No 'status' field found in response")
                        DispatchQueue.main.async {
                            roomManager.hostPlayingOnly = previousValue
                            playOnHostOnly = previousValue
                        }
                    }
                } else {
                    print("❌ Response is not valid JSON")
                    DispatchQueue.main.async {
                        roomManager.hostPlayingOnly = previousValue
                        playOnHostOnly = previousValue
                    }
                }
            } catch {
                print("❌ Error parsing JSON response: \(error)")
                print("❌ JSON parsing error details: \(error.localizedDescription)")
                // Revert UI if there was an error
                DispatchQueue.main.async {
                    roomManager.hostPlayingOnly = previousValue
                    playOnHostOnly = previousValue
                }
            }
        }.resume()
    }
    
    private func updateMaxDownvotes(_ newValue: Int) {
        guard !roomManager.roomCode.isEmpty else {
            print("❌ Room code is empty")
            return
        }
        
        guard roomManager.isCurrentUserHost else {
            print("❌ Only host can change max downvotes")
            maxDownvotes = roomManager.maxDownvotes
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
            print("❌ Error encoding request body: \(error)")
            isUpdatingDownvotes = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUpdatingDownvotes = false
            }
            
            if let error = error {
                print("❌ Network error: \(error)")
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let status = json["status"] as? String {
                        print("✅ Max downvotes update: \(status)")
                        if status == "Max downvotes changed" {
                            DispatchQueue.main.async {
                                roomManager.maxDownvotes = newValue
                            }
                        } else {
                            DispatchQueue.main.async {
                                maxDownvotes = roomManager.maxDownvotes
                            }
                        }
                    }
                }
            } catch {
                print("❌ Error parsing response: \(error)")
                DispatchQueue.main.async {
                    maxDownvotes = roomManager.maxDownvotes
                }
            }
        }.resume()
    }
    
    private func updateAutoplay(_ newValue: Bool) {
        guard !roomManager.roomCode.isEmpty else {
            print("❌ Room code is empty")
            return
        }
        
        guard roomManager.isCurrentUserHost else {
            print("❌ Only host can change autoplay setting")
            // Revert the toggle
            autoplayEnabled = roomManager.autoplayEnabled
            return
        }
        
        print("🔧 Updating autoplay to: \(newValue)")
        
        // Update room manager state immediately for responsive UI
        roomManager.autoplayEnabled = newValue
    }
}
