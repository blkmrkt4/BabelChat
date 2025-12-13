import UIKit

class MatchingPreferencesViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let proficiencyLevelSelector = ProficiencyLevelSelector()
    private let selectionDisplayLabel = UILabel()
    private let strictlyPlatonicSwitch = UISwitch()

    // MARK: - Properties
    private var selectedLevels: ProficiencySelection = .all
    private var isStrictlyPlatonic: Bool = false

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
        // Load proficiency selection
        selectedLevels = ProficiencySelection.fromDefaults()

        // Load strictly platonic setting
        isStrictlyPlatonic = UserDefaults.standard.bool(forKey: "strictlyPlatonic")
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

        // Strictly Platonic section
        let platonicSection = createPlatonicSection()
        stackView.addArrangedSubview(platonicSection)

        // Proficiency level section with level selector
        let proficiencySection = createProficiencySection()
        stackView.addArrangedSubview(proficiencySection)

        proficiencyLevelSelector.delegate = self
        proficiencyLevelSelector.setSelection(selectedLevels, animated: false)
        updateSelectionDisplayLabel()

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

    private func createPlatonicSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "Strictly Platonic"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Only match with others seeking platonic language exchange. You won't see or be shown to users looking for dating."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        strictlyPlatonicSwitch.isOn = isStrictlyPlatonic
        strictlyPlatonicSwitch.onTintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0) // Gold
        strictlyPlatonicSwitch.addTarget(self, action: #selector(platonicSwitchChanged), for: .valueChanged)
        container.addSubview(strictlyPlatonicSwitch)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        strictlyPlatonicSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            strictlyPlatonicSwitch.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            strictlyPlatonicSwitch.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: strictlyPlatonicSwitch.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    @objc private func platonicSwitchChanged() {
        isStrictlyPlatonic = strictlyPlatonicSwitch.isOn
        savePlatonicPreference()
    }

    private func savePlatonicPreference() {
        // Save to UserDefaults immediately for local state
        UserDefaults.standard.set(isStrictlyPlatonic, forKey: "strictlyPlatonic")

        // Save to Supabase
        Task {
            do {
                guard SupabaseService.shared.currentUserId != nil else { return }

                try await SupabaseService.shared.updateProfile(ProfileUpdate(strictlyPlatonic: isStrictlyPlatonic))
                print("✅ Saved strictly platonic preference: \(isStrictlyPlatonic)")

                // Haptic feedback
                await MainActor.run {
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }
            } catch {
                print("❌ Failed to save strictly platonic preference: \(error)")
                await MainActor.run {
                    // Revert on error
                    self.isStrictlyPlatonic = !self.isStrictlyPlatonic
                    self.strictlyPlatonicSwitch.isOn = self.isStrictlyPlatonic
                    UserDefaults.standard.set(self.isStrictlyPlatonic, forKey: "strictlyPlatonic")

                    let alert = UIAlertController(
                        title: "Update Failed",
                        message: "Could not save your preference. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func createProficiencySection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "Proficiency Levels"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap to toggle levels on/off. You can select any combination of levels to match with."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        // Selection display label
        selectionDisplayLabel.font = .systemFont(ofSize: 15, weight: .medium)
        selectionDisplayLabel.textColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0) // Gold
        selectionDisplayLabel.textAlignment = .center
        container.addSubview(selectionDisplayLabel)

        container.addSubview(proficiencyLevelSelector)

        // Hint label
        let hintLabel = UILabel()
        hintLabel.text = "Long press for full level names"
        hintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = .tertiaryLabel
        hintLabel.textAlignment = .center
        container.addSubview(hintLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        proficiencyLevelSelector.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            selectionDisplayLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            selectionDisplayLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            selectionDisplayLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            proficiencyLevelSelector.topAnchor.constraint(equalTo: selectionDisplayLabel.bottomAnchor, constant: 12),
            proficiencyLevelSelector.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            proficiencyLevelSelector.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            proficiencyLevelSelector.heightAnchor.constraint(equalToConstant: 48),

            hintLabel.topAnchor.constraint(equalTo: proficiencyLevelSelector.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hintLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func updateSelectionDisplayLabel() {
        selectionDisplayLabel.text = selectedLevels.displayString
    }

    private func savePreferences() {
        // Save to UserDefaults
        selectedLevels.saveToDefaults()

        // Also save to Supabase
        Task {
            do {
                guard SupabaseService.shared.currentUserId != nil else { return }

                // For Supabase, we still use min/max for backward compatibility
                // Get the range that covers all selected levels
                let orderedSelected = selectedLevels.levels
                guard let first = orderedSelected.first, let last = orderedSelected.last else { return }

                let update = ProfileUpdate(
                    minProficiencyLevel: first.rawValue,
                    maxProficiencyLevel: last.rawValue
                )

                try await SupabaseService.shared.updateProfile(update)
                print("✅ Saved proficiency levels to Supabase: \(selectedLevels.displayString)")
            } catch {
                print("❌ Failed to save proficiency levels to Supabase: \(error)")
            }
        }

        showSavedConfirmation()
    }

    private func showSavedConfirmation() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
    }
}

// MARK: - ProficiencyLevelSelectorDelegate
extension MatchingPreferencesViewController: ProficiencyLevelSelectorDelegate {
    func proficiencyLevelSelector(_ selector: ProficiencyLevelSelector, didSelectLevels selection: ProficiencySelection) {
        selectedLevels = selection
        updateSelectionDisplayLabel()
        savePreferences()
    }
}
