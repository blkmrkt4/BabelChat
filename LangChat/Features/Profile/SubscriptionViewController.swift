import UIKit

class SubscriptionViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let currentTierLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let currencyLabel = UILabel()

    private let freeTierView = UIView()
    private let premiumTierView = UIView()
    private let proTierView = UIView()

    // Price labels for dynamic updates
    private var premiumPriceLabel: UILabel?
    private var proPriceLabel: UILabel?

    private let subscriptionService = SubscriptionService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadPrices()
    }

    private func loadPrices() {
        // Fetch real App Store prices from RevenueCat
        subscriptionService.fetchOfferings { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let offerings):
                    self?.updatePricesFromOfferings(offerings)
                case .failure:
                    // Keep using default prices
                    break
                }
            }
        }
    }

    private func updatePricesFromOfferings(_ offerings: [SubscriptionOffering]) {
        // Update currency label
        currencyLabel.text = subscriptionService.pricingRegionDescription

        // Update Premium price
        if let premiumOffering = offerings.first(where: { $0.tier == .premium }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? premiumOffering.weeklyPriceString
                : premiumOffering.localizedPricePerPeriod
            premiumPriceLabel?.text = priceText
        }

        // Update Pro price
        if let proOffering = offerings.first(where: { $0.tier == .pro }) {
            let priceText = subscriptionService.shouldShowWeeklyPricing
                ? proOffering.weeklyPriceString
                : proOffering.localizedPricePerPeriod
            proPriceLabel?.text = priceText
        }
    }

    private func setupViews() {
        title = "Subscription"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissVC)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Restore",
            style: .plain,
            target: self,
            action: #selector(restorePurchases)
        )

        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Current tier label
        currentTierLabel.text = getCurrentTierText()
        currentTierLabel.font = .systemFont(ofSize: 24, weight: .bold)
        currentTierLabel.textAlignment = .center
        contentView.addSubview(currentTierLabel)
        currentTierLabel.translatesAutoresizingMaskIntoConstraints = false

        // Description
        descriptionLabel.text = "Upgrade your plan to unlock more features"
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Currency/Region indicator
        currencyLabel.text = subscriptionService.pricingRegionDescription
        currencyLabel.font = .systemFont(ofSize: 13, weight: .medium)
        currencyLabel.textColor = .systemBlue
        currencyLabel.textAlignment = .center
        currencyLabel.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        currencyLabel.layer.cornerRadius = 12
        currencyLabel.layer.masksToBounds = true
        contentView.addSubview(currencyLabel)
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false

        // Tier views
        setupTierView(freeTierView, tier: .free, buttonTitle: getCurrentTier() == "Free" ? "Current Plan" : "Downgrade", buttonAction: #selector(selectFreeTier))

        premiumPriceLabel = setupTierView(premiumTierView, tier: .premium, buttonTitle: getCurrentTier() == "Premium" ? "Current Plan" : "Upgrade", buttonAction: #selector(selectPremiumTier))

        proPriceLabel = setupTierView(proTierView, tier: .pro, buttonTitle: getCurrentTier() == "Pro" ? "Current Plan" : "Upgrade", buttonAction: #selector(selectProTier))

        let stackView = UIStackView(arrangedSubviews: [freeTierView, premiumTierView, proTierView])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            currentTierLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            currentTierLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            currentTierLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: currentTierLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            currencyLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            currencyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            currencyLabel.heightAnchor.constraint(equalToConstant: 28),
            currencyLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),

            stackView.topAnchor.constraint(equalTo: currencyLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 600)
        ])
    }

    @discardableResult
    private func setupTierView(_ tierView: UIView, tier: SubscriptionTier, buttonTitle: String, buttonAction: Selector) -> UILabel {
        tierView.backgroundColor = .secondarySystemBackground
        tierView.layer.cornerRadius = 12
        tierView.layer.borderWidth = 1
        tierView.layer.borderColor = UIColor.separator.cgColor

        let titleLabel = UILabel()
        titleLabel.text = tier.displayName
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        tierView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = tier.price
        priceLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        priceLabel.textColor = .systemBlue
        priceLabel.textAlignment = .center
        tierView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        let featuresStack = UIStackView()
        featuresStack.axis = .vertical
        featuresStack.spacing = 8
        featuresStack.alignment = .leading

        for feature in tier.features {
            let featureLabel = UILabel()
            featureLabel.text = "• \(feature)"
            featureLabel.font = .systemFont(ofSize: 15)
            featureLabel.numberOfLines = 0
            featuresStack.addArrangedSubview(featureLabel)
        }

        tierView.addSubview(featuresStack)
        featuresStack.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.backgroundColor = getCurrentTier() == tier.displayName ? .systemGray : .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.isEnabled = getCurrentTier() != tier.displayName
        button.addTarget(self, action: buttonAction, for: .touchUpInside)
        tierView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: tierView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: tierView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: tierView.trailingAnchor, constant: -16),

            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: tierView.leadingAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: tierView.trailingAnchor, constant: -16),

            featuresStack.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16),
            featuresStack.leadingAnchor.constraint(equalTo: tierView.leadingAnchor, constant: 20),
            featuresStack.trailingAnchor.constraint(equalTo: tierView.trailingAnchor, constant: -20),

            button.topAnchor.constraint(equalTo: featuresStack.bottomAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: tierView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: tierView.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: tierView.bottomAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        return priceLabel
    }

    private func getCurrentTier() -> String {
        return subscriptionService.currentStatus.tier.displayName
    }

    private func getCurrentTierText() -> String {
        let status = subscriptionService.currentStatus
        var text = "Current Plan: \(status.tier.displayName)"

        if status.isTrialing, let daysLeft = status.daysRemainingInTrial {
            text += " (Trial: \(daysLeft) days left)"
        } else if let expiresAt = status.expiresAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            text += "\nRenews: \(formatter.string(from: expiresAt))"
        }

        return text
    }

    @objc private func selectFreeTier() {
        // Can't downgrade to free - show manage subscription
        showManageSubscription()
    }

    @objc private func selectPremiumTier() {
        purchaseTier(.premium)
    }

    @objc private func selectProTier() {
        purchaseTier(.pro)
    }

    private func purchaseTier(_ tier: SubscriptionTier) {
        let alert = UIAlertController(
            title: "Subscribe to \(tier.displayName)",
            message: "You'll be charged \(subscriptionService.localizedPricePerPeriod(for: tier))",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Subscribe", style: .default) { [weak self] _ in
            self?.performPurchase(tier: tier)
        })

        present(alert, animated: true)
    }

    private func performPurchase(tier: SubscriptionTier) {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)
        view.isUserInteractionEnabled = false

        subscriptionService.purchase(tier: tier) { [weak self] result in
            DispatchQueue.main.async {
                spinner.removeFromSuperview()
                self?.view.isUserInteractionEnabled = true

                switch result {
                case .success(let status):
                    self?.showPurchaseSuccess(tier: status.tier)
                case .failure(let error):
                    self?.showPurchaseError(error)
                }
            }
        }
    }

    private func showPurchaseSuccess(tier: SubscriptionTier) {
        let alert = UIAlertController(
            title: "Welcome to \(tier.displayName)!",
            message: "Your subscription is now active.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showPurchaseError(_ error: Error) {
        let errorMessage: String
        let errorDescription = error.localizedDescription.lowercased()

        // Provide more helpful messages for common errors
        if errorDescription.contains("configuration") || errorDescription.contains("product") {
            errorMessage = "Subscriptions are not yet available. Please check back later or contact support."
        } else if errorDescription.contains("network") || errorDescription.contains("connection") {
            errorMessage = "Please check your internet connection and try again."
        } else if errorDescription.contains("cancel") {
            // User cancelled - don't show an error
            return
        } else {
            errorMessage = error.localizedDescription
        }

        print("❌ Purchase error: \(error)")

        let alert = UIAlertController(
            title: "Purchase Failed",
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showManageSubscription() {
        let alert = UIAlertController(
            title: "Manage Subscription",
            message: "To cancel or change your subscription, go to Settings > Apple ID > Subscriptions on your device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func restorePurchases() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)
        view.isUserInteractionEnabled = false

        subscriptionService.restorePurchases { [weak self] result in
            DispatchQueue.main.async {
                spinner.removeFromSuperview()
                self?.view.isUserInteractionEnabled = true

                switch result {
                case .success(let status):
                    if status.tier != .free {
                        let alert = UIAlertController(
                            title: "Purchases Restored",
                            message: "Your \(status.tier.displayName) subscription has been restored.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self?.dismiss(animated: true)
                        })
                        self?.present(alert, animated: true)
                    } else {
                        let alert = UIAlertController(
                            title: "No Purchases Found",
                            message: "No previous subscriptions were found for this account.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                case .failure(let error):
                    self?.showPurchaseError(error)
                }
            }
        }
    }

    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
