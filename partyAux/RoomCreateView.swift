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

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 50) {
                    Spacer(minLength: 40)
                    
                    // Header Section
                    VStack(spacing: 16) {
                        Text("Music Rooms")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Create a room or join an existing one to start sharing music")
                            .font(.callout)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .animation(.smooth.delay(0.2), value: true)
                    
                    // Create Room Section
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing))
                                    .frame(width: 45, height: 45)
                                    .shadow(color: Color.white.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Text("Create New Room")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }
                        
                        Button(action: {
                            createRoom()
                        }) {
                            HStack {
                                if isCreatingRoom {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating Room...")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Create Room")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isCreatingRoom ? 
                                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7)]), startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.black)
                            .cornerRadius(16)
                            .shadow(color: Color.white.opacity(0.4), radius: 12, x: 0, y: 6)
                            .scaleEffect(isCreatingRoom ? 0.98 : 1.0)
                            .animation(.bouncy, value: isCreatingRoom)
                        }
                        .disabled(isCreatingRoom || isJoiningRoom)
                        
                        // Show created room code
                        if showCreatedRoom && !roomManager.roomCode.isEmpty {
                            VStack(spacing: 12) {
                                Text("Room Created!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text("Room Code: \(roomManager.roomCode)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.springy, value: showCreatedRoom)
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.smooth.delay(0.4), value: true)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .animation(.smooth.delay(0.5), value: true)
                    
                    // Join Room Section
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.appCardBackground)
                                    .overlay(
                                        Circle()
                                            .stroke(LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                    )
                                    .frame(width: 45, height: 45)
                                
                                Image(systemName: "door.right.hand.open")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Join Existing Room")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }
                        
                        VStack(spacing: 16) {
                            Text("Enter Room Code")
                                .font(.callout)
                                .foregroundColor(.textSecondary)

                            ZStack {
                                TextField("", text: $joinCode)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .foregroundColor(.clear)
                                    .accentColor(.clear)
                                    .frame(width: 0, height: 0)
                                    .focused($isJoinCodeFocused)
                                    .onChange(of: joinCode) { newValue in
                                        handleJoinCodeChange(newValue)
                                    }

                                HStack(spacing: 12) {
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
                                HStack {
                                    if isJoiningRoom {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Joining Room...")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Join Room")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if joinCode.count == joinCodeLength && !isJoiningRoom {
                                            LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing)
                                        } else {
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.gray.opacity(0.3)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .foregroundColor(joinCode.count == joinCodeLength && !isJoiningRoom ? .black : .textTertiary)
                                .cornerRadius(16)
                                .shadow(
                                    color: joinCode.count == joinCodeLength ? Color.white.opacity(0.3) : Color.clear,
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                                .scaleEffect(isJoiningRoom ? 0.98 : 1.0)
                                .animation(.bouncy, value: isJoiningRoom)
                            }
                            .disabled(joinCode.count != joinCodeLength || isCreatingRoom || isJoiningRoom)
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.smooth.delay(0.6), value: true)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
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
                
                // Add success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
        .onChange(of: roomManager.joinedRoom) { joined in
            if joined {
                isJoiningRoom = false
                
                // Add success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
        .onTapGesture {
            isJoinCodeFocused = false
        }
    }
    
    private func createRoom() {
        isCreatingRoom = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        roomManager.createRoom()
    }
    
    private func joinRoom() {
        guard joinCode.count == joinCodeLength else { return }
        
        isJoiningRoom = true
        isJoinCodeFocused = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        roomManager.joinExistingRoom(code: joinCode)
    }
    
    private func handleJoinCodeChange(_ newValue: String) {
        let filteredValue = String(newValue.prefix(joinCodeLength).uppercased().filter { $0.isLetter || $0.isNumber })
        
        if filteredValue != joinCode {
            joinCode = filteredValue
            
            // Animate bounce effect for new characters
            if filteredValue.count > 0 && filteredValue.count <= joinCodeLength {
                let lastIndex = filteredValue.count - 1
                withAnimation(.bouncy) {
                    bounceIndices[lastIndex] = true
                }
                
                // Reset bounce after animation
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isFilled ? Color.white.opacity(0.1) : Color.appCardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isActive ? LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing) : 
                            LinearGradient(
                                gradient: Gradient(colors: [isFilled ? Color.white : Color.appSurface]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .frame(width: 45, height: 55)
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(.bouncy, value: bounce)
            
            Text(character)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isFilled ? .white : .textSecondary)
            
            // Cursor animation
            if isActive && character.isEmpty {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: 20)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
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

#Preview {
    RoomCreateJoinView()
}
