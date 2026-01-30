import UIKit

/// Combined dating preferences screen - only shown when user selects "Open to dating"
/// Asks for gender identity and who they'd like to match with in a tactful, inclusive way
class DatingPreferencesViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let datingScrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Gender section
    private let genderSectionLabel = UILabel()
    private let genderStack = UIStackView()
    private var genderButtons: [UIButton] = []

    // Preference section
    private let preferenceSectionLabel = UILabel()
    private let preferenceStack = UIStackView()
    private var preferenceButtons: [UIButton] = []

    private let noteLabel = UILabel()

    // MARK: - Properties
    private var selectedGender: Gender?
    private var selectedPreference: GenderPreference = .all

    // MARK: - Lifecycle
    override func configure() {
        step = .datingPreferences
        setTitle("onboarding_dating_title".localized)
        setupViews()

        // Default to "Everyone" for preference
        selectedPreference = .all
        updatePreferenceButtonAppearance(selectedTag: 0)
    }

    // MARK: - Setup
    private func setupViews() {
        datingScrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(datingScrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        datingScrollView.addSubview(contentStack)

        // Layout scroll view
        datingScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            datingScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            datingScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            datingScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            datingScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: datingScrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: datingScrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: datingScrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: datingScrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: datingScrollView.widthAnchor)
        ])

        setupGenderSection()
        setupPreferenceSection()
        setupNoteLabel()
    }

    private func setupGenderSection() {
        // Section label
        genderSectionLabel.text = "onboarding_dating_identify".localized
        genderSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        genderSectionLabel.textColor = .label
        contentStack.addArrangedSubview(genderSectionLabel)

        // Gender options stack
        genderStack.axis = .vertical
        genderStack.spacing = 10
        genderStack.alignment = .fill
        contentStack.addArrangedSubview(genderStack)

        // Create buttons for each gender - using friendlier display names for dating context
        let genderOptions: [(Gender, String, String)] = [
            (.male, "dating_gender_man".localized, "👨"),
            (.female, "dating_gender_woman".localized, "👩"),
            (.nonBinary, "dating_gender_nonbinary".localized, "🧑"),
            (.preferNotToSay, "dating_gender_prefer_not".localized, "🤐")
        ]

        for (index, option) in genderOptions.enumerated() {
            let button = createOptionButton(
                title: option.1,
                emoji: option.2,
                tag: index
            )
            button.addTarget(self, action: #selector(genderButtonTapped(_:)), for: .touchUpInside)
            genderButtons.append(button)
            genderStack.addArrangedSubview(button)
        }
    }

    private func setupPreferenceSection() {
        // Section label
        preferenceSectionLabel.text = "onboarding_dating_interested".localized
        preferenceSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        preferenceSectionLabel.textColor = .label
        contentStack.addArrangedSubview(preferenceSectionLabel)

        // Preference options stack
        preferenceStack.axis = .vertical
        preferenceStack.spacing = 10
        preferenceStack.alignment = .fill
        contentStack.addArrangedSubview(preferenceStack)

        // Preference options - inclusive and non-labeling
        let preferenceOptions: [(GenderPreference, String, String, String)] = [
            (.all, "dating_pref_everyone".localized, "🌈", "dating_pref_everyone_desc".localized),
            (.sameOnly, "dating_pref_same".localized, "🪞", "dating_pref_same_desc".localized),
            (.differentOnly, "dating_pref_different".localized, "🔄", "dating_pref_different_desc".localized)
        ]

        for (index, option) in preferenceOptions.enumerated() {
            let button = createPreferenceButton(
                title: option.1,
                emoji: option.2,
                subtitle: option.3,
                tag: index
            )
            button.addTarget(self, action: #selector(preferenceButtonTapped(_:)), for: .touchUpInside)
            preferenceButtons.append(button)
            preferenceStack.addArrangedSubview(button)
        }
    }

    private func setupNoteLabel() {
        noteLabel.text = "onboarding_dating_privacy_note".localized
        noteLabel.font = .systemFont(ofSize: 13, weight: .regular)
        noteLabel.textColor = .tertiaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.textAlignment = .center
        contentStack.addArrangedSubview(noteLabel)
    }

    private func createOptionButton(title: String, emoji: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = tag

        // Emoji label
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 24)
        emojiLabel.isUserInteractionEnabled = false
        button.addSubview(emojiLabel)

        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.isUserInteractionEnabled = false
        button.addSubview(titleLabel)

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 56),

            emojiLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])

        return button
    }

    private func createPreferenceButton(title: String, emoji: String, subtitle: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = tag

        // Emoji label
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 24)
        emojiLabel.isUserInteractionEnabled = false
        button.addSubview(emojiLabel)

        // Text stack
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        button.addSubview(textStack)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        textStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        textStack.addArrangedSubview(subtitleLabel)

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 70),

            emojiLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 32),

            textStack.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])

        return button
    }

    // MARK: - Actions
    @objc private func genderButtonTapped(_ sender: UIButton) {
        let genders: [Gender] = [.male, .female, .nonBinary, .preferNotToSay]
        selectedGender = genders[sender.tag]

        // Update button appearances
        for (index, button) in genderButtons.enumerated() {
            if index == sender.tag {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .secondarySystemBackground
            }
        }

        updateContinueState()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    @objc private func preferenceButtonTapped(_ sender: UIButton) {
        let preferences: [GenderPreference] = [.all, .sameOnly, .differentOnly]
        selectedPreference = preferences[sender.tag]

        updatePreferenceButtonAppearance(selectedTag: sender.tag)
        updateContinueState()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func updatePreferenceButtonAppearance(selectedTag: Int) {
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

    private func updateContinueState() {
        // Need gender selected to continue (preference has default)
        updateContinueButton(enabled: selectedGender != nil)
    }

    override func continueButtonTapped() {
        guard let gender = selectedGender else { return }

        // Return both values as a tuple
        let data: (Gender, GenderPreference) = (gender, selectedPreference)
        delegate?.didCompleteStep(withData: data)
    }
}
