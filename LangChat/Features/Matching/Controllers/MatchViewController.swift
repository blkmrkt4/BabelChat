import UIKit

class MatchViewController: UIViewController {

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let aiSetupButton = UIButton(type: .system)
    private let pageIndicator = UIView()
    private var cardView: MatchCardView!

    private var currentMatch: Match?
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var originalCenter: CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupGestures()
        loadSampleData()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        headerView.backgroundColor = .systemBackground
        view.addSubview(headerView)

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        headerView.addSubview(backButton)

        aiSetupButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        aiSetupButton.tintColor = .systemBlue
        aiSetupButton.addTarget(self, action: #selector(aiSetupButtonTapped), for: .touchUpInside)
        headerView.addSubview(aiSetupButton)

        titleLabel.text = "Your Matches"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)

        subtitleLabel.text = "1 connections"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        headerView.addSubview(subtitleLabel)

        pageIndicator.backgroundColor = .systemBlue
        pageIndicator.layer.cornerRadius = 2
        headerView.addSubview(pageIndicator)

        cardView = MatchCardView()
        view.addSubview(cardView)
    }

    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        aiSetupButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageIndicator.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            aiSetupButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            aiSetupButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            aiSetupButton.widthAnchor.constraint(equalToConstant: 44),
            aiSetupButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            pageIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            pageIndicator.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            pageIndicator.widthAnchor.constraint(equalToConstant: 40),
            pageIndicator.heightAnchor.constraint(equalToConstant: 4),

            cardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(panGestureRecognizer)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        cardView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        cardView.addGestureRecognizer(swipeRight)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            originalCenter = cardView.center

        case .changed:
            cardView.center = CGPoint(x: originalCenter.x + translation.x,
                                     y: originalCenter.y + translation.y)

            let rotationAngle = translation.x / (view.frame.width / 2) * 0.2
            cardView.transform = CGAffineTransform(rotationAngle: rotationAngle)

            let opacity = 1 - abs(translation.x) / (view.frame.width / 2)
            cardView.alpha = max(0.5, opacity)

        case .ended:
            if abs(translation.x) > 100 || abs(velocity.x) > 500 {
                if translation.x > 0 {
                    animateCardOff(direction: .right)
                } else {
                    animateCardOff(direction: .left)
                }
            } else {
                animateToCenter()
            }

        default:
            break
        }
    }

    @objc private func handleSwipeLeft() {
        animateCardOff(direction: .left)
    }

    @objc private func handleSwipeRight() {
        animateCardOff(direction: .right)
    }

    private func animateCardOff(direction: SwipeDirection) {
        let translationX: CGFloat = direction == .right ? view.frame.width * 1.5 : -view.frame.width * 1.5

        UIView.animate(withDuration: 0.3, animations: {
            self.cardView.center = CGPoint(x: translationX, y: self.cardView.center.y)
            self.cardView.alpha = 0
        }) { _ in
            self.handleSwipeAction(direction: direction)
            self.resetCard()
        }
    }

    private func animateToCenter() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.cardView.center = self.originalCenter
            self.cardView.transform = .identity
            self.cardView.alpha = 1
        })
    }

    private func resetCard() {
        cardView.center = originalCenter
        cardView.transform = .identity
        cardView.alpha = 1
    }

    private func handleSwipeAction(direction: SwipeDirection) {
        switch direction {
        case .right:
            print("Liked user")
        case .left:
            print("Passed on user")
        case .up:
            print("Super liked user")
        }
    }

    private func loadSampleData() {
        let nativeLanguage = UserLanguage(language: .english, proficiency: .native, isNative: true)
        let learningLanguages = [
            UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
            UserLanguage(language: .japanese, proficiency: .beginner, isNative: false)
        ]

        // Generate realistic photo URLs for Ji-hyun
        let photoURLs = [
            "https://picsum.photos/seed/jihyun1/400/600",
            "https://picsum.photos/seed/jihyun2/400/600",
            "https://picsum.photos/seed/jihyun3/400/600",
            "https://picsum.photos/seed/jihyun4/400/600",
            "https://picsum.photos/seed/jihyun5/400/600",
            "https://picsum.photos/seed/jihyun6/400/600"
        ]

        let sampleUser = User(
            id: "1",
            username: "jihyun_kim",
            firstName: "Ji-hyun",
            lastName: "Kim",
            bio: "Seoul native learning English and Spanish. Love K-dramas and coffee culture!",
            profileImageURL: "https://picsum.photos/seed/jihyun_profile/400/400",
            photoURLs: photoURLs,
            nativeLanguage: nativeLanguage,
            learningLanguages: learningLanguages,
            openToLanguages: [.english, .japanese],
            practiceLanguages: nil,
            location: "Seoul, South Korea",
            matchedDate: Date(timeIntervalSince1970: 1726358400),
            isOnline: true
        )

        let match = Match(
            id: "1",
            user: sampleUser,
            matchedAt: Date(),
            hasNewMessage: false,
            lastMessage: nil,
            lastMessageTime: nil
        )

        currentMatch = match
        cardView.user = sampleUser
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func aiSetupButtonTapped() {
        let aiSetupVC = AISetupContainerViewController()
        let navController = UINavigationController(rootViewController: aiSetupVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func navigateToChat() {
        print("Navigate to chat with user: \(currentMatch?.user.displayName ?? "")")
    }
}

