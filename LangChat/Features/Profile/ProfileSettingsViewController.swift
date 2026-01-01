import UIKit

class ProfileSettingsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum SettingSection: Int, CaseIterable {
        case basicInfo
        case location
        case languages
        case preferences

        var title: String? {
            switch self {
            case .basicInfo: return "Basic Info"
            case .location: return "Location"
            case .languages: return "Languages"
            case .preferences: return "Preferences"
            }
        }

        var items: [ProfileField] {
            switch self {
            case .basicInfo:
                return [.name, .birthYear, .bio]
            case .location:
                return [.hometown, .travelPlans]
            case .languages:
                return [.nativeLanguage, .learningLanguages]
            case .preferences:
                return [.relationshipIntent, .learningGoals, .strictlyPlatonic]
            }
        }
    }

    private enum ProfileField: String {
        case name
        case birthYear
        case bio
        case hometown
        case travelPlans
        case nativeLanguage
        case learningLanguages
        case relationshipIntent
        case learningGoals
        case strictlyPlatonic

        var title: String {
            switch self {
            case .name: return "Name"
            case .birthYear: return "Birth Year"
            case .bio: return "Bio"
            case .hometown: return "Hometown"
            case .travelPlans: return "Travel Plans"
            case .nativeLanguage: return "Native Language"
            case .learningLanguages: return "Learning Languages"
            case .relationshipIntent: return "Looking For"
            case .learningGoals: return "Learning Goals"
            case .strictlyPlatonic: return "Strictly Platonic"
            }
        }

        var icon: String {
            switch self {
            case .name: return "person"
            case .birthYear: return "calendar"
            case .bio: return "text.quote"
            case .hometown: return "mappin.and.ellipse"
            case .travelPlans: return "airplane"
            case .nativeLanguage: return "flag"
            case .learningLanguages: return "globe"
            case .relationshipIntent: return "heart"
            case .learningGoals: return "target"
            case .strictlyPlatonic: return "hand.raised"
            }
        }

        var placeholder: String {
            switch self {
            case .name: return "Tap to set name"
            case .birthYear: return "Tap to set birth year"
            case .bio: return "Tell others about yourself..."
            case .hometown: return "Tap to set location"
            case .travelPlans: return "Where are you traveling?"
            case .nativeLanguage: return "Select your native language"
            case .learningLanguages: return "Select languages you're learning"
            case .relationshipIntent: return "What are you looking for?"
            case .learningGoals: return "Select your learning goals"
            case .strictlyPlatonic: return "Language exchange only"
            }
        }

        var isToggle: Bool {
            return self == .strictlyPlatonic
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupViews() {
        title = "Profile Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")
        tableView.register(ToggleCell.self, forCellReuseIdentifier: "ToggleCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func getCurrentValue(for field: ProfileField) -> String {
        switch field {
        case .name:
            let firstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
            let lastName = UserDefaults.standard.string(forKey: "lastName") ?? ""
            if !firstName.isEmpty {
                return lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
            }
            return ""

        case .birthYear:
            let birthYear = UserDefaults.standard.integer(forKey: "birthYear")
            if birthYear > 0 {
                let age = Calendar.current.component(.year, from: Date()) - birthYear
                return "\(birthYear) (\(age) years old)"
            }
            return ""

        case .bio:
            return UserDefaults.standard.string(forKey: "bio") ?? ""

        case .hometown:
            let city = UserDefaults.standard.string(forKey: "city") ?? ""
            let country = UserDefaults.standard.string(forKey: "country") ?? ""
            if !city.isEmpty && !country.isEmpty {
                return "\(city), \(country)"
            }
            return UserDefaults.standard.string(forKey: "location") ?? ""

        case .travelPlans:
            if let data = UserDefaults.standard.data(forKey: "travelDestination"),
               let destination = try? JSONDecoder().decode(TravelDestination.self, from: data) {
                return destination.displayName
            }
            return ""

        case .nativeLanguage:
            return UserDefaults.standard.string(forKey: "nativeLanguage") ?? ""

        case .learningLanguages:
            if let languages = UserDefaults.standard.array(forKey: "learningLanguages") as? [String] {
                return languages.joined(separator: ", ")
            }
            return ""

        case .relationshipIntent:
            if let intents = UserDefaults.standard.array(forKey: "relationshipIntents") as? [String] {
                return intents.joined(separator: ", ")
            }
            return ""

        case .learningGoals:
            if let goals = UserDefaults.standard.array(forKey: "learningContexts") as? [String] {
                return goals.joined(separator: ", ")
            }
            return ""

        case .strictlyPlatonic:
            return UserDefaults.standard.bool(forKey: "strictlyPlatonic") ? "Yes" : "No"
        }
    }

    private func handleFieldSelection(_ field: ProfileField) {
        switch field {
        case .name: showNameEditor()
        case .birthYear: showBirthYearPicker()
        case .bio: showBioEditor()
        case .hometown: showLocationPicker()
        case .travelPlans: showTravelPlansEditor()
        case .nativeLanguage: showNativeLanguagePicker()
        case .learningLanguages: showLearningLanguagesPicker()
        case .relationshipIntent: showRelationshipIntentPicker()
        case .learningGoals: showLearningGoalsPicker()
        case .strictlyPlatonic: break // Handled by toggle
        }
    }

    // MARK: - Editors

    private func showNameEditor() {
        let currentFirstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
        let currentLastName = UserDefaults.standard.string(forKey: "lastName") ?? ""

        let alert = UIAlertController(title: "Update Name", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "First Name"
            textField.text = currentFirstName
            textField.autocapitalizationType = .words
        }

        alert.addTextField { textField in
            textField.placeholder = "Last Name (optional)"
            textField.text = currentLastName
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let firstName = alert?.textFields?[0].text, !firstName.isEmpty else { return }
            let lastName = alert?.textFields?[1].text ?? ""

            UserDefaults.standard.set(firstName, forKey: "firstName")
            UserDefaults.standard.set(lastName, forKey: "lastName")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func showBirthYearPicker() {
        let currentBirthYear = UserDefaults.standard.integer(forKey: "birthYear")

        let alert = UIAlertController(title: "Birth Year", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "e.g., 1990"
            textField.keyboardType = .numberPad
            if currentBirthYear > 0 {
                textField.text = "\(currentBirthYear)"
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let yearText = alert?.textFields?.first?.text,
                  let year = Int(yearText),
                  year > 1920 && year <= Calendar.current.component(.year, from: Date()) - 18 else {
                self?.showError("Please enter a valid birth year (must be 18+)")
                return
            }

            UserDefaults.standard.set(year, forKey: "birthYear")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func showBioEditor() {
        let vc = BioEditorViewController()
        vc.currentBio = UserDefaults.standard.string(forKey: "bio") ?? ""
        vc.onSave = { [weak self] newBio in
            UserDefaults.standard.set(newBio, forKey: "bio")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func showLocationPicker() {
        let vc = LocationPickerViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func showTravelPlansEditor() {
        let vc = TravelPlansViewController()
        vc.isEditMode = true
        vc.onSave = { [weak self] in
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showNativeLanguagePicker() {
        let vc = LanguagePickerViewController(
            title: "Native Language",
            selectedLanguages: [UserDefaults.standard.string(forKey: "nativeLanguage") ?? ""],
            allowsMultipleSelection: false
        )
        vc.onSave = { [weak self] languages in
            if let language = languages.first {
                UserDefaults.standard.set(language, forKey: "nativeLanguage")
                self?.saveToSupabase()
                self?.tableView.reloadData()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func showLearningLanguagesPicker() {
        let currentLanguages = UserDefaults.standard.array(forKey: "learningLanguages") as? [String] ?? []
        let vc = LanguagePickerViewController(
            title: "Learning Languages",
            selectedLanguages: currentLanguages,
            allowsMultipleSelection: true
        )
        vc.onSave = { [weak self] languages in
            UserDefaults.standard.set(languages, forKey: "learningLanguages")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func showRelationshipIntentPicker() {
        let options = ["Friendship", "Language Exchange", "Dating", "Networking", "Travel Buddy"]
        let currentIntents = UserDefaults.standard.array(forKey: "relationshipIntents") as? [String] ?? []

        let vc = MultiSelectPickerViewController(
            title: "Looking For",
            options: options,
            selectedOptions: currentIntents
        )
        vc.onSave = { [weak self] selected in
            UserDefaults.standard.set(selected, forKey: "relationshipIntents")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func showLearningGoalsPicker() {
        let options = ["Conversation Practice", "Grammar Help", "Pronunciation", "Cultural Exchange", "Professional/Business", "Travel Preparation", "Academic Study"]
        let currentGoals = UserDefaults.standard.array(forKey: "learningContexts") as? [String] ?? []

        let vc = MultiSelectPickerViewController(
            title: "Learning Goals",
            options: options,
            selectedOptions: currentGoals
        )
        vc.onSave = { [weak self] selected in
            UserDefaults.standard.set(selected, forKey: "learningContexts")
            self?.saveToSupabase()
            self?.tableView.reloadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func toggleStrictlyPlatonic(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: "strictlyPlatonic")
        saveToSupabase()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func saveToSupabase() {
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
        // The profile observer will handle the Supabase update
    }
}

// MARK: - UITableViewDataSource
extension ProfileSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingSection = SettingSection(rawValue: section) else { return 0 }
        return settingSection.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingSection = SettingSection(rawValue: section) else { return nil }
        return settingSection.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = SettingSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        let field = section.items[indexPath.row]

        if field.isToggle {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
            cell.configure(
                title: field.title,
                icon: field.icon,
                isOn: UserDefaults.standard.bool(forKey: "strictlyPlatonic")
            ) { [weak self] isOn in
                self?.toggleStrictlyPlatonic(isOn)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = field.title
        config.image = UIImage(systemName: field.icon)

        let currentValue = getCurrentValue(for: field)
        config.secondaryText = currentValue.isEmpty ? field.placeholder : currentValue
        config.secondaryTextProperties.color = currentValue.isEmpty ? .tertiaryLabel : .secondaryLabel
        config.secondaryTextProperties.numberOfLines = 2

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProfileSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = SettingSection(rawValue: indexPath.section) else { return }
        let field = section.items[indexPath.row]

        if !field.isToggle {
            handleFieldSelection(field)
        }
    }
}

// MARK: - LocationPickerDelegate
extension ProfileSettingsViewController: LocationPickerDelegate {
    func locationPicker(_ picker: LocationPickerViewController, didSelect location: LocationPickerViewController.LocationData) {
        UserDefaults.standard.set(location.displayName, forKey: "location")
        UserDefaults.standard.set(location.city, forKey: "city")
        UserDefaults.standard.set(location.country, forKey: "country")
        UserDefaults.standard.set(location.latitude, forKey: "latitude")
        UserDefaults.standard.set(location.longitude, forKey: "longitude")
        saveToSupabase()
        tableView.reloadData()
    }

    func locationPickerDidCancel(_ picker: LocationPickerViewController) {
        // Nothing to do
    }
}

// MARK: - Toggle Cell
class ToggleCell: UITableViewCell {
    private let toggle = UISwitch()
    private var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryView = toggle
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, icon: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        var config = defaultContentConfiguration()
        config.text = title
        config.image = UIImage(systemName: icon)
        contentConfiguration = config

        toggle.isOn = isOn
        self.onToggle = onToggle
    }

    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}

// MARK: - Bio Editor
class BioEditorViewController: UIViewController {
    var currentBio: String = ""
    var onSave: ((String) -> Void)?

    private let textView = UITextView()
    private let characterCountLabel = UILabel()
    private let maxCharacters = 500

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "Edit Bio"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        textView.text = currentBio
        textView.font = .systemFont(ofSize: 17)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        view.addSubview(textView)

        characterCountLabel.font = .systemFont(ofSize: 13)
        characterCountLabel.textColor = .secondaryLabel
        characterCountLabel.textAlignment = .right
        updateCharacterCount()
        view.addSubview(characterCountLabel)

        textView.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200),

            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
        ])

        textView.becomeFirstResponder()
    }

    private func updateCharacterCount() {
        let count = textView.text.count
        characterCountLabel.text = "\(count)/\(maxCharacters)"
        characterCountLabel.textColor = count > maxCharacters ? .systemRed : .secondaryLabel
        navigationItem.rightBarButtonItem?.isEnabled = count <= maxCharacters
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        onSave?(textView.text)
        dismiss(animated: true)
    }
}

extension BioEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
    }
}

// MARK: - Language Picker
class LanguagePickerViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var selectedLanguages: Set<String>
    private let allowsMultipleSelection: Bool
    var onSave: (([String]) -> Void)?

    private let languages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese",
        "Chinese (Mandarin)", "Japanese", "Korean", "Russian", "Arabic",
        "Hindi", "Dutch", "Polish", "Swedish", "Danish", "Norwegian",
        "Finnish", "Indonesian", "Filipino", "Vietnamese", "Thai", "Turkish"
    ]

    init(title: String, selectedLanguages: [String], allowsMultipleSelection: Bool) {
        self.selectedLanguages = Set(selectedLanguages)
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        onSave?(Array(selectedLanguages))
        dismiss(animated: true)
    }
}

extension LanguagePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let language = languages[indexPath.row]
        cell.textLabel?.text = language
        cell.accessoryType = selectedLanguages.contains(language) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let language = languages[indexPath.row]

        if allowsMultipleSelection {
            if selectedLanguages.contains(language) {
                selectedLanguages.remove(language)
            } else {
                selectedLanguages.insert(language)
            }
        } else {
            selectedLanguages = [language]
        }

        tableView.reloadData()
    }
}

// MARK: - Multi-Select Picker
class MultiSelectPickerViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let options: [String]
    private var selectedOptions: Set<String>
    var onSave: (([String]) -> Void)?

    init(title: String, options: [String], selectedOptions: [String]) {
        self.options = options
        self.selectedOptions = Set(selectedOptions)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        onSave?(Array(selectedOptions))
        dismiss(animated: true)
    }
}

extension MultiSelectPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let option = options[indexPath.row]
        cell.textLabel?.text = option
        cell.accessoryType = selectedOptions.contains(option) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]

        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }

        tableView.reloadData()
    }
}

