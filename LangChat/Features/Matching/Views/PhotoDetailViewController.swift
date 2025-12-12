import UIKit

class PhotoDetailViewController: UIViewController {

    // Data
    private var photoURLs: [String]
    private var captions: [String?]
    private var currentIndex: Int
    private var reportableUserId: String? // For reporting photos of other users
    private var isOwnProfile: Bool = false // For editing own photos

    // Callback for caption updates
    var onCaptionUpdated: ((Int, String?) -> Void)?

    // UI Components
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let captionContainerView = UIView()
    private let captionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let pageControl = UIPageControl()

    // Gesture recognizers
    private var panGestureRecognizer: UIPanGestureRecognizer?

    // Check if there are any photos to display
    var hasPhotos: Bool {
        return !photoURLs.isEmpty
    }

    init(photoURLs: [String], captions: [String?] = [], startingIndex: Int = 0, reportableUserId: String? = nil, isOwnProfile: Bool = false) {
        // Filter out empty/placeholder photos and track mapping
        var filteredPhotos: [String] = []
        var filteredCaptions: [String?] = []
        var originalIndexToFiltered: [Int: Int] = [:]

        for (index, url) in photoURLs.enumerated() {
            // Skip empty URLs and placeholder URLs (picsum.photos)
            if !url.isEmpty && !url.contains("picsum.photos") {
                originalIndexToFiltered[index] = filteredPhotos.count
                filteredPhotos.append(url)
                // Add corresponding caption if it exists
                if index < captions.count {
                    filteredCaptions.append(captions[index])
                } else {
                    filteredCaptions.append(nil)
                }
            }
        }

        self.photoURLs = filteredPhotos
        self.captions = filteredCaptions
        self.reportableUserId = reportableUserId
        self.isOwnProfile = isOwnProfile

        // Map the original starting index to filtered index
        if let mappedIndex = originalIndexToFiltered[startingIndex] {
            self.currentIndex = mappedIndex
        } else {
            // If the starting index was a placeholder, start at 0
            self.currentIndex = 0
        }
        super.init(nibName: nil, bundle: nil)

        // Ensure captions array matches photoURLs count
        while self.captions.count < self.photoURLs.count {
            self.captions.append(nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadCurrentPhoto()
    }

    private func setupViews() {
        view.backgroundColor = .black
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve

        // Scroll view for zooming
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Image view
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.clipsToBounds = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // Page control
        pageControl.numberOfPages = photoURLs.count
        pageControl.currentPage = currentIndex
        pageControl.pageIndicatorTintColor = .systemGray
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.isUserInteractionEnabled = false
        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        // Caption container
        captionContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        captionContainerView.layer.cornerRadius = 8
        view.addSubview(captionContainerView)
        captionContainerView.translatesAutoresizingMaskIntoConstraints = false

        // Caption label
        captionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        captionLabel.textColor = .white
        captionLabel.numberOfLines = 0
        captionLabel.textAlignment = .center
        captionContainerView.addSubview(captionLabel)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            captionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captionContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            pageControl.bottomAnchor.constraint(equalTo: captionContainerView.topAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            captionLabel.topAnchor.constraint(equalTo: captionContainerView.topAnchor, constant: 12),
            captionLabel.leadingAnchor.constraint(equalTo: captionContainerView.leadingAnchor, constant: 12),
            captionLabel.trailingAnchor.constraint(equalTo: captionContainerView.trailingAnchor, constant: -12),
            captionLabel.bottomAnchor.constraint(equalTo: captionContainerView.bottomAnchor, constant: -12)
        ])

        // Add swipe gestures
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        // Add tap to dismiss and return to profile
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.require(toFail: scrollView.pinchGestureRecognizer!)
        view.addGestureRecognizer(tapGesture)

        // Add long-press gesture for reporting or editing
        if reportableUserId != nil || isOwnProfile {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            longPressGesture.minimumPressDuration = 0.5
            view.addGestureRecognizer(longPressGesture)
        }
    }

    private func loadCurrentPhoto() {
        guard currentIndex < photoURLs.count else { return }

        let photoURL = photoURLs[currentIndex]
        ImageService.shared.loadImage(
            from: photoURL,
            into: imageView,
            placeholder: UIImage(systemName: "photo")
        )

        // Update page control
        pageControl.currentPage = currentIndex

        // Update caption
        if let caption = captions[currentIndex], !caption.isEmpty {
            captionLabel.text = caption
            captionContainerView.isHidden = false
        } else {
            captionContainerView.isHidden = true
        }

        // Reset zoom
        scrollView.zoomScale = 1.0
    }

    @objc private func handleSwipeLeft() {
        // Go to next photo
        if currentIndex < photoURLs.count - 1 {
            currentIndex += 1
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.loadCurrentPhoto()
            }
        }
    }

