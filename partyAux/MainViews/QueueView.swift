import SwiftUI

struct QueueView: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var isRefreshing = false
    @State private var showSearchView = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Queue")
                        .font(.headlineLarge)
                        .foregroundColor(.textPrimary)
                    Text("\(queueManager.queue.count) songs")
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)

            // Content based on queue state
            if queueManager.queue.isEmpty && !isRefreshing {
                EmptyQueueView(showSearchView: $showSearchView)
            } else if queueManager.queueOrder.isEmpty && !queueManager.queue.isEmpty {
                ErrorStateView()
            } else {
                QueueViewWithLikeDislike()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            if queueManager.queue.isEmpty {
                queueManager.fetchQueue {
                    print("Queue loaded: \(queueManager.queue.count) songs")
                }
            }
        }
        .sheet(isPresented: $showSearchView) {
            NavigationView {
                SearchView()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
                    .navigationBarHidden(true)
            }
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.warning.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.warning)
            }
            
            VStack(spacing: Spacing.xs) {
                Text("Queue data error")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                Text("Pull down to refresh the queue")
                    .font(.bodyMedium)
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Empty Queue View
struct EmptyQueueView: View {
    @Binding var showSearchView: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(LinearGradient.brandGradient.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: "music.note.list")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(LinearGradient.brandGradient)
            }

            VStack(spacing: Spacing.sm) {
                Text("No songs in queue")
                    .font(.headlineSmall)
                    .foregroundColor(.textPrimary)

                Text("Add some songs to get the party started!")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showSearchView = true
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Add Songs")
                        .font(.titleSmall)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(LinearGradient.brandGradient)
                .clipShape(Capsule())
                .shadow(color: .brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
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
        HStack(spacing: Spacing.sm) {
            // Song Index
            Text("\(index + 1)")
                .font(.labelMedium)
                .foregroundColor(.textTertiary)
                .frame(width: 24)
            
            // Album Art Thumbnail
            Group {
                if let url = albumArtURL {
                    JFIFImageView(imageUrl: url)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(Color.appElevated)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.textTertiary)
                        )
                }
            }
            .overlay(
                isMarkedForRemoval ?
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Color.error.opacity(0.4))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    ) : nil
            )
            
            // Song Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(songTitle)
                    .font(.titleSmall)
                    .foregroundColor(isMarkedForRemoval ? .textSecondary : .textPrimary)
                    .lineLimit(1)
                
                Text(songArtist)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 10))
                    Text(addedBy)
                        .font(.labelSmall)
                }
                .foregroundColor(.textTertiary)
            }
            
            Spacer()
            
            // Downvote section
            VStack(spacing: Spacing.xxs) {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onDislike()
                }) {
                    ZStack {
                        Circle()
                            .fill(isDisliked ? Color.error.opacity(0.2) : Color.appElevated)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(isDisliked ? Color.error.opacity(0.5) : Color.textMuted.opacity(0.2), lineWidth: 1)
                            )
                        
                        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isDisliked ? .error : .textSecondary)
                    }
                }
                .disabled(isDisliked)
                .scaleEffect(isDisliked ? 1.05 : 1.0)
                .animation(.bouncy, value: isDisliked)
                
                DownvoteProgressView(current: downvotes, max: maxDownvotes)
            }
        }
        .padding(Spacing.sm)
        .background(Color.appCardBackground.opacity(isMarkedForRemoval ? 0.5 : 1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(
                    isMarkedForRemoval ? Color.error.opacity(0.5) : Color.textMuted.opacity(0.1),
                    lineWidth: isMarkedForRemoval ? 2 : 1
                )
        )
        .opacity(isMarkedForRemoval ? 0.7 : 1.0)
        .scaleEffect(isMarkedForRemoval ? 0.98 : 1.0)
        .animation(.smooth, value: isMarkedForRemoval)
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
            return .brandPrimary
        case 0.5..<0.8:
            return .warning
        default:
            return .error
        }
    }
    
    private var isDangerous: Bool {
        progress >= 0.8
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.appElevated, lineWidth: 2.5)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: progress)
                
                if isDangerous {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(progressColor)
                }
            }
            
            Text("\(current)/\(max)")
                .font(.labelSmall)
                .foregroundColor(progressColor)
                .monospacedDigit()
        }
    }
}

// MARK: - Downvote Threshold Indicator
struct DownvoteThresholdIndicator: View {
    let maxDownvotes: Int
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.error.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "hand.thumbsdown.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.error)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Skip Threshold")
                    .font(.labelLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Songs skip after \(maxDownvotes) votes")
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 3) {
                ForEach(0..<maxDownvotes, id: \.self) { _ in
                    Circle()
                        .fill(Color.error.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.error, lineWidth: 1)
                        )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(Color.error.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
