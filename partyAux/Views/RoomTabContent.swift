//
//  RoomTabContent.swift
//  partyAux
//
//  Created by GitHub Copilot on 8/27/25.
//

import SwiftUI

struct RoomTabContent: View {
    @Binding var isCreatingRoom: Bool
    @Binding var isJoiningRoom: Bool
    @Binding var showCreatedRoom: Bool
    @Binding var joinCode: String
    @Binding var bounceIndices: [Bool]
    let roomManager: RoomManager
    let createRoom: () -> Void
    let joinRoom: () -> Void
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    @FocusState private var isJoinCodeFocused: Bool
    private let joinCodeLength = 6
    
    var body: some View {
        ScrollView {
            VStack(spacing: 50) {
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
                    
                    Button(action: createRoom) {
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
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .frame(width: 45, height: 45)
                                .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Join Existing Room")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                    }
                    
                    // Join Code Input
                    VStack(spacing: 16) {
                        Text("Enter Room Code")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<joinCodeLength, id: \.self) { index in
                                JoinCodeDigitView(
                                    character: String(joinCode.prefix(joinCodeLength).suffix(joinCodeLength - index).prefix(1)),
                                    isActive: index == joinCode.count && joinCode.count < joinCodeLength,
                                    isFilled: index < joinCode.count,
                                    bounce: bounceIndices[safe: index] ?? false
                                )
                            }
                        }
                        .onChange(of: joinCode) { newValue in
                            // Limit to 6 characters and convert to uppercase
                            let filtered = String(newValue.uppercased().prefix(joinCodeLength))
                            if filtered != joinCode {
                                joinCode = filtered
                            }
                            
                            // Trigger bounce animation for newly entered characters
                            if newValue.count > 0 && newValue.count <= joinCodeLength {
                                let newIndex = newValue.count - 1
                                if newIndex < bounceIndices.count {
                                    withAnimation(.bouncy) {
                                        bounceIndices[newIndex] = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        bounceIndices[newIndex] = false
                                    }
                                }
                            }
                        }
                        
                        // Hidden TextField for input handling
                        TextField("", text: $joinCode)
                            .focused($isJoinCodeFocused)
                            .keyboardType(.asciiCapable)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .opacity(0)
                            .frame(height: 1)
                            .onTapGesture {
                                isJoinCodeFocused = true
                            }
                    }
                    .onTapGesture {
                        isJoinCodeFocused = true
                    }
                    
                    Button(action: joinRoom) {
                        HStack {
                            if isJoiningRoom {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                                Text("Joining...")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Join Room")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            joinCode.count == joinCodeLength && !isJoiningRoom ?
                            LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.black)
                        .cornerRadius(16)
                        .shadow(
                            color: joinCode.count == joinCodeLength ? Color.white.opacity(0.4) : Color.clear,
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                        .scaleEffect(isJoiningRoom ? 0.98 : 1.0)
                        .animation(.bouncy, value: isJoiningRoom)
                    }
                    .disabled(joinCode.count != joinCodeLength || isJoiningRoom || isCreatingRoom)
                }
                .padding(.horizontal, 24)
                .animation(.smooth.delay(0.6), value: true)
                
                Spacer(minLength: 40)
            }
        }
    }
}

struct JoinCodeDigitView: View {
    let character: String
    let isActive: Bool
    let isFilled: Bool
    let bounce: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
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

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
