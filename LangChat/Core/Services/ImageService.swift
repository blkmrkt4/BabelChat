import UIKit

class ImageService {
    static let shared = ImageService()
    private let cache = NSCache<NSString, UIImage>()
    
    // Shared session for all image downloads
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // Generate placeholder images for testing
    // Best services for testing:
    // 1. Lorem Picsum (https://picsum.photos) - Random beautiful photos
    // 2. Unsplash Source (https://source.unsplash.com) - Quality photos by category
    // 3. Placeholder.com - Simple colored placeholders
    // 4. UI Faces (https://uifaces.co) - AI generated face photos

    func generatePhotoURLs(for userId: String, count: Int = 6) -> [String] {
        var urls: [String] = []

        // Using Lorem Picsum for high-quality random photos
        // Each URL will return a different random image
        for i in 0..<count {
            // Size optimized for our grid: 200x300 for portrait photos
            let seed = "\(userId)_\(i)"
            urls.append("https://picsum.photos/seed/\(seed)/400/600")
        }

        return urls
    }

    func generateProfileImageURL(for userId: String) -> String {
        // For profile images, use a square format
        return "https://picsum.photos/seed/profile_\(userId)/400/400"
    }

    func generateAvatarURL(for name: String, userId: String) -> String {
        // UI Avatars service for consistent avatar generation
        let initials = name.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()

        let colors = ["7F9CF5", "ECC94B", "F687B3", "9F7AEA", "38B2AC", "4299E1"]
        let colorIndex = userId.hashValue % colors.count
        let bgColor = colors[abs(colorIndex)]

        return "https://ui-avatars.com/api/?name=\(initials)&size=400&background=\(bgColor)&color=fff&bold=true"
    }

    func loadImage(from urlString: String, into imageView: UIImageView, placeholder: UIImage? = nil) {
        // Set placeholder immediately
        let placeholderImage = placeholder ?? generateLocalPlaceholder(for: urlString)
        imageView.image = placeholderImage
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFill

        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }

        // Check cache first
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            imageView.image = cachedImage
            imageView.contentMode = .scaleAspectFill
            return
        }

        // Download image using shared session
        session.dataTask(with: url) { [weak self, weak imageView] data, response, error in
            if let error = error {
                print("Image loading error: \(error.localizedDescription)")
                // Keep placeholder on error
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data from: \(urlString)")
                return
            }

            // Cache the image
            self?.cache.setObject(image, forKey: urlString as NSString)

            // Update UI on main thread
            DispatchQueue.main.async {
                UIView.transition(with: imageView ?? UIImageView(), duration: 0.3, options: .transitionCrossDissolve) {
                    imageView?.image = image
                    imageView?.contentMode = .scaleAspectFill
                }
            }
        }.resume()
    }

    // Generate colored placeholder based on string hash
    private func generateLocalPlaceholder(for string: String) -> UIImage {
        let colors: [UIColor] = [
            .systemBlue.withAlphaComponent(0.3),
            .systemGreen.withAlphaComponent(0.3),
            .systemOrange.withAlphaComponent(0.3),
            .systemPurple.withAlphaComponent(0.3),
            .systemTeal.withAlphaComponent(0.3),
            .systemPink.withAlphaComponent(0.3)
        ]

        let colorIndex = abs(string.hashValue % colors.count)
        let color = colors[colorIndex]

        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Add icon in center
            let iconImage = UIImage(systemName: "photo")?.withTintColor(.white.withAlphaComponent(0.5), renderingMode: .alwaysOriginal)
            let iconSize = CGSize(width: 100, height: 100)
            let iconRect = CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            iconImage?.draw(in: iconRect)
        }
    }

    // For production, you would use real photos:
    func getRealisticPhotoURLs(for userType: String) -> [String] {
        switch userType {
        case "korean_female":
            return [
                "https://source.unsplash.com/400x600/?korean,woman,portrait",
                "https://source.unsplash.com/400x600/?seoul,cafe",
                "https://source.unsplash.com/400x600/?korean,food",
                "https://source.unsplash.com/400x600/?hanbok",
                "https://source.unsplash.com/400x600/?seoul,night",
                "https://source.unsplash.com/400x600/?korean,culture"
            ]
        case "spanish_female":
            return [
                "https://source.unsplash.com/400x600/?spanish,woman",
                "https://source.unsplash.com/400x600/?barcelona",
                "https://source.unsplash.com/400x600/?tapas",
                "https://source.unsplash.com/400x600/?flamenco",
                "https://source.unsplash.com/400x600/?mediterranean",
                "https://source.unsplash.com/400x600/?spanish,architecture"
            ]
        case "japanese_male":
            return [
                "https://source.unsplash.com/400x600/?japanese,man",
                "https://source.unsplash.com/400x600/?tokyo,street",
                "https://source.unsplash.com/400x600/?ramen",
                "https://source.unsplash.com/400x600/?coding,computer",
                "https://source.unsplash.com/400x600/?akihabara",
                "https://source.unsplash.com/400x600/?mount,fuji"
            ]
        default:
            return generatePhotoURLs(for: userType)
        }
    }
}