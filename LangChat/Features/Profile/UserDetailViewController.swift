import UIKit

class UserDetailViewController: UIViewController {

    var user: User?
    var isMatched: Bool = false
    var allUsers: [User] = []
    var currentUserIndex: Int = 0

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Main profile image (circular, like ProfileViewController)
    private let profileImageView = UIImageView()

    // Name and badges
    private let nameLabel = UILabel()
    private let nativeLanguageBadge = LanguageBadgeView()

    // Language info
    private let aspiringLabel = UILabel()
    private let aspiringLanguagesStack = UIStackView()

    // Photo Grid
    private let photoGridView = PhotoGridView()

    // Action buttons container
    private let actionButtonsContainer = UIView()
    private let backButton = UIButton(type: .system)
    private let rejectButton = UIButton(type: .system)
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
        // Swipe left to reject (pass)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        // Swipe right to like
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
        // Same as reject button
        rejectButtonTapped()
    }

    @objc private func handleSwipeRight() {
        // Same as like button
        likeButtonTapped()
    }

    @objc private func handleSwipeUp() {
        // Same as forward button
        forwardButtonTapped()
    }

    @objc private func handleSwipeDown() {
        // Same as back button
        backButtonTapped()
    }

    private func setupNavigationBar() {
        title = user?.firstName ?? "Profile"
        navigationItem.largeTitleDisplayMode = .never

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
        contentView.addSubview(profileImageView)

        // Name label
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .left
        contentView.addSubview(nameLabel)

        // Native language badge
        contentView.addSubview(nativeLanguageBadge)

        // Aspiring languages
        aspiringLabel.text = "Learning:"
        aspiringLabel.font = .systemFont(ofSize: 16, weight: .regular)
        aspiringLabel.textColor = .secondaryLabel
        contentView.addSubview(aspiringLabel)

        aspiringLanguagesStack.axis = .horizontal
        aspiringLanguagesStack.spacing = 8
        aspiringLanguagesStack.distribution = .fill
        aspiringLanguagesStack.alignment = .center
        contentView.addSubview(aspiringLanguagesStack)

        // Photo grid
        photoGridView.layer.cornerRadius = 12
        photoGridView.clipsToBounds = true
        contentView.addSubview(photoGridView)

        // Action buttons container
        actionButtonsContainer.backgroundColor = .clear
        contentView.addSubview(actionButtonsContainer)

        // Setup action buttons
        setupActionButton(backButton, systemName: "chevron.left", tintColor: .systemGray)
        setupActionButton(rejectButton, systemName: "xmark.circle.fill", tintColor: .systemRed)
        setupActionButton(likeButton, systemName: "heart.circle.fill", tintColor: .systemGreen)
        setupActionButton(forwardButton, systemName: "chevron.right", tintColor: .systemGray)

        actionButtonsContainer.addSubview(backButton)
        actionButtonsContainer.addSubview(rejectButton)
        actionButtonsContainer.addSubview(likeButton)
        actionButtonsContainer.addSubview(forwardButton)

        // Open to match
        openToMatchLabel.font = .systemFont(ofSize: 16, weight: .medium)
        openToMatchLabel.textColor = .systemBlue
        openToMatchLabel.textAlignment = .left
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
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
    }

    private func setupActionButton(_ button: UIButton, systemName: String, tintColor: UIColor) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = tintColor
        button.contentMode = .scaleAspectFit

        // Configure button size
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular, scale: .default)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageBadge.translatesAutoresizingMaskIntoConstraints = false
        aspiringLabel.translatesAutoresizingMaskIntoConstraints = false
        aspiringLanguagesStack.translatesAutoresizingMaskIntoConstraints = false
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
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

            // Location - under native language badge, still beside profile image
            locationLabel.topAnchor.constraint(equalTo: nativeLanguageBadge.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            // Aspiring languages - below profile image
            aspiringLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            aspiringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            aspiringLanguagesStack.topAnchor.constraint(equalTo: aspiringLabel.bottomAnchor, constant: 6),
            aspiringLanguagesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            aspiringLanguagesStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
            aspiringLanguagesStack.heightAnchor.constraint(equalToConstant: 40),

            // Photo grid
            photoGridView.topAnchor.constraint(equalTo: aspiringLanguagesStack.bottomAnchor, constant: 16),
            photoGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoGridView.heightAnchor.constraint(equalTo: photoGridView.widthAnchor, multiplier: 0.67),

            // Action buttons container
            actionButtonsContainer.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 16),
            actionButtonsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionButtonsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionButtonsContainer.heightAnchor.constraint(equalToConstant: 60),

            // Action buttons - evenly spaced
            backButton.leadingAnchor.constraint(equalTo: actionButtonsContainer.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 60),
            backButton.heightAnchor.constraint(equalToConstant: 60),

            rejectButton.centerXAnchor.constraint(equalTo: actionButtonsContainer.centerXAnchor, constant: -40),
            rejectButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            rejectButton.widthAnchor.constraint(equalToConstant: 60),
            rejectButton.heightAnchor.constraint(equalToConstant: 60),

            likeButton.centerXAnchor.constraint(equalTo: actionButtonsContainer.centerXAnchor, constant: 40),
            likeButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 60),
            likeButton.heightAnchor.constraint(equalToConstant: 60),

            forwardButton.trailingAnchor.constraint(equalTo: actionButtonsContainer.trailingAnchor, constant: -20),
            forwardButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 60),
            forwardButton.heightAnchor.constraint(equalToConstant: 60),

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

        // Load profile image
        if let profileImageURL = user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: profileImageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        }

        // Native language badge
        nativeLanguageBadge.configure(with: user.nativeLanguage, isNative: true)

        // Learning languages
        aspiringLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for userLanguage in user.learningLanguages.prefix(3) {
            let badge = LanguageBadgeView()
            badge.configure(with: userLanguage, isNative: false)
            aspiringLanguagesStack.addArrangedSubview(badge)
        }

        // Location
        locationLabel.text = "📍 \(user.displayLocation ?? user.location ?? "")"

        // Open to languages
        if !user.openToLanguages.isEmpty {
            let languages = user.openToLanguages.map { $0.name }.joined(separator: ", ")
            openToMatchLabel.text = "⭐ Open to Match: \(languages)"
        } else if let practiceLanguages = user.practiceLanguages, !practiceLanguages.isEmpty {
            let languages = practiceLanguages.map { $0.language.name }.joined(separator: ", ")
            openToMatchLabel.text = "🗨️ Want to Match In: \(languages)"
        } else {
            openToMatchLabel.text = ""
        }

        // Bio
        bioLabel.text = user.bio ?? "No bio available"

        // Load photos
        photoGridView.configure(with: user.photoURLs)

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
        // User is not interested in this profile
        print("Not interested in \(user?.firstName ?? "user")")
        showActionFeedback("Not Interested", color: .systemRed)

        // Move to next profile after showing feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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

    @objc private func likeButtonTapped() {
        // User wants to match with this profile
        print("Wants to match with \(user?.firstName ?? "user")")

        // Check if it's a mutual match (in real app, would check backend)
        let isMatch = Bool.random() // Simulate 50% chance of mutual match for demo

        if isMatch {
            showMatchAnimation()
        } else {
            showActionFeedback("Match Request Sent! 💚", color: .systemGreen)

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
                // No more profiles, go back
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func chatTapped() {
        guard let user = user else { return }

        let chatVC = ChatViewController(user: user, match: Match(
            id: UUID().uuidString,
            user: user,
            matchedAt: Date(),
            hasNewMessage: false,
            lastMessage: nil,
            lastMessageTime: nil
        ))
        navigationController?.pushViewController(chatVC, animated: true)
    }
}