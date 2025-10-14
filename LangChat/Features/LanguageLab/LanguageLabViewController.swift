import UIKit

class LanguageLabViewController: UIViewController {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let shareButton = UIButton(type: .system)
    private let bentoGridView = UIView()

    // MARK: - Properties

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createBentoGrid()
        loadUserData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame if using fallback
        if let gradientLayer = backgroundImageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundImageView.bounds
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Background image setup
        // Try multiple approaches to load the image
        if let backgroundImage = UIImage(named: "LangSmoke.jpg") {
            backgroundImageView.image = backgroundImage
            print("LangSmoke.jpg loaded successfully via named")
        } else if let backgroundImage = UIImage(named: "LangSmoke") {
            backgroundImageView.image = backgroundImage
            print("LangSmoke loaded successfully via named (no extension)")
        } else if let bundlePath = Bundle.main.path(forResource: "LangSmoke", ofType: "jpg"),
                  let backgroundImage = UIImage(contentsOfFile: bundlePath) {
            backgroundImageView.image = backgroundImage
            print("LangSmoke.jpg loaded successfully via bundle path")
        } else {
            print("Failed to load LangSmoke image - creating gradient fallback")
            // Create a beautiful gradient as fallback
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1).cgColor,
                UIColor(red: 0.1, green: 0.08, blue: 0.12, alpha: 1).cgColor
            ]
            gradientLayer.locations = [0, 0.5, 1]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            backgroundImageView.layer.insertSublayer(gradientLayer, at: 0)

            // Update gradient frame in viewDidLayoutSubviews
            DispatchQueue.main.async { [weak self] in
                gradientLayer.frame = self?.backgroundImageView.bounds ?? .zero
            }
        }
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)

        // Dark overlay for better readability
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        view.addSubview(overlayView)

        // Scroll view setup
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Header setup
        contentView.addSubview(headerView)

        // Title
        titleLabel.text = "Language Lab"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        headerView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Your personalized language learning dashboard"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.numberOfLines = 0
        headerView.addSubview(subtitleLabel)

        // Share button
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        headerView.addSubview(shareButton)

        // Bento grid container
        contentView.addSubview(bentoGridView)

        // Layout
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        bentoGridView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Background image - full screen
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Overlay - full screen
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Title
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -16),

            // Share button
            shareButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            // Bento grid
            bentoGridView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            bentoGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bentoGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bentoGridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createBentoGrid() {
        let spacing: CGFloat = 16
        let screenWidth = UIScreen.main.bounds.width - 40 // Account for margins

        // Create cards with different sizes
        // Row 1: Large feature card - Current Streaks
        let streaksCard = StreaksCard(
            title: "Current Streaks",
            streaks: [
                ("🇪🇸", "Maria", "Korean", 15),
                ("🇫🇷", "Pierre", "Japanese", 12),
                ("🇯🇵", "Yuki", "English", 8),
                ("🇩🇪", "Hans", "Spanish", 7),
                ("🇮🇹", "Sofia", "French", 5)
            ]
        )

        // Row 2: Two medium cards
        let matchesCard = BentoCard(
            title: "Active Matches",
            subtitle: "Currently chatting",
            icon: "person.2.fill",
            value: "12",
            color: .systemGreen,
            size: .medium
        )

        let pendingMatchesCard = BentoCard(
            title: "Pending Matches",
            subtitle: "Want to match with you",
            icon: "person.crop.circle.badge.plus",
            value: "8",
            color: .systemPurple,
            size: .medium
        )

        // Row 3: Full width messages card
        let messagesCard = MessagesCard(
            title: "Messages This Week",
            sentCount: 127,
            receivedCount: 143
        )

        // Row 4: Achievement card (now full width)
        let achievementCard = BentoCard(
            title: "Latest Achievement",
            subtitle: "100 conversations milestone!",
            icon: "trophy.fill",
            value: "🎉",
            color: .systemYellow,
            size: .large
        )

        // Layout cards
        var currentY: CGFloat = 0

        // Row 1: Large streaks card
        bentoGridView.addSubview(streaksCard)
        streaksCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            streaksCard.leadingAnchor.constraint(equalTo: bentoGridView.leadingAnchor),
            streaksCard.topAnchor.constraint(equalTo: bentoGridView.topAnchor),
            streaksCard.widthAnchor.constraint(equalToConstant: screenWidth),
            streaksCard.heightAnchor.constraint(equalToConstant: 200)
        ])
        // Add tap gesture to streaks card
        let streaksTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        streaksCard.addGestureRecognizer(streaksTapGesture)
        streaksCard.isUserInteractionEnabled = true
        currentY += 200 + spacing

        // Row 2: Two medium cards (Active Matches, Pending Matches)
        let mediumWidth = (screenWidth - spacing) / 2
        addCard(matchesCard, x: 0, y: currentY, width: mediumWidth, height: 140)
        addCard(pendingMatchesCard, x: mediumWidth + spacing, y: currentY, width: mediumWidth, height: 140)
        currentY += 140 + spacing

        // Row 3: Full width messages card
        bentoGridView.addSubview(messagesCard)
        messagesCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messagesCard.leadingAnchor.constraint(equalTo: bentoGridView.leadingAnchor),
            messagesCard.topAnchor.constraint(equalTo: bentoGridView.topAnchor, constant: currentY),
            messagesCard.widthAnchor.constraint(equalToConstant: screenWidth),
            messagesCard.heightAnchor.constraint(equalToConstant: 120)
        ])
        let messagesTapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        messagesCard.addGestureRecognizer(messagesTapGesture)
        messagesCard.isUserInteractionEnabled = true
        currentY += 120 + spacing

        // Row 4: Full width achievement card
        addCard(achievementCard, x: 0, y: currentY, width: screenWidth, height: 140)
        currentY += 140

        // Update grid view height
        NSLayoutConstraint.activate([
            bentoGridView.heightAnchor.constraint(equalToConstant: currentY)
        ])
    }

    private func addCard(_ card: BentoCard, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        bentoGridView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: bentoGridView.leadingAnchor, constant: x),
            card.topAnchor.constraint(equalTo: bentoGridView.topAnchor, constant: y),
            card.widthAnchor.constraint(equalToConstant: width),
            card.heightAnchor.constraint(equalToConstant: height)
        ])

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
    }

    private func loadUserData() {
        // Load actual user data from UserDefaults
        // Title stays as "Language Lab" without the user's name

        // Update cards with real data if available
        // This would be populated from actual user statistics
    }

    // MARK: - Actions
    @objc private func shareButtonTapped() {
        let text = "Check out my Language Lab! I'm learning languages and making progress every day 🌍"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }

        present(activityVC, animated: true)
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        }

        // Handle different card taps
        if let bentoCard = view as? BentoCard {
            print("Tapped: \(bentoCard.titleLabel.text ?? "")")
        } else if let streaksCard = view as? StreaksCard {
            print("Tapped: Current Streaks")
        } else if let messagesCard = view as? MessagesCard {
            print("Tapped: Messages")
        }
    }
}

