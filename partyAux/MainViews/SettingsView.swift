import SwiftUI

struct SettingsView: View {
    @State private var playOnHostOnly = false
    @State private var autoplayEnabled = false
    @State private var maxDownvotes = 3
    @State private var isUpdatingDownvotes = false
    @State private var isUpdatingHostOnly = false
    @AppStorage("showYouTubeEmbed") private var showYouTubeEmbed = false
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var roomManager: RoomManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Premium background
                Color.deepNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Audio Settings Section
                        SettingsSectionView(title: "Audio Settings", icon: "speaker.wave.3.fill", iconColor: .electricCyan) {
                            VStack(spacing: 16) {
                                // Host Only Toggle
                                SettingsToggleRow(
                                    icon: "speaker.3.fill",
                                    iconColor: .orange,
                                    title: "Play on Host Device Only",
                                    subtitle: "When enabled, audio will only play on the host's device.",
                                    isOn: $playOnHostOnly,
                                    isDisabled: !roomManager.isCurrentUserHost || isUpdatingHostOnly,
                                    onChange: { updateHostPlayingOnly($0) }
                                )
                                
                                // Host-only info badge
                                if !roomManager.isCurrentUserHost {
                                    HostOnlyBadge()
                                }
                                
                                // Audio status indicator
                                if playOnHostOnly {
                                    AudioStatusIndicator(isHost: roomManager.isCurrentUserHost)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Autoplay Toggle
                                SettingsToggleRow(
                                    icon: "repeat.circle.fill",
                                    iconColor: .electricCyan,
                                    title: "Autoplay",
                                    subtitle: "Automatically add similar songs when the queue is empty.",
                                    isOn: $autoplayEnabled,
                                    isDisabled: !roomManager.isCurrentUserHost,
                                    onChange: { updateAutoplay($0) }
                                )
                                
                                if !roomManager.isCurrentUserHost {
                                    HostOnlyBadge()
                                }
                            }
                        }
                        
                        // Display Settings Section
                        SettingsSectionView(title: "Display Settings", icon: "display", iconColor: .softPurple) {
                            SettingsToggleRow(
                                icon: "play.rectangle.fill",
                                iconColor: .red,
                                title: "Show YouTube Player",
                                subtitle: "Display the YouTube video player on screen.",
                                isOn: $showYouTubeEmbed,
                                isDisabled: false,
                                onChange: { _ in }
                            )
                        }
                        
                        // Room Controls Section
                        SettingsSectionView(title: "Room Controls", icon: "slider.horizontal.3", iconColor: .coralPink) {
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    // Icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Maximum Downvotes")
                                            .font(Font.premium(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("Songs will be skipped at \(maxDownvotes) downvotes")
                                            .font(Font.premium(size: 12))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    if isUpdatingDownvotes {
                                        ProgressView()
                                            .tint(.electricCyan)
                                    } else {
                                        HStack(spacing: 12) {
                                            Button {
                                                if maxDownvotes > 1 {
                                                    maxDownvotes -= 1
                                                    updateMaxDownvotes(maxDownvotes)
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(maxDownvotes > 1 ? .electricCyan : .white.opacity(0.2))
                                            }
                                            .disabled(maxDownvotes <= 1 || !roomManager.isCurrentUserHost)
                                            
                                            Text("\(maxDownvotes)")
                                                .font(Font.premium(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 30)
                                            
                                            Button {
                                                if maxDownvotes < 100 {
                                                    maxDownvotes += 1
                                                    updateMaxDownvotes(maxDownvotes)
                                                }
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(maxDownvotes < 100 ? .electricCyan : .white.opacity(0.2))
                                            }
                                            .disabled(maxDownvotes >= 100 || !roomManager.isCurrentUserHost)
                                        }
                                    }
                                }
                                
                                if !roomManager.isCurrentUserHost {
                                    HostOnlyBadge()
                                }
                            }
                        }
                        
                        // Room Information Section
                        SettingsSectionView(title: "Room Information", icon: "info.circle.fill", iconColor: .electricCyan) {
                            VStack(spacing: 12) {
                                RoomInfoRow(label: "Host", value: roomManager.isCurrentUserHost ? "You" : "Other member", highlight: roomManager.isCurrentUserHost)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                RoomInfoRow(label: "Room Code", value: roomManager.roomCode, isMonospaced: true)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                RoomInfoRow(label: "Members", value: "\(roomManager.roomMembers.count)")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Room Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.deepNavy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/change-host-playing-only") else {
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
        
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/change-max-downvotes") else {
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

// MARK: - Settings Section View
struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(Font.premium(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .padding(.leading, 4)
            
            // Content card
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let isDisabled: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.premium(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(Font.premium(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.electricCyan)
                .disabled(isDisabled)
                .onChange(of: isOn) { newValue in
                    onChange(newValue)
                }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Host Only Badge
struct HostOnlyBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .foregroundColor(.electricCyan)
            
            Text("Only the host can change this setting")
                .font(Font.premium(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.electricCyan.opacity(0.1))
        )
    }
}

// MARK: - Audio Status Indicator
struct AudioStatusIndicator: View {
    let isHost: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isHost ? "checkmark.circle.fill" : "speaker.slash.fill")
                .font(.system(size: 14))
                .foregroundColor(isHost ? .green : .orange)
            
            Text(isHost ? "You can hear audio as the host" : "Audio is disabled for your device")
                .font(Font.premium(size: 12, weight: .medium))
                .foregroundColor(isHost ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHost ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHost ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Room Info Row
struct RoomInfoRow: View {
    let label: String
    let value: String
    var isMonospaced: Bool = false
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.premium(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            if isMonospaced {
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.electricCyan)
            } else {
                Text(value)
                    .font(Font.premium(size: 14, weight: .semibold))
                    .foregroundColor(highlight ? .electricCyan : .white)
            }
        }
    }
}
