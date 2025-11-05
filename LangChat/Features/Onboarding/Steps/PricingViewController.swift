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
    func didSkipPricing()
}

class PricingViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // Free tier card
    private let freeCard = UIView()
    private let freeTierLabel = UILabel()
    private let freePriceLabel = UILabel()
    private let freeFeatureStack = UIStackView()

    // Premium tier card
    private let premiumCard = UIView()
    private let premiumBadge = UILabel()
    private let premiumTierLabel = UILabel()
    private let premiumPriceLabel = UILabel()
    private let premiumTrialLabel = UILabel()
    private let premiumFeatureStack = UIStackView()
    private let premiumButton = UIButton(type: .system)

    private let skipButton = UIButton(type: .system)

    // MARK: - Properties
    weak var delegate: PricingViewControllerDelegate?
    private let subscriptionService = SubscriptionService.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadPricing()
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
        contentStack.spacing = 24
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)

        // Title
        titleLabel.text = "Choose Your Plan"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Start free, upgrade anytime for unlimited access"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subtitleLabel)

        // Add spacing
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        contentStack.addArrangedSubview(spacer)

        // Setup pricing cards (Premium first to grab attention)
        setupPremiumCard()
        setupFreeCard()

        // Skip button
        skipButton.setTitle("Continue with Free", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.backgroundColor = .white.withAlphaComponent(0.15)
        skipButton.layer.cornerRadius = 25
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipButton)
    }

    private func setupFreeCard() {
        freeCard.backgroundColor = .white.withAlphaComponent(0.1)
        freeCard.layer.cornerRadius = 20
        freeCard.layer.borderWidth = 1.5
        freeCard.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        contentStack.addArrangedSubview(freeCard)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.alignment = .leading
        freeCard.addSubview(cardStack)

        // Tier name
        freeTierLabel.text = "Discovery"
        freeTierLabel.font = .systemFont(ofSize: 24, weight: .bold)
        freeTierLabel.textColor = .white
        cardStack.addArrangedSubview(freeTierLabel)

        // Price
        freePriceLabel.text = "Free"
        freePriceLabel.font = .systemFont(ofSize: 36, weight: .heavy)
        freePriceLabel.textColor = .systemGreen
        cardStack.addArrangedSubview(freePriceLabel)

        // Features
        freeFeatureStack.axis = .vertical
        freeFeatureStack.spacing = 12
        freeFeatureStack.alignment = .leading
        cardStack.addArrangedSubview(freeFeatureStack)

        for feature in SubscriptionTier.free.features {
            let featureLabel = createFeatureLabel(feature, isIncluded: true)
            freeFeatureStack.addArrangedSubview(featureLabel)
        }

        // Layout
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: freeCard.topAnchor, constant: 24),
            cardStack.leadingAnchor.constraint(equalTo: freeCard.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: freeCard.trailingAnchor, constant: -24),
            cardStack.bottomAnchor.constraint(equalTo: freeCard.bottomAnchor, constant: -24)
        ])
    }

    private func setupPremiumCard() {
        premiumCard.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        premiumCard.layer.cornerRadius = 20
        premiumCard.layer.borderWidth = 2
        premiumCard.layer.borderColor = UIColor.systemBlue.cgColor
        premiumCard.layer.shadowColor = UIColor.systemBlue.cgColor
        premiumCard.layer.shadowOpacity = 0.3
        premiumCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        premiumCard.layer.shadowRadius = 8
        contentStack.addArrangedSubview(premiumCard)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.alignment = .leading
        premiumCard.addSubview(cardStack)

        // Popular badge
        premiumBadge.text = "MOST POPULAR"
        premiumBadge.font = .systemFont(ofSize: 12, weight: .bold)
        premiumBadge.textColor = .systemYellow
        premiumBadge.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        premiumBadge.textAlignment = .center
        premiumBadge.layer.cornerRadius = 12
        premiumBadge.layer.masksToBounds = true
        premiumBadge.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.addSubview(premiumBadge)

        // Tier name
        premiumTierLabel.text = "Premium"
        premiumTierLabel.font = .systemFont(ofSize: 24, weight: .bold)
        premiumTierLabel.textColor = .white
        cardStack.addArrangedSubview(premiumTierLabel)

        // Price
        premiumPriceLabel.text = "$9.99/month"
        premiumPriceLabel.font = .systemFont(ofSize: 36, weight: .heavy)
        premiumPriceLabel.textColor = .systemBlue
        cardStack.addArrangedSubview(premiumPriceLabel)

        // Trial info
        premiumTrialLabel.text = "7-day free trial • Cancel anytime"
        premiumTrialLabel.font = .systemFont(ofSize: 14, weight: .medium)
        premiumTrialLabel.textColor = .white.withAlphaComponent(0.9)
        premiumTrialLabel.backgroundColor = .white.withAlphaComponent(0.15)
        premiumTrialLabel.textAlignment = .center
        premiumTrialLabel.layer.cornerRadius = 16
        premiumTrialLabel.layer.masksToBounds = true
        premiumTrialLabel.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(premiumTrialLabel)

        // Features
        premiumFeatureStack.axis = .vertical
        premiumFeatureStack.spacing = 12
        premiumFeatureStack.alignment = .leading
        cardStack.addArrangedSubview(premiumFeatureStack)

        for feature in SubscriptionTier.premium.features {
            let featureLabel = createFeatureLabel(feature, isIncluded: true)
            premiumFeatureStack.addArrangedSubview(featureLabel)
        }

        // Start trial button
        premiumButton.setTitle("Start Free Trial", for: .normal)
        premiumButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        premiumButton.setTitleColor(.white, for: .normal)
        premiumButton.backgroundColor = .systemBlue
        premiumButton.layer.cornerRadius = 25
        premiumButton.addTarget(self, action: #selector(premiumTapped), for: .touchUpInside)
        premiumButton.translatesAutoresizingMaskIntoConstraints = false
        cardStack.addArrangedSubview(premiumButton)

        // Layout
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            premiumBadge.topAnchor.constraint(equalTo: premiumCard.topAnchor, constant: 16),
            premiumBadge.trailingAnchor.constraint(equalTo: premiumCard.trailingAnchor, constant: -16),
            premiumBadge.widthAnchor.constraint(equalToConstant: 120),
            premiumBadge.heightAnchor.constraint(equalToConstant: 24),

            cardStack.topAnchor.constraint(equalTo: premiumBadge.bottomAnchor, constant: 16),
            cardStack.leadingAnchor.constraint(equalTo: premiumCard.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: premiumCard.trailingAnchor, constant: -24),
            cardStack.bottomAnchor.constraint(equalTo: premiumCard.bottomAnchor, constant: -24),

            premiumTrialLabel.heightAnchor.constraint(equalToConstant: 32),
            premiumTrialLabel.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            premiumTrialLabel.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor),

            premiumButton.heightAnchor.constraint(equalToConstant: 56),
            premiumButton.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            premiumButton.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor)
        ])
    }

    private func createFeatureLabel(_ text: String, isIncluded: Bool) -> UILabel {
        let label = UILabel()
        let checkmark = isIncluded ? "✓" : "✗"
        let color = isIncluded ? UIColor.systemGreen : UIColor.systemGray
        label.text = "\(checkmark) \(text)"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white.withAlphaComponent(isIncluded ? 1.0 : 0.5)
        label.numberOfLines = 0
        return label
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -16),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            skipButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Data Loading
    private func loadPricing() {
        // Fetch pricing from RevenueCat
        subscriptionService.fetchOfferings { [weak self] result in
            switch result {
            case .success(let offerings):
                // Update UI with real pricing
                print("Loaded \(offerings.count) offerings")
                // TODO: Update price labels with actual prices from App Store
            case .failure(let error):
                print("Failed to load offerings: \(error.localizedDescription)")
                // Show default pricing
            }
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

    @objc private func skipTapped() {
        delegate?.didSkipPricing()
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
