import UIKit
import UserNotifications

class NotificationsPermissionViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let iconImageView = UIImageView()
    private let benefitsStackView = UIStackView()
    private let enableButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)

    // MARK: - Properties
    private let benefits = [
        ("💬", "New Matches", "Know when someone wants to practice with you"),
        ("📬", "Messages", "Never miss a language exchange opportunity"),
        ("🎯", "Practice Reminders", "Stay consistent with your learning goals"),
        ("📈", "Weekly Progress", "Track your language learning journey")
    ]

    // MARK: - Lifecycle
    override func configure() {
        step = .notifications
        setTitle("Stay Connected",
                subtitle: "Get notified about new matches and messages")
        setupViews()

        // Hide the default continue button
        continueButton.isHidden = true
    }

    // MARK: - Setup
    private func setupViews() {
        // Icon
        iconImageView.image = UIImage(systemName: "bell.badge.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)

        // Benefits stack
        benefitsStackView.axis = .vertical
        benefitsStackView.spacing = 20
        benefitsStackView.distribution = .fillEqually
        contentView.addSubview(benefitsStackView)

        // Create benefit rows
        for benefit in benefits {
            let rowView = createBenefitRow(
                emoji: benefit.0,
                title: benefit.1,
                description: benefit.2
            )
            benefitsStackView.addArrangedSubview(rowView)
        }

        // Enable button
        enableButton.setTitle("Enable Notifications", for: .normal)
        enableButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        enableButton.backgroundColor = .systemBlue
        enableButton.setTitleColor(.white, for: .normal)
        enableButton.layer.cornerRadius = 25
        enableButton.addTarget(self, action: #selector(enableNotificationsTapped), for: .touchUpInside)
        contentView.addSubview(enableButton)

        // Skip button
        skipButton.setTitle("Maybe Later", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        contentView.addSubview(skipButton)

        // Layout
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        benefitsStackView.translatesAutoresizingMaskIntoConstraints = false
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            // Benefits stack
            benefitsStackView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 40),
            benefitsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            benefitsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Enable button
            enableButton.topAnchor.constraint(equalTo: benefitsStackView.bottomAnchor, constant: 40),
            enableButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            enableButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            enableButton.heightAnchor.constraint(equalToConstant: 50),

            // Skip button
            skipButton.topAnchor.constraint(equalTo: enableButton.bottomAnchor, constant: 16),
            skipButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func createBenefitRow(emoji: String, title: String, description: String) -> UIView {
        let container = UIView()

        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        container.addSubview(emojiLabel)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        textStack.addArrangedSubview(titleLabel)

        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        textStack.addArrangedSubview(descriptionLabel)

        container.addSubview(textStack)

        // Layout
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 50),

            textStack.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func enableNotificationsTapped() {
        // Use PushNotificationService for consistent handling
        PushNotificationService.shared.requestAuthorization { [weak self] granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notificationsEnabled")

                if let error = error {
                    print("❌ Error requesting notifications: \(error.localizedDescription)")
                }

                if granted {
                    print("✅ User enabled notifications during onboarding")
                }

                self?.completeOnboarding()
            }
        }
    }

    @objc private func skipTapped() {
        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
        print("⏭️ User skipped notifications during onboarding")
        completeOnboarding()
    }

    private func completeOnboarding() {
        delegate?.didCompleteStep(withData: nil)
    }
}
