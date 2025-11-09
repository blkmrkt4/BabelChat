import UIKit

class UserDetailViewController: UIViewController, PhotoGridViewDelegate {

    var user: User?
    var match: Match? // Store the actual match object
    var isMatched: Bool = false
    var allUsers: [User] = []
    var currentUserIndex: Int = 0
    var isFromDiscover: Bool = false // Track if opened from Discover to hide back button

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Main profile image (circular, like ProfileViewController)
    private let profileImageView = UIImageView()

    // Name and badges
    private let nameLabel = UILabel()
    private let nativeLanguageBadge = LanguageBadgeView()
    private let learningLanguageBadge = LanguageBadgeView()

    // Language info
    private let aspiringLabel = UILabel()
    private let aspiringLanguagesStack = UIStackView()

    // Photo Grid
    private let photoGridView = PhotoGridView()

    // Action buttons container
    private let actionButtonsContainer = UIView()
    private let backButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
    private let pinButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)

    // Open to match
    private let openToMatchLabel = UILabel()

    // About section
    private let aboutLabel = UILabel()
    private let bioLabel = UILabel()

    // Location
    private let locationLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupConstraints()
        setupSwipeGestures()
        updateUI()
        updateNavigationButtons()
    }

    private func setupSwipeGestures() {
        // Swipe left to go to previous profile
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        // Swipe right to go to next profile
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        // Swipe up to go to next profile
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        // Swipe down to go to previous profile
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }

    @objc private func handleSwipeLeft() {
        // Navigate to previous profile
        backButtonTapped()
    }

    @objc private func handleSwipeRight() {
        // Navigate to next profile
        forwardButtonTapped()
    }

    @objc private func handleSwipeUp() {
        // Navigate to next profile
        forwardButtonTapped()
    }

    @objc private func handleSwipeDown() {
        // Navigate to previous profile
        backButtonTapped()
    }

    private func setupNavigationBar() {
        title = user?.firstName ?? "Profile"
        navigationItem.largeTitleDisplayMode = .never

        // Hide back button when viewing from Discover (use action buttons to navigate instead)
        if isFromDiscover {
            navigationItem.hidesBackButton = true
        }

        if isMatched {
            // Add chat button if matched
            let chatButton = UIBarButtonItem(
                image: UIImage(systemName: "message.fill"),
                style: .plain,
                target: self,
                action: #selector(chatTapped)
            )
            navigationItem.rightBarButtonItem = chatButton
        }
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Main circular profile image (matching ProfileViewController)
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.isUserInteractionEnabled = true
        contentView.addSubview(profileImageView)

        // Add tap gesture to profile image to view full-screen
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(profileTapGesture)

        // Name label
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .left
        contentView.addSubview(nameLabel)

        // Native language badge (only one to show)
        contentView.addSubview(nativeLanguageBadge)

        // Photo grid
        photoGridView.layer.cornerRadius = 12
        photoGridView.clipsToBounds = true
        photoGridView.delegate = self
        contentView.addSubview(photoGridView)

        // Action buttons container
        actionButtonsContainer.backgroundColor = .clear
        contentView.addSubview(actionButtonsContainer)

        // Setup action buttons with exact colors from design
        setupActionButton(backButton, systemName: "chevron.left",
                         borderColor: UIColor(hex: "#999999"),
                         iconColor: UIColor(hex: "#666666"))
        setupActionButton(rejectButton, systemName: "xmark",
                         borderColor: UIColor(hex: "#ff6b6b"),
                         iconColor: UIColor(hex: "#ff6b6b"))
        setupActionButton(pinButton, systemName: "star.fill",
                         borderColor: UIColor(hex: "#ffc837"),
                         iconColor: UIColor(hex: "#ff8008"))
        setupActionButton(likeButton, systemName: "checkmark",
                         borderColor: UIColor(hex: "#00c896"),
                         iconColor: UIColor(hex: "#00c896"))
        setupActionButton(forwardButton, systemName: "chevron.right",
                         borderColor: UIColor(hex: "#999999"),
                         iconColor: UIColor(hex: "#666666"))

        actionButtonsContainer.addSubview(backButton)
        actionButtonsContainer.addSubview(rejectButton)
        actionButtonsContainer.addSubview(pinButton)
        actionButtonsContainer.addSubview(likeButton)
        actionButtonsContainer.addSubview(forwardButton)

        // Open to match
        openToMatchLabel.font = .systemFont(ofSize: 16, weight: .medium)
        openToMatchLabel.textColor = .systemBlue
        openToMatchLabel.textAlignment = .left
        openToMatchLabel.numberOfLines = 0
        openToMatchLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(openToMatchLabel)

        // About section
        aboutLabel.text = "About"
        aboutLabel.font = .systemFont(ofSize: 20, weight: .bold)
        aboutLabel.textColor = .label
        contentView.addSubview(aboutLabel)

        bioLabel.font = .systemFont(ofSize: 16, weight: .regular)
        bioLabel.textColor = .secondaryLabel
        bioLabel.numberOfLines = 0
        contentView.addSubview(bioLabel)

        // Location
        locationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        locationLabel.textColor = .tertiaryLabel
        locationLabel.textAlignment = .left
        contentView.addSubview(locationLabel)

        // Add button actions
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        pinButton.addTarget(self, action: #selector(pinButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
    }

    private func setupActionButton(_ button: UIButton, systemName: String, borderColor: UIColor, iconColor: UIColor) {
        // Premium glassmorphism style matching HTML design
        // Background: rgba(255, 255, 255, 0.1)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 35 // 70x70 button size

        // Border: 3px solid
        button.layer.borderWidth = 3
        button.layer.borderColor = borderColor.cgColor

        // Shadow: 0 8px 32px rgba(0,0,0,0.1)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 32
        button.layer.shadowOpacity = 0.1

        // Add blur effect for backdrop-filter: blur(10px)
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = 35
        blurView.clipsToBounds = true
        blurView.alpha = 0.5 // Subtle blur
        button.insertSubview(blurView, at: 0)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        // Icon configuration - font-size: 1.8rem
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium, scale: .large)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = iconColor
        button.contentMode = .scaleAspectFit

        // Store colors for hover effect
        button.layer.setValue(borderColor, forKey: "originalBorderColor")
        button.layer.setValue(iconColor, forKey: "originalIconColor")

        // Add spring animation on tap
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        // Active state: scale(1.05) - slightly pressed
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut) {
            sender.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            // Change background to rgba(255, 255, 255, 0.2) on press
            sender.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        // Hover state: scale(1.15) then back to normal
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            // Enhanced shadow on hover
            sender.layer.shadowOpacity = 0.2
            sender.layer.shadowRadius = 40
        } completion: { _ in
            // Spring back to normal
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                sender.transform = .identity
                sender.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                sender.layer.shadowOpacity = 0.1
                sender.layer.shadowRadius = 32
            }
        }
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageBadge.translatesAutoresizingMaskIntoConstraints = false
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        openToMatchLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Main profile image - LEFT ALIGNED, same as ProfileViewController
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            // Name - BESIDE profile image
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            // Native language badge - under name, still beside profile image
            nativeLanguageBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nativeLanguageBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nativeLanguageBadge.heightAnchor.constraint(equalToConstant: 40),

            // Location - under native badge, still beside profile image
            locationLabel.topAnchor.constraint(equalTo: nativeLanguageBadge.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            // Photo grid - directly below profile image section
            photoGridView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            photoGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoGridView.heightAnchor.constraint(equalTo: photoGridView.widthAnchor, multiplier: 0.67),

            // Action buttons container
            actionButtonsContainer.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 16),
            actionButtonsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionButtonsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionButtonsContainer.heightAnchor.constraint(equalToConstant: 70),

            // Action buttons - 5 buttons evenly spaced (70x70 per design)
            backButton.leadingAnchor.constraint(equalTo: actionButtonsContainer.leadingAnchor, constant: 5),
            backButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 70),
            backButton.heightAnchor.constraint(equalToConstant: 70),

            rejectButton.centerXAnchor.constraint(equalTo: actionButtonsContainer.centerXAnchor, constant: -80),
            rejectButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            rejectButton.widthAnchor.constraint(equalToConstant: 70),
            rejectButton.heightAnchor.constraint(equalToConstant: 70),

            pinButton.centerXAnchor.constraint(equalTo: actionButtonsContainer.centerXAnchor),
            pinButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            pinButton.widthAnchor.constraint(equalToConstant: 70),
            pinButton.heightAnchor.constraint(equalToConstant: 70),

            likeButton.centerXAnchor.constraint(equalTo: actionButtonsContainer.centerXAnchor, constant: 80),
            likeButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 70),
            likeButton.heightAnchor.constraint(equalToConstant: 70),

            forwardButton.trailingAnchor.constraint(equalTo: actionButtonsContainer.trailingAnchor, constant: -5),
            forwardButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 70),
            forwardButton.heightAnchor.constraint(equalToConstant: 70),

            // Open to match
            openToMatchLabel.topAnchor.constraint(equalTo: actionButtonsContainer.bottomAnchor, constant: 12),
            openToMatchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            openToMatchLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // About section
            aboutLabel.topAnchor.constraint(equalTo: openToMatchLabel.bottomAnchor, constant: 20),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            bioLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 6),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bioLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func updateUI() {
        guard let user = user else { return }

        // Update navigation title
        title = user.firstName

        // Name
        nameLabel.text = "\(user.firstName) \(user.lastName ?? "")"

        // Load profile image with signed URL if needed
        if let profileImagePath = user.profileImageURL {
            Task {
                do {
                    // Check if it's a storage path (not a full URL)
                    let imageURL: String
                    if !profileImagePath.hasPrefix("http") && !profileImagePath.isEmpty {
                        // It's a storage path, generate signed URL
                        imageURL = try await SupabaseService.shared.getSignedPhotoURL(path: profileImagePath)
                    } else {
                        // It's already a URL or placeholder
                        imageURL = profileImagePath
                    }

                    await MainActor.run {
                        ImageService.shared.loadImage(
                            from: imageURL,
                            into: self.profileImageView,
                            placeholder: UIImage(systemName: "person.fill")
                        )
                    }
                } catch {
                    print("Failed to load profile image: \(error)")
                }
            }
        }

        // Show only native language badge
        nativeLanguageBadge.configure(with: user.nativeLanguage, isNative: true)

        // Location
        locationLabel.text = "📍 \(user.displayLocation ?? user.location ?? "")"

        // Open to Match - simplified display
        // No need to show proficiency requirements since the algorithm already filtered for you
        var openToMatchText = ""

        if !user.openToLanguages.isEmpty {
            // Show languages they're open to match in
            let languageNames = user.openToLanguages.map { $0.name }.joined(separator: ", ")
            openToMatchText = "⭐ Open to Match: \(languageNames)"

            // Show learning languages (that are NOT in open_to_languages)
            let openLanguageCodes = Set(user.openToLanguages.map { $0.code })
            let learningLanguages = user.learningLanguages.filter { !openLanguageCodes.contains($0.language.code) }

            if !learningLanguages.isEmpty {
                let learningNames = learningLanguages.map { $0.language.name }.joined(separator: ", ")
                openToMatchText += "\n📚 Also learning: \(learningNames)"
            }
        }

        openToMatchLabel.text = openToMatchText

        // Bio
        bioLabel.text = user.bio ?? "No bio available"

        // Load photos with signed URLs if needed
        Task {
            do {
                var photoURLs = user.photoURLs

                // Check if photos are storage paths and need signed URLs
                if let firstPhoto = photoURLs.first, !firstPhoto.hasPrefix("http") && !firstPhoto.isEmpty {
                    // Generate signed URLs for all grid photos
                    photoURLs = try await SupabaseService.shared.getSignedPhotoURLs(paths: photoURLs)
                }

                await MainActor.run {
                    self.photoGridView.configure(with: photoURLs)
                }
            } catch {
                print("Failed to load grid photos: \(error)")
                // Fall back to original URLs
                await MainActor.run {
                    self.photoGridView.configure(with: user.photoURLs)
                }
            }
        }

        // Update navigation button states
        updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        // Update button states based on position
        backButton.isEnabled = currentUserIndex > 0
        backButton.alpha = backButton.isEnabled ? 1.0 : 0.3

        forwardButton.isEnabled = currentUserIndex < allUsers.count - 1
        forwardButton.alpha = forwardButton.isEnabled ? 1.0 : 0.3
    }

    // MARK: - Action Button Methods
    @objc private func backButtonTapped() {
        // Go to previous profile
        if currentUserIndex > 0 {
            currentUserIndex -= 1
            user = allUsers[currentUserIndex]
            updateUI()

            // Animate transition
            UIView.transition(with: view, duration: 0.3, options: .transitionCurlDown, animations: nil)
        } else {
            // No more profiles to go back
            showActionFeedback("First Profile", color: .systemOrange)
        }
    }

    @objc private func rejectButtonTapped() {
        // Permanently hide this profile - "Don't show again"
        guard let user = user else { return }

        print("Hiding profile: \(user.firstName)")

        // Save to hidden profiles list
        var hiddenProfiles = UserDefaults.standard.stringArray(forKey: "hiddenProfileIds") ?? []
        if !hiddenProfiles.contains(user.id) {
            hiddenProfiles.append(user.id)
            UserDefaults.standard.set(hiddenProfiles, forKey: "hiddenProfileIds")
        }

        showActionFeedback("Profile Hidden", color: .systemRed)

        // Remove from current user list so it doesn't come back
        allUsers.removeAll { $0.id == user.id }

        // Move to next profile after showing feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if self.currentUserIndex < self.allUsers.count {
                // Update to current index (which is now the next user after removal)
                self.user = self.allUsers[self.currentUserIndex]
                self.updateUI()
                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            } else if self.currentUserIndex > 0 && !self.allUsers.isEmpty {
                // Go to previous user if we were at the end
                self.currentUserIndex = self.allUsers.count - 1
                self.user = self.allUsers[self.currentUserIndex]
                self.updateUI()
                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            } else {
                // No more profiles, go back to Discover (which will reload)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func pinButtonTapped() {
        // Save/pin profile for later without committing to match
        guard let user = user else { return }

        print("Pinned profile: \(user.firstName)")

        // Save to pinned profiles list
        var pinnedProfiles = UserDefaults.standard.stringArray(forKey: "pinnedProfileIds") ?? []
        if !pinnedProfiles.contains(user.id) {
            pinnedProfiles.append(user.id)
            UserDefaults.standard.set(pinnedProfiles, forKey: "pinnedProfileIds")
            showActionFeedback("Saved for Later 📌", color: .systemOrange)
        } else {
            // Already pinned, show different message
            showActionFeedback("Already Saved", color: .systemGray)
        }

        // In real app, would save to backend
        // Pinned profiles can be viewed in Your Matches or a separate Saved tab
    }

    @objc private func likeButtonTapped() {
        // Send match request - commit to matching
        guard let user = user else { return }

        // Check if this is a sample user (ID is not a valid UUID)
        let uuidPattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        let isValidUUID = user.id.range(of: uuidPattern, options: .regularExpression) != nil

        if !isValidUUID {
            // This is a sample user, can't record swipes
            print("⚠️ Cannot match with sample user: \(user.firstName) (ID: \(user.id))")
            showActionFeedback("Demo Profile - Can't Match", color: .systemOrange)
            return
        }

        print("Match request sent to \(user.firstName)")

        // Record swipe in Supabase and check for mutual match
        Task {
            do {
                let didMatch = try await SupabaseService.shared.recordSwipe(
                    swipedUserId: user.id,
                    direction: "right"
                )

                await MainActor.run {
                    if didMatch {
                        // It's a mutual match!
                        print("🎉 IT'S A MATCH with \(user.firstName)!")
                        self.showMatchAnimation()
                    } else {
                        // Swipe recorded but not a match yet
                        self.showActionFeedback("Match Request Sent! 💚", color: .systemGreen)

                        // Move to next profile after showing feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            if self.currentUserIndex < self.allUsers.count - 1 {
                                // Move to next profile
                                self.currentUserIndex += 1
                                self.user = self.allUsers[self.currentUserIndex]
                                self.updateUI()
                                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                            } else {
                                // No more profiles, go back
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error recording swipe: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                    self.showActionFeedback("Error - Try Again", color: .systemRed)
                }
            }
        }
    }

    @objc private func forwardButtonTapped() {
        // Go to next profile
        if currentUserIndex < allUsers.count - 1 {
            currentUserIndex += 1
            user = allUsers[currentUserIndex]
            updateUI()

            // Animate transition
            UIView.transition(with: view, duration: 0.3, options: .transitionCurlUp, animations: nil)
        } else {
            // No more profiles
            showActionFeedback("Last Profile", color: .systemOrange)
        }
    }

    private func showActionFeedback(_ text: String, color: UIColor) {
        let feedbackLabel = UILabel()
        feedbackLabel.text = text
        feedbackLabel.font = .systemFont(ofSize: 28, weight: .bold)
        feedbackLabel.textColor = color
        feedbackLabel.alpha = 0
        feedbackLabel.textAlignment = .center
        feedbackLabel.numberOfLines = 0

        view.addSubview(feedbackLabel)
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            feedbackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            feedbackLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])

        UIView.animate(withDuration: 0.3, animations: {
            feedbackLabel.alpha = 1
            feedbackLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.4, animations: {
                feedbackLabel.alpha = 0
                feedbackLabel.transform = .identity
            }) { _ in
                feedbackLabel.removeFromSuperview()
            }
        }
    }

    private func showMatchAnimation() {
        // Create match overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        overlayView.alpha = 0

        let matchLabel = UILabel()
        matchLabel.text = "It's a Match! 🎉"
        matchLabel.font = .systemFont(ofSize: 42, weight: .bold)
        matchLabel.textColor = .white
        matchLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = "You and \(user?.firstName ?? "they") liked each other!"
        messageLabel.font = .systemFont(ofSize: 20, weight: .medium)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.alpha = 0

        let sendMessageButton = UIButton(type: .system)
        sendMessageButton.setTitle("Send Message", for: .normal)
        sendMessageButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        sendMessageButton.setTitleColor(.white, for: .normal)
        sendMessageButton.backgroundColor = .systemGreen
        sendMessageButton.layer.cornerRadius = 25
        sendMessageButton.alpha = 0
        sendMessageButton.addTarget(self, action: #selector(sendMessageTapped), for: .touchUpInside)

        let keepSwipingButton = UIButton(type: .system)
        keepSwipingButton.setTitle("Keep Browsing", for: .normal)
        keepSwipingButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        keepSwipingButton.setTitleColor(.white, for: .normal)
        keepSwipingButton.alpha = 0
        keepSwipingButton.addTarget(self, action: #selector(keepBrowsingTapped), for: .touchUpInside)

        view.addSubview(overlayView)
        overlayView.addSubview(matchLabel)
        overlayView.addSubview(messageLabel)
        overlayView.addSubview(sendMessageButton)
        overlayView.addSubview(keepSwipingButton)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        matchLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        keepSwipingButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            matchLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            matchLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -60),

            messageLabel.topAnchor.constraint(equalTo: matchLabel.bottomAnchor, constant: 16),
            messageLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),

            sendMessageButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
            sendMessageButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            sendMessageButton.widthAnchor.constraint(equalToConstant: 200),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 50),

            keepSwipingButton.topAnchor.constraint(equalTo: sendMessageButton.bottomAnchor, constant: 16),
            keepSwipingButton.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor)
        ])

        // Animate the match screen
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
        }

        UIView.animate(withDuration: 0.5, delay: 0.2, animations: {
            matchLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                matchLabel.transform = .identity
            }
        }

        UIView.animate(withDuration: 0.3, delay: 0.4) {
            messageLabel.alpha = 1
        }

        UIView.animate(withDuration: 0.3, delay: 0.6) {
            sendMessageButton.alpha = 1
            keepSwipingButton.alpha = 1
        }

        self.matchOverlay = overlayView
    }

    private var matchOverlay: UIView?

    @objc private func sendMessageTapped() {
        // Remove overlay and go to chat
        UIView.animate(withDuration: 0.3, animations: {
            self.matchOverlay?.alpha = 0
        }) { _ in
            self.matchOverlay?.removeFromSuperview()
            self.matchOverlay = nil
            self.chatTapped()
        }
    }

    @objc private func keepBrowsingTapped() {
        // Remove overlay and go to next profile
        UIView.animate(withDuration: 0.3, animations: {
            self.matchOverlay?.alpha = 0
        }) { _ in
            self.matchOverlay?.removeFromSuperview()
            self.matchOverlay = nil

            if self.currentUserIndex < self.allUsers.count - 1 {
                // Move to next profile
                self.currentUserIndex += 1
                self.user = self.allUsers[self.currentUserIndex]
                self.updateUI()
                UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            } else {
                // No more profiles, go back to Discover (which will reload)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func chatTapped() {
        guard let user = user else { return }

        // Use the actual match object if available (from MatchesListViewController)
        // Otherwise create a temporary one (for profiles that aren't matched yet)
        let matchToUse: Match
        if let match = match {
            matchToUse = match
            print("✅ Using real match ID: \(match.id)")
        } else {
            matchToUse = Match(
                id: UUID().uuidString,
                user: user,
                matchedAt: Date(),
                hasNewMessage: false,
                lastMessage: nil,
                lastMessageTime: nil
            )
            print("⚠️ Creating temporary match for unmatched profile")
        }

        let chatVC = ChatViewController(user: user, match: matchToUse)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    // MARK: - Profile Image Tap

    @objc private func profileImageTapped() {
        guard let user = user else { return }

        // Create array with all 7 photos: 6 grid photos + 1 profile image
        var allPhotos = user.photoURLs
        if let profileURL = user.profileImageURL, !profileURL.isEmpty {
            allPhotos.append(profileURL)
        }

        // Get captions if available - ensure we have 7 captions
        var allCaptions = user.photoCaptions ?? []
        while allCaptions.count < allPhotos.count {
            allCaptions.append(nil)
        }

        // Present full-screen photo viewer starting at the profile image (index 6)
        let photoDetailVC = PhotoDetailViewController(
            photoURLs: allPhotos,
            captions: allCaptions,
            startingIndex: min(6, allPhotos.count - 1), // Profile image is 7th photo
            reportableUserId: user.id // Allow reporting this user's photos
        )

        present(photoDetailVC, animated: true)
    }

    // MARK: - PhotoGridViewDelegate

    func photoGridView(_ gridView: PhotoGridView, didTapPhotoAt index: Int, photoURL: String) {
        guard let user = user else { return }

        // Create array with all 7 photos: 6 grid photos + 1 profile image
        var allPhotos = user.photoURLs
        if let profileURL = user.profileImageURL, !profileURL.isEmpty {
            allPhotos.append(profileURL)
        }

        // Get captions if available
        var allCaptions = user.photoCaptions ?? []
        while allCaptions.count < allPhotos.count {
            allCaptions.append(nil)
        }

        // Present full-screen photo viewer
        let photoDetailVC = PhotoDetailViewController(
            photoURLs: allPhotos,
            captions: allCaptions,
            startingIndex: index,
            reportableUserId: user.id // Allow reporting this user's photos
        )

        present(photoDetailVC, animated: true)
    }

    func photoGridView(_ gridView: PhotoGridView, didLongPressPhotoAt index: Int, photoURL: String) {
        // Only allow reporting on other users' profiles (not own profile)
        guard let user = user else { return }

        // Show report options for this photo
        showReportOptions(for: user, photoURL: photoURL)
    }

    // MARK: - Photo Reporting

    private func showReportOptions(for user: User, photoURL: String) {
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
                self?.confirmReport(user: user, photoURL: photoURL, reason: reason)
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

    private func confirmReport(user: User, photoURL: String, reason: String) {
        let confirmAlert = UIAlertController(
            title: "Confirm Report",
            message: "Are you sure you want to report this photo for \"\(reason.lowercased())\"?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Report", style: .destructive) { [weak self] _ in
            self?.submitReport(userId: user.id, photoURL: photoURL, reason: reason)
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
}

// MARK: - UIColor Extension for Hex Colors
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}