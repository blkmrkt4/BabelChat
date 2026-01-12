import UIKit
import ImageIO

/// A swipeable carousel featuring the app's key screens: Landing, Features, How It Works, and Pricing
class OnboardingCarouselViewController: UIViewController {

    // MARK: - Properties
    var isViewingFromProfile = false
    private var pricingConfig: PricingConfig = PricingConfig.defaultConfig
    private let subscriptionService = SubscriptionService.shared

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let closeButton = UIButton(type: .system)
    private let getStartedButton = UIButton(type: .system)

    // Pricing card references for updating
    private var freeFeatureStack: UIStackView?
    private var premiumFeatureStack: UIStackView?
    private var proFeatureStack: UIStackView?
    private var premiumPriceLabel: UILabel?
    private var proPriceLabel: UILabel?
    private var freePriceLabel: UILabel?

    private let numberOfPages = 4

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
                self.subscriptionService.updatePricingConfig(config)
                self.updatePricingCards(with: config)
            }
        }

        // Fetch real App Store prices from RevenueCat
        subscriptionService.fetchOfferings { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let offerings):
                    self?.updatePricesFromOfferings(offerings)
                case .failure:
                    // Keep using config prices as fallback
                    break
                }
            }
        }
    }

    private func updatePricesFromOfferings(_ offerings: [SubscriptionOffering]) {
        // Update Premium price with localized App Store price
        if let premiumOffering = offerings.first(where: { $0.tier == .premium }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? premiumOffering.weeklyPriceString
                : premiumOffering.localizedPricePerPeriod
            premiumPriceLabel?.text = priceText
        }

        // Update Pro price with localized App Store price
        if let proOffering = offerings.first(where: { $0.tier == .pro }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? proOffering.weeklyPriceString
                : proOffering.localizedPricePerPeriod
            proPriceLabel?.text = priceText
        }

        // Free tier shows "7-Day Trial" (no price change needed)
        freePriceLabel?.text = "Free"
    }

    private func updatePricingCards(with config: PricingConfig) {
        // Use config prices as initial values (RevenueCat will update with real prices)
        premiumPriceLabel?.text = config.premiumPriceFormatted
        proPriceLabel?.text = config.proPriceFormatted

        // Update free features
        if let stack = freeFeatureStack {
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for feature in config.freeFeatures {
                let label = createPricingFeatureLabel(feature.title)
                stack.addArrangedSubview(label)
            }
        }

        // Update premium features
        if let stack = premiumFeatureStack {
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for feature in config.premiumFeatures {
                let label = createPricingFeatureLabel(feature.title)
                stack.addArrangedSubview(label)
            }
        }

        // Update pro features
        if let stack = proFeatureStack {
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for feature in config.proFeatures {
                let label = createPricingFeatureLabel(feature.title)
                stack.addArrangedSubview(label)
            }
        }
    }

    private func createPricingFeatureLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = "✓ \(text)"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.numberOfLines = 0
        return label
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .black

        // Scroll view for pages
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        view.addSubview(scrollView)

        // Page control
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
        view.addSubview(pageControl)

        // Close button (only visible when viewing from profile)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.isHidden = !isViewingFromProfile
        view.addSubview(closeButton)

        // Get Started button (only visible when NOT viewing from profile)
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        getStartedButton.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        getStartedButton.setTitleColor(.black, for: .normal)
        getStartedButton.layer.cornerRadius = 25
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        getStartedButton.isHidden = isViewingFromProfile
        view.addSubview(getStartedButton)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Close button - top right
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Scroll view - full screen
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Get Started button - bottom center, above page control
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70),
            getStartedButton.heightAnchor.constraint(equalToConstant: 50),

            // Page control - bottom
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupPages() {
        // Page 1: Landing (Logo + Tagline with GIF background)
        let page1 = createLandingPage()
        scrollView.addSubview(page1)

        // Page 2: Features (What makes this special)
        let page2 = createFeaturesPage()
        scrollView.addSubview(page2)

        // Page 3: How It Works
        let page3 = createHowItWorksPage()
        scrollView.addSubview(page3)

        // Page 4: Pricing
        let page4 = createPricingPage()
        scrollView.addSubview(page4)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let pageWidth = view.bounds.width
        let pageHeight = view.bounds.height

        // Update page frames
        for (index, subview) in scrollView.subviews.enumerated() {
            subview.frame = CGRect(
                x: pageWidth * CGFloat(index),
                y: 0,
                width: pageWidth,
                height: pageHeight
            )
        }

        // Update content size
        scrollView.contentSize = CGSize(
            width: pageWidth * CGFloat(numberOfPages),
            height: pageHeight
        )

        // Bring close button to front
        view.bringSubviewToFront(closeButton)
        view.bringSubviewToFront(pageControl)
    }

    // MARK: - Page 1: Landing
    private func createLandingPage() -> UIView {
        let pageView = UIView()

        // Background image/GIF
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        if let gifImage = loadGIF(named: "Language_Animation") {
            backgroundImageView.image = gifImage
        } else {
            setupAnimatedGradient(for: backgroundImageView)
        }
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(backgroundImageView)

        // Dark overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(overlayView)

        // Logo
        let logoLabel = UILabel()
        logoLabel.text = "Fluenca"
        logoLabel.font = .systemFont(ofSize: 52, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(logoLabel)

        // Tagline
        let taglineLabel = UILabel()
        taglineLabel.text = "Science says your brain learns faster when it cares"
        taglineLabel.font = .systemFont(ofSize: 18, weight: .medium)
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 0
        taglineLabel.lineBreakMode = .byWordWrapping
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(taglineLabel)

        // Thin separator line between taglines
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(separatorLine)

        // Second tagline
        let taglineLabel2 = UILabel()
        taglineLabel2.text = "Speaking like a local is the fastest path to fluency"
        taglineLabel2.font = .systemFont(ofSize: 15, weight: .regular)
        taglineLabel2.textColor = UIColor.white.withAlphaComponent(0.7)
        taglineLabel2.textAlignment = .center
        taglineLabel2.numberOfLines = 0
        taglineLabel2.lineBreakMode = .byWordWrapping
        taglineLabel2.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(taglineLabel2)

        // Swipe hint
        let swipeHint = UILabel()
        swipeHint.text = "Swipe to learn more →"
        swipeHint.font = .systemFont(ofSize: 15, weight: .medium)
        swipeHint.textColor = UIColor.white.withAlphaComponent(0.7)
        swipeHint.textAlignment = .center
        swipeHint.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(swipeHint)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: pageView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: pageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),

            logoLabel.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: pageView.safeAreaLayoutGuide.topAnchor, constant: 50),

            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 16),
            taglineLabel.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            taglineLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            taglineLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40),

            // Separator line between taglines
            separatorLine.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 60),
            separatorLine.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -60),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            taglineLabel2.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 12),
            taglineLabel2.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
            taglineLabel2.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 40),
            taglineLabel2.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -40),

            swipeHint.bottomAnchor.constraint(equalTo: pageView.bottomAnchor, constant: -100),
            swipeHint.centerXAnchor.constraint(equalTo: pageView.centerXAnchor)
        ])

        return pageView
    }

    // MARK: - Page 2: Features
    private func createFeaturesPage() -> UIView {
        let pageView = UIView()
        pageView.backgroundColor = .black

        // Subtle gold gradient overlay
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(gradientView)

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.12, green: 0.10, blue: 0.05, alpha: 1).cgColor,  // Dark with gold tint
            UIColor.black.cgColor,
            UIColor(red: 0.08, green: 0.06, blue: 0.02, alpha: 1).cgColor   // Dark with subtle gold
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)

        // Content
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(contentStack)

        // Icon container (to center it)
        let iconContainer = UIView()
        let iconView = UIImageView(image: UIImage(systemName: "heart.text.square.fill"))
        iconView.tintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 60),
            iconView.widthAnchor.constraint(equalToConstant: 60)
        ])
        contentStack.addArrangedSubview(iconContainer)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Learn the Way People Really Talk"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Textbooks can't teach you the local lingo, slang, and authentic expressions. Real conversations can."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subtitleLabel)

        // Spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        contentStack.addArrangedSubview(spacer)

        // Feature points
        let features = [
            ("sparkles", "Chemistry makes learning stick", "You're more likely to stay motivated with someone you genuinely connect with"),
            ("person.2.fill", "Match your way", "Looking for romance, friendship, or just language practice? You choose"),
            ("bubble.left.and.text.bubble.right.fill", "Practice with your Muse", "AI-powered language muses available 24/7 when humans aren't around")
        ]

        for (icon, title, desc) in features {
            let featureView = createFeatureRow(icon: icon, title: title, description: desc)
            contentStack.addArrangedSubview(featureView)
        }

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: pageView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),

            contentStack.centerYAnchor.constraint(equalTo: pageView.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -24)
        ])

        // Update gradient frame after layout
        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
        }

        return pageView
    }

    private func createFeatureRow(icon: String, title: String, description: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        descLabel.numberOfLines = 0
        textStack.addArrangedSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Page 3: How It Works
    private func createHowItWorksPage() -> UIView {
        let pageView = UIView()
        pageView.backgroundColor = .black

        // Subtle gold gradient overlay
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(gradientView)

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.cgColor,
            UIColor(red: 0.10, green: 0.08, blue: 0.03, alpha: 1).cgColor,  // Dark with gold tint
            UIColor.black.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)

        // Content
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(contentStack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Learn As You Chat"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Built-in tools help you understand\nand improve with every message"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subtitleLabel)

        // Spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 24).isActive = true
        contentStack.addArrangedSubview(spacer)

        // How it works items
        let items = [
            ("hand.point.right.fill", "Swipe Right", "See instant translations in your language"),
            ("hand.point.left.fill", "Swipe Left", "Get grammar help and learn from corrections"),
            ("flask.fill", "Language Lab", "Track your progress and see how you're improving"),
            ("message.badge.filled.fill", "Practice Daily", "The more you chat, the faster you learn")
        ]

        for (icon, title, desc) in items {
            let itemView = createHowItWorksItem(icon: icon, title: title, description: desc)
            contentStack.addArrangedSubview(itemView)
        }

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: pageView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),

            contentStack.centerYAnchor.constraint(equalTo: pageView.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -32)
        ])

        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
        }

        return pageView
    }

    private func createHowItWorksItem(icon: String, title: String, description: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.8, green: 0.65, blue: 0.0, alpha: 0.3).cgColor  // Gold border
        container.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hStack)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)  // Gold
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        hStack.addArrangedSubview(iconView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0
        textStack.addArrangedSubview(descLabel)

        hStack.addArrangedSubview(textStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            container.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 64)
        ])

        return container
    }

    // MARK: - Page 4: Pricing
    private func createPricingPage() -> UIView {
        let pageView = UIView()
        pageView.backgroundColor = .black

        // Subtle gold gradient overlay
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(gradientView)

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.08, green: 0.06, blue: 0.02, alpha: 1).cgColor,   // Dark with subtle gold
            UIColor.black.cgColor,
            UIColor(red: 0.10, green: 0.08, blue: 0.03, alpha: 1).cgColor    // Dark with gold tint
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)

        // Content - use scroll view to fit 3 tiers
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageView.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Choose Your Plan"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Start free, upgrade when you're ready"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        contentStack.addArrangedSubview(subtitleLabel)

        // Spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)

        // Free tier
        let freeCard = createPricingCard(tier: .free)
        contentStack.addArrangedSubview(freeCard)

        // Premium tier
        let premiumCard = createPricingCard(tier: .premium)
        contentStack.addArrangedSubview(premiumCard)

        // Pro tier
        let proCard = createPricingCard(tier: .pro)
        contentStack.addArrangedSubview(proCard)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: pageView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 60),
            scrollView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor, constant: -120),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])

        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
        }

        return pageView
    }

    private func createPricingCard(tier: SubscriptionTier) -> UIView {
        let goldColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        let isPremium = tier == .premium
        let isPro = tier == .pro
        let isFree = tier == .free

        let container = UIView()
        if isPro {
            container.backgroundColor = goldColor.withAlphaComponent(0.12)
            container.layer.borderWidth = 1.5
            container.layer.borderColor = goldColor.cgColor
        } else if isPremium {
            container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            container.layer.borderWidth = 1.5
            container.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            container.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = tier.displayName
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        if isPro {
            titleLabel.textColor = goldColor
        } else if isPremium {
            titleLabel.textColor = .systemBlue
        } else {
            titleLabel.textColor = .white
        }
        headerStack.addArrangedSubview(titleLabel)

        let priceLabel = UILabel()
        // Use localized price from RevenueCat if available, fallback to tier.price
        if isFree {
            priceLabel.text = "Free"
        } else if isPremium {
            priceLabel.text = subscriptionService.localizedPricePerPeriod(for: .premium)
        } else if isPro {
            priceLabel.text = subscriptionService.localizedPricePerPeriod(for: .pro)
        } else {
            priceLabel.text = tier.price
        }
        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)
        priceLabel.textColor = .white
        headerStack.addArrangedSubview(priceLabel)

        // Store price label reference for updating
        if isFree {
            self.freePriceLabel = priceLabel
        } else if isPremium {
            self.premiumPriceLabel = priceLabel
        } else if isPro {
            self.proPriceLabel = priceLabel
        }

        stack.addArrangedSubview(headerStack)

        // Short description
        let descLabel = UILabel()
        descLabel.text = tier.shortDescription
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        stack.addArrangedSubview(descLabel)

        // Features stack (will be populated by loadPricingConfig)
        let featureStack = UIStackView()
        featureStack.axis = .vertical
        featureStack.spacing = 4
        featureStack.alignment = .leading
        stack.addArrangedSubview(featureStack)

        // Store reference for updating
        if isFree {
            self.freeFeatureStack = featureStack
        } else if isPremium {
            self.premiumFeatureStack = featureStack
        } else if isPro {
            self.proFeatureStack = featureStack
        }

        // Add initial features from default config
        let features: [String]
        if isFree {
            features = pricingConfig.freeFeaturesText
        } else if isPremium {
            features = pricingConfig.premiumFeaturesText
        } else {
            features = pricingConfig.proFeaturesText
        }

        for feature in features {
            let label = createPricingFeatureLabel(feature)
            featureStack.addArrangedSubview(label)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            container.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 48)
        ])

        return container
    }

    // MARK: - Helpers
    private func loadGIF(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url) else {
            return nil
        }

        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += frameDuration
                }
            }
        }

        if images.isEmpty { return nil }
        if images.count == 1 { return images.first }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    private func setupAnimatedGradient(for imageView: UIImageView) {
        imageView.backgroundColor = .systemIndigo

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1).cgColor,
            UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1).cgColor,
            UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        imageView.layer.insertSublayer(gradientLayer, at: 0)

        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [
            UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1).cgColor,
            UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1).cgColor,
            UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1).cgColor
        ]
        animation.duration = 5.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")

        DispatchQueue.main.async {
            gradientLayer.frame = imageView.bounds
        }
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func getStartedTapped() {
        // Mark welcome screen as seen
        UserEngagementTracker.shared.markWelcomeScreenSeen()

        // Navigate to authentication screen
        let authVC = AuthenticationViewController()
        navigationController?.pushViewController(authVC, animated: true)
    }

    @objc private func pageControlTapped() {
        let page = pageControl.currentPage
        let offset = CGPoint(x: view.bounds.width * CGFloat(page), y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingCarouselViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / view.bounds.width))
        pageControl.currentPage = page
    }
}
