import UIKit

class GenderSelectionViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let stackView = UIStackView()
    private var selectedGender: Gender?
    private var genderButtons: [UIButton] = []

    // MARK: - Lifecycle
    override func configure() {
        step = .gender
        setTitle("What's your gender?",
                subtitle: "This helps us personalize your experience")
        setupGenderButtons()
    }

    // MARK: - Setup
    private func setupGenderButtons() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        contentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: CGFloat(Gender.allCases.count * 60 + (Gender.allCases.count - 1) * 12))
        ])

        // Create buttons for each gender option
        for gender in Gender.allCases {
            let button = createGenderButton(for: gender)
            genderButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func createGenderButton(for gender: Gender) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor

        // Create label with icon
        let iconLabel = UILabel()
        iconLabel.text = gender.icon
        iconLabel.font = .systemFont(ofSize: 24)
        iconLabel.textAlignment = .center
        button.addSubview(iconLabel)

        let titleLabel = UILabel()
        titleLabel.text = gender.displayName
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        button.addSubview(titleLabel)

        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])

        button.tag = Gender.allCases.firstIndex(of: gender) ?? 0
        button.addTarget(self, action: #selector(genderButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Actions
    @objc private func genderButtonTapped(_ sender: UIButton) {
        selectedGender = Gender.allCases[sender.tag]

        // Update UI
        for (index, button) in genderButtons.enumerated() {
            if index == sender.tag {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .secondarySystemBackground
            }
        }

        updateContinueButton(enabled: true)

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    override func continueButtonTapped() {
        guard let selectedGender = selectedGender else { return }
        delegate?.didCompleteStep(withData: selectedGender)
    }
}