// MARK: - Bento Card View
private class BentoCard: UIView {
    enum Size {
        case small, medium, large
    }

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let iconImageView = UIImageView()
    let valueLabel = UILabel()

    init(title: String, subtitle: String, icon: String, value: String, color: UIColor, size: Size) {
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        // Icon
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)

        // Title
        titleLabel.text = title
        titleLabel.font = size == .large ? .systemFont(ofSize: 20, weight: .semibold) :
                        size == .medium ? .systemFont(ofSize: 16, weight: .semibold) :
                        .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = subtitle
        subtitleLabel.font = size == .large ? .systemFont(ofSize: 14, weight: .regular) :
                           .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        addSubview(subtitleLabel)

        // Value
        valueLabel.text = value
        valueLabel.font = size == .large ? .systemFont(ofSize: 32, weight: .bold) :
                         size == .medium ? .systemFont(ofSize: 24, weight: .bold) :
                         .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = color
        valueLabel.textAlignment = .left
        addSubview(valueLabel)

        // Layout
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let padding: CGFloat = size == .large ? 20 : size == .medium ? 16 : 12
        let iconSize: CGFloat = size == .large ? 32 : size == .medium ? 28 : 24

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            // Value - left aligned
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding)
        ])

        if size == .small {
            // For small cards, hide subtitle if needed for space
            subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Streaks Card View
private class StreaksCard: UIView {
    let titleLabel = UILabel()
    private let stackView = UIStackView()

    init(title: String, streaks: [(flag: String, name: String, language: String, days: Int)]) {
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        // Title with flame icon
        titleLabel.text = "🔥 " + title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        // Stack view for streak rows
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        addSubview(stackView)

        // Add streak rows
        for (index, streak) in streaks.enumerated() {
            if index < 5 { // Limit to top 5
                let streakRow = createStreakRow(
                    rank: index + 1,
                    flag: streak.flag,
                    name: streak.name,
                    language: streak.language,
                    days: streak.days
                )
                stackView.addArrangedSubview(streakRow)
            }
        }

        // Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createStreakRow(rank: Int, flag: String, name: String, language: String, days: Int) -> UIView {
        let container = UIView()

        // Rank label
        let rankLabel = UILabel()
        rankLabel.text = "\(rank)"
        rankLabel.font = .systemFont(ofSize: 14, weight: .bold)
        rankLabel.textColor = rank <= 3 ? .systemOrange : .secondaryLabel
        rankLabel.textAlignment = .center
        container.addSubview(rankLabel)

        // Flag label
        let flagLabel = UILabel()
        flagLabel.text = flag
        flagLabel.font = .systemFont(ofSize: 18)
        container.addSubview(flagLabel)

        // Name label
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        nameLabel.textColor = .label
        container.addSubview(nameLabel)

        // Language label
        let languageLabel = UILabel()
        languageLabel.text = "(\(language))"
        languageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        languageLabel.textColor = .secondaryLabel
        container.addSubview(languageLabel)

        // Streak count
        let streakLabel = UILabel()
        streakLabel.text = "\(days) days"
        streakLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        streakLabel.textColor = .systemOrange
        streakLabel.textAlignment = .right
        container.addSubview(streakLabel)

        // Flame icon for top 3
        if rank <= 3 {
            let flameLabel = UILabel()
            flameLabel.text = "🔥"
            flameLabel.font = .systemFont(ofSize: 12)
            container.addSubview(flameLabel)

            flameLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                flameLabel.trailingAnchor.constraint(equalTo: streakLabel.leadingAnchor, constant: -4),
                flameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }

        // Layout
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        streakLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 25),

            flagLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            flagLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            languageLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            languageLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            streakLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            streakLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }
}

