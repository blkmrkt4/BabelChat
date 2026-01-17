import UIKit

class MatchingPreferencesViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Strictly Platonic
    private let strictlyPlatonicSwitch = UISwitch()

    // Dating Preferences (hidden when strictly platonic)
    private let datingPreferencesContainer = UIView()
    private var genderButtons: [UIButton] = []
    private var preferenceButtons: [UIButton] = []

    // Location Preferences
    private var locationPreferenceButtons: [LocationPreference: UIButton] = [:]
    private let distanceContainer = UIView()
    private let distanceSlider = UISlider()
    private let distanceLabel = UILabel()
    private var distanceHeightConstraint: NSLayoutConstraint!

    private let countryContainer = UIView()
    private let selectedCountriesLabel = UILabel()
    private let selectCountriesButton = UIButton(type: .system)
    private var countryHeightConstraint: NSLayoutConstraint!

    // Proficiency Level
    private let proficiencyLevelSelector = ProficiencyLevelSelector()
    private let selectionDisplayLabel = UILabel()

    // Blur Photos
    private let blurPhotosSwitch = UISwitch()

    // Looking For (Relationship Intent)
    private var lookingForButtons: [UIButton] = []
    private let lookingForOptions = ["Friendship", "Language Exchange", "Dating", "Networking", "Travel Buddy"]

    // Save confirmation
    private let saveConfirmationLabel = UILabel()

    // MARK: - Properties
    private var isStrictlyPlatonic: Bool = false
    private var blurPhotosUntilMatch: Bool = false
    private var selectedRelationshipIntents: Set<String> = []
    private var selectedGender: Gender?
    private var selectedGenderPreference: GenderPreference = .all
    private var selectedLocationPreference: LocationPreference = .anywhere
    private var selectedDistance: Int = 50
    private var selectedCountries: [String] = []
    private var isExcludeMode: Bool = false
    private var selectedLevels: ProficiencySelection = .all

    // User's location info
    private var userCity: String = ""
    private var userCountry: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadSavedPreferences()
        setupViews()
        updateDatingPreferencesVisibility(animated: false)
    }

    private func setupNavigationBar() {
        title = "Matching Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
    }

    private func loadSavedPreferences() {
        // Strictly platonic
        isStrictlyPlatonic = UserDefaults.standard.bool(forKey: "strictlyPlatonic")

        // Blur photos until match
        blurPhotosUntilMatch = UserDefaults.standard.bool(forKey: "blurPhotosUntilMatch")

        // Gender & preference
        if let genderRaw = UserDefaults.standard.string(forKey: "userGender"),
           let gender = Gender(rawValue: genderRaw) {
            selectedGender = gender
        }
        if let prefRaw = UserDefaults.standard.string(forKey: "genderPreference"),
           let pref = GenderPreference(rawValue: prefRaw) {
            selectedGenderPreference = pref
        }

        // User's location (for displaying in location options)
        userCity = UserDefaults.standard.string(forKey: "city") ?? ""
        userCountry = UserDefaults.standard.string(forKey: "country") ?? ""

        // Location preference
        if let locPrefRaw = UserDefaults.standard.string(forKey: "locationPreference"),
           let locPref = LocationPreference(rawValue: locPrefRaw) {
            selectedLocationPreference = locPref
        }
        selectedDistance = UserDefaults.standard.integer(forKey: "maxDistanceKm")
        if selectedDistance == 0 { selectedDistance = 50 }

        if let countries = UserDefaults.standard.array(forKey: "preferredCountries") as? [String] {
            selectedCountries = countries
            isExcludeMode = false
        } else if let excluded = UserDefaults.standard.array(forKey: "excludedCountries") as? [String] {
            selectedCountries = excluded
            isExcludeMode = true
        }

        // Proficiency
        selectedLevels = ProficiencySelection.fromDefaults()

        // Relationship intents (Looking For)
        if let intents = UserDefaults.standard.array(forKey: "relationshipIntents") as? [String] {
            selectedRelationshipIntents = Set(intents)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill

        // 1. Strictly Platonic section
        stackView.addArrangedSubview(createPlatonicSection())

        // 2. Blur Photos section
        stackView.addArrangedSubview(createBlurPhotosSection())

        // 3. Looking For section
        stackView.addArrangedSubview(createLookingForSection())

        // 4. Dating Preferences section (gender + preference)
        setupDatingPreferencesSection()
        stackView.addArrangedSubview(datingPreferencesContainer)

        // 4. Location Preferences section
        stackView.addArrangedSubview(createLocationSection())

        // 5. Proficiency Level section
        stackView.addArrangedSubview(createProficiencySection())

        // Save confirmation label (floating)
        setupSaveConfirmation()

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
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        // Set initial states
        proficiencyLevelSelector.delegate = self
        proficiencyLevelSelector.setSelection(selectedLevels, animated: false)
        updateSelectionDisplayLabel()
        updateLocationButtonAppearance()
        updateLocationExpandableContainers(animated: false)
    }

    // MARK: - Strictly Platonic Section
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
        subtitleLabel.text = "Only match with others seeking platonic language exchange"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        strictlyPlatonicSwitch.isOn = isStrictlyPlatonic
        strictlyPlatonicSwitch.onTintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
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
        updateDatingPreferencesVisibility(animated: true)
        savePlatonicPreference()
    }

    // MARK: - Blur Photos Section
    private func createBlurPhotosSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "Blur Photos Until Match"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your photos will be blurred for potential matches until you both swipe right"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        blurPhotosSwitch.isOn = blurPhotosUntilMatch
        blurPhotosSwitch.onTintColor = .systemBlue
        blurPhotosSwitch.addTarget(self, action: #selector(blurPhotosSwitchChanged), for: .valueChanged)
        container.addSubview(blurPhotosSwitch)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        blurPhotosSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            blurPhotosSwitch.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            blurPhotosSwitch.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurPhotosSwitch.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    @objc private func blurPhotosSwitchChanged() {
        blurPhotosUntilMatch = blurPhotosSwitch.isOn
        saveBlurPhotosPreference()
    }

    private func saveBlurPhotosPreference() {
        UserDefaults.standard.set(blurPhotosUntilMatch, forKey: "blurPhotosUntilMatch")

        Task {
            do {
                try await SupabaseService.shared.updateProfile(ProfileUpdate(blurPhotosUntilMatch: blurPhotosUntilMatch))
                await MainActor.run { showSaveConfirmation() }
                print("✅ Saved blur photos: \(blurPhotosUntilMatch)")
            } catch {
                print("❌ Failed to save blur photos: \(error)")
            }
        }
    }

    // MARK: - Looking For Section
    private func createLookingForSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 12
        innerStack.alignment = .fill
        container.addSubview(innerStack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Looking For"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        innerStack.addArrangedSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select all that apply"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        innerStack.addArrangedSubview(subtitleLabel)

        // Options - using a flow layout with 2 columns
        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 8
        optionsStack.alignment = .fill

        // Create rows of 2 buttons each
        var rowStack: UIStackView?
        for (index, option) in lookingForOptions.enumerated() {
            if index % 2 == 0 {
                rowStack = UIStackView()
                rowStack?.axis = .horizontal
                rowStack?.spacing = 8
                rowStack?.distribution = .fillEqually
                optionsStack.addArrangedSubview(rowStack!)
            }

            let button = createLookingForButton(title: option, tag: index)
            lookingForButtons.append(button)
            rowStack?.addArrangedSubview(button)

            // Highlight if selected
            if selectedRelationshipIntents.contains(option) {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            }
        }

        // Add empty view if odd number of options
        if lookingForOptions.count % 2 != 0 {
            let spacer = UIView()
            rowStack?.addArrangedSubview(spacer)
        }

        innerStack.addArrangedSubview(optionsStack)

        // Layout
        innerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func createLookingForButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(lookingForButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func lookingForButtonTapped(_ sender: UIButton) {
        let option = lookingForOptions[sender.tag]

        if selectedRelationshipIntents.contains(option) {
            selectedRelationshipIntents.remove(option)
            sender.layer.borderColor = UIColor.clear.cgColor
            sender.backgroundColor = .tertiarySystemBackground
        } else {
            selectedRelationshipIntents.insert(option)
            sender.layer.borderColor = UIColor.systemBlue.cgColor
            sender.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        }

        saveLookingForPreferences()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func saveLookingForPreferences() {
        UserDefaults.standard.set(Array(selectedRelationshipIntents), forKey: "relationshipIntents")

        Task {
            do {
                try await SupabaseService.shared.updateProfile(ProfileUpdate(relationshipIntents: Array(selectedRelationshipIntents)))
                await MainActor.run { showSaveConfirmation() }
                print("✅ Saved relationship intents: \(selectedRelationshipIntents)")
            } catch {
                print("❌ Failed to save relationship intents: \(error)")
            }
        }
    }

    // MARK: - Save Confirmation
    private func setupSaveConfirmation() {
        saveConfirmationLabel.text = "✓ Saved"
        saveConfirmationLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        saveConfirmationLabel.textColor = .white
        saveConfirmationLabel.backgroundColor = UIColor.systemGreen
        saveConfirmationLabel.textAlignment = .center
        saveConfirmationLabel.layer.cornerRadius = 16
        saveConfirmationLabel.layer.masksToBounds = true
        saveConfirmationLabel.alpha = 0

        view.addSubview(saveConfirmationLabel)
        saveConfirmationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            saveConfirmationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveConfirmationLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveConfirmationLabel.widthAnchor.constraint(equalToConstant: 100),
            saveConfirmationLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func showSaveConfirmation() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(withDuration: 0.2, animations: {
            self.saveConfirmationLabel.alpha = 1
            self.saveConfirmationLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0, options: [], animations: {
                self.saveConfirmationLabel.transform = .identity
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 1.0, options: [], animations: {
                    self.saveConfirmationLabel.alpha = 0
                })
            }
        }
    }

    private func updateDatingPreferencesVisibility(animated: Bool) {
        let shouldHide = isStrictlyPlatonic

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.datingPreferencesContainer.alpha = shouldHide ? 0 : 1
                self.datingPreferencesContainer.isHidden = shouldHide
            }
        } else {
            datingPreferencesContainer.alpha = shouldHide ? 0 : 1
            datingPreferencesContainer.isHidden = shouldHide
        }
    }

    // MARK: - Dating Preferences Section
    private func setupDatingPreferencesSection() {
        datingPreferencesContainer.backgroundColor = .secondarySystemBackground
        datingPreferencesContainer.layer.cornerRadius = 12

        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 16
        innerStack.alignment = .fill
        datingPreferencesContainer.addSubview(innerStack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Dating Preferences"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        innerStack.addArrangedSubview(titleLabel)

        // Gender identity section
        let genderLabel = UILabel()
        genderLabel.text = "I identify as..."
        genderLabel.font = .systemFont(ofSize: 15, weight: .medium)
        genderLabel.textColor = .secondaryLabel
        innerStack.addArrangedSubview(genderLabel)

        let genderStack = UIStackView()
        genderStack.axis = .horizontal
        genderStack.spacing = 8
        genderStack.distribution = .fillEqually

        let genderOptions: [(Gender, String)] = [
            (.male, "Man"),
            (.female, "Woman"),
            (.nonBinary, "Non-binary"),
            (.preferNotToSay, "Other")
        ]

        for (index, option) in genderOptions.enumerated() {
            let button = createCompactOptionButton(title: option.1, tag: index)
            button.addTarget(self, action: #selector(genderButtonTapped(_:)), for: .touchUpInside)
            genderButtons.append(button)
            genderStack.addArrangedSubview(button)

            // Highlight if selected
            if selectedGender == option.0 {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            }
        }
        innerStack.addArrangedSubview(genderStack)

        // Preference section
        let prefLabel = UILabel()
        prefLabel.text = "I'm interested in..."
        prefLabel.font = .systemFont(ofSize: 15, weight: .medium)
        prefLabel.textColor = .secondaryLabel
        innerStack.addArrangedSubview(prefLabel)

        let prefStack = UIStackView()
        prefStack.axis = .horizontal
        prefStack.spacing = 8
        prefStack.distribution = .fillEqually

        let prefOptions: [(GenderPreference, String)] = [
            (.all, "Everyone"),
            (.sameOnly, "Same"),
            (.differentOnly, "Different")
        ]

        for (index, option) in prefOptions.enumerated() {
            let button = createCompactOptionButton(title: option.1, tag: index)
            button.addTarget(self, action: #selector(preferenceButtonTapped(_:)), for: .touchUpInside)
            preferenceButtons.append(button)
            prefStack.addArrangedSubview(button)

            // Highlight if selected
            if selectedGenderPreference == option.0 {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            }
        }
        innerStack.addArrangedSubview(prefStack)

        // Layout
        innerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: datingPreferencesContainer.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: datingPreferencesContainer.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: datingPreferencesContainer.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: datingPreferencesContainer.bottomAnchor, constant: -16)
        ])
    }

    private func createCompactOptionButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    @objc private func genderButtonTapped(_ sender: UIButton) {
        let genders: [Gender] = [.male, .female, .nonBinary, .preferNotToSay]
        selectedGender = genders[sender.tag]

        for (index, button) in genderButtons.enumerated() {
            if index == sender.tag {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .tertiarySystemBackground
            }
        }

        saveGenderPreferences()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func preferenceButtonTapped(_ sender: UIButton) {
        let preferences: [GenderPreference] = [.all, .sameOnly, .differentOnly]
        selectedGenderPreference = preferences[sender.tag]

        for (index, button) in preferenceButtons.enumerated() {
            if index == sender.tag {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .tertiarySystemBackground
            }
        }

        saveGenderPreferences()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Location Section
    private func createLocationSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 12
        innerStack.alignment = .fill
        container.addSubview(innerStack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Location Preferences"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        innerStack.addArrangedSubview(titleLabel)

        // Location preference buttons
        for preference in LocationPreference.allCases {
            let button = createLocationButton(for: preference)
            locationPreferenceButtons[preference] = button
            innerStack.addArrangedSubview(button)

            // Add distance slider after localRegional
            if preference == .localRegional {
                setupDistanceSlider()
                innerStack.addArrangedSubview(distanceContainer)
            }

            // Add country selection after specificCountries
            if preference == .specificCountries {
                setupCountrySelection()
                innerStack.addArrangedSubview(countryContainer)
            }
        }

        // Layout
        innerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func createLocationButton(for preference: LocationPreference) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor

        let icon = UIImageView(image: UIImage(systemName: preference.icon))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit
        button.addSubview(icon)

        // Determine the display text based on preference and user's location
        var displayText = preference.displayName
        switch preference {
        case .country:
            if !userCountry.isEmpty {
                displayText = "My Country: \(userCountry)"
            }
        case .localRegional:
            if !userCity.isEmpty && !userCountry.isEmpty {
                displayText = "Local/Regional: \(userCity), \(userCountry)"
            } else if !userCity.isEmpty {
                displayText = "Local/Regional: \(userCity)"
            }
        default:
            break
        }

        let titleLabel = UILabel()
        titleLabel.text = displayText
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.isUserInteractionEnabled = false
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        button.addSubview(titleLabel)

        icon.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 48),

            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12)
        ])

        button.tag = LocationPreference.allCases.firstIndex(of: preference) ?? 0
        button.addTarget(self, action: #selector(locationButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    private func setupDistanceSlider() {
        distanceContainer.backgroundColor = .quaternarySystemFill
        distanceContainer.layer.cornerRadius = 10
        distanceContainer.clipsToBounds = true
        distanceContainer.alpha = 0

        distanceLabel.text = "Maximum distance: \(selectedDistance) km"
        distanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        distanceLabel.textColor = .secondaryLabel
        distanceLabel.textAlignment = .center
        distanceContainer.addSubview(distanceLabel)

        distanceSlider.minimumValue = 10
        distanceSlider.maximumValue = 200
        distanceSlider.value = Float(selectedDistance)
        distanceSlider.tintColor = .systemBlue
        distanceSlider.addTarget(self, action: #selector(distanceSliderChanged(_:)), for: .valueChanged)
        distanceSlider.addTarget(self, action: #selector(distanceSliderEnded), for: [.touchUpInside, .touchUpOutside])
        distanceContainer.addSubview(distanceSlider)

        distanceContainer.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceSlider.translatesAutoresizingMaskIntoConstraints = false

        distanceHeightConstraint = distanceContainer.heightAnchor.constraint(equalToConstant: 0)
        distanceHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            distanceLabel.topAnchor.constraint(equalTo: distanceContainer.topAnchor, constant: 12),
            distanceLabel.leadingAnchor.constraint(equalTo: distanceContainer.leadingAnchor, constant: 12),
            distanceLabel.trailingAnchor.constraint(equalTo: distanceContainer.trailingAnchor, constant: -12),

            distanceSlider.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 8),
            distanceSlider.leadingAnchor.constraint(equalTo: distanceContainer.leadingAnchor, constant: 12),
            distanceSlider.trailingAnchor.constraint(equalTo: distanceContainer.trailingAnchor, constant: -12)
        ])
    }

    private func setupCountrySelection() {
        countryContainer.backgroundColor = .quaternarySystemFill
        countryContainer.layer.cornerRadius = 10
        countryContainer.clipsToBounds = true
        countryContainer.alpha = 0

        selectedCountriesLabel.text = selectedCountries.isEmpty ? "No countries selected" : "\(selectedCountries.count) selected"
        selectedCountriesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        selectedCountriesLabel.textColor = .secondaryLabel
        selectedCountriesLabel.numberOfLines = 0
        countryContainer.addSubview(selectedCountriesLabel)

        selectCountriesButton.setTitle("Select Countries", for: .normal)
        selectCountriesButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        selectCountriesButton.backgroundColor = .systemBlue
        selectCountriesButton.setTitleColor(.white, for: .normal)
        selectCountriesButton.layer.cornerRadius = 8
        selectCountriesButton.addTarget(self, action: #selector(selectCountriesTapped), for: .touchUpInside)
        countryContainer.addSubview(selectCountriesButton)

        countryContainer.translatesAutoresizingMaskIntoConstraints = false
        selectedCountriesLabel.translatesAutoresizingMaskIntoConstraints = false
        selectCountriesButton.translatesAutoresizingMaskIntoConstraints = false

        countryHeightConstraint = countryContainer.heightAnchor.constraint(equalToConstant: 0)
        countryHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            selectedCountriesLabel.topAnchor.constraint(equalTo: countryContainer.topAnchor, constant: 12),
            selectedCountriesLabel.leadingAnchor.constraint(equalTo: countryContainer.leadingAnchor, constant: 12),
            selectedCountriesLabel.trailingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: -12),

            selectCountriesButton.topAnchor.constraint(equalTo: selectedCountriesLabel.bottomAnchor, constant: 8),
            selectCountriesButton.leadingAnchor.constraint(equalTo: countryContainer.leadingAnchor, constant: 12),
            selectCountriesButton.trailingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: -12),
            selectCountriesButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func locationButtonTapped(_ sender: UIButton) {
        selectedLocationPreference = LocationPreference.allCases[sender.tag]
        updateLocationButtonAppearance()
        updateLocationExpandableContainers(animated: true)
        saveLocationPreferences()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func distanceSliderChanged(_ sender: UISlider) {
        let snappedValue = round(sender.value / 5) * 5
        sender.value = snappedValue
        selectedDistance = Int(snappedValue)
        distanceLabel.text = "Maximum distance: \(selectedDistance) km"
    }

    @objc private func distanceSliderEnded() {
        saveLocationPreferences()
    }

    @objc private func selectCountriesTapped() {
        let countryPicker = CountryPickerViewController()
        countryPicker.selectedCountries = Set(selectedCountries)
        countryPicker.isExcludeMode = selectedLocationPreference == .excludeCountries
        countryPicker.delegate = self

        let nav = UINavigationController(rootViewController: countryPicker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func updateLocationButtonAppearance() {
        for (preference, button) in locationPreferenceButtons {
            if preference == selectedLocationPreference {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .tertiarySystemBackground
            }
        }
    }

    private func updateLocationExpandableContainers(animated: Bool) {
        let showDistance = selectedLocationPreference == .localRegional
        let showCountries = selectedLocationPreference == .specificCountries || selectedLocationPreference == .excludeCountries

        isExcludeMode = selectedLocationPreference == .excludeCountries
        selectCountriesButton.setTitle(isExcludeMode ? "Select Countries to Exclude" : "Select Countries", for: .normal)

        if showCountries && selectedCountries.isEmpty {
            selectedCountriesLabel.text = isExcludeMode ? "No countries excluded" : "No countries selected"
        }

        let animationBlock = {
            self.distanceHeightConstraint.constant = showDistance ? 80 : 0
            self.distanceContainer.alpha = showDistance ? 1 : 0

            self.countryHeightConstraint.constant = showCountries ? 90 : 0
            self.countryContainer.alpha = showCountries ? 1 : 0

            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    private func updateSelectedCountriesLabel() {
        if selectedCountries.isEmpty {
            selectedCountriesLabel.text = isExcludeMode ? "No countries excluded" : "No countries selected"
        } else {
            let names = selectedCountries.prefix(3).compactMap { Locale.current.localizedString(forRegionCode: $0) }
            if selectedCountries.count <= 3 {
                selectedCountriesLabel.text = names.joined(separator: ", ")
            } else {
                selectedCountriesLabel.text = "\(names.joined(separator: ", ")) +\(selectedCountries.count - 3) more"
            }
        }
    }

    // MARK: - Proficiency Section
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
        subtitleLabel.text = "Tap to toggle which levels you want to match with"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        container.addSubview(subtitleLabel)

        selectionDisplayLabel.font = .systemFont(ofSize: 15, weight: .medium)
        selectionDisplayLabel.textColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
        selectionDisplayLabel.textAlignment = .center
        container.addSubview(selectionDisplayLabel)

        container.addSubview(proficiencyLevelSelector)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        proficiencyLevelSelector.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            selectionDisplayLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            selectionDisplayLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            selectionDisplayLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            proficiencyLevelSelector.topAnchor.constraint(equalTo: selectionDisplayLabel.bottomAnchor, constant: 8),
            proficiencyLevelSelector.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            proficiencyLevelSelector.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            proficiencyLevelSelector.heightAnchor.constraint(equalToConstant: 48),
            proficiencyLevelSelector.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func updateSelectionDisplayLabel() {
        selectionDisplayLabel.text = selectedLevels.displayString
    }

    // MARK: - Save Methods
    private func savePlatonicPreference() {
        UserDefaults.standard.set(isStrictlyPlatonic, forKey: "strictlyPlatonic")

        Task {
            do {
                try await SupabaseService.shared.updateProfile(ProfileUpdate(strictlyPlatonic: isStrictlyPlatonic))
                await MainActor.run { showSaveConfirmation() }
                print("✅ Saved strictly platonic: \(isStrictlyPlatonic)")
            } catch {
                print("❌ Failed to save strictly platonic: \(error)")
            }
        }
    }

    private func saveGenderPreferences() {
        if let gender = selectedGender {
            UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
        }
        UserDefaults.standard.set(selectedGenderPreference.rawValue, forKey: "genderPreference")

        showSaveConfirmation()
        print("✅ Saved gender preferences: \(selectedGender?.rawValue ?? "none"), \(selectedGenderPreference.rawValue)")
    }

    private func saveLocationPreferences() {
        UserDefaults.standard.set(selectedLocationPreference.rawValue, forKey: "locationPreference")
        UserDefaults.standard.set(selectedDistance, forKey: "maxDistanceKm")

        // Clear both arrays first
        UserDefaults.standard.removeObject(forKey: "preferredCountries")
        UserDefaults.standard.removeObject(forKey: "excludedCountries")

        // Set the appropriate one
        if selectedLocationPreference == .specificCountries {
            UserDefaults.standard.set(selectedCountries, forKey: "preferredCountries")
        } else if selectedLocationPreference == .excludeCountries {
            UserDefaults.standard.set(selectedCountries, forKey: "excludedCountries")
        }

        showSaveConfirmation()
        print("✅ Saved location preferences: \(selectedLocationPreference.rawValue), \(selectedDistance)km")
    }

    private func saveProficiencyPreferences() {
        selectedLevels.saveToDefaults()

        Task {
            do {
                let orderedSelected = selectedLevels.levels
                guard let first = orderedSelected.first, let last = orderedSelected.last else { return }

                let update = ProfileUpdate(
                    minProficiencyLevel: first.rawValue,
                    maxProficiencyLevel: last.rawValue
                )

                try await SupabaseService.shared.updateProfile(update)
                await MainActor.run { showSaveConfirmation() }
                print("✅ Saved proficiency levels: \(selectedLevels.displayString)")
            } catch {
                print("❌ Failed to save proficiency levels: \(error)")
            }
        }
    }
}

// MARK: - CountryPickerDelegate
extension MatchingPreferencesViewController: CountryPickerDelegate {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountries countries: Set<String>) {
        selectedCountries = Array(countries).sorted()
        updateSelectedCountriesLabel()
        saveLocationPreferences()
    }
}

// MARK: - ProficiencyLevelSelectorDelegate
extension MatchingPreferencesViewController: ProficiencyLevelSelectorDelegate {
    func proficiencyLevelSelector(_ selector: ProficiencyLevelSelector, didSelectLevels selection: ProficiencySelection) {
        selectedLevels = selection
        updateSelectionDisplayLabel()
        saveProficiencyPreferences()
    }
}
