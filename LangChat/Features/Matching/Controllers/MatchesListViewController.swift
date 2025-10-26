import UIKit
import Supabase

class MatchesListViewController: UIViewController {

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var matches: [Match] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadMatches()
    }

    private func setupNavigationBar() {
        title = "Your Matches"
        navigationController?.navigationBar.prefersLargeTitles = true

        let notificationButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(notificationsTapped)
        )
        navigationItem.rightBarButtonItem = notificationButton
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MatchCollectionViewCell.self, forCellWithReuseIdentifier: "MatchCell")
        collectionView.register(BotPracticeCardCell.self, forCellWithReuseIdentifier: "BotPracticeCard")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadMatches() {
        // Load real matches from Supabase
        Task {
            do {
                print("📥 Loading matches from Supabase...")
                let matchResponses = try await SupabaseService.shared.getMatches()
                print("✅ Loaded \(matchResponses.count) matches from Supabase")

                // Log all match IDs
                for mr in matchResponses {
                    print("  📋 Match ID from DB: \(mr.id)")
                }

                guard let currentUserId = SupabaseService.shared.currentUserId?.uuidString else {
                    print("❌ No current user ID")
                    return
                }

                // Convert MatchResponse to Match with User objects
                var loadedMatches: [Match] = []

                for matchResponse in matchResponses {
                    print("🔍 Processing match: \(matchResponse.id)")
                    print("   user1_id: \(matchResponse.user1Id)")
                    print("   user2_id: \(matchResponse.user2Id)")
                    print("   current user: \(currentUserId)")

                    // Determine which user is the "other" user (not the current user)
                    // Use case-insensitive comparison for UUIDs
                    let otherUserId = matchResponse.user1Id.lowercased() == currentUserId.lowercased() ? matchResponse.user2Id : matchResponse.user1Id
                    print("   👉 Other user ID: \(otherUserId)")

                    // Fetch the other user's profile from Supabase
                    do {
                        let profile = try await SupabaseService.shared.client.database
                            .from("profiles")
                            .select()
                            .eq("id", value: otherUserId)
                            .single()
                            .execute()
                            .value as ProfileResponse

                        print("📥 Loaded profile: \(profile.firstName) (\(profile.email)) - ID: \(profile.id)")

                        // Convert ProfileResponse to User
                        let user = convertProfileToUser(profile)
                        print("👤 Converted to User: \(user.firstName) - ID: \(user.id)")

                        // Create Match
                        let match = Match(
                            id: matchResponse.id,
                            user: user,
                            matchedAt: ISO8601DateFormatter().date(from: matchResponse.matchedAt) ?? Date(),
                            hasNewMessage: false, // TODO: Check for unread messages
                            lastMessage: "Start chatting!",
                            lastMessageTime: ISO8601DateFormatter().date(from: matchResponse.matchedAt) ?? Date()
                        )

                        print("✅ Created Match object with ID: \(match.id)")
                        loadedMatches.append(match)
                        print("✅ Loaded match with \(user.firstName)")
                    } catch {
                        print("❌ Failed to load profile for user \(otherUserId): \(error)")
                    }
                }

                await MainActor.run {
                    self.matches = loadedMatches
                    self.collectionView.reloadData()
                    print("✅ Displayed \(loadedMatches.count) matches")
                }

            } catch {
                print("❌ Failed to load matches: \(error)")
                // Fallback to empty state or show error
                await MainActor.run {
                    self.matches = []
                    self.collectionView.reloadData()
                }
            }
        }
    }

    // Helper function to convert ProfileResponse to User
    private func convertProfileToUser(_ profile: ProfileResponse) -> User {
        // Parse learning languages
        let learningLanguages: [UserLanguage] = (profile.learningLanguages ?? []).compactMap { langName in
            guard let language = Language.from(name: langName) else { return nil }
            return UserLanguage(language: language, proficiency: .intermediate, isNative: false)
        }

        // Parse native language
        let nativeLanguage: Language = Language.from(name: profile.nativeLanguage) ?? .english

        // Parse matching preferences
        let allowNonNativeMatches = profile.allowNonNativeMatches ?? false
        let minProficiencyLevel = parseProficiencyLevel(profile.minProficiencyLevel) ?? .beginner
        let maxProficiencyLevel = parseProficiencyLevel(profile.maxProficiencyLevel) ?? .advanced

        return User(
            id: profile.id,
            username: profile.email.split(separator: "@").first.map(String.init) ?? "user",
            firstName: profile.firstName,
            lastName: profile.lastName,
            bio: profile.bio,
            profileImageURL: profile.profilePhotos?.first,
            photoURLs: profile.profilePhotos ?? [],
            nativeLanguage: UserLanguage(language: nativeLanguage, proficiency: .native, isNative: true),
            learningLanguages: learningLanguages,
            openToLanguages: learningLanguages.map { $0.language },
            practiceLanguages: nil,
            location: profile.location,
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: false, // TODO: Implement online status
            allowNonNativeMatches: allowNonNativeMatches,
            minProficiencyLevel: minProficiencyLevel,
            maxProficiencyLevel: maxProficiencyLevel
        )
    }

    // Helper to parse proficiency level from database string to enum
    private func parseProficiencyLevel(_ level: String?) -> LanguageProficiency? {
        guard let level = level else { return nil }
        switch level.lowercased() {
        case "beginner": return .beginner
        case "intermediate": return .intermediate
        case "advanced": return .advanced
        case "native": return .native
        default: return nil
        }
    }

    @objc private func notificationsTapped() {
        print("Notifications tapped")
    }
}

