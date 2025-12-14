import SwiftUI

struct RoomCreateJoinView: View {
    @State private var joinCode = ""
    @FocusState private var isJoinCodeFocused: Bool
    @State private var bounceIndices: [Bool] = Array(repeating: false, count: 6)
    private let joinCodeLength = 6
    
    @EnvironmentObject var roomManager: RoomManager
    
    @State private var isCreatingRoom = false
    @State private var isJoiningRoom = false
    @State private var showCreatedRoom = false
    @State private var animateGlow = false

    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            // Animated background glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .brandPrimary.opacity(0.2),
                            .brandSecondary.opacity(0.1),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 350
                    )
                )
                .frame(width: min(geometry.size.width * 1.5, 600), height: min(geometry.size.width * 1.5, 600))
                .offset(y: -150)
                .scaleEffect(animateGlow ? 1.2 : 1.0)
                .opacity(animateGlow ? 0.7 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateGlow
                )

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    Spacer(minLength: max(geometry.size.height * 0.05, 30))
                    
                    // Header Section
                    VStack(spacing: Spacing.sm) {
                        LogoView(size: min(geometry.size.width * 0.22, 88), hasBackground: false)
                        
                        Text("Music Rooms")
                            .font(.headlineMedium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Create or join a room to share music with friends")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    
                    // Create Room Card
                    VStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brandGradient)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: .brandPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Create New Room")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                Text("Start a new listening session")
                                    .font(.labelMedium)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        Button(action: {
                            createRoom()
                        }) {
                            HStack(spacing: Spacing.sm) {
                                if isCreatingRoom {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating...")
                                        .font(.titleSmall)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Create Room")
                                        .font(.titleSmall)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                isCreatingRoom
                                    ? LinearGradient(colors: [.brandPrimary.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.brandGradient
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .shadow(color: .brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isCreatingRoom || isJoiningRoom)
                        .scaleEffect(isCreatingRoom ? 0.98 : 1.0)
                        .animation(.snappy, value: isCreatingRoom)
                        
                        // Show created room code
                        if showCreatedRoom && !roomManager.roomCode.isEmpty {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                                    .font(.system(size: 20))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Room Created!")
                                        .font(.labelMedium)
                                        .foregroundColor(.success)
                                    Text("Code: \(roomManager.roomCode)")
                                        .font(.titleSmall)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Spacer()
                            }
                            .padding(Spacing.md)
                            .background(Color.success.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                    .strokeBorder(Color.success.opacity(0.3), lineWidth: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                            .strokeBorder(Color.textMuted.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)
                    
                    // Divider
                    HStack(spacing: Spacing.md) {
                        Rectangle()
                            .fill(Color.textMuted.opacity(0.2))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.labelMedium)
                            .foregroundColor(.textTertiary)
                        
                        Rectangle()
                            .fill(Color.textMuted.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Spacing.xl)
                    
                    // Join Room Card
                    VStack(spacing: Spacing.lg) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.appElevated)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(LinearGradient.brandGradient, lineWidth: 2)
                                    )
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "door.right.hand.open")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(LinearGradient.brandGradient)
                            }
                            
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Join Existing Room")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                Text("Enter a 6-character room code")
                                    .font(.labelMedium)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Room code input
                        ZStack {
                            TextField("", text: $joinCode)
                                .keyboardType(.asciiCapable)
                                .textContentType(.oneTimeCode)
                                .foregroundColor(.clear)
                                .accentColor(.clear)
                                .frame(width: 0, height: 0)
                                .focused($isJoinCodeFocused)
                                .onChange(of: joinCode) { newValue in
                                    handleJoinCodeChange(newValue)
                                }

                            HStack(spacing: Spacing.sm) {
                                ForEach(0..<joinCodeLength, id: \.self) { index in
                                    RoomCodeDigitView(
                                        character: joinCode[safe: index].map { String($0) } ?? "",
                                        isActive: index == joinCode.count,
                                        isFilled: index < joinCode.count,
                                        bounce: bounceIndices[index]
                                    )
                                }
                            }
                        }
                        .onTapGesture {
                            isJoinCodeFocused = true
                        }

                        Button(action: {
                            joinRoom()
                        }) {
                            HStack(spacing: Spacing.sm) {
                                if isJoiningRoom {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Joining...")
                                        .font(.titleSmall)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Join Room")
                                        .font(.titleSmall)
                                }
                            }
                            .foregroundColor(joinCode.count == joinCodeLength && !isJoiningRoom ? .white : .textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                joinCode.count == joinCodeLength && !isJoiningRoom
                                    ? LinearGradient.brandGradient
                                    : LinearGradient(colors: [.appElevated], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                            .shadow(
                                color: joinCode.count == joinCodeLength ? .brandPrimary.opacity(0.4) : .clear,
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(joinCode.count != joinCodeLength || isCreatingRoom || isJoiningRoom)
                        .scaleEffect(isJoiningRoom ? 0.98 : 1.0)
                        .animation(.snappy, value: isJoiningRoom)
                    }
                    .padding(Spacing.lg)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                            .strokeBorder(Color.textMuted.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.lg)
                    
                    Spacer(minLength: max(geometry.size.height * 0.05, 30))
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        }
        .onAppear { animateGlow = true }
        .onTapGesture {
            isJoinCodeFocused = false
        }
        .onAppear {
            roomManager.eventHandlers()
        }
        .onChange(of: roomManager.roomCode) { newRoomCode in
            if !newRoomCode.isEmpty && isCreatingRoom {
                withAnimation(.springy) {
                    showCreatedRoom = true
                    isCreatingRoom = false
                }
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
        .onChange(of: roomManager.joinedRoom) { joined in
            if joined {
                isJoiningRoom = false
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }
    
    private func createRoom() {
        isCreatingRoom = true
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        roomManager.createRoom()
    }
    
    private func joinRoom() {
        guard joinCode.count == joinCodeLength else { return }
        
        isJoiningRoom = true
        isJoinCodeFocused = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        roomManager.joinExistingRoom(code: joinCode)
    }
    
    private func handleJoinCodeChange(_ newValue: String) {
        let filteredValue = String(newValue.prefix(joinCodeLength).uppercased().filter { $0.isLetter || $0.isNumber })
        
        if filteredValue != joinCode {
            joinCode = filteredValue
            
            if filteredValue.count > 0 && filteredValue.count <= joinCodeLength {
                let lastIndex = filteredValue.count - 1
                withAnimation(.bouncy) {
                    bounceIndices[lastIndex] = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounceIndices[lastIndex] = false
                }
            }
        }
    }
}

struct RoomCodeDigitView: View {
    let character: String
    let isActive: Bool
    let isFilled: Bool
    let bounce: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(isFilled ? Color.brandPrimary.opacity(0.1) : Color.appElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .strokeBorder(
                            isActive ? LinearGradient.brandGradient :
                            isFilled ? LinearGradient(colors: [.brandPrimary.opacity(0.5)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.textMuted.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 48, height: 58)
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(.bouncy, value: bounce)
            
            Text(character)
                .font(.headlineSmall)
                .foregroundColor(isFilled ? .brandPrimary : .textSecondary)
            
            if isActive && character.isEmpty {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
            }
        }
    }
}

extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}
