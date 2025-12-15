import UIKit

class TutorialViewController: UIViewController {

    // MARK: - Pricing Config
    private var pricingConfig: PricingConfig = PricingConfig.defaultConfig

    // Pricing UI references for dynamic updates
    private var freePriceLabel: UILabel?
    private var premiumPriceLabel: UILabel?
    private var proPriceLabel: UILabel?
    private var freeFeaturesLabel: UILabel?
    private var premiumFeaturesLabel: UILabel?
    private var proFeaturesLabel: UILabel?

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let closeButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    // MARK: - Tutorial Pages
    private struct TutorialPage {
        let icon: String
        let title: String
        let description: String
        let tips: [String]
        let isDiscoverPage: Bool  // Special flag for button icons page
        let isPricingPage: Bool   // Special flag for pricing tiers page

        init(icon: String, title: String, description: String, tips: [String], isDiscoverPage: Bool = false, isPricingPage: Bool = false) {
            self.icon = icon
            self.title = title
            self.description = description
            self.tips = tips
            self.isDiscoverPage = isDiscoverPage
            self.isPricingPage = isPricingPage
        }
    }

    // Button definitions for Discover page - using custom image assets
    private struct ActionButtonInfo {
        let imageName: String?  // Custom image asset name (nil for SF Symbol)
        let sfSymbol: String?   // SF Symbol name (used if imageName is nil)
        let description: String
        let size: CGFloat       // Button display size
    }

    private var actionButtons: [ActionButtonInfo] {
        [
            ActionButtonInfo(imageName: "RejectButton", sfSymbol: nil, description: "Pass on this profile", size: 50),
            ActionButtonInfo(imageName: "StarButton", sfSymbol: nil, description: "Save for later", size: 36),
            ActionButtonInfo(imageName: "MatchButton", sfSymbol: nil, description: "Send match request", size: 50)
        ]
    }

    private let tutorialPages: [TutorialPage] = [
        TutorialPage(
            icon: "hand.tap.fill",
            title: "Discover & Match",
            description: "Browse potential partners using the action buttons",
            tips: [], // Will use custom button display instead
            isDiscoverPage: true
        ),
        TutorialPage(
            icon: "bubble.left.and.bubble.right.fill",
            title: "Chat & Learn",
            description: "Have real conversations to practice your target language",
            tips: [
                "Write messages in your learning language",
                "Don't worry about mistakes - that's how you learn!",
                "Ask your partner to correct you",
                "Tap the Muse button in the message bar for help composing"
            ]
        ),
        TutorialPage(
            icon: "sparkles",
            title: "Your Muse Assistant",
            description: "Get instant help composing messages in your target language",
            tips: [
                "Tap the Muse button (left of message input) anytime",
                "Ask how to say something in your learning language",
                "Muse gives you the perfect phrase to copy or use directly",
                "Practice with AI Muses 24/7 from the Matches screen"
            ]
        ),
        TutorialPage(
            icon: "hand.point.right.fill",
            title: "Swipe Right for Translation",
            description: "Instantly understand any message",
            tips: [
                "Swipe right on any message to see the translation",
                "The translation appears in your native language",
                "Helps you follow along when you don't understand",
                "Great for learning new vocabulary in context"
            ]
        ),
        TutorialPage(
            icon: "hand.point.left.fill",
            title: "Swipe Left for Grammar",
            description: "Get AI-powered language insights",
            tips: [
                "Swipe left on any message to see grammar help",
                "See corrections and explanations",
                "Learn alternative ways to express the same idea",
                "Long-press the grammar pane to toggle explanation language"
            ]
        ),
        TutorialPage(
            icon: "photo.on.rectangle.angled",
            title: "Managing Photos",
            description: "Control your profile photos and captions",
            tips: [
                "Tap any photo to view it full-screen",
                "Long-press a photo for options menu",
                "Add or edit captions to tell your story",
                "Report inappropriate photos from other profiles"
            ]
        ),
        TutorialPage(
            icon: "flask.fill",
            title: "Language Lab",
            description: "Track your language learning journey",
            tips: [
                "Access from the flask icon on your profile",
                "View your progress dashboard and stats",
                "See your conversation history highlights",
                "Track vocabulary and phrases you've learned"
            ]
        ),
        TutorialPage(
            icon: "star.fill",
            title: "Choose Your Plan",
            description: "Start free, upgrade when you're ready",
            tips: [], // Uses custom pricing layout
            isPricingPage: true
        )
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupPages()
        loadPricingConfig()
    }

