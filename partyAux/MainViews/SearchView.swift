import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResults: [[String: Any]] = []
    @State private var errorMessage: String? = nil
    @State private var queuedSongs: [[String: Any]] = []
    @State private var animatedIndex: Int? = nil
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    @State private var isLoadingSuggestions = false
    @State private var searchWorkItem: DispatchWorkItem?
    @State private var selectedSegment = 0 // 0: Songs, 1: Playlists
    @State private var playlistResults: [Playlist] = []
    @State private var isLoadingPlaylists = false
    @State private var showingAddToPlaylist = false
    @State private var selectedSongForPlaylist: [String: Any]?
    @State private var playlistManager: PlaylistManager?
    
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
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            // Segment Control
            Picker("Search Type", selection: $selectedSegment) {
                Text("Songs").tag(0)
                Text("Playlists").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedSegment) { _ in
                clearSearchResults()
            }

            // Search bar + button inline
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField(selectedSegment == 0 ? "Search YouTube..." : "Search playlists...", text: $searchText)
                            .foregroundColor(.white) // Changed to white
                            .placeholder(when: searchText.isEmpty) {
                                Text(selectedSegment == 0 ? "Search YouTube..." : "Search playlists...")
                                    .foregroundColor(.gray) // Changed to gray
                            }
                            .autocapitalization(.none)
                            .onChange(of: searchText) { newValue in
                                if selectedSegment == 0 {
                                    handleSearchTextChange(newValue)
                                }
                            }
                    }
                    .padding(10)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // Dark background
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 4) // Adjusted shadow
                    .onTapGesture {
                        if !searchText.isEmpty {
                            if selectedSegment == 0 {
                                handleSearchTextChange(searchText)
                            }
                        }
                    }

                    Button(action: performSearch) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color.purple)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)

                // Suggestions dropdown (only for songs)
                if selectedSegment == 0 && showSuggestions && !suggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                                
                                Text(suggestion)
                                    .foregroundColor(.white) // Changed to white
                                    .font(.system(size: 16))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // Dark background
                            .onTapGesture {
                                selectSuggestion(suggestion)
                            }
                            
                            if suggestion != suggestions.last {
                                Divider()
                                    .background(Color.gray.opacity(0.2)) // Adjusted divider
                            }
                        }
                    }
                    .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // Dark background
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 4) // Adjusted shadow
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }

            // Loading indicator
            if isLoading || isLoadingPlaylists {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }

            // Error
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Results
            if selectedSegment == 0 {
                // Song Results
                List {
                    ForEach(searchResults.indices, id: \.self) { index in
                        let item = searchResults[index]
                        SongRowView(item: item, index: index, animatedIndex: $animatedIndex) {
                            addToLocalQueue(song: item)
                        } onLongPress: {
                            selectedSongForPlaylist = item
                            showingAddToPlaylist = true
                        }
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(PlainListStyle())
                .opacity(searchResults.isEmpty && !isLoading ? 0 : 1)
            } else {
                // Playlist Results
                List {
                    ForEach(playlistResults) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager ?? PlaylistManager(userData: roomManager.userData))) {
                            PlaylistRowView(playlist: playlist)
                        }
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(PlainListStyle())
                .opacity(playlistResults.isEmpty && !isLoadingPlaylists ? 0 : 1)
            }
        }
        .padding(.top)
        .background(Color.black.ignoresSafeArea())
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

    private func clearSearchResults() {
        searchResults = []
        playlistResults = []
        errorMessage = nil
        hideSuggestions()
    }

    private func handleSearchTextChange(_ newValue: String) {
        // Cancel previous work item
        searchWorkItem?.cancel()
        
        // Hide suggestions if search text is empty
        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hideSuggestions()
            return
        }
        
        // Create new work item with delay (only for songs)
        if selectedSegment == 0 {
            let workItem = DispatchWorkItem {
                fetchSuggestions(for: newValue)
            }
            
            searchWorkItem = workItem
            
            // Execute after 0.3 seconds delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }
    
    private func fetchSuggestions(for query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoadingSuggestions = true
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            isLoadingSuggestions = false
            return
        }
        
        let urlString = "http://35.208.64.59/search/suggestions/\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            isLoadingSuggestions = false
            return
        }
        
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingSuggestions = false
            }
            
            if let error = error {
                print("Suggestions error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let suggestionsData = json["suggestions"] as? [[String: Any]] {
                    
                    let extractedSuggestions = suggestionsData.compactMap { suggestionDict -> String? in
                        if let completeQuery = suggestionDict["complete_query"] as? [String: Any],
                           let query = completeQuery["query"] as? String {
                            return query
                        }
                        return nil
                    }
                    
                    DispatchQueue.main.async {
                        self.suggestions = Array(extractedSuggestions.prefix(5))
                        self.showSuggestions = !self.suggestions.isEmpty
                    }
                }
            } catch {
                print("Failed to parse suggestions: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
        hideSuggestions()
        performSearch()
    }
    
    private func hideSuggestions() {
        showSuggestions = false
        suggestions = []
        searchWorkItem?.cancel()
    }

    private func performSearch() {
        hideSuggestions()
        errorMessage = nil
        clearSearchResults()
        
        if selectedSegment == 0 {
            performSongSearch()
        } else {
            performPlaylistSearch()
        }
    }
    
    private func performSongSearch() {
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
    
    private func performPlaylistSearch() {
        guard let manager = playlistManager else { return }
        
        isLoadingPlaylists = true
        manager.searchPlaylists(query: searchText)
        
        // Monitor the playlist manager for results
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkPlaylistSearchResults()
        }
    }
    
    private func checkPlaylistSearchResults() {
        guard let manager = playlistManager else { 
            isLoadingPlaylists = false
            return 
        }
        
        if !manager.isLoading {
            isLoadingPlaylists = false
            playlistResults = manager.searchedPlaylists
            if let error = manager.errorMessage {
                errorMessage = error
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkPlaylistSearchResults()
            }
        }
    }

    private func addToLocalQueue(song: [String: Any]) {
        if !queuedSongs.contains(where: { $0["url"] as? String == song["url"] as? String }) {
            addSongsToQueue(song: song)
        }
    }

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
        
        guard let data = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { _, _, _ in
            queueManager.fetchQueue { }
        }.resume()
    }
}

struct SongRowView: View {
    let item: [String: Any]
    let index: Int
    @Binding var animatedIndex: Int?
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Thumbnail
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

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(item["title"] as? String ?? "No Title")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(item["artist"] as? String ?? "No Artist")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if let durationStr = item["duration"] as? String {
                        Text("• \(formatDuration(durationStr))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            HStack {
                Button(action: {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    // Animation trigger
                    withAnimation(.easeInOut(duration: 0.2)) {
                        animatedIndex = index
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            animatedIndex = nil
                        }
                    }

                    onTap()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.purple)
                }
            }
        }
        .padding(.vertical, 4)
        .scaleEffect(animatedIndex == index ? 0.9 : 1.0)
        .contentShape(Rectangle())
        .onLongPressGesture {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            onLongPress()
        }
    }
    
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

// Custom placeholder modifier so we can set color
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
