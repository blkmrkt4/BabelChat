import UIKit

class DiscoverViewController: UIViewController {

    private let cardStackView = UIView()
    private var cardViews: [SwipeCardView] = []
    private let emptyStateLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private var allUsers: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadCards()
    }

    private func setupNavigationBar() {
        title = "Discover"
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

        emptyStateLabel.text = "No more profiles to show.\nCheck back later!"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
        reloadButton.isHidden = true
        view.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false

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
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        setupActionButtons()
    }

    private func setupActionButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .equalSpacing
        buttonStackView.spacing = 40
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        let rewindButton = createActionButton(
            image: "chevron.left",
            color: .systemGray,
            action: #selector(rewindTapped)
        )

        let passButton = createActionButton(
            image: "xmark.circle.fill",
            color: .systemRed,
            action: #selector(passTapped)
        )

        let likeButton = createActionButton(
            image: "heart.circle.fill",
            color: .systemGreen,
            action: #selector(likeTapped)
        )

        let boostButton = createActionButton(
            image: "chevron.right",
            color: .systemGray,
            action: #selector(boostTapped)
        )

        buttonStackView.addArrangedSubview(rewindButton)
        buttonStackView.addArrangedSubview(passButton)
        buttonStackView.addArrangedSubview(likeButton)
        buttonStackView.addArrangedSubview(boostButton)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            rewindButton.widthAnchor.constraint(equalToConstant: 50),
            rewindButton.heightAnchor.constraint(equalToConstant: 50),
            passButton.widthAnchor.constraint(equalToConstant: 64),
            passButton.heightAnchor.constraint(equalToConstant: 64),
            likeButton.widthAnchor.constraint(equalToConstant: 64),
            likeButton.heightAnchor.constraint(equalToConstant: 64),
            boostButton.widthAnchor.constraint(equalToConstant: 50),
            boostButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func createActionButton(image: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: image), for: .normal)
        button.tintColor = color
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func loadCards() {
        allUsers = createSampleUsers()

        for (index, user) in allUsers.enumerated() {
            let card = SwipeCardView()
            card.user = user
            card.delegate = self
            card.alpha = index == 0 ? 1 : 0.95
            cardStackView.addSubview(card)

            card.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: cardStackView.topAnchor),
                card.leadingAnchor.constraint(equalTo: cardStackView.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: cardStackView.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: cardStackView.bottomAnchor)
            ])

            cardStackView.sendSubviewToBack(card)
            cardViews.append(card)
        }
    }

    private func createSampleUsers() -> [User] {
        return [
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
        print("Filter tapped")
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

            // Pass the full list of users and current index for navigation
            detailVC.allUsers = allUsers
            if let userIndex = allUsers.firstIndex(where: { $0.id == user.id }) {
                detailVC.currentUserIndex = userIndex
            }

            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}