// MARK: - Messages Card View
private class MessagesCard: UIView {
    let titleLabel = UILabel()

    init(title: String, sentCount: Int, receivedCount: Int) {
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        // Title
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        // Messages icon
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "message.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)

        // Sent container
        let sentContainer = UIView()
        addSubview(sentContainer)

        let sentIconView = UIImageView()
        sentIconView.image = UIImage(systemName: "arrow.up.circle.fill")
        sentIconView.tintColor = .systemBlue
        sentIconView.contentMode = .scaleAspectFit
        sentContainer.addSubview(sentIconView)

        let sentLabel = UILabel()
        sentLabel.text = "Sent"
        sentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        sentLabel.textColor = .secondaryLabel
        sentContainer.addSubview(sentLabel)

        let sentCountLabel = UILabel()
        sentCountLabel.text = "\(sentCount)"
        sentCountLabel.font = .systemFont(ofSize: 24, weight: .bold)
        sentCountLabel.textColor = .systemBlue
        sentContainer.addSubview(sentCountLabel)

        // Received container
        let receivedContainer = UIView()
        addSubview(receivedContainer)

        let receivedIconView = UIImageView()
        receivedIconView.image = UIImage(systemName: "arrow.down.circle.fill")
        receivedIconView.tintColor = .systemTeal
        receivedIconView.contentMode = .scaleAspectFit
        receivedContainer.addSubview(receivedIconView)

        let receivedLabel = UILabel()
        receivedLabel.text = "Received"
        receivedLabel.font = .systemFont(ofSize: 14, weight: .regular)
        receivedLabel.textColor = .secondaryLabel
        receivedContainer.addSubview(receivedLabel)

        let receivedCountLabel = UILabel()
        receivedCountLabel.text = "\(receivedCount)"
        receivedCountLabel.font = .systemFont(ofSize: 24, weight: .bold)
        receivedCountLabel.textColor = .systemTeal
        receivedContainer.addSubview(receivedCountLabel)

        // Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        sentContainer.translatesAutoresizingMaskIntoConstraints = false
        receivedContainer.translatesAutoresizingMaskIntoConstraints = false
        sentIconView.translatesAutoresizingMaskIntoConstraints = false
        sentLabel.translatesAutoresizingMaskIntoConstraints = false
        sentCountLabel.translatesAutoresizingMaskIntoConstraints = false
        receivedIconView.translatesAutoresizingMaskIntoConstraints = false
        receivedLabel.translatesAutoresizingMaskIntoConstraints = false
        receivedCountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Title
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),

