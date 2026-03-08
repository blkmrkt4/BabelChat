import UIKit
import Supabase
import AVFoundation

class MatchesListViewController: UIViewController {

    private var collectionView: UICollectionView!

    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()

    private var allMatches: [Match] = []
    private var filteredMatches: [Match] = []
    private var filterCategories: [MatchFilterCategory] = []
    private var selectedFilterIndex: Int = 0
    private var currentUserLearningLanguages: [Language] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadMatches()

        // Track screen view
        AnalyticsService.shared.track(.matchesListViewed)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false

        let titleLabel = UILabel()
        titleLabel.text = "matches_your_matches".localized
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        navigationItem.titleView = titleLabel

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        navigationItem.leftBarButtonItem = profileButton

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    @objc private func profileTapped() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }

    // MARK: - Layout

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self?.createMuseHeaderSection()
            case 1:
                return self?.createFilterChipsSection()
            case 2:
                return self?.createMatchListSection()
            default:
                return self?.createMatchListSection()
            }
        }
    }

    private func createMuseHeaderSection() -> NSCollectionLayoutSection {
        // Empty item (header is supplementary)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        // Muse header as supplementary
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(144))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func createFilterChipsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .absolute(34))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .absolute(34))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        return section
    }

    private func createMatchListSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(76))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(76))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")
        collectionView.register(MatchFilterChipCell.self, forCellWithReuseIdentifier: "ChipCell")
        collectionView.register(MatchListCell.self, forCellWithReuseIdentifier: "MatchListCell")
        collectionView.register(MuseHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "MuseHeader")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Empty state view
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = "matches_empty_title".localized + "\n" + "matches_empty_subtitle".localized
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

    // MARK: - Data Loading

    private func loadMatches() {
        Task {
            do {
                print("Loading matches from Supabase...")
                let matchResponses = try await SupabaseService.shared.getMatches()
                print("Loaded \(matchResponses.count) matches from Supabase")

                guard let currentUserId = SupabaseService.shared.currentUserId?.uuidString else {
                    print("No current user ID")
                    return
                }

                var loadedMatches: [Match] = []

                for matchResponse in matchResponses {
                    let otherUserId = matchResponse.user1Id.lowercased() == currentUserId.lowercased() ? matchResponse.user2Id : matchResponse.user1Id

                    do {
                        let profile = try await SupabaseService.shared.client.database
                            .from("profiles")
                            .select()
                            .eq("id", value: otherUserId)
                            .single()
                            .execute()
                            .value as ProfileResponse

                        let user = convertProfileToUser(profile)

                        let match = Match(
                            id: matchResponse.id,
                            user: user,
                            matchedAt: ISO8601DateFormatter().date(from: matchResponse.matchedAt) ?? Date(),
                            hasNewMessage: false,
                            lastMessage: "Start chatting!",
                            lastMessageTime: ISO8601DateFormatter().date(from: matchResponse.matchedAt) ?? Date()
                        )

                        loadedMatches.append(match)
                    } catch {
                        print("Failed to load profile for user \(otherUserId): \(error)")
                    }
                }

                // Try to get current user for filter building
                var currentUser: User? = nil
                do {
                    let profile = try await SupabaseService.shared.getCurrentProfile()
                    currentUser = convertProfileToUser(profile)
                } catch {
                    print("Failed to load current profile for filters: \(error)")
                }

                await MainActor.run {
                    self.allMatches = loadedMatches
                    self.buildFilterCategories(currentUser: currentUser)
                    self.applyFilter()
                    self.collectionView.reloadData()
                    self.updateEmptyState()
                }

            } catch {
                print("Failed to load matches: \(error)")
                await MainActor.run {
                    self.allMatches = []
                    self.filteredMatches = []
                    self.collectionView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }

    private func buildFilterCategories(currentUser: User?) {
        filterCategories = MatchFilterCategoryBuilder.buildCategories(
            matches: allMatches,
            currentUser: currentUser
        )
        selectedFilterIndex = 0
    }

    private func applyFilter() {
        guard selectedFilterIndex < filterCategories.count else {
            filteredMatches = allMatches
            return
        }
        filteredMatches = filterCategories[selectedFilterIndex].filterFunction(allMatches)
    }

    // MARK: - Category Label Builder

    private func buildCategoryLabel(for match: Match) -> String {
        var tags: [String] = []

        // Add relationship intent if not the default
        let intent = match.user.matchingPreferences.relationshipIntent
        if intent != .languageExchange {
            tags.append(intent.displayName)
        }

        // Add "[Language] Learning" for native language if it's one of current user's learning languages
        let learningLanguages = currentUserLearningLanguagesList()
        if learningLanguages.contains(match.user.nativeLanguage.language) {
            let langName = match.user.nativeLanguage.language.name
            tags.append(String(format: "matches_filter_language_learning".localized, langName))
        }

        return tags.joined(separator: " - ")
    }

    private func currentUserLearningLanguagesList() -> [Language] {
        if !currentUserLearningLanguages.isEmpty { return currentUserLearningLanguages }
        guard let userLanguagesData = UserDefaults.standard.data(forKey: "userLanguages"),
              let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: userLanguagesData) else {
            return []
        }
        currentUserLearningLanguages = userLanguageData.learningLanguages.map { $0.language }
        return currentUserLearningLanguages
    }

    // MARK: - Helpers

    private func convertProfileToUser(_ profile: ProfileResponse) -> User {
        let learningLanguages: [UserLanguage] = (profile.learningLanguages ?? []).compactMap { langName in
            guard let language = Language.from(name: langName) else { return nil }
            return UserLanguage(language: language, proficiency: .intermediate, isNative: false)
        }

        let nativeLanguage: Language = Language.from(name: profile.nativeLanguage) ?? .english

        let allowNonNativeMatches = profile.allowNonNativeMatches ?? false
        let minProficiencyLevel = parseProficiencyLevel(profile.minProficiencyLevel) ?? .beginner
        let maxProficiencyLevel = parseProficiencyLevel(profile.maxProficiencyLevel) ?? .advanced

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

    private func isUserRecentlyActive(_ lastActive: String?) -> Bool {
        guard let lastActiveString = lastActive else { return false }
        let formatter = ISO8601DateFormatter()
        guard let lastActiveDate = formatter.date(from: lastActiveString) else { return false }
        let minutesSinceActive = Date().timeIntervalSince(lastActiveDate) / 60
        return minutesSinceActive < 15
    }

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
        emptyStateView.isHidden = !allMatches.isEmpty
    }
}

// MARK: - UICollectionViewDataSource

extension MatchesListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 0 // Muse header (supplementary only)
        case 1: return filterCategories.count
        case 2: return filteredMatches.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 1:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChipCell", for: indexPath) as? MatchFilterChipCell else {
                return UICollectionViewCell()
            }
            let category = filterCategories[indexPath.item]
            cell.configure(title: category.displayTitle, isSelected: indexPath.item == selectedFilterIndex)
            return cell

        case 2:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchListCell", for: indexPath) as? MatchListCell else {
                return UICollectionViewCell()
            }
            let match = filteredMatches[indexPath.item]
            let categoryText = buildCategoryLabel(for: match)
            cell.configure(with: match, categoryLabel: categoryText)
            return cell

        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader && indexPath.section == 0 {
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

// MARK: - UICollectionViewDelegate

extension MatchesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            // Filter chip tapped
            guard indexPath.item != selectedFilterIndex else { return }
            selectedFilterIndex = indexPath.item
            applyFilter()
            collectionView.reloadSections(IndexSet([1, 2]))

        case 2:
            // Match row tapped
            let match = filteredMatches[indexPath.item]
            let detailVC = UserDetailViewController()
            detailVC.user = match.user
            detailVC.match = match
            detailVC.isMatched = true

            detailVC.allUsers = filteredMatches.map { $0.user }
            detailVC.allMatches = filteredMatches
            detailVC.currentUserIndex = indexPath.item

            navigationController?.pushViewController(detailVC, animated: true)

        default:
            break
        }
    }

    // MARK: - Muse Actions

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

    private func getAvailableMuses() -> [User] {
        var availableLanguages = Set<Language>()

        availableLanguages.insert(.english)

        if let userLanguagesData = UserDefaults.standard.data(forKey: "userLanguages"),
           let userLanguageData = try? JSONDecoder().decode(UserLanguageData.self, from: userLanguagesData) {
            for learning in userLanguageData.learningLanguages {
                availableLanguages.insert(learning.language)
            }
        }

        if let museLanguageCodes = UserDefaults.standard.array(forKey: "museLanguages") as? [String] {
            for code in museLanguageCodes {
                if let language = Language(rawValue: code) {
                    availableLanguages.insert(language)
                }
            }
        }

        let allMuses = AIBotFactory.createAIBots()
        let filteredMuses = allMuses.filter { availableLanguages.contains($0.nativeLanguage.language) }

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

// MARK: - Muse Header View with Looping Video

class MuseHeaderView: UICollectionReusableView {

    var onMuseTapped: (() -> Void)?

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

        videoContainerView.backgroundColor = .clear
        videoContainerView.layer.cornerRadius = 60
        videoContainerView.clipsToBounds = true
        addSubview(videoContainerView)
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(museTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
        videoContainerView.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            videoContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoContainerView.widthAnchor.constraint(equalToConstant: 120),
            videoContainerView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func setupVideo() {
        guard let videoURL = Bundle.main.url(forResource: "MusePulse", withExtension: "mp4") else {
            print("MusePulse.mp4 not found in bundle - showing fallback image")
            showFallbackImage()
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer?.isMuted = true

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

        let headerView = UIView()
        headerView.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "matches_meet_your_muse".localized
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let editPill = UIButton(type: .system)
        editPill.setTitle(" " + "common_edit".localized, for: .normal)
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
