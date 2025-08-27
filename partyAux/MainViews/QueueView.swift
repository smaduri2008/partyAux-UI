import SwiftUI

struct QueueView: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    //@EnvironmentObject var userAuth: userAuth

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Current Queue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()

                /*
                // Refresh button
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    queueManager.fetchQueue {
                        print("Queue refreshed")
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                }
                */
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            if queueManager.queue.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No songs in queue")
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text("Add some songs to get started!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else {
                QueueViewWithLikeDislike()
                    .environmentObject(queueManager)
                    .environmentObject(roomManager)
            }
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
        .onAppear {
            // Fetch queue when view appears
            queueManager.fetchQueue {
                print("Queue loaded: \(queueManager.queue)")
                print("Queue count: \(queueManager.queue.count)")
            }
        }
    }
}

struct QueueViewWithLikeDislike: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var songDislikes: [String: Bool] = [:]
    @State private var songDislikesNum: [String: Int] = [:]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(queueManager.queue.enumerated()), id: \.element.key) { index, queueItem in
                    if let songDict = queueItem.value as? [String: Any] {
                        let songID = songDict["uuid"] as? String ?? ""
                        QueueSongRowWithLikeDislike(
                            song: songDict,
                            index: index,
                            isDisliked: songDislikes[songID] ?? false,
                            downvotes: songDislikesNum[songID] ?? 0,   // <-- Pass downvotes here
                            onDislike: {
                                songDislikes[songID] = !(songDislikes[songID] ?? false)
                                // ...
                                guard let urlRequest = URL(string: "https://35.208.64.59/add-downvote") else {return}
                                var request = URLRequest(url: urlRequest)
                                request.httpMethod = "POST"
                                request.addValue("application/json", forHTTPHeaderField: "ContentType")
                                request.httpBody = try? JSONSerialization.data(withJSONObject: ["jwt" : roomManager.userData.jwt, "room": roomManager.roomCode, "song_uuid": songDict["uuid"]])
                                
                                URLSession.shared.dataTask(with: request) { data, response, _ in
                                    guard let data = data,
                                          let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                          let status = jsonData["status"] as? String else { return }
                                    DispatchQueue.main.async {
                                        print(status)
                                        if status == "Downvote Added" {
                                            // Save the downvotes number for this song
                                            songDislikesNum[songID] = jsonData["downvotes"] as? Int ?? 0
                                        }
                                    }
                                }.resume()
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Queue Song Row With Like/Dislike
struct QueueSongRowWithLikeDislike: View {
    let song: [String: Any]
    let index: Int
    //let isLiked: Bool
    let isDisliked: Bool
    //let onLike: () -> Void
    let downvotes: Int    // <-- Add this line
    let onDislike: () -> Void
    
    @State private var hasDisliked = false   // 👈 local state

    
    var body: some View {
        HStack(spacing: 12) {
            // Song Index
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.textTertiary)
                .frame(width: 20)
            
            // Album Art Thumbnail
            if let albumArtURL = song["album_art"] as? String, let url = URL(string: albumArtURL) {
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
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song["title"] as? String ?? "Unknown Title")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(song["artist"] as? String ?? "Unknown Artist")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                
                // Added by text
                Text("Added by \(song["added_by"] as? String ?? "Unknown User")")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Like/Dislike Buttons
            HStack(spacing: 8) {
                // Dislike Button
                Button(action:{
                    onDislike()
                    hasDisliked = true
                }) {
                    Image(systemName: hasDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisliked ? .red : .textTertiary)
                        .scaleEffect(isDisliked ? 1.1 : 1.0)
                        .animation(.bouncy, value: isDisliked)
                    
                }
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .cornerRadius(18)
                .disabled(hasDisliked)
                
                Text("\(downvotes)")
                    .font(.caption)
                    .foregroundColor(.red)
                
                // Like Button
                /*
                Button(action: onLike) {
                    Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isLiked ? .green : .textTertiary)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                        .animation(.bouncy, value: isLiked)
                }
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .cornerRadius(18)
                 */
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appCardBackground.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appSurface, lineWidth: 1)
        )
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