extension MatchesListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Section 0: Bot practice card, Section 1: Matches
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1 // Bot practice card
        } else {
            return matches.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BotPracticeCard", for: indexPath) as! BotPracticeCardCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as! MatchCollectionViewCell
            cell.configure(with: matches[indexPath.row])
            return cell
        }
    }
}

extension MatchesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // Bot practice card tapped - show bot selection
            showBotSelection()
        } else {
            let match = matches[indexPath.row]
            let detailVC = UserDetailViewController()
            detailVC.user = match.user
            detailVC.match = match // Pass the actual match object with real database ID
            detailVC.isMatched = true // Already matched

            // Pass the full list of matched users and current index for navigation
            detailVC.allUsers = matches.map { $0.user }
            detailVC.currentUserIndex = indexPath.row

            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    private func showBotSelection() {
        let alert = UIAlertController(
            title: "Practice with a Bot",
            message: "Choose a language to practice",
            preferredStyle: .actionSheet
        )

        let aiBots = AIBotFactory.createAIBots()
        for bot in aiBots {
            let action = UIAlertAction(
                title: "\(bot.firstName) - \(bot.nativeLanguage.language.name)",
                style: .default
            ) { [weak self] _ in
                self?.startChatWithBot(bot)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = collectionView
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alert, animated: true)
    }

    private func startChatWithBot(_ bot: User) {
        let match = Match(
            id: bot.id,
            user: bot,
            matchedAt: Date(),
            hasNewMessage: false,
            lastMessage: "Start practicing!",
            lastMessageTime: Date()
        )
        let chatVC = ChatViewController(user: bot, match: match)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension MatchesListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            // Bot practice card - full width, thin height
            let width = view.frame.width - 32 // 16pt padding on each side
            return CGSize(width: width, height: 60)
        } else {
            // Match cards - 2 columns
            let width = (view.frame.width - 48) / 2
            return CGSize(width: width, height: width * 1.3)
        }
    }
}

class MatchCollectionViewCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let languagesLabel = UILabel()
    private let locationLabel = UILabel()
    private let onlineIndicator = UIView()
    private let newMessageBadge = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        languagesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        languagesLabel.textColor = .white.withAlphaComponent(0.9)
        contentView.addSubview(languagesLabel)
        languagesLabel.translatesAutoresizingMaskIntoConstraints = false

        locationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        locationLabel.textColor = .white.withAlphaComponent(0.8)
        contentView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        onlineIndicator.backgroundColor = .systemGreen
        onlineIndicator.layer.cornerRadius = 6
        onlineIndicator.layer.borderWidth = 2
        onlineIndicator.layer.borderColor = UIColor.white.cgColor
        contentView.addSubview(onlineIndicator)
        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false

        newMessageBadge.backgroundColor = .systemRed
        newMessageBadge.layer.cornerRadius = 4
        contentView.addSubview(newMessageBadge)
        newMessageBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: languagesLabel.topAnchor, constant: -2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            languagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            languagesLabel.bottomAnchor.constraint(equalTo: locationLabel.topAnchor, constant: -2),
            languagesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            onlineIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            onlineIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 12),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 12),

            newMessageBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            newMessageBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            newMessageBadge.widthAnchor.constraint(equalToConstant: 8),
            newMessageBadge.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = imageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = imageView.bounds
        }
    }

    func configure(with match: Match) {
        nameLabel.text = match.user.firstName

        let languages = [match.user.nativeLanguage.displayCode] +
            match.user.learningLanguages.map { $0.displayCode }
        languagesLabel.text = languages.joined(separator: " • ")

        // Display location based on user's privacy setting
        locationLabel.text = match.user.displayLocation ?? ""

        onlineIndicator.isHidden = !match.user.isOnline
        newMessageBadge.isHidden = !match.hasNewMessage

        // Add gradient overlay for text readability
        if imageView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) == nil {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.6).cgColor
            ]
            gradientLayer.locations = [0.5, 1.0]
            imageView.layer.addSublayer(gradientLayer)
        }

        // Load profile image
        if let profileImageURL = match.user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: imageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        } else {
            imageView.image = UIImage(systemName: "person.fill")
            imageView.tintColor = .systemGray3
        }
    }
}

// MARK: - Bot Practice Card Cell

class BotPracticeCardCell: UICollectionViewCell {

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let chevronImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor

        // Robot icon
        iconImageView.image = UIImage(systemName: "brain.head.profile")
        iconImageView.tintColor = .systemPurple
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        titleLabel.text = "Practice with a Bot"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .systemPurple
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .systemPurple
        chevronImageView.contentMode = .scaleAspectFit
        contentView.addSubview(chevronImageView)
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
}