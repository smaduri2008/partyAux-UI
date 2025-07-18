import SwiftUI

struct RoomCreateJoinView: View {
    @State private var joinCode = ""
    @FocusState private var isJoinCodeFocused: Bool
    private let joinCodeLength = 6
    
    @EnvironmentObject var roomManager: RoomManager

    let purpleColor = Color(red: 123/255, green: 97/255, blue: 255/255)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                VStack {
                    Button(action: {
                        roomManager.connect()
                        roomManager.createRoom()
                        roomManager.joinRoom()
                    }) {
                        Text("Create Room")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(width: 140, height: 55)
                            .background(purpleColor)
                            .cornerRadius(14)
                            .shadow(color: purpleColor.opacity(0.4), radius: 10)
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 350, height: 1)

                VStack(spacing: 16) {
                    Text("Enter Room Code")
                        .foregroundColor(.white)
                        .font(.headline)

                    ZStack {
                        TextField("", text: $joinCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                            .frame(width: 0, height: 0)
                            .focused($isJoinCodeFocused)
                            .onChange(of: joinCode) { newValue in
                                if newValue.count > joinCodeLength {
                                    joinCode = String(newValue.prefix(joinCodeLength))
                                }
                                joinCode = joinCode.uppercased()
                            }

                        HStack(spacing: 12) {
                            ForEach(0..<joinCodeLength, id: \.self) { index in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(purpleColor, lineWidth: 2)
                                        .frame(width: 45, height: 55)

                                    Text(joinCode[safe: index].map { String($0) } ?? "")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isJoinCodeFocused = true
                    }

                    Button(action: {
                        roomManager.roomCode = joinCode
                        roomManager.connect()
                        roomManager.joinRoom()
                    }) {
                        Text("Join Room")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(width: 140, height: 50)
                            .background(purpleColor)
                            .cornerRadius(14)
                            .shadow(color: purpleColor.opacity(0.4), radius: 10)
                    }
                }
            }
            .padding(.horizontal, 40)
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