    @objc private func handleSwipeRight() {
        // Go to previous photo
        if currentIndex > 0 {
            currentIndex -= 1
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.loadCurrentPhoto()
            }
        }
    }

    @objc private func handleTap() {
        // Dismiss and return to Instagram-style profile page
        dismiss(animated: true)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Photo Reporting

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Only trigger on began to avoid multiple calls
        guard gesture.state == .began else { return }

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Get current photo URL
        guard currentIndex < photoURLs.count else { return }
        let photoURL = photoURLs[currentIndex]

        if isOwnProfile {
            // Show edit options for own photos
            showEditOptions(photoURL: photoURL)
        } else if let userId = reportableUserId {
            // Show report options for other users' photos
            showReportOptions(userId: userId, photoURL: photoURL)
        }
    }

    private func showReportOptions(userId: String, photoURL: String) {
        let alertController = UIAlertController(
            title: "Report Photo",
            message: "Why are you reporting this photo?",
            preferredStyle: .actionSheet
        )

        let reportReasons = [
            "Inappropriate content",
            "Spam or misleading",
            "Not a real photo",
            "Violence or dangerous content",
            "Harassment or hate speech",
            "Other"
        ]

        for reason in reportReasons {
            alertController.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.confirmReport(userId: userId, photoURL: photoURL, reason: reason)
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support - anchor to center of screen
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true)
    }

    private func confirmReport(userId: String, photoURL: String, reason: String) {
        let confirmAlert = UIAlertController(
            title: "Confirm Report",
            message: "Are you sure you want to report this photo for \"\(reason.lowercased())\"?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Report", style: .destructive) { [weak self] _ in
            self?.submitReport(userId: userId, photoURL: photoURL, reason: reason)
        })

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(confirmAlert, animated: true)
    }

    private func submitReport(userId: String, photoURL: String, reason: String) {
        Task {
            do {
                try await SupabaseService.shared.reportPhoto(
                    reportedUserId: userId,
                    photoURL: photoURL,
                    reason: reason,
                    description: nil
                )

                await MainActor.run {
                    let successAlert = UIAlertController(
                        title: "Report Submitted",
                        message: "Thank you for helping keep our community safe. We'll review this report shortly.",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(successAlert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let errorAlert = UIAlertController(
                        title: "Report Failed",
                        message: "Failed to submit report: \(error.localizedDescription). Please try again.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

    // MARK: - Own Photo Editing

    private func showEditOptions(photoURL: String) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alertController.addAction(UIAlertAction(title: "Change Photo", style: .default) { [weak self] _ in
            self?.changePhoto()
        })

        let currentCaption = currentIndex < captions.count ? captions[currentIndex] : nil
        let captionTitle = currentCaption?.isEmpty == false ? "Edit Caption" : "Add Caption"

        alertController.addAction(UIAlertAction(title: captionTitle, style: .default) { [weak self] _ in
            self?.editCaption(currentCaption: currentCaption)
        })

        alertController.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
            self?.removePhoto()
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true)
    }

    private func changePhoto() {
        // Dismiss and let the presenting view controller handle navigation to photo picker
        dismiss(animated: true) {
            // Post notification that user wants to change photo
            NotificationCenter.default.post(name: .userWantsToChangePhoto, object: nil, userInfo: ["index": self.currentIndex])
        }
    }

    private func editCaption(currentCaption: String?) {
        let alertController = UIAlertController(
            title: "Photo Caption",
            message: "Add a caption for this photo",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.text = currentCaption
            textField.placeholder = "Enter caption..."
            textField.autocapitalizationType = .sentences
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let caption = alertController.textFields?.first?.text else { return }
            self.saveCaption(caption)
        })

        present(alertController, animated: true)
    }

    private func saveCaption(_ caption: String) {
        let newCaption = caption.isEmpty ? nil : caption

        // Update local captions array
        if currentIndex < captions.count {
            captions[currentIndex] = newCaption
        }

        // Update caption display
        if let caption = newCaption, !caption.isEmpty {
            captionLabel.text = caption
            captionContainerView.isHidden = false
        } else {
            captionContainerView.isHidden = true
        }

        // Notify via callback
        onCaptionUpdated?(currentIndex, newCaption)

        // Save to Supabase
        Task {
            do {
                try await SupabaseService.shared.updatePhotoCaptions(captions: captions.map { $0 })
                await MainActor.run {
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                }
            } catch {
                print("❌ Error saving caption: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save caption. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func removePhoto() {
        let confirmAlert = UIAlertController(
            title: "Remove Photo",
            message: "Are you sure you want to remove this photo?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.performRemovePhoto()
        })

        present(confirmAlert, animated: true)
    }

    private func performRemovePhoto() {
        // Dismiss and let the presenting view controller handle the removal
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .userWantsToRemovePhoto, object: nil, userInfo: ["index": self.currentIndex])
        }
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image when zoomed
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                   y: scrollView.contentSize.height * 0.5 + offsetY)
    }
}
