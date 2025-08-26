import SwiftUI

struct QueueView: View {
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Current Queue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                
                /*
                // Add refresh button like in SearchView
                Button(action: {
                    queueManager.fetchQueue {
                        print("Queue refreshed")
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                 */
            }
            .padding()

            // Debug info - remove this once it's working
            Text("Queue count: \(queueManager.queue.count)")
                .font(.caption)
                .foregroundColor(.gray)

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
                List {
                    // Use the ordered array instead of dictionary enumeration
                    ForEach(Array(queueManager.queueOrder.enumerated()), id: \.offset) { index, key in
                        if let item = queueManager.queue[key] {
                            // Try to convert to [String: Any] first (from SearchView additions)
                            if let songDict = item as? [String: Any] {
                                QueueRowView(songDict: songDict, index: index)
                            }
                            // Then try [String: AnyHashable] (from server fetch)
                            else if let songHashable = item as? [String: AnyHashable] {
                                // Convert AnyHashable values to Any for consistent handling
                                let songDict = songHashable.mapValues { $0 as Any }
                                QueueRowView(songDict: songDict, index: index)
                            }
                            // Debug row if casting fails
                            else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Debug: Failed to cast item \(index)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text("Type: \(type(of: item))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text("Key: \(key)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding()
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear {
            // Fetch queue when view appears
            queueManager.fetchQueue {
                print("Queue loaded: \(queueManager.queue)")
                print("Queue count: \(queueManager.queue.count)")
            }
        }
    }
}

struct QueueRowView: View {
    let songDict: [String: Any]
    let index: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Album art - exactly like SearchView
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

            // Song info - exactly like SearchView
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

            // Instead of add button, show queue position
            VStack {
                Text("#\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Same duration formatting as SearchView
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
