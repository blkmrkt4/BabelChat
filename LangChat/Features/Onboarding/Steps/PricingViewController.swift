//
//  PricingViewController.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import UIKit

protocol PricingViewControllerDelegate: AnyObject {
    func didSelectFreeTier()
    func didSelectPremiumTier()
    func didSelectProTier()
    func didSkipPricing()
}

class PricingViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let currencyLabel = UILabel()

    // Free tier card
    private let freeCard = UIView()
    private let freeTierLabel = UILabel()
    private let freePriceLabel = UILabel()
    private let freeFeatureStack = UIStackView()
    private let freeButton = UIButton(type: .system)

    // Premium tier card
    private let premiumCard = UIView()
    private let premiumBadge = UILabel()
    private let premiumTierLabel = UILabel()
    private let premiumPriceLabel = UILabel()
    private let premiumTrialLabel = UILabel()
    private let premiumFeatureStack = UIStackView()
    private let premiumButton = UIButton(type: .system)

    // Pro tier card
    private let proCard = UIView()
    private let proTierLabel = UILabel()
    private let proPriceLabel = UILabel()
    private let proFeatureStack = UIStackView()
    private let proButton = UIButton(type: .system)

    // MARK: - Properties
    weak var delegate: PricingViewControllerDelegate?
    private let subscriptionService = SubscriptionService.shared
    private var pricingConfig: PricingConfig = PricingConfig.defaultConfig

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadPricingConfig()
    }

    // MARK: - Setup
    private func setupViews() {
        // Dark gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.05, green: 0.10, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.10, green: 0.05, blue: 0.20, alpha: 1.0).cgColor
        ]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        overrideUserInterfaceStyle = .dark

        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)

        // Title
        titleLabel.text = "Choose Your Plan"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Practice with AI free, upgrade for real connections & natural voices"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subtitleLabel)

        // Currency/Region indicator
        currencyLabel.text = subscriptionService.pricingRegionDescription
        currencyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        currencyLabel.textColor = .systemBlue.withAlphaComponent(0.9)
        currencyLabel.textAlignment = .center
        currencyLabel.backgroundColor = .white.withAlphaComponent(0.1)
        currencyLabel.layer.cornerRadius = 12
        currencyLabel.layer.masksToBounds = true
        contentStack.addArrangedSubview(currencyLabel)

        // Add padding to currency label
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false
        currencyLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true

        // Setup pricing cards
        setupFreeCard()
        setupPremiumCard()
        setupProCard()
    }

    private func setupFreeCard() {
        freeCard.backgroundColor = .white.withAlphaComponent(0.1)
        freeCard.layer.cornerRadius = 16
        freeCard.layer.borderWidth = 1.5
        freeCard.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        contentStack.addArrangedSubview(freeCard)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.alignment = .leading
        freeCard.addSubview(cardStack)

        // Tier name and price on same line
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .firstBaseline
        cardStack.addArrangedSubview(headerStack)

        freeTierLabel.text = "Free"
        freeTierLabel.font = .systemFont(ofSize: 20, weight: .bold)
        freeTierLabel.textColor = .white
        headerStack.addArrangedSubview(freeTierLabel)

        freePriceLabel.text = "$0"
        freePriceLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        freePriceLabel.textColor = .systemGreen
        headerStack.addArrangedSubview(freePriceLabel)

        // Features (populated by loadPricingConfig)
        freeFeatureStack.axis = .vertical
        freeFeatureStack.spacing = 6
        freeFeatureStack.alignment = .leading
        cardStack.addArrangedSubview(freeFeatureStack)

        // Continue with Free button
        freeButton.setTitle("Continue with Free", for: .normal)
        freeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        freeButton.setTitleColor(.white, for: .normal)
        freeButton.backgroundColor = .white.withAlphaComponent(0.2)
        freeButton.layer.cornerRadius = 22
        freeButton.layer.borderWidth = 1
        freeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        freeButton.addTarget(self, action: #selector(freeTapped), for: .touchUpInside)
        freeButton.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(freeButton)

        // Layout
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: freeCard.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: freeCard.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: freeCard.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: freeCard.bottomAnchor, constant: -16),

            freeButton.heightAnchor.constraint(equalToConstant: 44),
            freeButton.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            freeButton.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor)
        ])
    }

    private func setupPremiumCard() {
        premiumCard.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        premiumCard.layer.cornerRadius = 16
        premiumCard.layer.borderWidth = 2
        premiumCard.layer.borderColor = UIColor.systemBlue.cgColor
        premiumCard.layer.shadowColor = UIColor.systemBlue.cgColor
        premiumCard.layer.shadowOpacity = 0.3
        premiumCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        premiumCard.layer.shadowRadius = 8
        contentStack.addArrangedSubview(premiumCard)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.alignment = .leading
        premiumCard.addSubview(cardStack)

        // Tier name and price on same line
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .firstBaseline
        cardStack.addArrangedSubview(headerStack)

        premiumTierLabel.text = "Premium"
        premiumTierLabel.font = .systemFont(ofSize: 20, weight: .bold)
        premiumTierLabel.textColor = .white
        headerStack.addArrangedSubview(premiumTierLabel)

        premiumPriceLabel.text = "$9.99/mo"
        premiumPriceLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        premiumPriceLabel.textColor = .systemBlue
        headerStack.addArrangedSubview(premiumPriceLabel)

        // Trial info
        premiumTrialLabel.text = "7-day free trial • Cancel anytime"
        premiumTrialLabel.font = .systemFont(ofSize: 12, weight: .medium)
        premiumTrialLabel.textColor = .white.withAlphaComponent(0.9)
        premiumTrialLabel.backgroundColor = .white.withAlphaComponent(0.15)
        premiumTrialLabel.textAlignment = .center
        premiumTrialLabel.layer.cornerRadius = 12
        premiumTrialLabel.layer.masksToBounds = true
        premiumTrialLabel.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(premiumTrialLabel)

        // Features (populated by loadPricingConfig)
        premiumFeatureStack.axis = .vertical
        premiumFeatureStack.spacing = 6
        premiumFeatureStack.alignment = .leading
        cardStack.addArrangedSubview(premiumFeatureStack)

        // Start trial button
        premiumButton.setTitle("Start Free Trial", for: .normal)
        premiumButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        premiumButton.setTitleColor(.white, for: .normal)
        premiumButton.backgroundColor = .systemBlue
        premiumButton.layer.cornerRadius = 22
        premiumButton.addTarget(self, action: #selector(premiumTapped), for: .touchUpInside)
        premiumButton.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(premiumButton)

        // Layout
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: premiumCard.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: premiumCard.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: premiumCard.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: premiumCard.bottomAnchor, constant: -16),

            premiumTrialLabel.heightAnchor.constraint(equalToConstant: 26),
            premiumTrialLabel.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            premiumTrialLabel.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor),

            premiumButton.heightAnchor.constraint(equalToConstant: 44),
            premiumButton.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            premiumButton.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor)
        ])
    }

    private func setupProCard() {
        proCard.backgroundColor = .systemYellow.withAlphaComponent(0.1)
        proCard.layer.cornerRadius = 16
        proCard.layer.borderWidth = 2
        proCard.layer.borderColor = UIColor.systemYellow.cgColor
        proCard.layer.shadowColor = UIColor.systemYellow.cgColor
        proCard.layer.shadowOpacity = 0.3
        proCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        proCard.layer.shadowRadius = 8
        contentStack.addArrangedSubview(proCard)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.alignment = .leading
        proCard.addSubview(cardStack)

        // Tier name and price on same line
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .firstBaseline
        cardStack.addArrangedSubview(headerStack)

        proTierLabel.text = "Pro"
        proTierLabel.font = .systemFont(ofSize: 20, weight: .bold)
        proTierLabel.textColor = .systemYellow
        headerStack.addArrangedSubview(proTierLabel)

        proPriceLabel.text = "$19.99/mo"
        proPriceLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        proPriceLabel.textColor = .systemYellow
        headerStack.addArrangedSubview(proPriceLabel)

        // Features (populated by loadPricingConfig)
        proFeatureStack.axis = .vertical
        proFeatureStack.spacing = 6
        proFeatureStack.alignment = .leading
        cardStack.addArrangedSubview(proFeatureStack)

        // Button
        proButton.setTitle("Start Pro", for: .normal)
        proButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        proButton.setTitleColor(.black, for: .normal)
        proButton.backgroundColor = .systemYellow
        proButton.layer.cornerRadius = 22
        proButton.addTarget(self, action: #selector(proTapped), for: .touchUpInside)
        proButton.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(proButton)

        // Layout
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: proCard.topAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: proCard.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: proCard.trailingAnchor, constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: proCard.bottomAnchor, constant: -16),

            proButton.heightAnchor.constraint(equalToConstant: 44),
            proButton.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            proButton.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor)
        ])
    }

    private func createFeatureLabel(_ text: String, isIncluded: Bool) -> UILabel {
        let label = UILabel()
        let checkmark = isIncluded ? "✓" : "✗"
        label.text = "\(checkmark) \(text)"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white.withAlphaComponent(isIncluded ? 1.0 : 0.5)
        label.numberOfLines = 0
        return label
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Data Loading
    private func loadPricingConfig() {
        // Show loading state for prices
        premiumPriceLabel.text = "Loading..."
        proPriceLabel.text = "Loading..."

        // Show default config for features immediately
        updateUIWithConfig(pricingConfig)

        // Fetch remote config from Supabase for features
        Task {
            let config = await PricingConfigManager.shared.getConfig()
            await MainActor.run {
                self.pricingConfig = config
                // Update SubscriptionService with config (for weekly pricing countries)
                self.subscriptionService.updatePricingConfig(config)
                self.updateUIWithConfig(config)
            }
        }

        // Listen for offerings loaded notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(offeringsDidLoad),
            name: .offeringsLoaded,
            object: nil
        )

        // Fetch from RevenueCat for actual App Store prices
        subscriptionService.fetchOfferings { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let offerings):
                    print("Loaded \(offerings.count) offerings from RevenueCat")
                    self?.updatePricesFromOfferings(offerings)
                case .failure(let error):
                    print("Failed to load offerings: \(error.localizedDescription)")
                    // Use fallback prices from config
                    self?.updatePricesWithFallback()
                }
            }
        }
    }

    @objc private func offeringsDidLoad(_ notification: Notification) {
        guard let offerings = notification.object as? [SubscriptionOffering] else { return }
        updatePricesFromOfferings(offerings)
    }

    private func updatePricesFromOfferings(_ offerings: [SubscriptionOffering]) {
        // Update currency/region label with actual currency from App Store
        currencyLabel.text = subscriptionService.pricingRegionDescription

        // Update Premium price
        if let premiumOffering = offerings.first(where: { $0.tier == .premium }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? premiumOffering.weeklyPriceString
                : premiumOffering.localizedPricePerPeriod
            premiumPriceLabel.text = priceText

            // Update trial info
            if premiumOffering.trialDays > 0 {
                premiumTrialLabel.text = "\(premiumOffering.trialDays)-day free trial • Cancel anytime"
            }
        }

        // Update Pro price
        if let proOffering = offerings.first(where: { $0.tier == .pro }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? proOffering.weeklyPriceString
                : proOffering.localizedPricePerPeriod
            proPriceLabel.text = priceText
        }

        // Show weekly billing note if applicable
        if subscriptionService.shouldShowWeeklyPricing {
            premiumTrialLabel.text = (premiumTrialLabel.text ?? "") + " • Billed monthly"
        }
    }

    private func updatePricesWithFallback() {
        // Use hardcoded fallback prices if RevenueCat fails
        premiumPriceLabel.text = pricingConfig.premiumPriceFormatted
        proPriceLabel.text = pricingConfig.proPriceFormatted
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateUIWithConfig(_ config: PricingConfig) {
        // Only update prices from config if offerings haven't loaded yet
        // (offerings have real localized App Store prices)
        if !subscriptionService.hasLoadedOfferings {
            premiumPriceLabel.text = config.premiumPriceFormatted
            proPriceLabel.text = config.proPriceFormatted
            premiumTrialLabel.text = config.premiumBanner
        }

        // Clear and repopulate feature stacks
        freeFeatureStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        premiumFeatureStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        proFeatureStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Free features
        for feature in config.freeFeatures {
            let label = createFeatureLabel(feature.title, isIncluded: feature.included)
            freeFeatureStack.addArrangedSubview(label)
        }

        // Premium features
        for feature in config.premiumFeatures {
            let label = createFeatureLabel(feature.title, isIncluded: feature.included)
            premiumFeatureStack.addArrangedSubview(label)
        }

        // Pro features
        for feature in config.proFeatures {
            let label = createFeatureLabel(feature.title, isIncluded: feature.included)
            proFeatureStack.addArrangedSubview(label)
        }
    }

    // MARK: - Actions
    @objc private func premiumTapped() {
        // Show loading state
        premiumButton.setTitle("Loading...", for: .normal)
        premiumButton.isEnabled = false

        // Purchase premium
        subscriptionService.purchase(tier: .premium) { [weak self] result in
            DispatchQueue.main.async {
                self?.premiumButton.setTitle("Start Free Trial", for: .normal)
                self?.premiumButton.isEnabled = true

                switch result {
                case .success(let status):
                    print("✅ Purchase successful: \(status.tier.displayName)")
                    self?.delegate?.didSelectPremiumTier()
                case .failure(let error):
                    print("❌ Purchase failed: \(error.localizedDescription)")
                    self?.showError(error)
                }
            }
        }
    }
    
    @objc private func proTapped() {
        // Show loading state
        proButton.setTitle("Loading...", for: .normal)
        proButton.isEnabled = false

        // Purchase pro
        subscriptionService.purchase(tier: .pro) { [weak self] result in
            DispatchQueue.main.async {
                self?.proButton.setTitle("Start Pro", for: .normal)
                self?.proButton.isEnabled = true

                switch result {
                case .success(let status):
                    print("✅ Purchase successful: \(status.tier.displayName)")
                    self?.delegate?.didSelectProTier()
                case .failure(let error):
                    print("❌ Purchase failed: \(error.localizedDescription)")
                    self?.showError(error)
                }
            }
        }
    }

    @objc private func freeTapped() {
        delegate?.didSelectFreeTier()
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Purchase Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
