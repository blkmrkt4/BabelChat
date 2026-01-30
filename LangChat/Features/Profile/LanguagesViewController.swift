import UIKit

class LanguagesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var nativeLanguage: UserLanguage?
    private var learningLanguages: [UserLanguage] = []
    private var openToLanguages: [Language] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadUserLanguages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload in case changes were made in EditProfileViewController
        loadUserLanguages()
    }

    private func setupViews() {
        title = "Languages"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadUserLanguages() {
        // Load from UserDefaults for now
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            nativeLanguage = decoded.nativeLanguage
            learningLanguages = decoded.learningLanguages
            openToLanguages = decoded.openToLanguages
        } else {
            // Default data
            nativeLanguage = UserLanguage(language: .english, proficiency: .native, isNative: true)
            learningLanguages = [
                UserLanguage(language: .spanish, proficiency: .intermediate, isNative: false),
                UserLanguage(language: .japanese, proficiency: .beginner, isNative: false)
            ]
            openToLanguages = [.spanish]
        }

        tableView.reloadData()
    }

    // MARK: - Proficiency Editing

    private func showProficiencyPicker(for index: Int) {
        let language = learningLanguages[index]

        let alertController = UIAlertController(
            title: "Change Proficiency",
            message: "Select your \(language.language.name) proficiency level",
            preferredStyle: .actionSheet
        )

        for proficiency in LanguageProficiency.allCases {
            if proficiency == .native { continue } // Skip native for learning languages

            let isSelected = proficiency == language.proficiency
            let title = isSelected ? "✓ \(proficiency.displayName)" : proficiency.displayName

            alertController.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.updateProficiency(at: index, to: proficiency)
            })
        }

        alertController.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alertController.popoverPresentationController {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 1)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }

        present(alertController, animated: true)
    }

    private func updateProficiency(at index: Int, to proficiency: LanguageProficiency) {
        let language = learningLanguages[index]
        learningLanguages[index] = UserLanguage(
            language: language.language,
            proficiency: proficiency,
            isNative: false
        )

        tableView.reloadRows(at: [IndexPath(row: index, section: 1)], with: .automatic)
        saveLanguages()
    }

    // MARK: - Add Language

    private func showAddLanguagePicker() {
        let alertController = UIAlertController(
            title: "Add Learning Language",
            message: "Select a language to learn",
            preferredStyle: .actionSheet
        )

        let languages: [Language] = [.english, .spanish, .french, .german, .japanese, .korean, .chinese, .portuguese, .italian, .russian]

        for language in languages {
            // Skip if already learning this language or it's the native language
            if learningLanguages.contains(where: { $0.language.code == language.code }) { continue }
            if nativeLanguage?.language.code == language.code { continue }

            alertController.addAction(UIAlertAction(title: "\(language.name) (\(language.nativeName ?? ""))", style: .default) { [weak self] _ in
                self?.showProficiencyPickerForNewLanguage(language)
            })
        }

        alertController.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true)
    }

    private func showProficiencyPickerForNewLanguage(_ language: Language) {
        let alertController = UIAlertController(
            title: "Select Proficiency Level",
            message: "How well do you speak \(language.name)?",
            preferredStyle: .actionSheet
        )

        for proficiency in LanguageProficiency.allCases {
            if proficiency == .native { continue }

            alertController.addAction(UIAlertAction(title: proficiency.displayName, style: .default) { [weak self] _ in
                self?.addLanguage(language, proficiency: proficiency)
            })
        }

        alertController.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true)
    }

    private func addLanguage(_ language: Language, proficiency: LanguageProficiency) {
        let userLanguage = UserLanguage(language: language, proficiency: proficiency, isNative: false)
        learningLanguages.append(userLanguage)

        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        saveLanguages()
    }

    private func removeLanguage(at index: Int) {
        let language = learningLanguages[index]

        let alert = UIAlertController(
            title: "Remove Language",
            message: "Remove \(language.language.name) from your learning languages?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "common_remove".localized, style: .destructive) { [weak self] _ in
            self?.learningLanguages.remove(at: index)
            self?.openToLanguages.removeAll { $0.code == language.language.code }
            self?.tableView.reloadData()
            self?.saveLanguages()
        })

        present(alert, animated: true)
    }

    // MARK: - Native Language

    private func showNativeLanguagePicker() {
        let alertController = UIAlertController(
            title: "Native Language",
            message: "Select your native language",
            preferredStyle: .actionSheet
        )

        let languages: [Language] = [.english, .spanish, .french, .german, .japanese, .korean, .chinese, .portuguese, .italian, .russian]

        for language in languages {
            let isSelected = nativeLanguage?.language.code == language.code
            let title = isSelected ? "✓ \(language.name)" : language.name

            alertController.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.nativeLanguage = UserLanguage(language: language, proficiency: .native, isNative: true)
                self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self?.saveLanguages()
            })
        }

        alertController.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alertController.popoverPresentationController {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }

        present(alertController, animated: true)
    }

    // MARK: - Save

    private func saveLanguages() {
        guard let native = nativeLanguage else { return }

        let languageData = UserLanguageData(
            nativeLanguage: native,
            learningLanguages: learningLanguages,
            openToLanguages: openToLanguages,
            practiceLanguages: nil
        )

        if let encoded = try? JSONEncoder().encode(languageData) {
            UserDefaults.standard.set(encoded, forKey: "userLanguages")
        }

        // Build proficiency levels dictionary for Supabase
        var proficiencyDict: [String: String] = [:]
        for lang in learningLanguages {
            proficiencyDict[lang.language.name] = lang.proficiency.rawValue
        }

        // Sync to Supabase
        let profileUpdate = ProfileUpdate(
            nativeLanguage: native.language.name,
            learningLanguages: learningLanguages.map { $0.language.name },
            proficiencyLevels: proficiencyDict,
            openToLanguages: openToLanguages.map { $0.name }
        )

        Task {
            do {
                try await SupabaseService.shared.updateProfile(profileUpdate)
                print("✅ Languages saved to Supabase")
            } catch {
                print("❌ Failed to save languages to Supabase: \(error)")
            }
        }

        // Notify observers
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
}

