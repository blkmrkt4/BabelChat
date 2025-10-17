import UIKit

class RelationshipIntentViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let stackView = UIStackView()
    private var selectedIntents: Set<RelationshipIntent> = [.languagePracticeOnly]
    private var intentButtons: [UIButton] = []

    // MARK: - Lifecycle
    override func configure() {
        step = .relationshipIntent
        setTitle("What are you looking for?",
                subtitle: "Select all that apply")
        setupIntentButtons()
        updateContinueButton(enabled: true)
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
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Create buttons for each relationship intent
        for intent in RelationshipIntent.allCases {
            let button = createIntentButton(for: intent)
            intentButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        // Auto-select "Language practice only" as default
        updateButtonAppearance()
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

        // Toggle selection
        if selectedIntents.contains(intent) {
            selectedIntents.remove(intent)
        } else {
            selectedIntents.insert(intent)
        }

        // Always need at least one selected
        if selectedIntents.isEmpty {
            selectedIntents.insert(.languagePracticeOnly)
        }

        updateButtonAppearance()
        updateContinueButton(enabled: !selectedIntents.isEmpty)

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func updateButtonAppearance() {
        for (index, button) in intentButtons.enumerated() {
            let intent = RelationshipIntent.allCases[index]
            if selectedIntents.contains(intent) {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .secondarySystemBackground
            }
        }
    }

    override func continueButtonTapped() {
        let intentsArray = Array(selectedIntents)
        delegate?.didCompleteStep(withData: intentsArray)
    }
}
