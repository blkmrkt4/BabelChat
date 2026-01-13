import UIKit

class RelationshipIntentViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let stackView = UIStackView()
    private var selectedIntent: RelationshipIntent = .languagePracticeOnly
    private var intentButtons: [UIButton] = []

    // Privacy options container (shown when languagePracticeOnly is selected)
    private let privacyContainer = UIView()
    private let privacyStack = UIStackView()
    private var privacyHeightConstraint: NSLayoutConstraint!
    private var strictlyPlatonicToggle: UISwitch!
    private var blurPhotosToggle: UISwitch!

    // Privacy state
    private var isStrictlyPlatonic: Bool = false
    private var blurPhotosUntilMatch: Bool = false

    // MARK: - Lifecycle
    override func configure() {
        step = .relationshipIntent
        setTitle("Looking for?")
        setupIntentButtons()
        setupPrivacyOptions()
        updateContinueButton(enabled: true)

        // Show privacy options initially since languagePracticeOnly is default
        updatePrivacyVisibility(animated: false)
    }

    // MARK: - Setup
    private func setupIntentButtons() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Create buttons for each relationship intent
        for intent in RelationshipIntent.allCases {
            let button = createIntentButton(for: intent)
            intentButtons.append(button)
            stackView.addArrangedSubview(button)

            // Add privacy container after languagePracticeOnly button
            if intent == .languagePracticeOnly {
                stackView.addArrangedSubview(privacyContainer)
            }
        }

        // Auto-select "Language practice only" as default
        updateButtonAppearance()
    }

    private func setupPrivacyOptions() {
        privacyContainer.clipsToBounds = true
        privacyContainer.alpha = 0
        privacyContainer.translatesAutoresizingMaskIntoConstraints = false

        // Height constraint for animation
        privacyHeightConstraint = privacyContainer.heightAnchor.constraint(equalToConstant: 0)
        privacyHeightConstraint.isActive = true

        // Privacy stack
        privacyStack.axis = .vertical
        privacyStack.spacing = 12
        privacyStack.alignment = .fill
        privacyContainer.addSubview(privacyStack)

        privacyStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            privacyStack.topAnchor.constraint(equalTo: privacyContainer.topAnchor, constant: 8),
            privacyStack.leadingAnchor.constraint(equalTo: privacyContainer.leadingAnchor),
            privacyStack.trailingAnchor.constraint(equalTo: privacyContainer.trailingAnchor),
            privacyStack.bottomAnchor.constraint(lessThanOrEqualTo: privacyContainer.bottomAnchor, constant: -8)
        ])

        // Header
        let headerLabel = UILabel()
        headerLabel.text = "Privacy Options"
        headerLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headerLabel.textColor = .white.withAlphaComponent(0.8)
        privacyStack.addArrangedSubview(headerLabel)

        // Strictly Platonic Toggle
        let platonicCard = createPrivacyToggle(
            title: "Strictly Platonic",
            subtitle: "Only match with others who also want platonic exchange",
            icon: "person.2.fill",
            isOn: isStrictlyPlatonic
        ) { [weak self] isOn in
            self?.isStrictlyPlatonic = isOn
            self?.addHapticFeedback()
        }
        strictlyPlatonicToggle = platonicCard.toggle
        privacyStack.addArrangedSubview(platonicCard.view)

        // Blur Photos Toggle
        let blurCard = createPrivacyToggle(
            title: "Blur Photos Until Matched",
            subtitle: "Focus on language skills first",
            icon: "eye.slash.fill",
            isOn: blurPhotosUntilMatch
        ) { [weak self] isOn in
            self?.blurPhotosUntilMatch = isOn
            self?.addHapticFeedback()
        }
        blurPhotosToggle = blurCard.toggle
        privacyStack.addArrangedSubview(blurCard.view)
    }

    private func createPrivacyToggle(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Bool,
        onToggle: @escaping (Bool) -> Void
    ) -> (view: UIView, toggle: UISwitch) {
        let cardView = UIView()
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        cardView.addSubview(iconView)

        // Text stack
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        cardView.addSubview(textStack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.6)
        subtitleLabel.numberOfLines = 0
        textStack.addArrangedSubview(subtitleLabel)

        // Toggle
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = .systemBlue
        toggle.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        toggle.addAction(UIAction { _ in
            onToggle(toggle.isOn)
        }, for: .valueChanged)
        cardView.addSubview(toggle)

        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        toggle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            toggle.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            toggle.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -8),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        return (cardView, toggle)
    }

    private func createIntentButton(for intent: RelationshipIntent) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: intent.icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        button.addSubview(iconView)

        // Create container for text content
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 4
        containerStack.alignment = .leading
        containerStack.isUserInteractionEnabled = false
        button.addSubview(containerStack)

        let titleLabel = UILabel()
        titleLabel.text = intent.displayName
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        containerStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = intent.subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        containerStack.addArrangedSubview(subtitleLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            containerStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            containerStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])

        button.tag = RelationshipIntent.allCases.firstIndex(of: intent) ?? 0
        button.addTarget(self, action: #selector(intentButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Actions
    @objc private func intentButtonTapped(_ sender: UIButton) {
        let intent = RelationshipIntent.allCases[sender.tag]

        // Single selection only (radio button behavior)
        selectedIntent = intent

        updateButtonAppearance()
        updatePrivacyVisibility(animated: true)
        updateContinueButton(enabled: true)

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func updateButtonAppearance() {
        for (index, button) in intentButtons.enumerated() {
            let intent = RelationshipIntent.allCases[index]
            if selectedIntent == intent {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .secondarySystemBackground
            }
        }
    }

    private func updatePrivacyVisibility(animated: Bool) {
        // Show privacy options only when languagePracticeOnly is selected
        let showPrivacy = selectedIntent == .languagePracticeOnly
        let targetHeight: CGFloat = showPrivacy ? 200 : 0

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.privacyHeightConstraint.constant = targetHeight
                self.privacyContainer.alpha = showPrivacy ? 1 : 0
                self.view.layoutIfNeeded()
            }
        } else {
            privacyHeightConstraint.constant = targetHeight
            privacyContainer.alpha = showPrivacy ? 1 : 0
        }
    }

    private func addHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    override func continueButtonTapped() {
        // Include privacy settings with the relationship intent
        let data: [String: Any] = [
            "intent": selectedIntent,
            "strictlyPlatonic": isStrictlyPlatonic,
            "blurPhotosUntilMatch": blurPhotosUntilMatch
        ]
        delegate?.didCompleteStep(withData: data)
    }
}