// MARK: - UITableViewDataSource
extension LanguagesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Native language
        case 1: return learningLanguages.count + 1 // +1 for "Add Language" row
        case 2: return openToLanguages.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Native Language"
        case 1: return "Languages I'm Learning"
        case 2: return "Open to Match In"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "Tap a language to change proficiency level. Swipe left to remove."
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)

        var config = cell.defaultContentConfiguration()

        switch indexPath.section {
        case 0:
            if let native = nativeLanguage {
                config.text = native.language.name
                config.secondaryText = native.language.nativeName
                config.image = UIImage(systemName: "star.fill")
                config.imageProperties.tintColor = .systemYellow
            }
            cell.accessoryType = .disclosureIndicator

        case 1:
            if indexPath.row < learningLanguages.count {
                let language = learningLanguages[indexPath.row]
                config.text = language.language.name
                config.secondaryText = "\(language.proficiency.displayName) • \(language.language.nativeName ?? "")"
                config.image = UIImage(systemName: "book.fill")
                config.imageProperties.tintColor = .systemBlue
                cell.accessoryType = .disclosureIndicator
            } else {
                // "Add Language" row
                config.text = "add_language".localized
                config.textProperties.color = .systemBlue
                config.image = UIImage(systemName: "plus.circle.fill")
                config.imageProperties.tintColor = .systemBlue
                config.secondaryText = nil
                cell.accessoryType = .none
            }

        case 2:
            let language = openToLanguages[indexPath.row]
            config.text = language.name
            config.secondaryText = language.nativeName
            config.image = UIImage(systemName: "message.fill")
            config.imageProperties.tintColor = .systemGreen
            cell.accessoryType = .disclosureIndicator

        default:
            break
        }

        cell.contentConfiguration = config

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only learning languages can be deleted (not the "Add" row)
        return indexPath.section == 1 && indexPath.row < learningLanguages.count
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 1 && indexPath.row < learningLanguages.count {
            let language = learningLanguages[indexPath.row]
            learningLanguages.remove(at: indexPath.row)
            openToLanguages.removeAll { $0.code == language.language.code }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveLanguages()
        }
    }
}

// MARK: - UITableViewDelegate
extension LanguagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            // Native language - show picker
            showNativeLanguagePicker()

        case 1:
            if indexPath.row < learningLanguages.count {
                // Existing language - show proficiency picker
                showProficiencyPicker(for: indexPath.row)
            } else {
                // "Add Language" row
                showAddLanguagePicker()
            }

        case 2:
            // Open to match languages - could add editing here if needed
            break

        default:
            break
        }
    }
}

// Helper struct for UserDefaults encoding
struct UserLanguageData: Codable {
    let nativeLanguage: UserLanguage
    let learningLanguages: [UserLanguage]
    let openToLanguages: [Language]
    let practiceLanguages: [UserLanguage]?
}