    private func loadPricingConfig() {
        Task {
            let config = await PricingConfigManager.shared.getConfig()
            await MainActor.run {
                self.pricingConfig = config
                self.updatePricingCards(with: config)
            }
        }
    }

    private func updatePricingCards(with config: PricingConfig) {
        // Update price labels
        premiumPriceLabel?.text = config.premiumPriceFormatted
        proPriceLabel?.text = config.proPriceFormatted

        // Update feature labels
        if let label = freeFeaturesLabel {
            let features = config.freeFeaturesText.prefix(4).map { "• \($0)" }.joined(separator: "\n")
            label.text = features
        }
        if let label = premiumFeaturesLabel {
            let features = config.premiumFeaturesText.prefix(4).map { "• \($0)" }.joined(separator: "\n")
            label.text = features
        }
        if let label = proFeaturesLabel {
            let features = config.proFeaturesText.prefix(4).map { "• \($0)" }.joined(separator: "\n")
            label.text = features
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // Gold color used throughout
    private let goldColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .black

        // Subtle gold gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.10, green: 0.08, blue: 0.03, alpha: 1).cgColor,  // Dark with gold tint
            UIColor.black.cgColor,
            UIColor(red: 0.08, green: 0.06, blue: 0.02, alpha: 1).cgColor   // Dark with subtle gold
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Scroll view for pages
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        view.addSubview(scrollView)

        // Page control
        pageControl.numberOfPages = tutorialPages.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = goldColor
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
        view.addSubview(pageControl)

        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Done button - gold themed
        doneButton.setTitle("Got It!", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        doneButton.backgroundColor = goldColor
        doneButton.setTitleColor(.black, for: .normal)
        doneButton.layer.cornerRadius = 25
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(doneButton)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -16),

            // Page control
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20),

            // Done button
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupPages() {
        for (index, page) in tutorialPages.enumerated() {
            let pageView = createPageView(for: page, at: index)
            scrollView.addSubview(pageView)
        }

        // Set content size after layout
        view.layoutIfNeeded()
        scrollView.contentSize = CGSize(
            width: view.bounds.width * CGFloat(tutorialPages.count),
            height: scrollView.bounds.height
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient frame
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }

        // Update page frames
        for (index, subview) in scrollView.subviews.enumerated() {
            subview.frame = CGRect(
                x: view.bounds.width * CGFloat(index),
                y: 0,
                width: view.bounds.width,
                height: scrollView.bounds.height
            )
        }

        // Update content size
        scrollView.contentSize = CGSize(
            width: view.bounds.width * CGFloat(tutorialPages.count),
            height: scrollView.bounds.height
        )
    }

    private func createPageView(for page: TutorialPage, at index: Int) -> UIView {
        let pageView = UIView()
        pageView.frame = CGRect(
            x: view.bounds.width * CGFloat(index),
            y: 0,
            width: view.bounds.width,
            height: scrollView.bounds.height
        )

        // Icon - gold colored
        let iconView = UIImageView(image: UIImage(systemName: page.icon))
        iconView.tintColor = goldColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(iconView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(titleLabel)

        // Description
        let descLabel = UILabel()
        descLabel.text = page.description
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(descLabel)

        // Tips container - dark with gold border
        let tipsContainer = UIView()
        tipsContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        tipsContainer.layer.cornerRadius = 16
        tipsContainer.layer.borderWidth = 1
        tipsContainer.layer.borderColor = UIColor(red: 0.8, green: 0.65, blue: 0.0, alpha: 0.3).cgColor
        tipsContainer.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(tipsContainer)

        // Check if this is the Discover page with button icons
        if page.isDiscoverPage {
            // Create button icons display
            let buttonsStack = UIStackView()
            buttonsStack.axis = .vertical
            buttonsStack.spacing = 16
            buttonsStack.translatesAutoresizingMaskIntoConstraints = false
            tipsContainer.addSubview(buttonsStack)

            for buttonInfo in actionButtons {
                let rowView = createButtonTipRow(buttonInfo: buttonInfo)
                buttonsStack.addArrangedSubview(rowView)
            }

            NSLayoutConstraint.activate([
                buttonsStack.topAnchor.constraint(equalTo: tipsContainer.topAnchor, constant: 20),
                buttonsStack.leadingAnchor.constraint(equalTo: tipsContainer.leadingAnchor, constant: 16),
                buttonsStack.trailingAnchor.constraint(equalTo: tipsContainer.trailingAnchor, constant: -16),
                buttonsStack.bottomAnchor.constraint(equalTo: tipsContainer.bottomAnchor, constant: -20)
            ])
        } else if page.isPricingPage {
            // Create pricing tiers display
            let pricingStack = UIStackView()
            pricingStack.axis = .vertical
            pricingStack.spacing = 8
            pricingStack.translatesAutoresizingMaskIntoConstraints = false
            tipsContainer.addSubview(pricingStack)

            // Add all 3 tiers
            let tiers: [SubscriptionTier] = [.free, .premium, .pro]
            for tier in tiers {
                let tierView = createPricingTierRow(tier: tier)
                pricingStack.addArrangedSubview(tierView)
            }

            NSLayoutConstraint.activate([
                pricingStack.topAnchor.constraint(equalTo: tipsContainer.topAnchor, constant: 10),
                pricingStack.leadingAnchor.constraint(equalTo: tipsContainer.leadingAnchor, constant: 10),
                pricingStack.trailingAnchor.constraint(equalTo: tipsContainer.trailingAnchor, constant: -10),
                pricingStack.bottomAnchor.constraint(equalTo: tipsContainer.bottomAnchor, constant: -10)
            ])
        } else {
            // Standard tips stack
            let tipsStack = UIStackView()
            tipsStack.axis = .vertical
            tipsStack.spacing = 12
            tipsStack.translatesAutoresizingMaskIntoConstraints = false
            tipsContainer.addSubview(tipsStack)

            for tip in page.tips {
                let tipView = createTipView(text: tip)
                tipsStack.addArrangedSubview(tipView)
            }

            NSLayoutConstraint.activate([
                tipsStack.topAnchor.constraint(equalTo: tipsContainer.topAnchor, constant: 20),
                tipsStack.leadingAnchor.constraint(equalTo: tipsContainer.leadingAnchor, constant: 20),
                tipsStack.trailingAnchor.constraint(equalTo: tipsContainer.trailingAnchor, constant: -20),
                tipsStack.bottomAnchor.constraint(equalTo: tipsContainer.bottomAnchor, constant: -20)
            ])
        }

        NSLayoutConstraint.activate([
            // Icon - moved up
            iconView.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50),

            // Title - tighter spacing
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -24),

            // Description - tighter spacing
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 24),
            descLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -24),

            // Tips container - tighter spacing
            tipsContainer.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            tipsContainer.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 20),
            tipsContainer.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -20)
        ])

        return pageView
    }

    private func createButtonTipRow(buttonInfo: ActionButtonInfo) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let buttonSize = buttonInfo.size

        // Create image view for custom button
        let buttonImageView = UIImageView()
        buttonImageView.contentMode = .scaleAspectFit
        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonImageView)

        // Load custom image or SF Symbol
        if let imageName = buttonInfo.imageName, let image = UIImage(named: imageName) {
            buttonImageView.image = image.withRenderingMode(.alwaysOriginal)
        } else if let sfSymbol = buttonInfo.sfSymbol {
            let config = UIImage.SymbolConfiguration(pointSize: buttonSize * 0.6, weight: .medium)
            buttonImageView.image = UIImage(systemName: sfSymbol, withConfiguration: config)
            buttonImageView.tintColor = goldColor
        }

        // Description label
        let descLabel = UILabel()
        descLabel.text = buttonInfo.description
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .white
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            buttonImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            buttonImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttonImageView.widthAnchor.constraint(equalToConstant: buttonSize),
            buttonImageView.heightAnchor.constraint(equalToConstant: buttonSize),

            descLabel.leadingAnchor.constraint(equalTo: buttonImageView.trailingAnchor, constant: 16),
            descLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            descLabel.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            descLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])

        return container
    }

    private func createTipView(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bulletView = UIView()
        bulletView.backgroundColor = goldColor  // Gold bullet
        bulletView.layer.cornerRadius = 4
        bulletView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bulletView)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            bulletView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bulletView.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            bulletView.widthAnchor.constraint(equalToConstant: 8),
            bulletView.heightAnchor.constraint(equalToConstant: 8),

            label.leadingAnchor.constraint(equalTo: bulletView.trailingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createPricingTierRow(tier: SubscriptionTier) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Background styling based on tier
        let isPremium = tier == .premium
        let isPro = tier == .pro
        let isFree = tier == .free

        if isPremium {
            container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            container.layer.borderWidth = 1.5
            container.layer.borderColor = UIColor.systemBlue.cgColor
        } else if isPro {
            container.backgroundColor = goldColor.withAlphaComponent(0.15)
            container.layer.borderWidth = 1.5
            container.layer.borderColor = goldColor.cgColor
        } else {
            container.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }
        container.layer.cornerRadius = 10

        // Header row: tier name + price
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerStack)

        let tierLabel = UILabel()
        tierLabel.text = tier.displayName
        tierLabel.font = .systemFont(ofSize: 15, weight: .bold)
        if isPro {
            tierLabel.textColor = goldColor
        } else if isPremium {
            tierLabel.textColor = .systemBlue
        } else {
            tierLabel.textColor = .white
        }
        headerStack.addArrangedSubview(tierLabel)

        let priceLabel = UILabel()
        // Use config for pricing
        if isPremium {
            priceLabel.text = pricingConfig.premiumPriceFormatted
            self.premiumPriceLabel = priceLabel
        } else if isPro {
            priceLabel.text = pricingConfig.proPriceFormatted
            self.proPriceLabel = priceLabel
        } else {
            priceLabel.text = tier.price  // Free is always "Free"
            self.freePriceLabel = priceLabel
        }
        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.textColor = .white
        headerStack.addArrangedSubview(priceLabel)

        // Short description
        let descLabel = UILabel()
        descLabel.text = tier.shortDescription
        descLabel.font = .systemFont(ofSize: 11, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descLabel)

        // Key features (show first 4) - use config
        let featuresLabel = UILabel()
        let features: [String]
        if isFree {
            features = pricingConfig.freeFeaturesText
            self.freeFeaturesLabel = featuresLabel
        } else if isPremium {
            features = pricingConfig.premiumFeaturesText
            self.premiumFeaturesLabel = featuresLabel
        } else {
            features = pricingConfig.proFeaturesText
            self.proFeaturesLabel = featuresLabel
        }
        let topFeatures = features.prefix(4).map { "• \($0)" }.joined(separator: "\n")
        featuresLabel.text = topFeatures
        featuresLabel.font = .systemFont(ofSize: 11, weight: .regular)
        featuresLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        featuresLabel.numberOfLines = 0
        featuresLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(featuresLabel)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            headerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),

            descLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 2),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),

            featuresLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 4),
            featuresLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            featuresLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            featuresLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    @objc private func pageControlTapped() {
        let page = pageControl.currentPage
        let offset = CGPoint(x: view.bounds.width * CGFloat(page), y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension TutorialViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / view.bounds.width))
        pageControl.currentPage = page

        // Update done button text on last page
        if page == tutorialPages.count - 1 {
            doneButton.setTitle("Start Chatting!", for: .normal)
        } else {
            doneButton.setTitle("Got It!", for: .normal)
        }
    }
}

