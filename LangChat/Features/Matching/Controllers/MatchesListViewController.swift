import UIKit
import Supabase
import AVFoundation

class MatchesListViewController: UIViewController {

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        // Section insets are set per-section in insetForSectionAt delegate method
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()

    private var matches: [Match] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadMatches()

        // Track screen view
        AnalyticsService.shared.track(.matchesListViewed)
    }

    private func setupNavigationBar() {
        // Hide navigation title - we'll use a custom header instead
        navigationItem.title = ""
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MatchCollectionViewCell.self, forCellWithReuseIdentifier: "MatchCell")
        collectionView.register(MuseHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "MuseHeader")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Empty state view
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = "No matches yet\nSwipe right on profiles you like in Discover!"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
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
                        // Note: hasNewMessage requires last_read_at tracking in database
                        // For proper implementation: add user1_last_read_at, user2_last_read_at to matches table
                        // Then compare with most recent message timestamp
                        let match = Match(
                            id: matchResponse.id,
                            user: user,
                            matchedAt: ISO8601DateFormatter().date(from: matchResponse.matchedAt) ?? Date(),
                            hasNewMessage: false,
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
                    self.updateEmptyState()
                    print("✅ Displayed \(loadedMatches.count) matches")
                }

            } catch {
                print("❌ Failed to load matches: \(error)")
                // Fallback to empty state or show error
                await MainActor.run {
                    self.matches = []
                    self.collectionView.reloadData()
                    self.updateEmptyState()
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

        // Split 7-photo array: indices 0-5 for grid, index 6 for profile
        let allPhotos = profile.profilePhotos ?? []
        let profileImageURL = allPhotos.count > 6 ? allPhotos[6] : allPhotos.first
        let gridPhotoURLs = Array(allPhotos.prefix(6))

        return User(
            id: profile.id,
            username: profile.email.split(separator: "@").first.map(String.init) ?? "user",
            firstName: profile.firstName,
            lastName: profile.lastName,
            bio: profile.bio,
            profileImageURL: profileImageURL,
            photoURLs: gridPhotoURLs,
            nativeLanguage: UserLanguage(language: nativeLanguage, proficiency: .native, isNative: true),
            learningLanguages: learningLanguages,
            openToLanguages: learningLanguages.map { $0.language },
            practiceLanguages: nil,
            location: profile.location,
            showCityInProfile: true,
            matchedDate: Date(),
            isOnline: isUserRecentlyActive(profile.lastActive),
            allowNonNativeMatches: allowNonNativeMatches,
            minProficiencyLevel: minProficiencyLevel,
            maxProficiencyLevel: maxProficiencyLevel
        )
    }

    /// Check if user has been active recently (within 15 minutes = "Active now")
    private func isUserRecentlyActive(_ lastActive: String?) -> Bool {
        guard let lastActiveString = lastActive else { return false }

        let formatter = ISO8601DateFormatter()
        guard let lastActiveDate = formatter.date(from: lastActiveString) else { return false }

        // Consider "online" if active within last 15 minutes
        let minutesSinceActive = Date().timeIntervalSince(lastActiveDate) / 60
        return minutesSinceActive < 15
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

    private func updateEmptyState() {
        emptyStateView.isHidden = !matches.isEmpty
    }

}

extension MatchesListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matches.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as? MatchCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: matches[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MuseHeader", for: indexPath) as? MuseHeaderView else {
                return UICollectionReusableView()
            }
            header.onMuseTapped = { [weak self] in
                self?.showBotSelection()
            }
            return header
        }
        return UICollectionReusableView()
    }
}

