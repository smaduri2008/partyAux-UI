import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResults: [[String: Any]] = []
    @State private var errorMessage: String? = nil
    @State private var queuedSongs: [[String: Any]] = []
    
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            TextField("Search YouTube...", text: $searchText)
                .padding(12)
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(8)
                .padding(.horizontal)

            Button("Search") {
                performSearch()
            }
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding()
            .background(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color(red: 0.4, green: 0.0, blue: 0.6))
            .foregroundColor(.white)
            .cornerRadius(10)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            List {
                ForEach(searchResults.indices, id: \.self) { index in
                    let item = searchResults[index]
                    HStack(alignment: .center, spacing: 12) {
                        if let imageUrlString = item["album_art"] as? String,
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

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item["title"] as? String ?? "No Title")
                                .font(.headline)

                            HStack(spacing: 8) {
                                Text(item["artist"] as? String ?? "No Artist")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if let durationStr = item["duration"] as? String {
                                    Text("• \(formatDuration(durationStr))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Spacer()

                        Button(action: {
                            addToLocalQueue(song: item)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            .opacity(searchResults.isEmpty && !isLoading ? 0 : 1)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
    }

    private func performSearch() {
        errorMessage = nil
        searchResults = []
        isLoading = true

        guard let encodedSearchTerm = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            errorMessage = "Invalid search text"
            isLoading = false
            return
        }

        let urlString = "http://35.208.64.59/search/\(encodedSearchTerm)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.searchResults = jsonArray
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unexpected data format"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func addToLocalQueue(song: [String: Any]) {
        if !queuedSongs.contains(where: { $0["url"] as? String == song["url"] as? String }) {
            addSongsToQueue(song: song)
            queueManager.queue[song["url"] as! String] = song as? AnyHashable
            //queuedSongs.append(song)
            print("✅ Added to local queue: \(song["title"] ?? "Untitled")")
        } else {
            print("⚠️ Song already in local queue")
        }
    }

    // Parses strings like "2 minutes, 51 seconds" into "2:51"
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
    
    func addSongsToQueue(song: [String: Any]) {
        guard let urlRequest = URL(string: "http://35.208.64.59/add-song-to-queue") else { return }
        var request = URLRequest(url: urlRequest)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "room": roomManager.roomCode,
            "jwt": roomManager.userData.jwt,
            "song": song
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("could not format data")
            return
        }
        
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("no data returned")
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("response: \(raw)")
            }

        }.resume()
    }

}

#Preview {
    NavigationView {
        SearchView()
    }
}
