import UIKit
import PhotosUI

class ProfileViewController: UIViewController, PhotoGridViewDelegate {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Current profile data for photo handling
    private var currentProfile: ProfileResponse?
    private var currentPhotoURLs: [String] = []
    private var currentPhotoCaptions: [String?] = []
    private var currentPhotoBlurSettings: [Bool] = []  // Per-photo blur settings
    private var selectedPhotoIndex: Int = 0  // Track which slot we're adding to

    // Main profile image (circular, like in MatchCardView)
    private let profileImageView = UIImageView()
    private let profileImageEditBadge = UIView()  // Edit indicator
    private let profileImageBlurBadge = UIView()  // Blur until match indicator
    private let profileImageBlurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))  // Blur preview

    // Name and badges
    private let nameLabel = UILabel()
    private let nativeLanguageBadge = LanguageBadgeView()

    // Language info
    private let aspiringLabel = UILabel()
    private let aspiringLanguagesStack = UIStackView()

    // Photo Grid
    private let photoGridView = PhotoGridView()

    // Open to match
    private let openToMatchLabel = UILabel()

    // About section
    private let aboutLabel = UILabel()
    private let bioLabel = UILabel()
    private let bioTextView = UITextView()
    private let bioEditHintLabel = UILabel()
    private var bioLabelBottomConstraint: NSLayoutConstraint?
    private var bioTextViewHeightConstraint: NSLayoutConstraint?
    private var isEditingBio = false

    // Location
    private let locationLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupConstraints()
        loadProfileData()

        // Listen for profile updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(profileUpdated(_:)),
            name: .userProfileUpdated,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure navigation bar is visible (in case coming back from LanguageLab)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadProfileData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNavigationBar() {
        // No title needed - it's clear from the tab bar
        navigationController?.navigationBar.prefersLargeTitles = false

        // Left side: Language Lab, Welcome Screen
        let languageLabButton = UIBarButtonItem(
            image: UIImage(systemName: "flask"),
            style: .plain,
            target: self,
            action: #selector(languageLabTapped)
        )

        let welcomeButton = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            style: .plain,
            target: self,
            action: #selector(welcomeScreenTapped)
        )

        // Right side: App Tutorial, Settings
        let tutorialButton = UIBarButtonItem(
            image: UIImage(systemName: "questionmark.circle"),
            style: .plain,
            target: self,
            action: #selector(tutorialTapped)
        )

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )

        navigationItem.leftBarButtonItems = [languageLabButton, welcomeButton]
        navigationItem.rightBarButtonItems = [settingsButton, tutorialButton]
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Main circular profile image (like in MatchCardView)
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

        // Add tap gesture to change profile photo
        let profileImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(profileImageTapGesture)

        // Add blur effect view for preview (circular, matches profile image)
        profileImageBlurEffectView.layer.cornerRadius = 60
        profileImageBlurEffectView.clipsToBounds = true
        profileImageBlurEffectView.isHidden = true
        profileImageBlurEffectView.isUserInteractionEnabled = false
        contentView.addSubview(profileImageBlurEffectView)

        // Edit badge on profile image (small camera icon)
        profileImageEditBadge.backgroundColor = .systemBlue
        profileImageEditBadge.layer.cornerRadius = 16
        profileImageEditBadge.layer.borderWidth = 2
        profileImageEditBadge.layer.borderColor = UIColor.white.cgColor
        profileImageEditBadge.clipsToBounds = true
        contentView.addSubview(profileImageEditBadge)

        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        profileImageEditBadge.addSubview(cameraIcon)

        NSLayoutConstraint.activate([
            cameraIcon.centerXAnchor.constraint(equalTo: profileImageEditBadge.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: profileImageEditBadge.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 16),
            cameraIcon.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Blur badge on profile image (eye.slash icon - shows when photo is set to blur until match)
        profileImageBlurBadge.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        profileImageBlurBadge.layer.cornerRadius = 14
        profileImageBlurBadge.layer.borderWidth = 2
        profileImageBlurBadge.layer.borderColor = UIColor.white.cgColor
        profileImageBlurBadge.clipsToBounds = true
        profileImageBlurBadge.isHidden = true  // Hidden by default
        profileImageBlurBadge.isUserInteractionEnabled = true
        contentView.addSubview(profileImageBlurBadge)

        // Add tap gesture to blur badge to preview blur effect
        let blurBadgeTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageBlurBadgeTapped))
        profileImageBlurBadge.addGestureRecognizer(blurBadgeTapGesture)

        let blurIcon = UIImageView(image: UIImage(systemName: "eye.slash.fill"))
        blurIcon.tintColor = .white
        blurIcon.contentMode = .scaleAspectFit
        blurIcon.translatesAutoresizingMaskIntoConstraints = false
        profileImageBlurBadge.addSubview(blurIcon)

        NSLayoutConstraint.activate([
            blurIcon.centerXAnchor.constraint(equalTo: profileImageBlurBadge.centerXAnchor),
            blurIcon.centerYAnchor.constraint(equalTo: profileImageBlurBadge.centerYAnchor),
            blurIcon.widthAnchor.constraint(equalToConstant: 14),
            blurIcon.heightAnchor.constraint(equalToConstant: 14)
        ])

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
        photoGridView.delegate = self
        photoGridView.isEditable = true  // User can add photos to their own profile
        contentView.addSubview(photoGridView)

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
        bioLabel.isUserInteractionEnabled = true
        contentView.addSubview(bioLabel)

        // Add long press gesture to edit bio
        let bioLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(bioLongPressed(_:)))
        bioLongPressGesture.minimumPressDuration = 0.5
        bioLabel.addGestureRecognizer(bioLongPressGesture)

        // Bio text view (for inline editing)
        bioTextView.font = .systemFont(ofSize: 16, weight: .regular)
        bioTextView.textColor = .label
        bioTextView.backgroundColor = .secondarySystemBackground
        bioTextView.layer.cornerRadius = 12
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.borderColor = UIColor.systemBlue.cgColor
        bioTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        bioTextView.isScrollEnabled = true
        bioTextView.isHidden = true
        bioTextView.delegate = self
        contentView.addSubview(bioTextView)

        // Edit hint label
        bioEditHintLabel.text = "Long press to edit"
        bioEditHintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bioEditHintLabel.textColor = .tertiaryLabel
        bioEditHintLabel.textAlignment = .right
        contentView.addSubview(bioEditHintLabel)

        // Location
        locationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        locationLabel.textColor = .label
        locationLabel.textAlignment = .left
        contentView.addSubview(locationLabel)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageEditBadge.translatesAutoresizingMaskIntoConstraints = false
        profileImageBlurBadge.translatesAutoresizingMaskIntoConstraints = false
        profileImageBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageBadge.translatesAutoresizingMaskIntoConstraints = false
        aspiringLabel.translatesAutoresizingMaskIntoConstraints = false
        aspiringLanguagesStack.translatesAutoresizingMaskIntoConstraints = false
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        openToMatchLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        bioEditHintLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        // Create the bottom constraint for bioLabel (will be deactivated when editing)
        bioLabelBottomConstraint = bioLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)

        // Create height constraint for bioTextView
        bioTextViewHeightConstraint = bioTextView.heightAnchor.constraint(equalToConstant: 150)

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

            // Main profile image - LEFT ALIGNED, moved up to use available space
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            // Blur effect view - overlay on profile image
            profileImageBlurEffectView.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            profileImageBlurEffectView.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            profileImageBlurEffectView.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            profileImageBlurEffectView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor),

            // Edit badge - bottom right of profile image
            profileImageEditBadge.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -4),
            profileImageEditBadge.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: -4),
            profileImageEditBadge.widthAnchor.constraint(equalToConstant: 32),
            profileImageEditBadge.heightAnchor.constraint(equalToConstant: 32),

            // Blur badge - top left of profile image (opposite corner from edit badge)
            profileImageBlurBadge.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 4),
            profileImageBlurBadge.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor, constant: 4),
            profileImageBlurBadge.widthAnchor.constraint(equalToConstant: 28),
            profileImageBlurBadge.heightAnchor.constraint(equalToConstant: 28),

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

            // Open to match
            openToMatchLabel.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 12),
            openToMatchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            openToMatchLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // About section header with hint
            aboutLabel.topAnchor.constraint(equalTo: openToMatchLabel.bottomAnchor, constant: 20),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            bioEditHintLabel.centerYAnchor.constraint(equalTo: aboutLabel.centerYAnchor),
            bioEditHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Bio label (shown when not editing)
            bioLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 6),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bioLabelBottomConstraint!,

            // Bio text view (shown when editing)
            bioTextView.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 6),
            bioTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bioTextViewHeightConstraint!
        ])
    }

    private func loadProfileData() {
        // Load profile data from Supabase
        Task {
            do {
                let profile = try await SupabaseService.shared.getCurrentProfile()
                await MainActor.run {
                    updateUIWithProfile(profile)
                }
            } catch {
                print("❌ Error loading profile from Supabase: \(error)")
                // Fall back to UserDefaults if Supabase fails
                await MainActor.run {
                    loadProfileDataFromUserDefaults()
                }
            }
        }
    }

    private func updateUIWithProfile(_ profile: ProfileResponse) {
        // Store profile for photo handling
        self.currentProfile = profile
        self.currentPhotoCaptions = profile.photoCaptions ?? []
        self.currentPhotoBlurSettings = profile.photoBlurSettings ?? []

        // Name
        let firstName = profile.firstName
        let lastName = profile.lastName ?? ""
        nameLabel.text = lastName.isEmpty ? firstName : "\(firstName) \(lastName)"

        // Bio
        bioLabel.text = profile.bio ?? "Long press to add your bio"

        // Location
        let location = profile.location ?? "Add location"
        if location != "Add location" {
            locationLabel.text = "📍 \(location)"
        } else {
            locationLabel.text = "📍 Add location"
        }

        // Native language badge
        if let nativeLang = Language.allCases.first(where: { $0.code == profile.nativeLanguage || $0.name.lowercased() == profile.nativeLanguage.lowercased() }) {
            let nativeUserLanguage = UserLanguage(language: nativeLang, proficiency: .native, isNative: true)
            nativeLanguageBadge.configure(with: nativeUserLanguage, isNative: true)
        }

        // Learning languages
        aspiringLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let learningLanguages = profile.learningLanguages {
            for langString in learningLanguages.prefix(3) {
                if let lang = Language.allCases.first(where: { $0.code == langString || $0.name.lowercased() == langString.lowercased() }) {
                    let userLanguage = UserLanguage(language: lang, proficiency: .intermediate, isNative: false)
                    let badge = LanguageBadgeView()
                    badge.configure(with: userLanguage, isNative: false)
                    aspiringLanguagesStack.addArrangedSubview(badge)
                }
            }
        }

        // Open to languages (using learning languages for now)
        if let learningLanguages = profile.learningLanguages, !learningLanguages.isEmpty {
            openToMatchLabel.text = "🗨️ Learning: \(learningLanguages.joined(separator: ", "))"
        } else {
            openToMatchLabel.text = ""
        }

        // Load profile image - specifically use index 6 (the dedicated profile photo)
        // Do NOT fall back to grid photos - they are independent
        if let photos = profile.profilePhotos,
           photos.count > 6,
           !photos[6].isEmpty {
            loadProfileImage(from: photos[6])
            // Show blur badge if profile photo (index 6) is set to blur
            let isProfilePhotoBlurred = currentPhotoBlurSettings.count > 6 ? currentPhotoBlurSettings[6] : false
            profileImageBlurBadge.isHidden = !isProfilePhotoBlurred
        } else {
            // Show placeholder with "add photo" style
            profileImageView.image = UIImage(systemName: "person.crop.circle.badge.plus")
            profileImageView.tintColor = .systemGray3
            profileImageView.contentMode = .scaleAspectFit
            profileImageBlurBadge.isHidden = true  // No photo, no blur badge
        }

        // Load photo grid with signed URLs
        loadPhotoGrid(from: profile.profilePhotos ?? [])
    }

    private func loadProfileImage(from path: String) {
        // Reset contentMode for actual photos (was changed to scaleAspectFit for placeholder)
        profileImageView.contentMode = .scaleAspectFill

        // Check if it's a storage path or already a URL
        if path.hasPrefix("http") {
            // Already a URL
            ImageService.shared.loadImage(
                from: path,
                into: profileImageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        } else if !path.isEmpty {
            // It's a storage path - get signed URL
            Task {
                do {
                    let signedURL = try await SupabaseService.shared.getSignedPhotoURL(path: path)
                    await MainActor.run {
                        ImageService.shared.loadImage(
                            from: signedURL,
                            into: self.profileImageView,
                            placeholder: UIImage(systemName: "person.fill")
                        )
                    }
                } catch {
                    print("❌ Error getting signed URL for profile image: \(error)")
                }
            }
        }
    }

    private func loadPhotoGrid(from paths: [String]) {
        // Get first 6 photos for the grid
        let gridPaths = Array(paths.prefix(6))

        Task {
            do {
                let signedURLs = try await SupabaseService.shared.getSignedPhotoURLs(paths: gridPaths)
                await MainActor.run {
                    // Store signed URLs for photo handling
                    self.currentPhotoURLs = signedURLs
                    self.photoGridView.configure(with: signedURLs)
                    // Set blur settings for the grid (first 6 photos)
                    let gridBlurSettings = Array(self.currentPhotoBlurSettings.prefix(6))
                    self.photoGridView.setBlurSettings(gridBlurSettings)
                }
            } catch {
                print("❌ Error getting signed URLs for photo grid: \(error)")
                // Show empty grid on error
                await MainActor.run {
                    self.currentPhotoURLs = []
                    self.photoGridView.configure(with: [])
                }
            }
        }
    }

    private func loadProfileDataFromUserDefaults() {
        // Fallback: Load from UserDefaults
        let firstName = UserDefaults.standard.string(forKey: "firstName") ?? "Your"
        let lastName = UserDefaults.standard.string(forKey: "lastName") ?? "Name"
        nameLabel.text = "\(firstName) \(lastName)"

        // Load profile image
        if let profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL"),
           !profileImageURL.isEmpty {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: profileImageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        }

        // Load bio
        bioLabel.text = UserDefaults.standard.string(forKey: "bio") ?? "Long press to add your bio"

        // Load location and privacy setting
        let location = UserDefaults.standard.string(forKey: "location") ?? "Add location"
        let showCity = UserDefaults.standard.bool(forKey: "showCityInProfile")

        if location != "Add location" {
            if showCity {
                locationLabel.text = "📍 \(location)"
            } else {
                // Extract country from "City, Country" format
                let components = location.components(separatedBy: ",")
                if components.count > 1 {
                    locationLabel.text = "📍 \(components.last!.trimmingCharacters(in: .whitespaces))"
                } else {
                    locationLabel.text = "📍 \(location)"
                }
            }
        } else {
            locationLabel.text = "📍 Add location"
        }

        // Load language data
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {

            // Native language badge
            nativeLanguageBadge.configure(with: decoded.nativeLanguage, isNative: true)

            // Learning languages
            aspiringLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for userLanguage in decoded.learningLanguages.prefix(3) {
                let badge = LanguageBadgeView()
                badge.configure(with: userLanguage, isNative: false)
                aspiringLanguagesStack.addArrangedSubview(badge)
            }

            // Open to languages
            if !decoded.openToLanguages.isEmpty {
                let languages = decoded.openToLanguages.map { $0.name }.joined(separator: ", ")
                openToMatchLabel.text = "⭐ Open to Match: \(languages)"
            } else if let practiceLanguages = decoded.practiceLanguages, !practiceLanguages.isEmpty {
                let languages = practiceLanguages.map { $0.language.name }.joined(separator: ", ")
                openToMatchLabel.text = "🗨️ Want to Match In: \(languages)"
            } else {
                openToMatchLabel.text = ""
            }
        }

        // Show empty photo grid instead of random placeholders
        photoGridView.configure(with: [])
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    @objc private func languageLabTapped() {
        let languageLabVC = LanguageLabViewController()
        navigationController?.pushViewController(languageLabVC, animated: true)
    }

    @objc private func welcomeScreenTapped() {
        let carouselVC = OnboardingCarouselViewController()
        carouselVC.isViewingFromProfile = true
        carouselVC.modalPresentationStyle = .fullScreen
        present(carouselVC, animated: true)
    }

    @objc private func tutorialTapped() {
        let tutorialVC = TutorialViewController()
        let navController = UINavigationController(rootViewController: tutorialVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func profileUpdated(_ notification: Notification) {
        loadProfileData()
    }

    @objc private func profileImageTapped() {
        // Show options for the circular profile photo (stored at index 6)
        let alertController = UIAlertController(
            title: "Profile Photo",
            message: "This is your main profile photo that appears in matches",
            preferredStyle: .actionSheet
        )

        alertController.addAction(UIAlertAction(title: "Change Photo", style: .default) { [weak self] _ in
            self?.changeProfilePhoto()
        })

        // Check if there's already a profile photo at index 6
        if let profile = currentProfile,
           let photos = profile.profilePhotos,
           photos.count > 6,
           !photos[6].isEmpty {

            // Blur Until Match option for profile photo (index 6)
            let isBlurred = currentPhotoBlurSettings.count > 6 ? currentPhotoBlurSettings[6] : false
            let blurTitle = isBlurred ? "✓ Blur Until Match" : "Blur Until Match"

            alertController.addAction(UIAlertAction(title: blurTitle, style: .default) { [weak self] _ in
                self?.togglePhotoBlur(at: 6)
            })

            alertController.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
                self?.removeProfilePhoto()
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = profileImageView
            popoverController.sourceRect = profileImageView.bounds
        }

        present(alertController, animated: true)
    }

    private func changeProfilePhoto() {
        // Set index to 6 for the profile photo slot
        selectedPhotoIndex = 6

        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func removeProfilePhoto() {
        guard let profile = currentProfile,
              var photos = profile.profilePhotos,
              photos.count > 6 else { return }

        // Clear the profile photo at index 6
        photos[6] = ""

        Task {
            do {
                try await SupabaseService.shared.updateUserPhotos(photoURLs: photos)
                await MainActor.run {
                    self.loadProfileData()
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                }
            } catch {
                print("❌ Error removing profile photo: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to remove profile photo. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Bio Editing

    @objc private func bioLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard !isEditingBio else { return }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        startEditingBio()
    }

    private func startEditingBio() {
        isEditingBio = true

        let currentBio = currentProfile?.bio ?? ""
        let placeholderText = "Long press to add your bio"

        // Set text view content (don't show placeholder as actual text)
        bioTextView.text = currentBio == placeholderText ? "" : currentBio

        // Update UI
        UIView.animate(withDuration: 0.25) {
            self.bioLabel.alpha = 0
            self.bioTextView.alpha = 1
            self.bioTextView.isHidden = false
            self.bioEditHintLabel.text = "Tap outside to save"
            self.bioEditHintLabel.textColor = .systemBlue
        } completion: { _ in
            self.bioLabel.isHidden = true
        }

        // Update constraints
        bioLabelBottomConstraint?.isActive = false
        let textViewBottomConstraint = bioTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        textViewBottomConstraint.isActive = true

        // Add Done button to navigation bar
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneEditingBioTapped))
        navigationItem.rightBarButtonItems?.insert(doneButton, at: 0)

        // Focus text view
        bioTextView.becomeFirstResponder()

        // Scroll to make bio visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let rect = self.bioTextView.convert(self.bioTextView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    @objc private func doneEditingBioTapped() {
        finishEditingBio()
    }

    private func finishEditingBio() {
        guard isEditingBio else { return }

        let newBio = bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Dismiss keyboard
        bioTextView.resignFirstResponder()

        // Save the bio
        saveBio(newBio)

        // Update UI back to label mode
        UIView.animate(withDuration: 0.25) {
            self.bioLabel.alpha = 1
            self.bioTextView.alpha = 0
            self.bioLabel.isHidden = false
            self.bioEditHintLabel.text = "Long press to edit"
            self.bioEditHintLabel.textColor = .tertiaryLabel
        } completion: { _ in
            self.bioTextView.isHidden = true
        }

        // Update constraints
        bioLabelBottomConstraint?.isActive = true

        // Remove Done button from navigation bar
        if let rightItems = navigationItem.rightBarButtonItems,
           let doneIndex = rightItems.firstIndex(where: { $0.title == "Done" }) {
            var items = rightItems
            items.remove(at: doneIndex)
            navigationItem.rightBarButtonItems = items
        }

        isEditingBio = false
    }

    private func saveBio(_ bio: String) {
        Task {
            do {
                try await SupabaseService.shared.updateUserBio(bio: bio)
                await MainActor.run {
                    // Update local state
                    self.bioLabel.text = bio.isEmpty ? "Long press to add your bio" : bio

                    // Update UserDefaults as fallback
                    UserDefaults.standard.set(bio, forKey: "bio")

                    // Success feedback
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)

                    // Notify other parts of the app
                    NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                }
            } catch {
                print("❌ Error saving bio: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save your bio. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - PhotoGridViewDelegate

    func photoGridView(_ gridView: PhotoGridView, didTapPhotoAt index: Int, photoURL: String) {
        // Present full-screen photo viewer with all photos
        guard !currentPhotoURLs.isEmpty else { return }

        // Ensure captions array matches photos count
        var captions = currentPhotoCaptions
        while captions.count < currentPhotoURLs.count {
            captions.append(nil)
        }

        let photoDetailVC = PhotoDetailViewController(
            photoURLs: currentPhotoURLs,
            captions: captions,
            startingIndex: index,
            reportableUserId: nil,
            isOwnProfile: true // Enable edit options
        )

        // Handle caption updates
        photoDetailVC.onCaptionUpdated = { [weak self] index, caption in
            if index < self?.currentPhotoCaptions.count ?? 0 {
                self?.currentPhotoCaptions[index] = caption
            }
        }

        present(photoDetailVC, animated: true)
    }

    func photoGridView(_ gridView: PhotoGridView, didLongPressPhotoAt index: Int, photoURL: String) {
        // Show edit options for own profile photos
        showPhotoEditOptions(at: index, photoURL: photoURL)
    }

    func photoGridView(_ gridView: PhotoGridView, didTapEmptySlotAt index: Int) {
        // User tapped on empty slot - open photo picker to add a photo
        changePhoto(at: index)
    }

    // MARK: - Photo Edit Options (Own Profile)

    private func showPhotoEditOptions(at index: Int, photoURL: String) {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alertController.addAction(UIAlertAction(title: "Change Photo", style: .default) { [weak self] _ in
            self?.changePhoto(at: index)
        })

        // Only show additional options if there's a photo
        if !photoURL.isEmpty {
            let currentCaption = index < currentPhotoCaptions.count ? currentPhotoCaptions[index] : nil
            let captionTitle = currentCaption?.isEmpty == false ? "Edit Caption" : "Add Caption"

            alertController.addAction(UIAlertAction(title: captionTitle, style: .default) { [weak self] _ in
                self?.editCaption(at: index, currentCaption: currentCaption)
            })

            // Blur Until Match option
            let isBlurred = index < currentPhotoBlurSettings.count ? currentPhotoBlurSettings[index] : false
            let blurTitle = isBlurred ? "✓ Blur Until Match" : "Blur Until Match"

            alertController.addAction(UIAlertAction(title: blurTitle, style: .default) { [weak self] _ in
                self?.togglePhotoBlur(at: index)
            })

            alertController.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
                self?.removePhoto(at: index)
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alertController, animated: true)
    }

    private func changePhoto(at index: Int) {
        // Open camera roll directly
        selectedPhotoIndex = index

        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func editCaption(at index: Int, currentCaption: String?) {
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
            guard let caption = alertController.textFields?.first?.text else { return }
            self?.saveCaption(caption, at: index)
        })

        present(alertController, animated: true)
    }

    private func saveCaption(_ caption: String, at index: Int) {
        // Update captions array
        var captions = currentPhotoCaptions
        while captions.count <= index {
            captions.append(nil)
        }
        captions[index] = caption.isEmpty ? nil : caption

        // Save to Supabase
        Task {
            do {
                try await SupabaseService.shared.updatePhotoCaptions(captions: captions)
                await MainActor.run {
                    self.currentPhotoCaptions = captions
                    // Show success feedback
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

    private func removePhoto(at index: Int) {
        let confirmAlert = UIAlertController(
            title: "Remove Photo",
            message: "Are you sure you want to remove this photo?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.performRemovePhoto(at: index)
        })

        present(confirmAlert, animated: true)
    }

    private func performRemovePhoto(at index: Int) {
        guard let profile = currentProfile,
              var photos = profile.profilePhotos else { return }

        // Clear the photo at this index (set to empty string)
        if index < photos.count {
            photos[index] = ""
        }

        // Save to Supabase
        Task {
            do {
                try await SupabaseService.shared.updateUserPhotos(photoURLs: photos)
                await MainActor.run {
                    // Reload profile to reflect changes
                    self.loadProfileData()
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                }
            } catch {
                print("❌ Error removing photo: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to remove photo. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func togglePhotoBlur(at index: Int) {
        // Toggle the blur setting for this photo
        var blurSettings = currentPhotoBlurSettings

        // Ensure array is large enough
        while blurSettings.count <= index {
            blurSettings.append(false)
        }

        // Toggle the value
        blurSettings[index] = !blurSettings[index]

        // Save to Supabase
        Task {
            do {
                try await SupabaseService.shared.updatePhotoBlurSettings(blurSettings: blurSettings)
                await MainActor.run {
                    self.currentPhotoBlurSettings = blurSettings

                    // Cache to UserDefaults for quick access in discovery screens
                    UserDefaults.standard.set(blurSettings, forKey: "photoBlurSettings")

                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)

                    // Update blur indicators
                    self.updateBlurIndicators()

                    // Show confirmation
                    let message = blurSettings[index]
                        ? "Photo will be blurred until you match"
                        : "Photo will be visible to everyone"
                    self.showToast(message: message)
                }
            } catch {
                print("❌ Error updating blur setting: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to update blur setting. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func updateBlurIndicators() {
        // Update photo grid blur indicators
        let gridBlurSettings = Array(currentPhotoBlurSettings.prefix(6))
        photoGridView.setBlurSettings(gridBlurSettings)

        // Update profile photo blur badge (index 6)
        let isProfilePhotoBlurred = currentPhotoBlurSettings.count > 6 ? currentPhotoBlurSettings[6] : false
        let hasProfilePhoto = currentProfile?.profilePhotos?.count ?? 0 > 6 &&
                              !(currentProfile?.profilePhotos?[6].isEmpty ?? true)
        profileImageBlurBadge.isHidden = !(isProfilePhotoBlurred && hasProfilePhoto)
    }

    @objc private func profileImageBlurBadgeTapped() {
        // Show temporary blur preview on profile photo
        showProfilePhotoBlurPreview()
    }

    /// Shows a temporary blur effect on the profile photo
    private func showProfilePhotoBlurPreview() {
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        // Show blur with animation
        profileImageBlurEffectView.alpha = 0
        profileImageBlurEffectView.isHidden = false

        UIView.animate(withDuration: 0.2) {
            self.profileImageBlurEffectView.alpha = 1
        }

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.profileImageBlurEffectView.alpha = 0
            } completion: { _ in
                self?.profileImageBlurEffectView.isHidden = true
            }
        }
    }

    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0

        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        // Add padding
        toastLabel.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let result = results.first else { return }

        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Uploading Photo", message: "Please wait...", preferredStyle: .alert)
        present(loadingAlert, animated: true)

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self,
                  let originalImage = object as? UIImage else {
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true)
                }
                return
            }

            Task {
                do {
                    // Resize image to max 1200px to reduce memory usage and upload size
                    // This prevents crashes on devices with high-resolution camera photos
                    let resizedImage = self.resizeImage(originalImage, maxDimension: 1200)

                    // Compress image to JPEG with moderate quality
                    guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                        throw NSError(domain: "PhotoUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
                    }

                    // Get user ID
                    guard let userId = SupabaseService.shared.currentUserId?.uuidString else {
                        throw NSError(domain: "PhotoUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
                    }

                    // Upload to Supabase storage
                    let storagePath = try await SupabaseService.shared.uploadPhoto(
                        imageData,
                        userId: userId,
                        photoIndex: self.selectedPhotoIndex
                    )

                    // Update the photo array using storage paths (not signed URLs)
                    var photos = self.currentProfile?.profilePhotos ?? []
                    while photos.count <= self.selectedPhotoIndex {
                        photos.append("")
                    }
                    photos[self.selectedPhotoIndex] = storagePath

                    // Save to Supabase
                    try await SupabaseService.shared.updateUserPhotos(photoURLs: photos)

                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            // Reload profile to show the new photo
                            self.loadProfileData()

                            let feedback = UINotificationFeedbackGenerator()
                            feedback.notificationOccurred(.success)
                        }
                    }

                    print("✅ Photo uploaded to slot \(self.selectedPhotoIndex): \(storagePath)")

                } catch {
                    print("❌ Failed to upload photo: \(error)")
                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            let alert = UIAlertController(
                                title: "Upload Failed",
                                message: "Could not upload photo. Please try again.",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    /// This significantly reduces memory usage for high-resolution photos
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

// MARK: - UITextViewDelegate
extension ProfileViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == bioTextView && isEditingBio {
            finishEditingBio()
        }
    }
}