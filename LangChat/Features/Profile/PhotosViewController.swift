import UIKit
import PhotosUI

class PhotosViewController: UIViewController {

    private let collectionView: UICollectionView
    private var photos: [String] = []

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        let itemsPerRow: CGFloat = 3
        let totalSpacing = spacing * (itemsPerRow + 1)
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / itemsPerRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadPhotos()
    }

    private func setupViews() {
        title = "My Photos"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPhotoTapped)
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionCell.self, forCellWithReuseIdentifier: "PhotoCell")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadPhotos() {
        // Load from UserDefaults
        if let savedPhotos = UserDefaults.standard.stringArray(forKey: "userPhotos"), !savedPhotos.isEmpty {
            photos = savedPhotos
        } else {
            // Default empty state - user can add photos
            photos = []
        }
        collectionView.reloadData()
    }

    @objc private func addPhotoTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 6 - photos.count // Max 6 photos total
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func savePhotos() {
        UserDefaults.standard.set(photos, forKey: "userPhotos")
    }
}

// MARK: - UICollectionViewDataSource
extension PhotosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(photos.count + 1, 6) // +1 for add button, max 6 total
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCollectionCell else {
            return UICollectionViewCell()
        }
        if indexPath.item < photos.count {
            cell.configure(with: photos[indexPath.item])
        } else {
            // Add photo cell
            cell.configureAsAddButton()
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < photos.count {
            // Show delete option
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { [weak self] _ in
                self?.photos.remove(at: indexPath.item)
                self?.savePhotos()
                self?.collectionView.reloadData()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController,
               let cell = collectionView.cellForItem(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }

            present(alert, animated: true)
        } else {
            // Add new photo
            addPhotoTapped()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotosViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard !results.isEmpty else { return }

        // Show loading indicator with cancel option
        let loadingAlert = UIAlertController(title: "Uploading Photos", message: "Please wait...", preferredStyle: .alert)
        var isCancelled = false
        loadingAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            isCancelled = true
        })
        present(loadingAlert, animated: true)

        Task {
            var uploadedCount = 0
            var failedCount = 0

            for result in results {
                // Check if user cancelled
                if isCancelled { break }

                do {
                    // Load the image with timeout
                    let image = try await withTimeout(seconds: 30) {
                        try await self.loadImage(from: result)
                    }

                    // Compress to JPEG
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        failedCount += 1
                        continue
                    }

                    // Get user ID
                    guard let userId = SupabaseService.shared.currentUserId?.uuidString else {
                        failedCount += 1
                        continue
                    }

                    // Upload to Supabase with timeout
                    let photoIndex = self.photos.count
                    let storagePath = try await withTimeout(seconds: 60) {
                        try await SupabaseService.shared.uploadPhoto(
                            imageData,
                            userId: userId,
                            photoIndex: photoIndex
                        )
                    }

                    // Add to array
                    await MainActor.run {
                        self.photos.append(storagePath)
                        self.savePhotos()
                        self.collectionView.reloadData()
                    }

                    uploadedCount += 1
                    print("✅ Photo uploaded: \(storagePath)")

                } catch {
                    print("❌ Failed to upload photo: \(error)")
                    failedCount += 1
                }
            }

            // Dismiss loading - ensure this always happens
            await MainActor.run {
                // Dismiss any presented alert
                if self.presentedViewController != nil {
                    self.dismiss(animated: true) {
                        self.showUploadResult(uploaded: uploadedCount, failed: failedCount, cancelled: isCancelled)
                    }
                } else {
                    self.showUploadResult(uploaded: uploadedCount, failed: failedCount, cancelled: isCancelled)
                }
            }
        }
    }

    private func showUploadResult(uploaded: Int, failed: Int, cancelled: Bool) {
        if cancelled {
            let alert = UIAlertController(
                title: "Upload Cancelled",
                message: uploaded > 0 ? "\(uploaded) photo(s) were uploaded before cancellation." : nil,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else if failed > 0 {
            let alert = UIAlertController(
                title: "Upload Complete",
                message: "\(uploaded) photo(s) uploaded. \(failed) failed.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    /// Helper to load UIImage from PHPickerResult asynchronously with proper error handling
    private func loadImage(from result: PHPickerResult) async throws -> UIImage {
        let originalImage: UIImage = try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                guard !hasResumed else { return }
                hasResumed = true

                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = object as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "PhotoPicker", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not load image"]))
                }
            }
        }

        // Resize image to max 1200px to reduce memory usage and prevent crashes
        return resizeImage(originalImage, maxDimension: 1200)
    }

    /// Execute an async operation with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "Timeout", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Operation timed out after \(Int(seconds)) seconds"])
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already small enough, return it
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use UIGraphicsImageRenderer for efficient memory handling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }
}

// MARK: - Photo Cell
class PhotoCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let addButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.backgroundColor = .systemGray6
        addButton.layer.cornerRadius = 8
        addButton.isHidden = true
        addButton.isUserInteractionEnabled = false

        contentView.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            addButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with pathOrUrl: String) {
        imageView.isHidden = false
        addButton.isHidden = true

        // Check if it's a storage path (not a URL) - needs signed URL
        if !pathOrUrl.isEmpty && !pathOrUrl.hasPrefix("http") {
            // It's a storage path, get signed URL
            Task {
                do {
                    let signedURL = try await SupabaseService.shared.getSignedPhotoURL(path: pathOrUrl)
                    await MainActor.run {
                        ImageService.shared.loadImage(
                            from: signedURL,
                            into: self.imageView,
                            placeholder: UIImage(systemName: "photo")
                        )
                    }
                } catch {
                    print("❌ Failed to get signed URL: \(error)")
                    await MainActor.run {
                        self.imageView.image = UIImage(systemName: "photo")
                        self.imageView.tintColor = .systemGray3
                    }
                }
            }
        } else if pathOrUrl.hasPrefix("http") {
            // It's already a URL
            ImageService.shared.loadImage(
                from: pathOrUrl,
                into: imageView,
                placeholder: UIImage(systemName: "photo")
            )
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
        }
    }

    func configureAsAddButton() {
        imageView.isHidden = true
        addButton.isHidden = false
    }
}