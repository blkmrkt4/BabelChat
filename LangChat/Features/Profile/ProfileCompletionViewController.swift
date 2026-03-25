import UIKit
import UserNotifications

class ProfileCompletionViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    enum ProfileItem: String, CaseIterable {
        case birthday
        case hometown
        case nativeLanguage
        case learningLanguages
        case matchingSettings
        case museLanguages
        case feedbackLevel
        case bio
        case photos
        case travelPlans
        case notifications

        var title: String {
            switch self {
            case .birthday: return "profile_completion_birth_date".localized
            case .hometown: return "profile_completion_location".localized
            case .nativeLanguage: return "profile_field_native_language".localized
            case .learningLanguages: return "profile_field_learning_languages".localized
            case .matchingSettings: return "settings_matching_settings".localized
            case .museLanguages: return "settings_muse_languages".localized
            case .feedbackLevel: return "settings_feedback_level".localized
            case .bio: return "profile_completion_bio".localized
            case .photos: return "profile_completion_photos".localized
            case .travelPlans: return "profile_completion_travel_plans".localized
            case .notifications: return "profile_completion_notifications".localized
            }
        }

        var icon: String {
            switch self {
            case .birthday: return "calendar"
            case .hometown: return "mappin.and.ellipse"
            case .nativeLanguage: return "flag"
            case .learningLanguages: return "globe"
            case .matchingSettings: return "slider.horizontal.3"
            case .museLanguages: return "sparkles"
            case .feedbackLevel: return "text.bubble"
            case .bio: return "text.quote"
            case .photos: return "photo.on.rectangle"
            case .travelPlans: return "airplane"
            case .notifications: return "bell"
            }
        }

        var isCompleted: Bool {
            let defaults = UserDefaults.standard
            switch self {
            case .birthday:
                return defaults.integer(forKey: "birthYear") > 0
            case .hometown:
                let location = defaults.string(forKey: "location") ?? ""
                return !location.isEmpty
            case .nativeLanguage:
                let lang = defaults.string(forKey: "nativeLanguage") ?? ""
                return !lang.isEmpty
            case .learningLanguages:
                let langs = defaults.stringArray(forKey: "learningLanguages") ?? []
                return !langs.isEmpty
            case .matchingSettings:
                // Complete when all key matching preferences are set
                let hasPlatonic = defaults.object(forKey: "strictlyPlatonic") != nil
                let hasGoals = !(defaults.stringArray(forKey: "learningContexts") ?? []).isEmpty
                let hasIntents = !(defaults.stringArray(forKey: "relationshipIntents") ?? []).isEmpty
                    || !(defaults.string(forKey: "relationshipIntent") ?? "").isEmpty
                return hasPlatonic && hasGoals && hasIntents
            case .museLanguages:
                let langs = defaults.stringArray(forKey: "museLanguages") ?? []
                return !langs.isEmpty
            case .feedbackLevel:
                return defaults.object(forKey: "granularityLevel") != nil
            case .bio:
                let bio = defaults.string(forKey: "bio") ?? ""
                return !bio.isEmpty
            case .photos:
                let photoURLs = defaults.stringArray(forKey: "photoURLs") ?? []
                let nonEmptyPhotos = photoURLs.filter { !$0.isEmpty }
                let profilePhoto = defaults.string(forKey: "profilePhotoURL") ?? ""
                let totalPhotos = nonEmptyPhotos.count + (profilePhoto.isEmpty ? 0 : 1)
                return totalPhotos >= 2
            case .travelPlans:
                return defaults.data(forKey: "travelDestination") != nil
            case .notifications:
                return defaults.object(forKey: "notificationsEnabled") != nil
            }
        }

