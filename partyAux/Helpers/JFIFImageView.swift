import SwiftUI

struct JFIFImageView: View {
        let imageUrl: URL?
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageUrl) { _ in
            uiImage = nil
            loadImage()
        }
    }

    private func loadImage() {
        guard let imageUrl = imageUrl else {
            // No URL, keep spinner
            return
        }
        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = loadedImage
                    print("Image Loaded: \(imageUrl)")
                }
            } else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
}
