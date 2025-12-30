import UIKit

/// Settings screen for managing which languages appear when chatting with AI Muse
class MuseLanguagesSettingsViewController: UIViewController {

    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let saveButton = UIButton(type: .system)

    // MARK: - Properties
    private var allMuseLanguages: [Language] = []
    private var selectedLanguages: Set<Language> = []
    private var alwaysIncludedLanguages: Set<Language> = [] // Native + learning languages

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadLanguages()
    }

    // MARK: - Setup
    private func setupViews() {
        title = "Muse Languages"
        view.backgroundColor = .systemGroupedBackground

        // Add close button if presented modally
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }

        // Save button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MuseLanguageSettingsCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.allowsMultipleSelection = true

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadLanguages() {
        // Get user's native and learning languages (always included, can't be removed)
        if let nativeCode = UserDefaults.standard.string(forKey: "nativeLanguage"),
           let native = Language(rawValue: nativeCode) {
            alwaysIncludedLanguages.insert(native)
        }

        if let learningCodes = UserDefaults.standard.array(forKey: "learningLanguages") as? [String] {
            for code in learningCodes {
                if let lang = Language(rawValue: code) {
                    alwaysIncludedLanguages.insert(lang)
                }
            }
        }

        // Get currently selected muse languages
        if let museCodes = UserDefaults.standard.array(forKey: "museLanguages") as? [String] {
            for code in museCodes {
                if let lang = Language(rawValue: code) {
                    selectedLanguages.insert(lang)
                }
            }
        }

        // All available muse languages
        allMuseLanguages = Language.museLanguages

        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        // Save selected languages to UserDefaults
        let languageCodes = selectedLanguages.map { $0.rawValue }
        UserDefaults.standard.set(languageCodes, forKey: "museLanguages")

        // Post notification for UI updates
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)

        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Pop or dismiss
        if navigationController?.viewControllers.first == self {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension MuseLanguagesSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Always included + Additional languages
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return alwaysIncludedLanguages.count
        } else {
            return allMuseLanguages.filter { !alwaysIncludedLanguages.contains($0) }.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Always Available"
        } else {
            return "Additional Languages"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Your native and learning languages are always available when chatting with your Muse."
        } else {
            return "Select additional languages you'd like to explore. These will appear as options when messaging your AI Muse."
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as? MuseLanguageSettingsCell else {
            return UITableViewCell()
        }

        if indexPath.section == 0 {
            // Always included languages
            let sortedIncluded = Array(alwaysIncludedLanguages).sorted { $0.name < $1.name }
            let language = sortedIncluded[indexPath.row]
            cell.configure(with: language, isSelected: true, isLocked: true)
        } else {
            // Additional languages
            let additionalLanguages = allMuseLanguages.filter { !alwaysIncludedLanguages.contains($0) }
            let language = additionalLanguages[indexPath.row]
            let isSelected = selectedLanguages.contains(language)
            cell.configure(with: language, isSelected: isSelected, isLocked: false)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension MuseLanguagesSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Can't toggle always-included languages
        guard indexPath.section == 1 else { return }

        let additionalLanguages = allMuseLanguages.filter { !alwaysIncludedLanguages.contains($0) }
        let language = additionalLanguages[indexPath.row]

        // Toggle selection
        if selectedLanguages.contains(language) {
            selectedLanguages.remove(language)
        } else {
            selectedLanguages.insert(language)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: - Muse Language Settings Cell
private class MuseLanguageSettingsCell: UITableViewCell {
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let nativeNameLabel = UILabel()
    private let checkmarkView = UIImageView()
    private let lockView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none

        // Flag
        flagLabel.font = .systemFont(ofSize: 28)
        contentView.addSubview(flagLabel)

        // Name stack
        let nameStack = UIStackView()
        nameStack.axis = .vertical
        nameStack.spacing = 2
        contentView.addSubview(nameStack)

        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        nameStack.addArrangedSubview(nameLabel)

        nativeNameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        nativeNameLabel.textColor = .secondaryLabel
        nameStack.addArrangedSubview(nativeNameLabel)

        // Checkmark
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = .systemBlue
        checkmarkView.contentMode = .scaleAspectFit
        contentView.addSubview(checkmarkView)

        // Lock (for always-included)
        lockView.image = UIImage(systemName: "lock.fill")
        lockView.tintColor = .systemGray
        lockView.contentMode = .scaleAspectFit
        lockView.isHidden = true
        contentView.addSubview(lockView)

        // Layout
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameStack.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        lockView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            flagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 36),

            nameStack.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            nameStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameStack.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -12),

            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24),

            lockView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lockView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            lockView.widthAnchor.constraint(equalToConstant: 20),
            lockView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with language: Language, isSelected: Bool, isLocked: Bool) {
        flagLabel.text = language.flag
        nameLabel.text = language.name
        nativeNameLabel.text = language.nativeName

        if isLocked {
            // Always included - show lock, hide checkmark
            checkmarkView.isHidden = true
            lockView.isHidden = false
            contentView.alpha = 0.7
        } else {
            // Toggleable
            lockView.isHidden = true
            checkmarkView.isHidden = false
            contentView.alpha = 1.0

            if isSelected {
                checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
                checkmarkView.tintColor = .systemBlue
            } else {
                checkmarkView.image = UIImage(systemName: "circle")
                checkmarkView.tintColor = .systemGray3
            }
        }
    }
}
