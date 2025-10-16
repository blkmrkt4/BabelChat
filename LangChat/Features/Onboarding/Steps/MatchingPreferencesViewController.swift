import UIKit

class MatchingPreferencesViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadSavedPreferences()
        setupViews()
    }

    private func setupNavigationBar() {
        title = "Matching Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
    }

    private func loadSavedPreferences() {
        // Load saved preferences from UserDefaults or use defaults
        allowNonNativeMatches = UserDefaults.standard.object(forKey: "allowNonNativeMatches") as? Bool ?? false

        if let minLevel = UserDefaults.standard.string(forKey: "minProficiencyLevel"),
           let parsedMin = parseProficiency(minLevel) {
            minProficiency = parsedMin
        }

        if let maxLevel = UserDefaults.standard.string(forKey: "maxProficiencyLevel"),
           let parsedMax = parseProficiency(maxLevel) {
            maxProficiency = parsedMax
        }

        // Set picker based on saved values
        updatePickerSelection()
    }

    private func parseProficiency(_ level: String) -> LanguageProficiency? {
        switch level.lowercased() {
        case "beginner": return .beginner
        case "intermediate": return .intermediate
        case "advanced": return .advanced
        default: return nil
        }
    }

    private func updatePickerSelection() {
        if minProficiency == .beginner && maxProficiency == .advanced {
            proficiencyPicker.selectedSegmentIndex = 0 // All Levels
        } else if minProficiency == .beginner && maxProficiency == .intermediate {
            proficiencyPicker.selectedSegmentIndex = 1 // Beginner-Int
        } else if minProficiency == .intermediate && maxProficiency == .advanced {
            proficiencyPicker.selectedSegmentIndex = 2 // Int-Advanced
        } else if minProficiency == .advanced && maxProficiency == .advanced {
            proficiencyPicker.selectedSegmentIndex = 3 // Advanced Only
        } else if minProficiency == .intermediate && maxProficiency == .intermediate {
            proficiencyPicker.selectedSegmentIndex = 4 // Intermediate Only
        } else if minProficiency == .beginner && maxProficiency == .beginner {
            proficiencyPicker.selectedSegmentIndex = 5 // Beginner Only
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.showsVerticalScrollIndicator = false

        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill

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

        proficiencyPicker.isEnabled = allowNonNativeMatches
        proficiencyPicker.addTarget(self, action: #selector(proficiencyChanged), for: .valueChanged)

        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
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

        // Save to UserDefaults
        UserDefaults.standard.set(allowNonNativeMatches, forKey: "allowNonNativeMatches")

        // Animate proficiency picker visibility
        UIView.animate(withDuration: 0.3) {
            self.stackView.arrangedSubviews.last?.alpha = self.allowNonNativeMatches ? 1.0 : 0.4
        }

        proficiencyPicker.isEnabled = allowNonNativeMatches

        // Show confirmation
        showSavedConfirmation()
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

        // Save to UserDefaults
        UserDefaults.standard.set(minProficiency.rawValue, forKey: "minProficiencyLevel")
        UserDefaults.standard.set(maxProficiency.rawValue, forKey: "maxProficiencyLevel")

        // Show confirmation
        showSavedConfirmation()
    }

    private func showSavedConfirmation() {
        // Simple visual feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
    }
}
