import SwiftUI

struct QueueView: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Current Queue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()

                // Refresh button
                Button(action: {
                    guard !isRefreshing else { return }
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    isRefreshing = true
                    queueManager.fetchQueue {
                        isRefreshing = false
                        print("Queue refreshed")
                    }
                }) {
                    Group {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                .disabled(isRefreshing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Content based on queue state
            if queueManager.queue.isEmpty && !isRefreshing {
                EmptyQueueView()
            } else if queueManager.queueOrder.isEmpty && !queueManager.queue.isEmpty {
                // Handle case where queue has data but order is missing
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Queue data error")
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text("Please refresh to reload the queue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                QueueViewWithLikeDislike()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
            }
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
        .onAppear {
            // Only fetch queue if it's empty
            if queueManager.queue.isEmpty {
                queueManager.fetchQueue {
                    print("Queue loaded: \(queueManager.queue.count) songs")
                }
            }
        }
    }
}

// MARK: - Empty Queue View
struct EmptyQueueView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 12) {
                Text("No songs in queue")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                Text("Add some songs to get the party started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Add songs suggestion
            Button(action: {
                // This could navigate to search or suggest adding songs
                print("Navigate to search")
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Songs")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct QueueViewWithLikeDislike: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var userDownvotedSongs: Set<String> = []
    @State private var showingAddToPlaylist = false
    @State private var selectedSongForPlaylist: [String: Any]?
    @State private var playlistManager: PlaylistManager?
    
    var body: some View {
        VStack(spacing: 0) {
            // Downvote threshold indicator
            DownvoteThresholdIndicator(maxDownvotes: roomManager.maxDownvotes)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Use indices for better performance and avoid duplicate ID issues
                    ForEach(0..<queueManager.queueOrder.count, id: \.self) { index in
                        // Safety check to prevent index out of bounds
                        if index < queueManager.queueOrder.count {
                            let songID = queueManager.queueOrder[index]
                            if let songDict = queueManager.queue[songID] {
                                let downvotesArray = songDict["downvotes"] as? [String] ?? []
                                let hasUserDownvoted = downvotesArray.contains(roomManager.userData.email)
                                
                                // Use downvotes array count if available, otherwise use downvote_count from socket
                                let downvoteCount = !downvotesArray.isEmpty ? downvotesArray.count : (songDict["downvote_count"] as? Int ?? 0)
                                
                                QueueSongRowWithLikeDislike(
                                    song: songDict,
                                    index: index,
                                    isDisliked: hasUserDownvoted,
                                    downvotes: downvoteCount,
                                    maxDownvotes: roomManager.maxDownvotes,
                                    onDislike: {
                                        guard !hasUserDownvoted else {
                                            print("⚠️ User has already downvoted this song")
                                            return
                                        }
                                        
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        
                                        roomManager.downvoteSong(songUuid: songID) { success, message in
                                            DispatchQueue.main.async {
                                                if success {
                                                    print("✅ \(message)")
                                                    
                                                    // Immediately update the local queue data for instant feedback
                                                    if var songData = queueManager.queue[songID] {
                                                        let currentCount = songData["downvote_count"] as? Int ?? downvoteCount
                                                        songData["downvote_count"] = currentCount + 1
                                                        
                                                        // Also add user to downvotes array if it exists, or create it if it doesn't
                                                        if var downvotesArray = songData["downvotes"] as? [String] {
                                                            if !downvotesArray.contains(roomManager.userData.email) {
                                                                downvotesArray.append(roomManager.userData.email)
                                                                songData["downvotes"] = downvotesArray
                                                                print("✅ Updated queue song downvotes array: \(downvotesArray)")
                                                            }
                                                        } else {
                                                            // Create downvotes array if it doesn't exist
                                                            songData["downvotes"] = [roomManager.userData.email]
                                                            print("✅ Created new queue song downvotes array: [\(roomManager.userData.email)]")
                                                        }
                                                        
                                                        queueManager.queue[songID] = songData
                                                        queueManager.objectWillChange.send()
                                                    }
                                                } else {
                                                    print("❌ Downvote failed: \(message)")
                                                }
                                            }
                                        }
                                    },
                                    onLongPress: {
                                        selectedSongForPlaylist = songDict
                                        showingAddToPlaylist = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable {
                // Pull to refresh functionality
                queueManager.fetchQueue {
                    print("Queue refreshed via pull-to-refresh")
                }
            }
        }
        .onAppear {
            // Initialize playlist manager with current user data
            if playlistManager == nil, let userData = roomManager.userData as? UserAuth {
                playlistManager = PlaylistManager(userData: userData)
            }
        }
        .sheet(isPresented: $showingAddToPlaylist) {
            if let song = selectedSongForPlaylist, let manager = playlistManager {
                AddToPlaylistView(song: song, playlistManager: manager)
            }
        }
    }
}

// MARK: - Queue Song Row With Like/Dislike
struct QueueSongRowWithLikeDislike: View {
    let song: [String: Any]
    let index: Int
    let isDisliked: Bool
    let downvotes: Int
    let maxDownvotes: Int
    let onDislike: () -> Void
    let onLongPress: (() -> Void)?
    
    // Cache song properties for better performance
    private var songTitle: String {
        song["title"] as? String ?? "Unknown Title"
    }
    
    private var songArtist: String {
        song["artist"] as? String ?? "Unknown Artist"
    }
    
    private var addedBy: String {
        song["added_by"] as? String ?? "Unknown User"
    }
    
    private var albumArtURL: URL? {
        if let albumArtString = song["album_art"] as? String {
            return URL(string: albumArtString)
        }
        return nil
    }
    
    private var isMarkedForRemoval: Bool {
        downvotes >= maxDownvotes
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Song Index
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.textTertiary)
                .frame(width: 20)
            
            // Album Art Thumbnail
            Group {
                if let url = albumArtURL {
                    JFIFImageView(imageUrl: url)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCardBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 16))
                                .foregroundColor(.textTertiary)
                        )
                }
            }
            .overlay(
                // Add removal warning overlay
                isMarkedForRemoval ?
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    ) : nil
            )
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(songTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(isMarkedForRemoval ? .textSecondary : .textPrimary)
                    .lineLimit(1)
                
                Text(songArtist)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                
                // Added by text
                Text("Added by \(addedBy)")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Downvote section
            VStack(spacing: 4) {
                // Dislike Button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onDislike()
                }) {
                    Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisliked ? .red : .textTertiary)
                        .scaleEffect(isDisliked ? 1.1 : 1.0)
                        .animation(.bouncy(duration: 0.3), value: isDisliked)
                }
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .cornerRadius(18)
                .disabled(isDisliked)
                .opacity(isDisliked ? 0.6 : 1.0)
                
                // Downvote progress indicator
                DownvoteProgressView(current: downvotes, max: maxDownvotes)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground.opacity(isMarkedForRemoval ? 0.4 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isMarkedForRemoval ? Color.red : Color.appSurface, lineWidth: isMarkedForRemoval ? 2 : 1)
        )
        .opacity(isMarkedForRemoval ? 0.6 : 1.0)
        .scaleEffect(isMarkedForRemoval ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isMarkedForRemoval)
        .contentShape(Rectangle())
        .onLongPressGesture {
            if let onLongPress = onLongPress {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                onLongPress()
            }
        }
    }
}

// MARK: - Legacy Queue Row (keeping as backup)
struct QueueRowView: View {
    @EnvironmentObject var roomManager: RoomManager
    let songDict: [String: Any]
    let index: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Album art
            if let imageUrlString = songDict["album_art"] as? String,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(songDict["title"] as? String ?? "No Title")
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(songDict["artist"] as? String ?? "No Artist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let durationStr = songDict["duration"] as? String {
                        Text("• \(formatDuration(durationStr))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Queue position + downvotes
            VStack(spacing: 6) {
                Text("#\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)

                // Downvote button
                Button(action: {
                    if roomManager.downvotes > 0 {
                        roomManager.downvotes -= 1
                        print("Downvoted. Remaining: \(roomManager.downvotes)")
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsdown")
                        Text("\(roomManager.downvotes)")
                            .font(.caption)
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(6)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
    
    // Duration formatting
    private func formatDuration(_ durationString: String) -> String {
        var minutes = 0
        var seconds = 0
        let lowercased = durationString.lowercased()

        if let minMatch = lowercased.range(of: #"(\d+)\s*minute"#, options: .regularExpression) {
            let minStr = String(lowercased[minMatch])
            let digits = minStr.filter("0123456789".contains)
            minutes = Int(digits) ?? 0
        }

        if let secMatch = lowercased.range(of: #"(\d+)\s*second"#, options: .regularExpression) {
            let secStr = String(lowercased[secMatch])
            let digits = secStr.filter("0123456789".contains)
            seconds = Int(digits) ?? 0
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Downvote Progress View
struct DownvoteProgressView: View {
    let current: Int
    let max: Int
    
    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(Double(current) / Double(max), 1.0)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .gray
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var isDangerous: Bool {
        progress >= 0.8
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Progress circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Danger indicator when close to max
                if isDangerous {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(progressColor)
                        .scaleEffect(isDangerous ? 1.0 : 0.8)
                        .animation(.bouncy(duration: 0.4), value: isDangerous)
                }
            }
            
            // Count text
            Text("\(current)/\(max)")
                .font(.caption2)
                .foregroundColor(progressColor)
                .fontWeight(.medium)
                .animation(.easeInOut(duration: 0.2), value: progressColor)
        }
    }
}

// MARK: - Downvote Threshold Indicator
struct DownvoteThresholdIndicator: View {
    let maxDownvotes: Int
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.thumbsdown.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Downvote Threshold")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("Songs are removed after \(maxDownvotes) downvotes")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Threshold visualization
            HStack(spacing: 4) {
                ForEach(0..<maxDownvotes, id: \.self) { index in
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}
