import SwiftUI

struct PlaylistAddSongView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var playlistManager: PlaylistManager
    let playlist: Playlist

    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResults: [[String: Any]] = []
    @State private var errorMessage: String? = nil
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    @State private var isLoadingSuggestions = false
    @State private var searchWorkItem: DispatchWorkItem?
    @State private var animatedIndex: Int? = nil
    @State private var addingSongId: String? = nil
    @State private var showResultAlert = false
    @State private var resultAlertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Premium Search bar
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.electricCyan)
                            TextField("Search YouTube...", text: $searchText)
                                .foregroundColor(.white)
                                .font(Font.premium(size: 16))
                                .placeholder(when: searchText.isEmpty) {
                                    Text("Search YouTube...").foregroundColor(.white.opacity(0.4))
                                }
                                .autocapitalization(.none)
                                .onChange(of: searchText, perform: handleSearchTextChange)
                        }
                        .padding(14)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Suggestions dropdown with premium styling
                    if showSuggestions && !suggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.electricCyan.opacity(0.7))
                                        .font(.system(size: 14))

                                        Text(suggestion)
                                        .foregroundColor(.white)
                                        .font(Font.premium(size: 15))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.appCardBackground)
                                .onTapGesture {
                                    selectSuggestion(suggestion)
                                }
                                if suggestion != suggestions.last {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }

                // Loading indicator with premium styling
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .electricCyan))
                        .scaleEffect(1.2)
                        .padding(.top, 20)
                }

                // Error with premium styling
                if let errorMessage = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.coralPink)
                        Text(errorMessage)
                            .foregroundColor(.coralPink)
                            .font(Font.premium(size: 14))
                    }
                    .padding(.horizontal, 20)
                }

                // Song Results with premium styling
                List {
                    ForEach(searchResults.indices, id: \.self) { index in
                        let item = searchResults[index]
                        SongRowForPlaylistView(
                            item: item,
                            index: index,
                            animatedIndex: $animatedIndex,
                            addingSongId: $addingSongId,
                            onAddSong: {
                                // Ensure video_id is set for API
                                var songToSend = item
                                if let url = item["url"] as? String {
                                    songToSend["video_id"] = url
                                }
                                addSongToPlaylist(song: songToSend, index: index)
                            }
                        )
                        .listRowBackground(Color.deepNavy)
                        .listRowSeparatorTint(Color.white.opacity(0.1))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .opacity(searchResults.isEmpty && !isLoading ? 0 : 1)
            }
            .padding(.top)
            .background(Color.deepNavy.ignoresSafeArea())
            .navigationBarTitle("Add Songs", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(Font.premium(size: 16, weight: .medium))
                    .foregroundColor(.electricCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: performSearch) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.3) : .electricCyan)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(isPresented: $showResultAlert) {
                Alert(title: Text(resultAlertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Search helpers

    private func handleSearchTextChange(_ newValue: String) {
        searchWorkItem?.cancel()
        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hideSuggestions()
            return
        }
        let workItem = DispatchWorkItem {
            fetchSuggestions(for: newValue)
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func fetchSuggestions(for query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoadingSuggestions = true
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            isLoadingSuggestions = false
            return
        }
        let urlString = "http://api.partyaux.party/search/suggestions/\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            isLoadingSuggestions = false
            return
        }
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingSuggestions = false
            }
            if let error = error { print("Suggestions error: \(error.localizedDescription)"); return }
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
            } catch { print("Failed to parse suggestions: \(error.localizedDescription)") }
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
        searchResults = []
        isLoading = true
        guard let encodedSearchTerm = searchText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            errorMessage = "Invalid search text"
            isLoading = false
            return
        }
        let urlString = "http://api.partyaux.party/search/\(encodedSearchTerm)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = "Network error: \(error.localizedDescription)" }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                return
            }
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    DispatchQueue.main.async { self.searchResults = jsonArray }
                } else {
                    DispatchQueue.main.async { self.errorMessage = "Unexpected data format" }
                }
            } catch {
                DispatchQueue.main.async { self.errorMessage = "Failed to parse response: \(error.localizedDescription)" }
            }
        }.resume()
    }

    // MARK: - Add song to playlist

    private func addSongToPlaylist(song: [String: Any], index: Int) {
        // Accept both video_id and url for progress indicator
        let songId = (song["video_id"] as? String) ?? (song["url"] as? String) ?? ""
        print("SONGID: \(songId)")
        guard !songId.isEmpty else { return }
        
        // Trigger animation and haptic feedback
        triggerAddAnimation(index: index)
        
        addingSongId = songId
        // ONLY add to playlist - do not add to queue!
        playlistManager.addSongToPlaylist(playlistId: playlist.playlistId, song: song) { success in
            DispatchQueue.main.async {
                addingSongId = nil
                resultAlertMessage = success ? "Song added to playlist!" : "Failed to add song."
                showResultAlert = true
                // Removed automatic dismissal - user stays in this view
            }
        }
    }
    
    private func triggerAddAnimation(index: Int) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animation
        withAnimation(.easeInOut(duration: 0.2)) {
            animatedIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.2)) {
                animatedIndex = nil
            }
        }
    }

    // MARK: - Duration formatting

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

// MARK: - Song Row View
struct SongRowForPlaylistView: View {
    let item: [String: Any]
    let index: Int
    @Binding var animatedIndex: Int?
    @Binding var addingSongId: String?
    let onAddSong: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Premium Thumbnail
            if let imageUrlString = item["album_art"] as? String,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appCardBackground)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .electricCyan))
                                .scaleEffect(0.6)
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCardBackground)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.electricCyan.opacity(0.5))
                    )
            }
            
            // Song info with premium styling
            VStack(alignment: .leading, spacing: 4) {
                Text(item["title"] as? String ?? "No Title")
                    .font(Font.premium(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(item["artist"] as? String ?? "No Artist")
                        .font(Font.premium(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    if let durationStr = item["duration"] as? String {
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        Text(formatDuration(durationStr))
                            .font(Font.premium(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            // Premium Plus button
            Button(action: onAddSong) {
                if addingSongId == (item["video_id"] as? String ?? item["url"] as? String) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .electricCyan))
                        .scaleEffect(0.7)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.electricCyan.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.electricCyan)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .scaleEffect(animatedIndex == index ? 0.95 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onAddSong()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
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

/*
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
}*/
