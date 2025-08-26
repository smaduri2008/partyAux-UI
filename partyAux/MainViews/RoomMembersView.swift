import SwiftUI

// MARK: - Room Members View
struct RoomMembersView: View {
    @ObservedObject var roomManager: RoomManager
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.springy) {
                        isVisible = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                // Title
                Text("Room Members")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Member count badge
                Text("\(roomManager.roomMembers.count)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
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
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .background(LinearGradient.backgroundGradient.ignoresSafeArea())
        .onAppear {
            // Refresh room info when members view appears
            //roomManager.getRoomInfo()
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
            // Profile Picture Placeholder
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                // User initials
                Text(String(username.prefix(2).uppercased()))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(username)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // Host Crown
                    if isHost {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    
                    // Current User Badge
                    if isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                // Role indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isHost ? Color.yellow : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(isHost ? "Host" : "Member")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isHost ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Members Overlay View (for use in MusicPlayerView)
struct MembersOverlayView: View {
    @Binding var isMembersVisible: Bool
    @EnvironmentObject var roomManager: RoomManager
    
    var body: some View {
        RoomMembersView(roomManager: roomManager, isVisible: $isMembersVisible)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .zIndex(2)
    }
}
