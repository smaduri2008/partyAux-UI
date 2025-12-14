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
    @FocusState private var isSearchFocused: Bool
    
    @EnvironmentObject var queueManager: QueueManager
    @EnvironmentObject var roomManager: RoomManager
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Title
            HStack {
                Text("Search")
                    .font(.headlineLarge)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)

            // Segment Control
            HStack(spacing: 0) {
                SegmentButton(title: "Songs", icon: "music.note", isSelected: selectedSegment == 0) {
                    withAnimation(.snappy) { selectedSegment = 0 }
                    clearSearchResults()
                }
                SegmentButton(title: "Playlists", icon: "music.note.list", isSelected: selectedSegment == 1) {
                    withAnimation(.snappy) { selectedSegment = 1 }
                    clearSearchResults()
                }
            }
            .padding(Spacing.xxs)
            .background(Color.appElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .padding(.horizontal, Spacing.lg)

            // Search bar
            VStack(spacing: 0) {
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textTertiary)
                            .font(.system(size: 16, weight: .medium))

                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text(selectedSegment == 0 ? "Search for songs..." : "Search playlists...")
                                    .foregroundColor(.textMuted)
                            }
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)
                            .autocapitalization(.none)
                            .focused($isSearchFocused)
                            .onChange(of: searchText) { newValue in
                                if selectedSegment == 0 {
                                    handleSearchTextChange(newValue)
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                hideSuggestions()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .strokeBorder(
                                isSearchFocused ? LinearGradient.brandGradient : LinearGradient(colors: [.textMuted.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                                lineWidth: isSearchFocused ? 2 : 1
                            )
                    )

                    Button(action: performSearch) {
                        ZStack {
                            Circle()
                                .fill(
                                    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? AnyShapeStyle(Color.appElevated)
                                        : AnyShapeStyle(LinearGradient.brandGradient)
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .textMuted : .white)
                        }
                        .shadow(color: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, Spacing.lg)

                // Suggestions dropdown
                if selectedSegment == 0 && showSuggestions && !suggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.textTertiary)
                                    .font(.system(size: 12))
                                
                                Text(suggestion)
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectSuggestion(suggestion)
                            }
                            
                            if suggestion != suggestions.last {
                                Divider()
                                    .background(Color.textMuted.opacity(0.2))
                            }
                        }
                    }
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .strokeBorder(Color.textMuted.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Loading indicator
            if isLoading || isLoadingPlaylists {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                    Text("Searching...")
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, Spacing.lg)
            }

            // Error
            if let errorMessage = errorMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.error)
                    Text(errorMessage)
                        .font(.labelMedium)
                        .foregroundColor(.error)
                }
                .padding(.horizontal, Spacing.lg)
            }

            // Results
            if selectedSegment == 0 {
                // Song Results
                if searchResults.isEmpty && !isLoading {
                    EmptySearchState(segment: 0)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(searchResults.indices, id: \.self) { index in
                                let item = searchResults[index]
                                SongRowView(item: item, index: index, animatedIndex: $animatedIndex) {
                                    addToLocalQueue(song: item)
                                } onLongPress: {
                                    selectedSongForPlaylist = item
                                    showingAddToPlaylist = true
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
            } else {
                // Playlist Results
                if playlistResults.isEmpty && !isLoadingPlaylists {
                    EmptySearchState(segment: 1)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(playlistResults) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist, playlistManager: playlistManager ?? PlaylistManager(userData: roomManager.userData))) {
                                    PlaylistRowView(playlist: playlist)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
            }
        }
        .padding(.top, Spacing.sm)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
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
        
        let urlString = "https://api.partyaux.party/search/suggestions/\(encodedQuery)"
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

        let urlString = "https://api.partyaux.party/search/\(encodedSearchTerm)"
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
        guard let urlRequest = URL(string: "https://api.partyaux.party/add-song-to-queue") else { return }
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

// MARK: - Segment Button
struct SegmentButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.labelLarge)
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected
                    ? LinearGradient.brandGradient
                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty Search State
struct EmptySearchState: View {
    let segment: Int
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: segment == 0 ? "music.note.list" : "rectangle.stack.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(LinearGradient.brandGradient)
            }
            
            VStack(spacing: Spacing.xs) {
                Text(segment == 0 ? "Search for songs" : "Search for playlists")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                Text(segment == 0 ? "Find your favorite tracks to add to the queue" : "Discover playlists from other users")
                    .font(.bodyMedium)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

struct SongRowView: View {
    let item: [String: Any]
    let index: Int
    @Binding var animatedIndex: Int?
    let onTap: () -> Void
    let onLongPress: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            // Thumbnail
            if let imageUrlString = item["album_art"] as? String,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.appElevated)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .textTertiary))
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Color.appElevated)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.textTertiary)
                    )
            }

            // Song info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item["title"] as? String ?? "No Title")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text(item["artist"] as? String ?? "No Artist")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)

                    if let durationStr = item["duration"] as? String {
                        Text("•")
                            .foregroundColor(.textMuted)
                        Text(formatDuration(durationStr))
                            .font(.bodySmall)
                            .foregroundColor(.textTertiary)
                    }
                }
            }

            Spacer()

            // Add button
            Button(action: {
                triggerHapticAndAnimation()
                onTap()
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brandGradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: .brandPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Spacing.sm)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(Color.textMuted.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            triggerHapticAndAnimation()
            onTap()
        }
        .onLongPressGesture {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            onLongPress()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.snappy) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.snappy) {
                        isPressed = false
                    }
                }
        )
    }
    
    private func triggerHapticAndAnimation() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.snappy) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                isPressed = false
            }
        }

        withAnimation(.snappy) {
            animatedIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.snappy) {
                animatedIndex = nil
            }
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