        /// For items like Matching Settings that have multiple sub-requirements
        var isPartiallyCompleted: Bool {
            guard self == .matchingSettings else { return false }
            guard !isCompleted else { return false }
            let defaults = UserDefaults.standard
            let hasPlatonic = defaults.object(forKey: "strictlyPlatonic") != nil
            let hasGoals = !(defaults.stringArray(forKey: "learningContexts") ?? []).isEmpty
            let hasIntents = !(defaults.stringArray(forKey: "relationshipIntents") ?? []).isEmpty
                || !(defaults.string(forKey: "relationshipIntent") ?? "").isEmpty
            // Partial = at least one is set but not all
            return hasPlatonic || hasGoals || hasIntents
        }
    }

    private var items: [ProfileItem] {
        ProfileItem.allCases
    }

    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshCompletion),
                                               name: .userProfileUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateHeader()
    }

    private func setupViews() {
        title = "settings_complete_profile".localized
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        if presentingViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "common_done".localized,
                style: .done,
                target: self,
                action: #selector(dismissTapped)
            )
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CompletionCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupHeader()
    }

    private let progressLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)

    private func setupHeader() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))

        let subtitleLabel = UILabel()
        subtitleLabel.text = "profile_completion_subtitle".localized
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        progressLabel.font = .systemFont(ofSize: 14, weight: .medium)
        progressLabel.textColor = .label

        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [subtitleLabel, progressBar, progressLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor, constant: -8),
            progressBar.heightAnchor.constraint(equalToConstant: 8)
        ])

        tableView.tableHeaderView = headerView
        updateHeader()
    }

    private func updateHeader() {
        let total = items.count
        let completed = completedCount
        let progress = Float(completed) / Float(total)
        progressBar.setProgress(progress, animated: true)
        progressLabel.text = String(format: "profile_completion_progress".localized, completed, total)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    @objc private func refreshCompletion() {
        tableView.reloadData()
        updateHeader()
    }

    // MARK: - Navigation (direct to specific editors)

    private func handleItemTap(_ item: ProfileItem) {
        switch item {
        case .birthday:
            let currentBirthYear = UserDefaults.standard.integer(forKey: "birthYear")
            let currentBirthMonth = UserDefaults.standard.integer(forKey: "birthMonth")
            let vc = BirthDatePickerViewController()
            vc.currentYear = currentBirthYear > 0 ? currentBirthYear : nil
            vc.currentMonth = currentBirthMonth > 0 ? currentBirthMonth : nil
            vc.onSave = { [weak self] month, year in
                UserDefaults.standard.set(year, forKey: "birthYear")
                UserDefaults.standard.set(month, forKey: "birthMonth")
                self?.saveToSupabase()
                self?.tableView.reloadData()
                self?.updateHeader()
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            present(nav, animated: true)

        case .hometown:
            let vc = LocationPickerViewController()
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)

        case .nativeLanguage:
            let storedLanguage = UserDefaults.standard.string(forKey: "nativeLanguage") ?? ""
            let displayLanguage = convertToLanguageDisplayName(storedLanguage)
            let vc = LanguagePickerViewController(
                title: "profile_field_native_language".localized,
                selectedLanguages: [displayLanguage],
                allowsMultipleSelection: false
            )
            vc.onSave = { [weak self] languages in
                if let language = languages.first {
                    UserDefaults.standard.set(language, forKey: "nativeLanguage")
                    self?.saveToSupabase()
                    self?.tableView.reloadData()
                    self?.updateHeader()
                }
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)

        case .learningLanguages:
            let currentLanguages = UserDefaults.standard.stringArray(forKey: "learningLanguages") ?? []
            let displayLanguages = currentLanguages.map { convertToLanguageDisplayName($0) }
            let vc = LanguagePickerViewController(
                title: "profile_field_learning_languages".localized,
                selectedLanguages: displayLanguages,
                allowsMultipleSelection: true
            )
            vc.onSave = { [weak self] languages in
                UserDefaults.standard.set(languages, forKey: "learningLanguages")
                self?.saveToSupabase()
                self?.tableView.reloadData()
                self?.updateHeader()
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)

        case .matchingSettings:
            let vc = MatchingPreferencesViewController()
            navigationController?.pushViewController(vc, animated: true)

        case .museLanguages:
            let vc = MuseLanguagesSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)

        case .feedbackLevel:
            showGrammarFeedbackLevel()

        case .bio:
            let vc = BioEditorViewController()
            vc.currentBio = UserDefaults.standard.string(forKey: "bio") ?? ""
            vc.onSave = { [weak self] newBio in
                UserDefaults.standard.set(newBio, forKey: "bio")
                self?.saveToSupabase()
                self?.tableView.reloadData()
                self?.updateHeader()
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)

        case .photos:
            if let tabBar = findTabBarController() {
                dismiss(animated: true) {
                    if let nav = tabBar.selectedViewController as? UINavigationController {
                        let profileVC = ProfileViewController()
                        nav.pushViewController(profileVC, animated: true)
                    }
                }
            } else {
                let profileVC = ProfileViewController()
                navigationController?.pushViewController(profileVC, animated: true)
            }

        case .travelPlans:
            let vc = TravelPlansViewController()
            vc.isEditMode = true
            vc.onSave = { [weak self] in
                self?.tableView.reloadData()
                self?.updateHeader()
            }
            navigationController?.pushViewController(vc, animated: true)

        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    self.tableView.reloadData()
                    self.updateHeader()
                }
            }
        }
    }

    // MARK: - Grammar Feedback Level

    private func showGrammarFeedbackLevel() {
        let savedGranularity = UserDefaults.standard.integer(forKey: "granularityLevel")
        let currentLevel = savedGranularity == 0 ? 2 : savedGranularity

        let alert = UIAlertController(
            title: "settings_grammar_feedback_title".localized,
            message: "settings_grammar_feedback_message".localized,
            preferredStyle: .actionSheet
        )

        let levels: [(String, String, Int)] = [
            ("settings_grammar_minimal".localized, "settings_grammar_minimal_desc".localized, 1),
            ("settings_grammar_moderate".localized, "settings_grammar_moderate_desc".localized, 2),
            ("settings_grammar_verbose".localized, "settings_grammar_verbose_desc".localized, 3)
        ]

        for (title, _, value) in levels {
            let isSelected = value == currentLevel
            let actionTitle = isSelected ? "\u{2713} \(title)" : title
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
                UserDefaults.standard.set(value, forKey: "granularityLevel")
                self?.tableView.reloadData()
                self?.updateHeader()
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    // MARK: - Helpers

    /// Convert stored language value (code or name) to picker display name
    private func convertToLanguageDisplayName(_ stored: String) -> String {
        if let language = Language(rawValue: stored) {
            return language.name
        }
        if let language = Language.from(languageCode: stored) {
            return language.name
        }
        if let language = Language.from(name: stored) {
            return language.name
        }
        return stored
    }

    private func saveToSupabase() {
        Task {
            do {
                try await SupabaseService.shared.syncAllOnboardingDataToSupabase()
            } catch {
                print("❌ Failed to sync profile: \(error)")
            }
        }
    }

    private func findTabBarController() -> UITabBarController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let tabBar = next as? UITabBarController {
                return tabBar
            }
            responder = next
        }
        return nil
    }

    // MARK: - Completion Check

    static var isProfileIncomplete: Bool {
        let incompleteCount = ProfileItem.allCases.filter { !$0.isCompleted }.count
        return incompleteCount > 0
    }

    static var completionPercentage: Int {
        let total = ProfileItem.allCases.count
        let completed = ProfileItem.allCases.filter { $0.isCompleted }.count
        return Int((Float(completed) / Float(total)) * 100)
    }
}

