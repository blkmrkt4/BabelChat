import UIKit

class DiscoverViewController: UIViewController {

    private let cardStackView = UIView()
    private var cardViews: [SwipeCardView] = []
    private let emptyStateLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // Store matched users with their scores and reasons
    private var matchedProfiles: [(user: User, score: Int, reasons: [String])] = []
    private var allUsers: [User] = []
    private var hasShownProfileDetail = false // Track if we've shown the profile detail view

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadCards()

        // Track screen view
        AnalyticsService.shared.track(.discoverViewed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // If user finished viewing profiles and popped back, reload new profiles
        if hasShownProfileDetail && !loadingIndicator.isAnimating {
            hasShownProfileDetail = false
            allUsers.removeAll()
            matchedProfiles.removeAll()
            loadCards()
        }
    }

    private func setupNavigationBar() {
        title = "tab_discover".localized
        navigationController?.navigationBar.prefersLargeTitles = true

        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(filterTapped)
        )
        navigationItem.rightBarButtonItem = filterButton
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        cardStackView.backgroundColor = .clear
        view.addSubview(cardStackView)
        cardStackView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = "discover_no_profiles".localized + "\n" + "discover_users_joining".localized
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        reloadButton.setTitle("discover_reload".localized, for: .normal)
        reloadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
        reloadButton.isHidden = true
        view.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            reloadButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 20),
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        setupActionButtons()
    }

    private func setupActionButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .equalSpacing
        buttonStackView.spacing = 24
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        // Reject button (red X)
        let rejectButton = createImageButton(
            imageName: "RejectButton",
            action: #selector(passTapped)
        )

        // Star button (gold star) - for super like
        let starButton = createImageButton(
            imageName: "StarButton",
            action: #selector(starTapped)
        )

        // Match button (green chat checkmark)
        let matchButton = createImageButton(
            imageName: "MatchButton",
            action: #selector(likeTapped)
        )

        buttonStackView.addArrangedSubview(rejectButton)
        buttonStackView.addArrangedSubview(starButton)
        buttonStackView.addArrangedSubview(matchButton)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            rejectButton.widthAnchor.constraint(equalToConstant: 64),
            rejectButton.heightAnchor.constraint(equalToConstant: 64),
            starButton.widthAnchor.constraint(equalToConstant: 64),
            starButton.heightAnchor.constraint(equalToConstant: 64),
            matchButton.widthAnchor.constraint(equalToConstant: 64),
            matchButton.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    private func createImageButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc private func starTapped() {
        if let topCard = cardViews.last {
            // Super like - swipe up
            topCard.swipeCard(direction: .up)
        }
    }

    private func loadCards() {
        loadingIndicator.startAnimating()

        Task {
            do {
                // Fetch matched profiles from Supabase with scoring
                matchedProfiles = try await SupabaseService.shared.getMatchedDiscoveryProfiles(limit: 20)
                allUsers = matchedProfiles.map { $0.user }

                await MainActor.run {
                    loadingIndicator.stopAnimating()

                    if allUsers.isEmpty {
                        showEmptyState()
                    } else {
                        // Instead of showing cards, directly show Instagram-style profile view
                        showProfileDetailView()
                    }
                }
            } catch {
                print("❌ Error loading discovery profiles: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                await MainActor.run {
                    loadingIndicator.stopAnimating()

                    // Determine user-friendly error message
                    let errorMessage: String
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        errorMessage = "discover_check_connection".localized
                    } else {
                        errorMessage = "discover_couldnt_load".localized
                    }

                    let alert = UIAlertController(
                        title: "discover_unable_to_load".localized,
                        message: errorMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "discover_try_again".localized, style: .default) { _ in
                        self.loadCards()
                    })
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .cancel) { _ in
                        self.showEmptyState()
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func createCardViews() {
        // DEPRECATED: This method is no longer used
        // Instagram-style profile view is shown directly instead
    }

    private func showProfileDetailView() {
        // Filter out hidden profiles
        let hiddenProfileIds = UserDefaults.standard.stringArray(forKey: "hiddenProfileIds") ?? []
        let visibleUsers = allUsers.filter { !hiddenProfileIds.contains($0.id) }

        guard !visibleUsers.isEmpty else {
            // All profiles were hidden, show empty state
            showEmptyState()
            return
        }

        // Create and push UserDetailViewController with the list of users
        let detailVC = UserDetailViewController()
        detailVC.user = visibleUsers[0] // Start with first user
        detailVC.allUsers = visibleUsers // Pass filtered users for navigation
        detailVC.currentUserIndex = 0
        detailVC.isMatched = false
        detailVC.isFromDiscover = true // Hide back button since we navigated automatically

        // Pass the user's per-photo blur settings for per-photo blur display
        detailVC.viewingUserBlurSettings = visibleUsers[0].photoBlurSettings

        hasShownProfileDetail = true // Track that we showed profiles
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showEmptyState() {
        emptyStateLabel.isHidden = false
        reloadButton.isHidden = false
    }

    private func createSampleUsers() -> [User] {
        // Current user profile may be learning: Spanish, Japanese, French, etc.
        // Create diverse users to match various learning goals
        // Matching logic: Users who are native in target language AND learning English

        return [
            // FRENCH SPEAKERS LEARNING ENGLISH (Match on French <-> English)
            User(
                id: "13",
                username: "amelie_laurent",
                firstName: "Amélie",
                lastName: "Laurent",
                bio: "Parisian art student who loves museums and coffee. Learning English for my exchange program!",
                profileImageURL: "https://picsum.photos/seed/amelie_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "amelie", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Paris, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "14",
                username: "lucas_moreau",
                firstName: "Lucas",
                lastName: "Moreau",
                bio: "Lyon chef passionate about French cuisine 🥐 Want to improve my English for my cooking channel!",
                profileImageURL: "https://picsum.photos/seed/lucas_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "lucas", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .beginner, isNative: false),
                    UserLanguage(language: .italian, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .italian],
                practiceLanguages: nil,
                location: "Lyon, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "15",
                username: "chloe_dubois",
                firstName: "Chloé",
                lastName: "Dubois",
                bio: "Marseille native, love sailing and the Mediterranean! Studying English for international business.",
                profileImageURL: "https://picsum.photos/seed/chloe_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "chloe", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .advanced, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Marseille, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "16",
                username: "theo_bernard",
                firstName: "Théo",
                lastName: "Bernard",
                bio: "Bordeaux wine enthusiast 🍷 Learning English and Spanish for my wine export business!",
                profileImageURL: "https://picsum.photos/seed/theo_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "theo", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
                    UserLanguage(language: .spanish, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .spanish],
                practiceLanguages: nil,
                location: "Bordeaux, France",
                matchedDate: nil,
                isOnline: false
            ),
            User(
                id: "17",
                username: "lea_petit",
                firstName: "Léa",
                lastName: "Petit",
                bio: "Nice photographer capturing the French Riviera 📸 Want to practice English for my travel blog!",
                profileImageURL: "https://picsum.photos/seed/lea_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "lea", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Nice, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "18",
                username: "marie_rousseau",
                firstName: "Marie",
                lastName: "Rousseau",
                bio: "Toulouse software engineer who loves sci-fi and video games. Learning English for tech conferences!",
                profileImageURL: "https://picsum.photos/seed/marie_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "marie", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .advanced, isNative: false),
                    UserLanguage(language: .german, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .german],
                practiceLanguages: nil,
                location: "Toulouse, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "19",
                username: "antoine_martin",
                firstName: "Antoine",
                lastName: "Martin",
                bio: "Strasbourg musician playing jazz saxophone 🎷 Want to improve English for touring internationally!",
                profileImageURL: "https://picsum.photos/seed/antoine_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "antoine", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Strasbourg, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "20",
                username: "emma_leroy",
                firstName: "Emma",
                lastName: "Leroy",
                bio: "Nantes fashion designer inspired by French elegance ✨ Learning English for fashion weeks abroad!",
                profileImageURL: "https://picsum.photos/seed/emma_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "emma", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .beginner, isNative: false),
                    UserLanguage(language: .italian, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .italian],
                practiceLanguages: nil,
                location: "Nantes, France",
                matchedDate: nil,
                isOnline: false
            ),


            // SPANISH SPEAKERS LEARNING ENGLISH (Match on Spanish <-> English)
            User(
                id: "1",
                username: "maria_garcia",
                firstName: "Maria",
                lastName: "Garcia",
                bio: "Barcelona native, passionate about languages and travel. Currently learning Japanese!",
                profileImageURL: "https://picsum.photos/seed/maria_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "maria", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .advanced, isNative: false),
                    UserLanguage(language: .japanese, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .japanese],
                practiceLanguages: nil,
                location: "Barcelona, Spain",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "5",
                username: "carlos_mendez",
                firstName: "Carlos",
                lastName: "Méndez",
                bio: "Madrid musician 🎸 Love rock music and teaching guitar. Want to improve my English for touring!",
                profileImageURL: "https://picsum.photos/seed/carlos_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "carlos", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Madrid, Spain",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "6",
                username: "sofia_lopez",
                firstName: "Sofía",
                lastName: "López",
                bio: "Buenos Aires born, coffee addict ☕ Studying English for my marketing career. Also picking up some Portuguese!",
                profileImageURL: "https://picsum.photos/seed/sofia_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "sofia", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .beginner, isNative: false),
                    UserLanguage(language: .portuguese, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .portuguese],
                practiceLanguages: nil,
                location: "Buenos Aires, Argentina",
                matchedDate: nil,
                isOnline: false
            ),
            User(
                id: "7",
                username: "diego_rivera",
                firstName: "Diego",
                lastName: "Rivera",
                bio: "Mexico City photographer 📸 Love capturing street art and culture. Learning English and French!",
                profileImageURL: "https://picsum.photos/seed/diego_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "diego", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .advanced, isNative: false),
                    UserLanguage(language: .french, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .french],
                practiceLanguages: nil,
                location: "Mexico City, Mexico",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "8",
                username: "lucia_torres",
                firstName: "Lucía",
                lastName: "Torres",
                bio: "Spanish teacher from Seville who loves flamenco dancing. Want to practice conversational English!",
                profileImageURL: "https://picsum.photos/seed/lucia_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "lucia", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Seville, Spain",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "9",
                username: "isabel_santos",
                firstName: "Isabel",
                lastName: "Santos",
                bio: "Valencia native working in tourism. Learning English for work and German for fun!",
                profileImageURL: "https://picsum.photos/seed/isabel_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "isabel", count: 6),
                nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
                    UserLanguage(language: .german, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .german],
                practiceLanguages: nil,
                location: "Valencia, Spain",
                matchedDate: nil,
                isOnline: false
            ),

            // JAPANESE SPEAKERS LEARNING ENGLISH (Match on Japanese <-> English)
            User(
                id: "2",
                username: "yuki_tanaka",
                firstName: "Yuki",
                lastName: "Tanaka",
                bio: "Tokyo software developer. Love anime and want to practice English!",
                profileImageURL: "https://picsum.photos/seed/yuki_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "yuki", count: 6),
                nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Tokyo, Japan",
                matchedDate: nil,
                isOnline: false
            ),
            User(
                id: "10",
                username: "sakura_yamamoto",
                firstName: "Sakura",
                lastName: "Yamamoto",
                bio: "Osaka chef who loves creating fusion cuisine 🍜 Learning English and Korean for my food blog!",
                profileImageURL: "https://picsum.photos/seed/sakura_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "sakura", count: 6),
                nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .beginner, isNative: false),
                    UserLanguage(language: .korean, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .korean],
                practiceLanguages: nil,
                location: "Osaka, Japan",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "11",
                username: "kenji_sato",
                firstName: "Kenji",
                lastName: "Sato",
                bio: "Kyoto university student studying international relations. Love manga and practicing English!",
                profileImageURL: "https://picsum.photos/seed/kenji_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "kenji", count: 6),
                nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .advanced, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Kyoto, Japan",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "12",
                username: "aiko_nakamura",
                firstName: "Aiko",
                lastName: "Nakamura",
                bio: "Fashion designer from Harajuku ✨ Want to improve my English for international fashion shows. Also learning French!",
                profileImageURL: "https://picsum.photos/seed/aiko_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "aiko", count: 6),
                nativeLanguage: UserLanguage(language: .japanese, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
                    UserLanguage(language: .french, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .french],
                practiceLanguages: nil,
                location: "Tokyo, Japan",
                matchedDate: nil,
                isOnline: true
            ),

            // NON-MATCHING USERS (for comparison - won't match with John)
            User(
                id: "3",
                username: "pierre_dubois",
                firstName: "Pierre",
                lastName: "Dubois",
                bio: "French chef in Paris. Looking to improve my English and learn Italian for my trips to Rome!",
                profileImageURL: "https://picsum.photos/seed/pierre_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "pierre", count: 6),
                nativeLanguage: UserLanguage(language: .french, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
                    UserLanguage(language: .italian, proficiency: .beginner, isNative: false)
                ],
                openToLanguages: [.english, .italian],
                practiceLanguages: nil,
                location: "Paris, France",
                matchedDate: nil,
                isOnline: true
            ),
            User(
                id: "4",
                username: "pooja_sharma",
                firstName: "Pooja",
                lastName: "Sharma",
                bio: "Mumbai native, love Bollywood and chai! Practicing English for my job in tech.",
                profileImageURL: "https://picsum.photos/seed/pooja_profile/400/400",
                photoURLs: ImageService.shared.generatePhotoURLs(for: "pooja", count: 6),
                nativeLanguage: UserLanguage(language: .hindi, proficiency: .native, isNative: true),
                learningLanguages: [
                    UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
                ],
                openToLanguages: [.english],
                practiceLanguages: nil,
                location: "Mumbai, India",
                matchedDate: nil,
                isOnline: true
            )
        ]
    }

    @objc private func filterTapped() {
        let preferencesVC = PreferencesViewController()
        let navController = UINavigationController(rootViewController: preferencesVC)
        present(navController, animated: true)
    }

    @objc private func reloadTapped() {
        emptyStateLabel.isHidden = true
        reloadButton.isHidden = true
        loadCards()
    }

    @objc private func rewindTapped() {
        print("Rewind tapped")
    }

    @objc private func passTapped() {
        if let topCard = cardViews.last {
            topCard.swipeCard(direction: .left)
        }
    }

    @objc private func likeTapped() {
        if let topCard = cardViews.last {
            topCard.swipeCard(direction: .right)
        }
    }

    @objc private func boostTapped() {
        // Skip to next profile without taking action
        if let topCard = cardViews.last {
            // Remove without animation
            cardViews.removeAll { $0 == topCard }
            topCard.removeFromSuperview()

            if cardViews.isEmpty {
                emptyStateLabel.isHidden = false
                reloadButton.isHidden = false
            }
        }
    }
}

extension DiscoverViewController: SwipeCardDelegate {
    func didSwipe(_ card: SwipeCardView, direction: SwipeDirection) {
        guard let user = card.user else { return }

        // Track swipe event
        let swipeDirection: String
        switch direction {
        case .left: swipeDirection = "left"
        case .right: swipeDirection = "right"
        case .up: swipeDirection = "super"
        }
        AnalyticsService.shared.trackSwipe(direction: swipeDirection, profileId: user.id)

        // Save swipe to Supabase
        Task {
            do {
                let directionString: String
                switch direction {
                case .left: directionString = "left"
                case .right: directionString = "right"
                case .up: directionString = "super" // Super like
                }

                let didMatch = try await SupabaseService.shared.recordSwipe(
                    swipedUserId: user.id,
                    direction: directionString
                )

                if didMatch {
                    print("🎉 IT'S A MATCH with \(user.firstName)!")
                    // Track match created
                    AnalyticsService.shared.track(.matchCreated, properties: ["matched_user_id": user.id])
                    // TODO: Show match animation
                } else {
                    print("✅ Swipe recorded: \(directionString) on \(user.firstName)")
                }
            } catch {
                print("❌ Error recording swipe: \(error)")
                AnalyticsService.shared.trackError(error, context: "record_swipe")
            }
        }

        // Remove card from UI
        cardViews.removeAll { $0 == card }
        card.removeFromSuperview()

        if cardViews.isEmpty {
            emptyStateLabel.isHidden = false
            reloadButton.isHidden = false
        }
    }

    func didTapCard(_ card: SwipeCardView) {
        if let user = card.user {
            let detailVC = UserDetailViewController()
            detailVC.user = user
            detailVC.isMatched = false // Not matched yet in Discover

            // Pass match score and reasons if available
            if let matchInfo = matchedProfiles.first(where: { $0.user.id == user.id }) {
                // Store score and reasons for detail view
                print("📊 Match Score: \(matchInfo.score)% - Reasons: \(matchInfo.reasons.joined(separator: ", "))")
            }

            // Pass the full list of users and current index for navigation
            detailVC.allUsers = allUsers
            if let userIndex = allUsers.firstIndex(where: { $0.id == user.id }) {
                detailVC.currentUserIndex = userIndex
            }

            // Pass the user's per-photo blur settings for per-photo blur display
            detailVC.viewingUserBlurSettings = user.photoBlurSettings

            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}