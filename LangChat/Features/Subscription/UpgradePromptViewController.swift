//
//  UpgradePromptViewController.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import UIKit

class UpgradePromptViewController: UIViewController {

    // MARK: - UI Components
    private let containerView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let featureStack = UIStackView()
    private let upgradeButton = UIButton(type: .system)
    private let maybeLaterButton = UIButton(type: .system)

    // MARK: - Properties
    private let limitType: UsageLimitType
    private let resetDate: Date
    private let subscriptionService = SubscriptionService.shared

    // MARK: - Initialization
    init(limitType: UsageLimitType, resetDate: Date) {
        self.limitType = limitType
        self.resetDate = resetDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Setup
    private func setupViews() {
        // Semi-transparent background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        // Tap to dismiss background
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)

        // Container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 24
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.layer.shadowRadius = 20
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        view.addSubview(containerView)

        // Prevent tap on container from dismissing
        let containerTap = UITapGestureRecognizer(target: nil, action: nil)
        containerView.addGestureRecognizer(containerTap)

        // Icon
        iconLabel.font = .systemFont(ofSize: 64)
        iconLabel.textAlignment = .center
        containerView.addSubview(iconLabel)

        // Title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)

        // Message
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .secondaryLabel
        containerView.addSubview(messageLabel)

        // Feature stack
        featureStack.axis = .vertical
        featureStack.spacing = 12
        featureStack.alignment = .leading
        containerView.addSubview(featureStack)

        // Upgrade button
        upgradeButton.setTitle("Upgrade to Premium", for: .normal)
        upgradeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        upgradeButton.setTitleColor(.white, for: .normal)
        upgradeButton.backgroundColor = .systemBlue
        upgradeButton.layer.cornerRadius = 25
        upgradeButton.addTarget(self, action: #selector(upgradeTapped), for: .touchUpInside)
        containerView.addSubview(upgradeButton)

        // Maybe later button
        maybeLaterButton.setTitle("Maybe Later", for: .normal)
        maybeLaterButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        maybeLaterButton.setTitleColor(.secondaryLabel, for: .normal)
        maybeLaterButton.addTarget(self, action: #selector(maybeLaterTapped), for: .touchUpInside)
        containerView.addSubview(maybeLaterButton)
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        featureStack.translatesAutoresizingMaskIntoConstraints = false
        upgradeButton.translatesAutoresizingMaskIntoConstraints = false
        maybeLaterButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            iconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            featureStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            featureStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            featureStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),

            upgradeButton.topAnchor.constraint(equalTo: featureStack.bottomAnchor, constant: 32),
            upgradeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            upgradeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            upgradeButton.heightAnchor.constraint(equalToConstant: 56),

            maybeLaterButton.topAnchor.constraint(equalTo: upgradeButton.bottomAnchor, constant: 12),
            maybeLaterButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            maybeLaterButton.heightAnchor.constraint(equalToConstant: 44),
            maybeLaterButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }

    private func configureContent() {
        switch limitType {
        case .aiMessages:
            iconLabel.text = "💬"
            titleLabel.text = "Daily AI Message Limit Reached"
            messageLabel.text = "You've used your 5 daily AI messages. Upgrade to Premium for unlimited AI-powered conversations!"

        case .profileViews:
            iconLabel.text = "👤"
            titleLabel.text = "Daily Profile View Limit Reached"
            messageLabel.text = "You've viewed 10 profiles today. Upgrade to Premium to browse unlimited profiles and find your perfect language partner!"
        }

        // Add premium features with TTS benefits
        let features = SubscriptionTier.premium.features.map { "✓ \($0)" }

        for feature in features {
            let label = UILabel()
            label.text = feature
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .label
            featureStack.addArrangedSubview(label)
        }

        // Show reset time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let resetTimeString = formatter.string(from: resetDate)

        let resetLabel = UILabel()
        resetLabel.text = "Free tier resets at \(resetTimeString)"
        resetLabel.font = .systemFont(ofSize: 13, weight: .regular)
        resetLabel.textColor = .tertiaryLabel
        resetLabel.textAlignment = .center
        containerView.addSubview(resetLabel)

        resetLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetLabel.topAnchor.constraint(equalTo: maybeLaterButton.bottomAnchor, constant: 8),
            resetLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }

    // MARK: - Animation
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.view.alpha = 0
        }) { _ in
            completion()
        }
    }

    // MARK: - Actions
    @objc private func upgradeTapped() {
        // Show loading
        upgradeButton.setTitle("Loading...", for: .normal)
        upgradeButton.isEnabled = false

        // Navigate to pricing page
        subscriptionService.purchase(tier: .premium) { [weak self] result in
            DispatchQueue.main.async {
                self?.upgradeButton.setTitle("Upgrade to Premium", for: .normal)
                self?.upgradeButton.isEnabled = true

                switch result {
                case .success:
                    print("✅ Upgrade successful")
                    self?.animateOut {
                        self?.dismiss(animated: false)
                    }
                case .failure(let error):
                    print("❌ Upgrade failed: \(error.localizedDescription)")
                    self?.showError(error)
                }
            }
        }
    }

    @objc private func maybeLaterTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    @objc private func backgroundTapped() {
        // Allow dismissing by tapping background
        maybeLaterTapped()
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Upgrade Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Convenience Presentation
extension UpgradePromptViewController {
    /// Present upgrade prompt for a specific limit type
    static func present(for limitType: UsageLimitType, resetDate: Date, from viewController: UIViewController) {
        let promptVC = UpgradePromptViewController(limitType: limitType, resetDate: resetDate)
        viewController.present(promptVC, animated: true)
    }
}
