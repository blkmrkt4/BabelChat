import UIKit

class MatchingPreferencesViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let toggleSwitch = UISwitch()
    private let proficiencyPicker = UISegmentedControl(items: [
        "All Levels",
        "Beginner-Int",
        "Int-Advanced",
        "Advanced Only",
        "Intermediate Only",
        "Beginner Only"
    ])

    // MARK: - Properties
    private var allowNonNativeMatches: Bool = false
    private var minProficiency: LanguageProficiency = .beginner
    private var maxProficiency: LanguageProficiency = .advanced

    // MARK: - Lifecycle
    override func configure() {
        step = .learningLanguages  // Will be added as a new step
        setTitle("Matching Preferences",
                subtitle: "Choose who you'd like to practice with")
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        scrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        scrollView.addSubview(stackView)

        // Non-native matches section
        let nonNativeSection = createSectionView(
            title: "Match with Non-Native Speakers",
            subtitle: "Allow matches with users who are also learning your target language",
            control: toggleSwitch
        )
        stackView.addArrangedSubview(nonNativeSection)

        toggleSwitch.isOn = allowNonNativeMatches
        toggleSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        // Proficiency level section
        let proficiencySection = createProficiencySection()
        stackView.addArrangedSubview(proficiencySection)
        proficiencySection.alpha = allowNonNativeMatches ? 1.0 : 0.4

        proficiencyPicker.selectedSegmentIndex = 0
        proficiencyPicker.addTarget(self, action: #selector(proficiencyChanged), for: .valueChanged)

        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func createSectionView(title: String, subtitle: String, control: UIView) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        container.addSubview(control)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: control.leadingAnchor, constant: -12),

            control.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func createProficiencySection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "Proficiency Level Range"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select the proficiency levels you're comfortable matching with"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        container.addSubview(proficiencyPicker)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        proficiencyPicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            proficiencyPicker.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            proficiencyPicker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            proficiencyPicker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            proficiencyPicker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    @objc private func toggleChanged() {
        allowNonNativeMatches = toggleSwitch.isOn

        // Animate proficiency picker visibility
        UIView.animate(withDuration: 0.3) {
            self.stackView.arrangedSubviews.last?.alpha = self.allowNonNativeMatches ? 1.0 : 0.4
        }

        proficiencyPicker.isEnabled = allowNonNativeMatches
        updateContinueButton(enabled: true)
    }

    @objc private func proficiencyChanged() {
        // Map selection to proficiency levels
        switch proficiencyPicker.selectedSegmentIndex {
        case 0: // All Levels
            minProficiency = .beginner
            maxProficiency = .advanced
        case 1: // Beginner-Int
            minProficiency = .beginner
            maxProficiency = .intermediate
        case 2: // Int-Advanced
            minProficiency = .intermediate
            maxProficiency = .advanced
        case 3: // Advanced Only
            minProficiency = .advanced
            maxProficiency = .advanced
        case 4: // Intermediate Only
            minProficiency = .intermediate
            maxProficiency = .intermediate
        case 5: // Beginner Only
            minProficiency = .beginner
            maxProficiency = .beginner
        default:
            break
        }
    }

    override func continueButtonTapped() {
        let preferences = (allowNonNativeMatches, minProficiency, maxProficiency)
        delegate?.didCompleteStep(withData: preferences)
    }
}
