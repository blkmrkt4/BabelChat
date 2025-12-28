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
        return UserDefaults.standard.string(forKey: "subscriptionTier") ?? "Free"
    }

    private func getCurrentTierText() -> String {
        let tier = getCurrentTier()
        return "Current Plan: \(tier)"
    }

    @objc private func selectFreeTier() {
        showConfirmation(tier: "Free")
    }

    @objc private func selectPremiumTier() {
        showConfirmation(tier: "Premium")
    }

    @objc private func selectProTier() {
        showConfirmation(tier: "Pro")
    }

    private func showConfirmation(tier: String) {
        let alert = UIAlertController(
            title: "Confirm \(tier) Plan",
            message: "This is a demo. In production, this would use StoreKit to process the payment.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            UserDefaults.standard.set(tier, forKey: "subscriptionTier")
            self?.currentTierLabel.text = "Current Plan: \(tier)"

            // Reload the view
            self?.navigationController?.popViewController(animated: true)
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
