import UIKit

class ProfileViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Main profile image (circular, like in MatchCardView)
    private let profileImageView = UIImageView()

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
        loadProfileData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNavigationBar() {
        // No title needed - it's clear from the tab bar
        navigationController?.navigationBar.prefersLargeTitles = false

        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(editProfileTapped)
        )

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )

        let languageLabButton = UIBarButtonItem(
            image: UIImage(systemName: "flask"),
            style: .plain,
            target: self,
            action: #selector(languageLabTapped)
        )

        navigationItem.rightBarButtonItems = [settingsButton, editButton]
        navigationItem.leftBarButtonItem = languageLabButton
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

            // Main profile image - LEFT ALIGNED, moved up to use available space
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

            // Open to match
            openToMatchLabel.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 12),
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

    private func loadProfileData() {
        // Load from UserDefaults
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
        bioLabel.text = UserDefaults.standard.string(forKey: "bio") ?? "Tap Edit Profile to add your bio"

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

        // Load photos
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "user"
        let photoURLs = ImageService.shared.generatePhotoURLs(for: userId, count: 6)
        photoGridView.configure(with: photoURLs)
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    @objc private func editProfileTapped() {
        let editProfileVC = EditProfileViewController()
        let navController = UINavigationController(rootViewController: editProfileVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func languageLabTapped() {
        let languageLabVC = LanguageLabViewController()
        navigationController?.pushViewController(languageLabVC, animated: true)
    }

    @objc private func profileUpdated(_ notification: Notification) {
        loadProfileData()
    }
}