extension MatchesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = matches[indexPath.item]
        let detailVC = UserDetailViewController()
        detailVC.user = match.user
        detailVC.match = match
        detailVC.isMatched = true

        detailVC.allUsers = matches.map { $0.user }
        detailVC.allMatches = matches
        detailVC.currentUserIndex = indexPath.item

        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showBotSelection() {
        let availableMuses = getAvailableMuses()
        let sheet = MuseSelectionSheetViewController(muses: availableMuses)
        sheet.onMuseSelected = { [weak self] muse in
            self?.startChatWithBot(muse)
        }
        sheet.onEditLanguages = { [weak self] in
            self?.openMuseLanguagesSettings()
        }

        if let presentationController = sheet.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }

        present(sheet, animated: true)
    }

    private func openMuseLanguagesSettings() {
        let museLanguagesVC = MuseLanguagesSettingsViewController()
        let navController = UINavigationController(rootViewController: museLanguagesVC)
        present(navController, animated: true)
    }

    /// Get the Muses available to the user based on their language preferences
    /// Includes: English (always), learning languages, and additional Muse languages from onboarding
    private func getAvailableMuses() -> [User] {
        var availableLanguages = Set<Language>()

        // Always include English
        availableLanguages.insert(.english)

        // Add learning languages from user profile
        if let userLanguagesData = UserDefaults.standard.data(forKey: "userLanguages"),
           let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: userLanguagesData) {
            for learning in userLanguageData.learningLanguages {
                availableLanguages.insert(learning.language)
            }
        }

        // Add additional Muse languages from settings/onboarding
        if let museLanguageCodes = UserDefaults.standard.array(forKey: "museLanguages") as? [String] {
            for code in museLanguageCodes {
                if let language = Language(rawValue: code) {
                    availableLanguages.insert(language)
                }
            }
        }

        // Get all Muses and filter to only available languages
        let allMuses = AIBotFactory.createAIBots()
        let filteredMuses = allMuses.filter { availableLanguages.contains($0.nativeLanguage.language) }

        // If no languages selected yet (new user), show all Muses as fallback
        if filteredMuses.isEmpty {
            return allMuses
        }

        return filteredMuses
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
        let horizontalPadding: CGFloat = 16
        let interItemSpacing: CGFloat = 16
        // Match cards - 2 columns
        let totalWidth = view.frame.width - (horizontalPadding * 2) - interItemSpacing
        let width = totalWidth / 2
        return CGSize(width: width, height: width * 1.3)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Header with title + Muse button
        // Title: ~40pt, Muse button: 120pt, spacing: 20pt
        return CGSize(width: view.frame.width, height: 200)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
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

// MARK: - Muse Header View with Looping Video

class MuseHeaderView: UICollectionReusableView {

    var onMuseTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let videoContainerView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupVideo()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupVideo()
    }

    private func setupViews() {
        backgroundColor = .systemBackground

        // Centered title
        titleLabel.text = "Your Matches"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Video container (tappable)
        videoContainerView.backgroundColor = .clear
        videoContainerView.layer.cornerRadius = 60
        videoContainerView.clipsToBounds = true
        addSubview(videoContainerView)
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(museTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
        videoContainerView.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            videoContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            videoContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoContainerView.widthAnchor.constraint(equalToConstant: 120),
            videoContainerView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func setupVideo() {
        guard let videoURL = Bundle.main.url(forResource: "MusePulse", withExtension: "mp4") else {
            print("❌ MusePulse.mp4 not found in bundle - showing fallback image")
            showFallbackImage()
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer?.isMuted = true

        // Create looper for seamless looping
        if let player = queuePlayer {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        }

        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = CGRect(x: 0, y: 0, width: 120, height: 120)

        if let layer = playerLayer {
            videoContainerView.layer.addSublayer(layer)
        }

        queuePlayer?.play()
    }

    private func showFallbackImage() {
        // Show MuseButton image as fallback if video not available
        let imageView = UIImageView(image: UIImage(named: "MuseButton"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }

    @objc private func museTapped() {
        onMuseTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        queuePlayer?.play()
    }
}

// MARK: - Muse Selection Sheet

class MuseSelectionSheetViewController: UIViewController {

    var onMuseSelected: ((User) -> Void)?
    var onEditLanguages: (() -> Void)?

    private let muses: [User]
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(muses: [User]) {
        self.muses = muses
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Header with title and edit pill
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Meet your Muse"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Edit pill button
        let editPill = UIButton(type: .system)
        editPill.setTitle(" Edit", for: .normal)
        editPill.setImage(UIImage(systemName: "pencil"), for: .normal)
        editPill.tintColor = .white
        editPill.setTitleColor(.white, for: .normal)
        editPill.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        editPill.backgroundColor = .systemBlue
        editPill.layer.cornerRadius = 14
        editPill.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 14)
        editPill.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        headerView.addSubview(editPill)
        editPill.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Table view for muses
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MuseOptionCell.self, forCellReuseIdentifier: "MuseCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        tableView.rowHeight = 56
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            editPill.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            editPill.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            editPill.heightAnchor.constraint(equalToConstant: 28),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func editTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onEditLanguages?()
        }
    }
}

extension MuseSelectionSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return muses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MuseCell", for: indexPath) as? MuseOptionCell else {
            return UITableViewCell()
        }
        let muse = muses[indexPath.row]
        cell.configure(with: muse)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let muse = muses[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onMuseSelected?(muse)
        }
    }
}

// MARK: - Muse Option Cell

private class MuseOptionCell: UITableViewCell {
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let languageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        flagLabel.font = .systemFont(ofSize: 28)
        contentView.addSubview(flagLabel)
        flagLabel.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        languageLabel.font = .systemFont(ofSize: 14)
        languageLabel.textColor = .secondaryLabel
        contentView.addSubview(languageLabel)
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            flagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            languageLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            languageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(with muse: User) {
        flagLabel.text = muse.nativeLanguage.language.flag
        nameLabel.text = muse.firstName
        languageLabel.text = muse.nativeLanguage.language.name
    }
}