// MARK: - UITableViewDataSource
extension ProfileCompletionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletionCell", for: indexPath)
        let item = items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = UIImage(systemName: item.icon)

        if item.isCompleted {
            config.imageProperties.tintColor = .systemGreen
            cell.accessoryView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal))
        } else if item.isPartiallyCompleted {
            config.imageProperties.tintColor = .systemOrange
            cell.accessoryView = UIImageView(image: UIImage(systemName: "circle.lefthalf.filled")?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal))
        } else {
            config.imageProperties.tintColor = .systemBlue
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        }

        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProfileCompletionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleItemTap(items[indexPath.row])
    }
}

// MARK: - LocationPickerDelegate
extension ProfileCompletionViewController: LocationPickerDelegate {
    func locationPicker(_ picker: LocationPickerViewController, didSelect location: LocationPickerViewController.LocationData) {
        UserDefaults.standard.set(location.displayName, forKey: "location")
        UserDefaults.standard.set(location.city, forKey: "city")
        UserDefaults.standard.set(location.country, forKey: "country")
        UserDefaults.standard.set(location.latitude, forKey: "latitude")
        UserDefaults.standard.set(location.longitude, forKey: "longitude")
        saveToSupabase()
        tableView.reloadData()
        updateHeader()
    }

    func locationPickerDidCancel(_ picker: LocationPickerViewController) {
        // Nothing to do
    }
}
