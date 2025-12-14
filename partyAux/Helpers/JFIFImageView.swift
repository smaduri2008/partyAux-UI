import SwiftUI

struct JFIFImageView: View {
    let imageUrl: URL?
    @State private var uiImage: UIImage?
    
    // Static cache to share across all instances
    private static let imageCache = NSCache<NSURL, UIImage>()

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
            // Only reset if the URL actually changed to something new that isn't cached
            if let url = imageUrl, let cached = Self.imageCache.object(forKey: url as NSURL) {
                uiImage = cached
            } else {
                uiImage = nil
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let imageUrl = imageUrl else {
            return
        }
        
        // Check cache first
        if let cachedImage = Self.imageCache.object(forKey: imageUrl as NSURL) {
            self.uiImage = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                // Cache the image
                Self.imageCache.setObject(loadedImage, forKey: imageUrl as NSURL)
                
                DispatchQueue.main.async {
                    self.uiImage = loadedImage
                }
            } else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
}
