import UIKit

class GenderPreferenceViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let stackView = UIStackView()
    private var selectedPreference: GenderPreference?
    private var preferenceButtons: [UIButton] = []

    // MARK: - Lifecycle
    override func configure() {
        step = .genderPreference
        setTitle("Who would you like to match with?",
                subtitle: "Choose your matching preference")
        setupPreferenceButtons()
    }

    // MARK: - Setup
    private func setupPreferenceButtons() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Create buttons for each preference option
        for preference in GenderPreference.allCases {
            let button = createPreferenceButton(for: preference)
            preferenceButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        // Auto-select "Everyone" as default
        selectedPreference = .all
        updateButtonAppearance(selectedTag: 0)
        updateContinueButton(enabled: true)
    }

    private func createPreferenceButton(for preference: GenderPreference) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor

        // Create container for content
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 4
        containerStack.alignment = .leading
        containerStack.isUserInteractionEnabled = false
        button.addSubview(containerStack)

        let titleLabel = UILabel()
        titleLabel.text = preference.displayName
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        containerStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = preference.subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        containerStack.addArrangedSubview(subtitleLabel)

        containerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])

        button.tag = GenderPreference.allCases.firstIndex(of: preference) ?? 0
        button.addTarget(self, action: #selector(preferenceButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Actions
    @objc private func preferenceButtonTapped(_ sender: UIButton) {
        selectedPreference = GenderPreference.allCases[sender.tag]
        updateButtonAppearance(selectedTag: sender.tag)
        updateContinueButton(enabled: true)

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func updateButtonAppearance(selectedTag: Int) {
        for (index, button) in preferenceButtons.enumerated() {
            if index == selectedTag {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .secondarySystemBackground
            }
        }
    }

    override func continueButtonTapped() {
        guard let selectedPreference = selectedPreference else { return }
        delegate?.didCompleteStep(withData: selectedPreference)
    }
}
