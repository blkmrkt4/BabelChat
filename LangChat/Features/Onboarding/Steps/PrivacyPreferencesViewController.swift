import UIKit

class PrivacyPreferencesViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let stackView = UIStackView()
    private var strictlyPlatonicToggle: UISwitch!
    private var blurPhotosToggle: UISwitch!

    // MARK: - State
    private var isStrictlyPlatonic: Bool = false
    private var blurPhotosUntilMatch: Bool = false

    // MARK: - Lifecycle
    override func configure() {
        step = .privacyPreferences
        setTitle("Privacy Settings",
                subtitle: "Customize your experience")
        setupPreferenceToggles()
        updateContinueButton(enabled: true)
    }

    // MARK: - Setup
    private func setupPreferenceToggles() {
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Strictly Platonic Toggle
        let platonicCard = createPreferenceCard(
            title: "Strictly Platonic",
            subtitle: "Only match with users who want platonic language exchange - no dating intentions",
            icon: "person.2.fill",
            isOn: isStrictlyPlatonic
        ) { [weak self] isOn in
            self?.isStrictlyPlatonic = isOn
            self?.addHapticFeedback()
        }
        strictlyPlatonicToggle = platonicCard.toggle
        stackView.addArrangedSubview(platonicCard.view)

        // Blur Photos Toggle
        let blurCard = createPreferenceCard(
            title: "Blur Photos Until Matched",
            subtitle: "Focus on language skills first - your photos will be revealed once you match",
            icon: "eye.slash.fill",
            isOn: blurPhotosUntilMatch
        ) { [weak self] isOn in
            self?.blurPhotosUntilMatch = isOn
            self?.addHapticFeedback()
        }
        blurPhotosToggle = blurCard.toggle
        stackView.addArrangedSubview(blurCard.view)

        // Info label
        let infoLabel = UILabel()
        infoLabel.text = "These settings can be changed later in your profile settings."
        infoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        infoLabel.textColor = .white.withAlphaComponent(0.6)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        stackView.addArrangedSubview(infoLabel)
    }

    private func createPreferenceCard(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Bool,
        onToggle: @escaping (Bool) -> Void
    ) -> (view: UIView, toggle: UISwitch) {
        let cardView = UIView()
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        cardView.addSubview(iconView)

        // Text stack
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        cardView.addSubview(textStack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.7)
        subtitleLabel.numberOfLines = 0
        textStack.addArrangedSubview(subtitleLabel)

        // Toggle
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = .systemBlue
        toggle.addAction(UIAction { _ in
            onToggle(toggle.isOn)
        }, for: .valueChanged)
        cardView.addSubview(toggle)

        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        toggle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            toggle.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        return (cardView, toggle)
    }

    private func addHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Actions
    override func continueButtonTapped() {
        let preferences = (strictlyPlatonic: isStrictlyPlatonic, blurPhotosUntilMatch: blurPhotosUntilMatch)
        delegate?.didCompleteStep(withData: preferences)
    }
}
