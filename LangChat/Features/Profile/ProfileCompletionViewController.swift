import UIKit
import UserNotifications

class ProfileCompletionViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    enum ProfileItem: String, CaseIterable {
        case birthDate
        case location
        case learningGoals
        case bio
        case photos
        case travelPlans
        case relationshipIntent
        case privacySettings
        case notifications

        var title: String {
            switch self {
            case .birthDate: return "profile_completion_birth_date".localized
            case .location: return "profile_completion_location".localized
            case .learningGoals: return "profile_completion_learning_goals".localized
            case .bio: return "profile_completion_bio".localized
            case .photos: return "profile_completion_photos".localized
            case .travelPlans: return "profile_completion_travel_plans".localized
            case .relationshipIntent: return "profile_completion_relationship".localized
            case .privacySettings: return "profile_completion_privacy".localized
            case .notifications: return "profile_completion_notifications".localized
            }
        }

        var icon: String {
            switch self {
            case .birthDate: return "calendar"
            case .location: return "mappin.and.ellipse"
            case .learningGoals: return "target"
            case .bio: return "text.quote"
            case .photos: return "photo.on.rectangle"
            case .travelPlans: return "airplane"
            case .relationshipIntent: return "heart"
            case .privacySettings: return "lock.shield"
            case .notifications: return "bell"
            }
        }

        var isCompleted: Bool {
            let defaults = UserDefaults.standard
            switch self {
            case .birthDate:
                return defaults.integer(forKey: "birthYear") > 0
            case .location:
                let location = defaults.string(forKey: "location") ?? ""
                return !location.isEmpty
            case .learningGoals:
                let contexts = defaults.stringArray(forKey: "learningContexts") ?? []
                return !contexts.isEmpty
            case .bio:
                let bio = defaults.string(forKey: "bio") ?? ""
                return !bio.isEmpty
            case .photos:
                // Require at least 2 photos total (profile + grid)
                let photoURLs = defaults.stringArray(forKey: "photoURLs") ?? []
                let nonEmptyPhotos = photoURLs.filter { !$0.isEmpty }
                let profilePhoto = defaults.string(forKey: "profilePhotoURL") ?? ""
                let totalPhotos = nonEmptyPhotos.count + (profilePhoto.isEmpty ? 0 : 1)
                return totalPhotos >= 2
            case .travelPlans:
                return defaults.data(forKey: "travelDestination") != nil
            case .relationshipIntent:
                let intent = defaults.string(forKey: "relationshipIntent") ?? ""
                // Default is "languageExchange", so any value means it's been set
                return !intent.isEmpty
            case .privacySettings:
                // Consider complete if the user has explicitly set either privacy toggle
                return defaults.object(forKey: "strictlyPlatonic") != nil
            case .notifications:
                return defaults.object(forKey: "notificationsEnabled") != nil
            }
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
        title = "profile_completion_title".localized
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

    // MARK: - Navigation

    private func handleItemTap(_ item: ProfileItem) {
        switch item {
        case .birthDate, .bio, .location, .travelPlans, .learningGoals, .relationshipIntent:
            let profileSettingsVC = ProfileSettingsViewController()
            navigationController?.pushViewController(profileSettingsVC, animated: true)

        case .photos:
            // Navigate to profile (photos are managed there)
            if let tabBar = findTabBarController() {
                dismiss(animated: true) {
                    // Switch to the tab that shows profile, or push profile VC
                    if let nav = tabBar.selectedViewController as? UINavigationController {
                        let profileVC = ProfileViewController()
                        nav.pushViewController(profileVC, animated: true)
                    }
                }
            } else {
                let profileVC = ProfileViewController()
                navigationController?.pushViewController(profileVC, animated: true)
            }

        case .privacySettings:
            let matchingPrefsVC = MatchingPreferencesViewController()
            navigationController?.pushViewController(matchingPrefsVC, animated: true)

        case .notifications:
            // Request notification permission directly
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
