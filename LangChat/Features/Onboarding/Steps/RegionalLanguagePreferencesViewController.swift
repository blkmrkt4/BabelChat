import UIKit

class RegionalLanguagePreferencesViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let infoLabel = UILabel()
    private let exampleLabel = UILabel()

    // MARK: - Properties
    var learningLanguages: [Language] = []
    private var regionalPreferences: [RegionalLanguagePreference] = []

    // MARK: - Lifecycle
    override func configure() {
        step = .regionalLanguagePreferences
        setTitle("Regional preferences?",
                subtitle: "Optional: Specify regional dialects or accents")
        setupViews()

        // Enable continue button (can skip this step)
        updateContinueButton(enabled: true)
        continueButton.setTitle("Skip", for: .normal)
    }

    // MARK: - Setup
    private func setupViews() {
        // Info label
        infoLabel.text = "Some languages vary by region. You can specify if you prefer to learn a particular dialect or accent."
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        contentView.addSubview(infoLabel)

        // Example label
        exampleLabel.text = "Examples:\n• Spanish from Spain vs. Latin America\n• French from France vs. Quebec\n• Portuguese from Portugal vs. Brazil"
        exampleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        exampleLabel.textColor = .tertiaryLabel
        exampleLabel.numberOfLines = 0
        exampleLabel.textAlignment = .left
        contentView.addSubview(exampleLabel)

        // Image/icon
        let iconView = UIImageView(image: UIImage(systemName: "globe.americas.fill"))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)

        // Note label
        let noteLabel = UILabel()
        noteLabel.text = "You can set these preferences later in settings"
        noteLabel.font = .systemFont(ofSize: 13, weight: .regular)
        noteLabel.textColor = .tertiaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.textAlignment = .center
        contentView.addSubview(noteLabel)

        // Layout
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        exampleLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            infoLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            exampleLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 24),
            exampleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exampleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            noteLabel.topAnchor.constraint(equalTo: exampleLabel.bottomAnchor, constant: 32),
            noteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            noteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    override func continueButtonTapped() {
        // For now, always pass empty array (no regional preferences)
        // In the future, this would show a proper regional preference picker
        delegate?.didCompleteStep(withData: regionalPreferences)
    }
}
