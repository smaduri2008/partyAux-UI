import SwiftUI

// MARK: - Room Members View
struct RoomMembersView: View {
    @ObservedObject var roomManager: RoomManager
    @Binding var isVisible: Bool
    
    var body: some View {
        ZStack {
            // Premium background
            Color.deepNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Header
                HStack {
                    // Back button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.springy) {
                            isVisible = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(Font.premium(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    // Title with icon
                    HStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.electricCyan)
                        
                        Text("Members")
                            .font(Font.premium(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Member count badge
                    Text("\(roomManager.roomMembers.count)")
                        .font(Font.premium(size: 14, weight: .bold))
                        .foregroundColor(.electricCyan)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.electricCyan.opacity(0.15))
                                .overlay(
                                    Circle()
                                        .stroke(Color.electricCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Members List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(roomManager.roomMembers, id: \.self) { memberEmail in
                            MemberRowView(
                                memberEmail: memberEmail,
                                username: roomManager.roomMembersUsernames[memberEmail] ?? "Unknown",
                                isHost: memberEmail == roomManager.roomHost,
                                isCurrentUser: memberEmail == roomManager.userData.email
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            print("🔄 RoomMembersView appeared - refreshing room info")
            roomManager.getRoomInfo()
        }
        .onReceive(roomManager.$roomMembers) { newMembers in
            print("🔄 RoomMembersView detected roomMembers change: \(newMembers)")
        }
        .onReceive(roomManager.$roomMembersUsernames) { newUsernames in
            print("🔄 RoomMembersView detected usernames change: \(newUsernames)")
        }
        .onChange(of: roomManager.roomMembers.count) { count in
            print("🔄 RoomMembersView member count changed to: \(count)")
        }
        .refreshable {
            print("🔄 Pull to refresh triggered")
            roomManager.getRoomInfo()
        }
    }
}

// MARK: - Member Row View
struct MemberRowView: View {
    let memberEmail: String
    let username: String
    let isHost: Bool
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Picture with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isHost ? [.electricCyan, .softPurple] : [.softPurple, .coralPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: (isHost ? Color.electricCyan : Color.softPurple).opacity(0.4), radius: 8, x: 0, y: 4)
                
                // User initials
                    Text(String(username.prefix(2).uppercased()))
                    .font(Font.premium(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // Host crown overlay
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .offset(x: 16, y: -18)
                        .shadow(color: .yellow.opacity(0.5), radius: 4)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(username)
                        .font(Font.premium(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Current User Badge
                    if isCurrentUser {
                        Text("You")
                            .font(Font.premium(size: 10, weight: .bold))
                            .foregroundColor(.electricCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.electricCyan.opacity(0.15))
                            )
                    }
                }
                
                // Role indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(isHost ? Color.yellow : Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: isHost ? .yellow.opacity(0.5) : .green.opacity(0.5), radius: 3)
                    
                    Text(isHost ? "Host" : "Member")
                        .font(Font.premium(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isHost ? 
                                LinearGradient(colors: [.electricCyan.opacity(0.3), .softPurple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Members Overlay View (for use in MusicPlayerView)
struct MembersOverlayView: View {
    @Binding var isMembersVisible: Bool
    @ObservedObject var roomManager: RoomManager
    
    var body: some View {
        RoomMembersView(roomManager: roomManager, isVisible: $isMembersVisible)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .zIndex(2)
    }
}
