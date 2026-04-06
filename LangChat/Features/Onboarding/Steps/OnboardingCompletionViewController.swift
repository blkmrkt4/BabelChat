import UIKit

class OnboardingCompletionViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let iconLabel = UILabel()
    private let headingLabel = UILabel()
    private let messageLabel = UILabel()
    private let checklistLabel = UILabel()
    private let getStartedButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func configure() {
        step = .completion
        setTitle("")

        // Hide default continue button and back button — this is the final screen
        continueButton.isHidden = true
        backButton.isHidden = true
        progressView.isHidden = true

        setupCompletionViews()
    }

    // MARK: - Setup
    private func setupCompletionViews() {
        // Checkmark icon
        iconLabel.text = "\u{2705}"
        iconLabel.font = .systemFont(ofSize: 72)
        iconLabel.textAlignment = .center
        contentView.addSubview(iconLabel)

        // Heading
        headingLabel.text = "You're all set!"
        headingLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headingLabel.textColor = .white
        headingLabel.textAlignment = .center
        headingLabel.numberOfLines = 0
        contentView.addSubview(headingLabel)

        // Message
        messageLabel.text = "Visit Settings to complete your profile:"
        messageLabel.font = .systemFont(ofSize: 17, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)

        // Checklist of profile items
        let items = [
            "Bio \u{2014} tell people about yourself",
            "More photos",
            "Age range preference",
            "Location preference",
            "Travel plans",
            "Proficiency range",
            "Privacy preferences",
            "Notification settings"
        ]
        let bulletList = items.map { "\u{2022} \($0)" }.joined(separator: "\n")
        checklistLabel.text = bulletList
        checklistLabel.font = .systemFont(ofSize: 15, weight: .regular)
        checklistLabel.textColor = .white.withAlphaComponent(0.7)
        checklistLabel.textAlignment = .left
        checklistLabel.numberOfLines = 0
        contentView.addSubview(checklistLabel)

        // Get Started button
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        getStartedButton.backgroundColor = .systemBlue
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.layer.cornerRadius = 25
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        contentView.addSubview(getStartedButton)

        // Layout
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        checklistLabel.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            headingLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 20),
            headingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            headingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            messageLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            checklistLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            checklistLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            checklistLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            getStartedButton.topAnchor.constraint(equalTo: checklistLabel.bottomAnchor, constant: 32),
            getStartedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            getStartedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            getStartedButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Actions
    @objc private func getStartedTapped() {
        delegate?.didCompleteStep(withData: nil)
    }
}
