import SwiftUI

struct LogoView: View {
    var size: CGFloat = 88
    var hasBackground: Bool = true
    var body: some View {
        Group {
            if let uiImage = UIImage(named: "PartyAux_transparent") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                if hasBackground {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.brandGradient)
                            .frame(width: size, height: size)
                            .shadow(color: .brandPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: size * 0.45, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            LogoView(size: 88)
            LogoView(size: 64, hasBackground: true)
            LogoView(size: 44, hasBackground: false)
        }
        .padding()
        .background(Color.deepNavy)
    }
}