            // Sent container - left side, below title
            sentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            sentContainer.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            sentContainer.widthAnchor.constraint(equalToConstant: 100),
            sentContainer.heightAnchor.constraint(equalToConstant: 50),

            sentIconView.leadingAnchor.constraint(equalTo: sentContainer.leadingAnchor),
            sentIconView.topAnchor.constraint(equalTo: sentContainer.topAnchor),
            sentIconView.widthAnchor.constraint(equalToConstant: 20),
            sentIconView.heightAnchor.constraint(equalToConstant: 20),

            sentCountLabel.leadingAnchor.constraint(equalTo: sentIconView.trailingAnchor, constant: 8),
            sentCountLabel.centerYAnchor.constraint(equalTo: sentIconView.centerYAnchor),

            sentLabel.leadingAnchor.constraint(equalTo: sentIconView.leadingAnchor),
            sentLabel.topAnchor.constraint(equalTo: sentIconView.bottomAnchor, constant: 4),

            // Received container - left side, next to sent
            receivedContainer.leadingAnchor.constraint(equalTo: sentContainer.trailingAnchor, constant: 40),
            receivedContainer.topAnchor.constraint(equalTo: sentContainer.topAnchor),
            receivedContainer.widthAnchor.constraint(equalToConstant: 120),
            receivedContainer.heightAnchor.constraint(equalToConstant: 50),

            receivedIconView.leadingAnchor.constraint(equalTo: receivedContainer.leadingAnchor),
            receivedIconView.topAnchor.constraint(equalTo: receivedContainer.topAnchor),
            receivedIconView.widthAnchor.constraint(equalToConstant: 20),
            receivedIconView.heightAnchor.constraint(equalToConstant: 20),

            receivedCountLabel.leadingAnchor.constraint(equalTo: receivedIconView.trailingAnchor, constant: 8),
            receivedCountLabel.centerYAnchor.constraint(equalTo: receivedIconView.centerYAnchor),

            receivedLabel.leadingAnchor.constraint(equalTo: receivedIconView.leadingAnchor),
            receivedLabel.topAnchor.constraint(equalTo: receivedIconView.bottomAnchor, constant: 4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}