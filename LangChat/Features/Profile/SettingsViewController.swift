import UIKit
import CoreLocation
import Photos

class SettingsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum SettingSection: Int, CaseIterable {
        case profileSettings
        case matchingSettings
        case museSettings
        case social
        #if DEBUG
        case aiSettings
        #endif
        case grammarFeedback
        case privacy
        case support
        case about

        var title: String? {
            switch self {
            case .profileSettings: return nil  // No header for single profile item
            case .matchingSettings: return nil  // No header for single matching item
            case .museSettings: return "AI Muse"
            case .social: return "Share"
            #if DEBUG
            case .aiSettings: return "AI Settings"
            #endif
            case .grammarFeedback: return "Grammar Feedback"
            case .privacy: return "Privacy & Safety"
            case .support: return "Support"
            case .about: return "About"
            }
        }

        var items: [(title: String, icon: String)] {
            switch self {
            case .profileSettings:
                return [
                    ("Profile Settings", "person.circle")
                ]
            case .matchingSettings:
                return [
                    ("Matching Settings", "slider.horizontal.3")
                ]
            case .museSettings:
                return [
                    ("Muse Languages", "globe")
                ]
            case .social:
                return [
                    ("Invite Friends", "person.badge.plus")
                ]
            #if DEBUG
            case .aiSettings:
                return [
                    ("Model Bindings", "link.circle")
                ]
            #endif
            case .grammarFeedback:
                return [
                    ("Feedback Level", "slider.horizontal.3")
                ]
            case .privacy:
                return [
                    ("Data & Privacy", "lock.shield"),
                    ("Notifications", "bell"),
                    ("Appearance", "moon")
                ]
            case .support:
                return [
                    ("Subscription", "crown"),
                    ("Help Center", "questionmark.circle"),
                    ("Request a Feature", "lightbulb"),
                    ("Contact Us", "envelope"),
                    ("Report a Problem", "exclamationmark.bubble")
                ]
            case .about:
                return [
                    ("Terms of Service", "doc.text"),
                    ("Privacy Policy", "hand.raised"),
                    ("Open Source Libraries", "chevron.left.forwardslash.chevron.right"),
                    ("Version", "info.circle")
                ]
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add sign out button in footer
        #if DEBUG
        let footerHeight: CGFloat = 150  // Extra space for debug button
        #else
        let footerHeight: CGFloat = 100
        #endif

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: footerHeight))

        let signOutButton = UIButton(type: .system)
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.systemRed, for: .normal)
        signOutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        footerView.addSubview(signOutButton)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            signOutButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            signOutButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20)
        ])

        #if DEBUG
        // Add debug reset button to return to landing page
        let resetToLandingButton = UIButton(type: .system)
        resetToLandingButton.setTitle("Reset to Landing Page", for: .normal)
        resetToLandingButton.setTitleColor(.systemOrange, for: .normal)
        resetToLandingButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        resetToLandingButton.addTarget(self, action: #selector(resetToLandingPageTapped), for: .touchUpInside)

        footerView.addSubview(resetToLandingButton)
        resetToLandingButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            resetToLandingButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            resetToLandingButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 16)
        ])
        #endif

        tableView.tableFooterView = footerView
    }

    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            Task {
                do {
                    // Sign out from Supabase
                    try await SupabaseService.shared.signOut()
                    print("✅ Signed out from Supabase")
                } catch {
                    print("⚠️ Sign out error: \(error)")
                }

                await MainActor.run {
                    // Navigate to authentication screen
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let authVC = AuthenticationViewController()
                        let navController = UINavigationController(rootViewController: authVC)
                        navController.setNavigationBarHidden(true, animated: false)
                        window.rootViewController = navController

                        UIView.transition(with: window,
                                        duration: 0.5,
                                        options: .transitionCrossDissolve,
                                        animations: nil,
                                        completion: nil)

                        print("✅ Navigated to authentication screen")
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    #if DEBUG
    @objc private func resetToLandingPageTapped() {
        let alert = UIAlertController(
            title: "Reset to Landing Page",
            message: "This will sign you out and reset all engagement tracking, showing the welcome screen as if it's your first time using the app.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            Task {
                do {
                    // Sign out from Supabase
                    try await SupabaseService.shared.signOut()
                    print("✅ Signed out from Supabase")
                } catch {
                    print("⚠️ Sign out error: \(error)")
                }

                await MainActor.run {
                    // Clear all user data and reset engagement tracking
                    DebugConfig.resetAllUserData()

                    // Navigate to welcome screen
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let welcomeVC = WelcomeViewController()
                        let navController = UINavigationController(rootViewController: welcomeVC)
                        navController.setNavigationBarHidden(true, animated: false)
                        window.rootViewController = navController

                        UIView.transition(with: window,
                                        duration: 0.5,
                                        options: .transitionCrossDissolve,
                                        animations: nil,
                                        completion: nil)

                        print("✅ Reset complete - showing welcome screen")
                    }
                }
            }
        })

        present(alert, animated: true)
    }
    #endif

    private func handleSettingSelection(section: Int, row: Int) {
        guard let settingSection = SettingSection(rawValue: section) else { return }

        switch settingSection {
        case .profileSettings:
            showProfileSettings()

        case .matchingSettings:
            showMatchingSettings()

        case .museSettings:
            showMuseLanguages()

        case .social:
            showInviteFriends()

        #if DEBUG
        case .aiSettings:
            // Only one item now - Model Bindings (view-only)
            showModelBindings()
        #endif

        case .grammarFeedback:
            switch row {
            case 0: showGrammarFeedbackLevel()
            default: break
            }

        case .privacy:
            switch row {
            case 0: showDataPrivacy()
            case 1: break // Notifications switch cell handled by switch control
            case 2: showAppearanceSettings()
            default: break
            }

        case .support:
            switch row {
            case 0: showSubscription()
            case 1: showHelpCenter()
            case 2: requestFeature()
            case 3: contactSupport()
            case 4: reportProblem()
            default: break
            }

        case .about:
            switch row {
            case 0: showTermsOfService()
            case 1: showPrivacyPolicy()
            case 2: showOpenSourceLibraries()
            case 3: showVersion()
            default: break
            }
        }
    }

    // MARK: - Privacy Setting Updates
    private func updateStrictlyPlatonic(_ isOn: Bool) {
        // Update UserDefaults immediately for local state
        UserDefaults.standard.set(isOn, forKey: "strictlyPlatonic")

        Task {
            do {
                try await SupabaseService.shared.updateProfile(ProfileUpdate(strictlyPlatonic: isOn))
                print("✅ Strictly platonic preference updated to: \(isOn)")

                // Post notification for UI updates
                await MainActor.run {
                    NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                }
            } catch {
                print("❌ Error updating strictly platonic preference: \(error)")
                await MainActor.run {
                    // Revert UserDefaults and switch
                    UserDefaults.standard.set(!isOn, forKey: "strictlyPlatonic")
                    self.tableView.reloadData()

                    let alert = UIAlertController(
                        title: "Update Failed",
                        message: "Could not update your preference. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func updateBlurPhotosUntilMatch(_ isOn: Bool) {
        // Update UserDefaults immediately for local state
        UserDefaults.standard.set(isOn, forKey: "blurPhotosUntilMatch")

        Task {
            do {
                try await SupabaseService.shared.updateProfile(ProfileUpdate(blurPhotosUntilMatch: isOn))
                print("✅ Blur photos until match preference updated to: \(isOn)")

                // Post notification for UI updates
                await MainActor.run {
                    NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                }
            } catch {
                print("❌ Error updating blur photos preference: \(error)")
                await MainActor.run {
                    // Revert UserDefaults and switch
                    UserDefaults.standard.set(!isOn, forKey: "blurPhotosUntilMatch")
                    self.tableView.reloadData()

                    let alert = UIAlertController(
                        title: "Update Failed",
                        message: "Could not update your preference. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Setting Actions
    private func showProfileSettings() {
        let profileSettingsVC = ProfileSettingsViewController()
        navigationController?.pushViewController(profileSettingsVC, animated: true)
    }

    private func showMatchingSettings() {
        // Navigate to comprehensive matching settings screen
        // This will include: Photos, Bio, Languages, and Matching Preferences
        let matchingPrefsVC = MatchingPreferencesViewController()
        navigationController?.pushViewController(matchingPrefsVC, animated: true)
    }

    private func showMuseLanguages() {
        let museLanguagesVC = MuseLanguagesSettingsViewController()
        navigationController?.pushViewController(museLanguagesVC, animated: true)
    }

    private func showInviteFriends() {
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Generating invite link...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)

        Task {
            do {
                // Generate invite code
                let code = try await SupabaseService.shared.generateInviteCode()

                // Get user's name for the share text
                let firstName = UserDefaults.standard.string(forKey: "firstName") ?? "A friend"

                // Build shareable text
                let shareText = SupabaseService.shared.buildShareableInviteText(code: code, inviterName: firstName)

                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        // Show share sheet
                        let activityVC = UIActivityViewController(
                            activityItems: [shareText],
                            applicationActivities: nil
                        )

                        // Configure for iPad
                        if let popover = activityVC.popoverPresentationController {
                            popover.sourceView = self.tableView
                            if let socialSection = SettingSection.allCases.firstIndex(of: .social) {
                                popover.sourceRect = self.tableView.rectForRow(at: IndexPath(row: 0, section: socialSection))
                            }
                        }

                        self.present(activityVC, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Could not generate invite link. Please try again.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
                print("❌ Error generating invite: \(error)")
            }
        }
    }

    private func showSubscription() {
        let subscriptionVC = SubscriptionViewController()
        let navController = UINavigationController(rootViewController: subscriptionVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    private func showGrammarFeedbackLevel() {
        let savedGranularity = UserDefaults.standard.integer(forKey: "granularityLevel")
        let currentLevel = savedGranularity == 0 ? 2 : savedGranularity // Default to Moderate

        let alert = UIAlertController(
            title: "Grammar Feedback Level",
            message: "Choose how much grammar feedback you want when chatting",
            preferredStyle: .actionSheet
        )

        let levels: [(String, String, Int)] = [
            ("Minimal", "Only critical errors", 1),
            ("Moderate", "Important corrections and alternatives", 2),
            ("Verbose", "Detailed feedback with cultural notes", 3)
        ]

        for (title, description, value) in levels {
            let isSelected = value == currentLevel
            let actionTitle = isSelected ? "✓ \(title)" : title
            let action = UIAlertAction(title: actionTitle, style: .default) { _ in
                UserDefaults.standard.set(value, forKey: "granularityLevel")
                print("Grammar feedback level set to: \(title)")
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 0, section: SettingSection.grammarFeedback.rawValue))
        }

        present(alert, animated: true)
    }

    #if DEBUG
    private func showModelBindings() {
        let bindingsVC = AIModelBindingsViewController()
        bindingsVC.title = "Model Bindings"
        navigationController?.pushViewController(bindingsVC, animated: true)
    }
    #endif

    private func showNotificationSettings() {
        print("Show notification settings")
    }

    private func showAppearanceSettings() {
        let currentMode = UserDefaults.standard.integer(forKey: "appearanceMode")

        let alert = UIAlertController(
            title: "Appearance",
            message: "Choose your preferred appearance mode",
            preferredStyle: .actionSheet
        )

        let modes: [(String, Int, UIUserInterfaceStyle)] = [
            ("Light", 0, .light),
            ("Dark", 1, .dark),
            ("System Default", 2, .unspecified)
        ]

        for (title, value, style) in modes {
            let isSelected = value == currentMode
            let actionTitle = isSelected ? "✓ \(title)" : title
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
                UserDefaults.standard.set(value, forKey: "appearanceMode")

                // Apply the appearance change immediately
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.overrideUserInterfaceStyle = style
                    }
                }
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 2, section: SettingSection.privacy.rawValue))
        }

        present(alert, animated: true)
    }

    private func showDataPrivacy() {
        let dataPrivacyVC = DataPrivacyViewController()
        navigationController?.pushViewController(dataPrivacyVC, animated: true)
    }

    private func showHelpCenter() {
        // Show the tutorial/help screen (same as ? icon on Profile)
        let tutorialVC = TutorialViewController()
        let navController = UINavigationController(rootViewController: tutorialVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func requestFeature() {
        let featureVC = FeatureRequestViewController()
        let navController = UINavigationController(rootViewController: featureVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    private func contactSupport() {
        // Show contact support with email option
        let alert = UIAlertController(
            title: "Contact Support",
            message: "How would you like to contact us?",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Send Email", style: .default) { [weak self] _ in
            self?.sendSupportEmail(type: "general")
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 3, section: SettingSection.support.rawValue))
        }

        present(alert, animated: true)
    }

    private func reportProblem() {
        // Show report problem with text input
        let alert = UIAlertController(
            title: "Report a Problem",
            message: "Please describe the issue you're experiencing",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Describe the problem..."
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let message = alert.textFields?.first?.text, !message.isEmpty else {
                self?.showAlert(title: "Error", message: "Please describe the problem")
                return
            }
            self?.submitFeedback(type: "bug_report", message: message)
        })

        present(alert, animated: true)
    }

    private func sendSupportEmail(type: String) {
        // Submit as contact support feedback
        let alert = UIAlertController(
            title: "Contact Support",
            message: "Please describe how we can help you",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "How can we help?"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let message = alert.textFields?.first?.text, !message.isEmpty else {
                self?.showAlert(title: "Error", message: "Please describe your question")
                return
            }
            self?.submitFeedback(type: "contact_support", message: message)
        })

        present(alert, animated: true)
    }

    private func submitFeedback(type: String, message: String) {
        Task {
            do {
                try await SupabaseService.shared.submitFeedback(
                    type: type,
                    message: message
                )
                await MainActor.run {
                    self.showAlert(title: "Thank You!", message: "Your feedback has been submitted.")
                }
            } catch {
                print("❌ Error submitting feedback: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to submit feedback. Please try again.")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showTermsOfService() {
        print("Show terms of service")
    }

    private func showPrivacyPolicy() {
        print("Show privacy policy")
    }

    private func showOpenSourceLibraries() {
        print("Show open source libraries")
    }

    private func showVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let alert = UIAlertController(
            title: "Fluenca",
            message: "Version \(version) (\(build))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingSection = SettingSection(rawValue: section) else { return 0 }
        return settingSection.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingSection = SettingSection(rawValue: section) else { return nil }
        return settingSection.title  // Returns nil for profile and matchingSettings sections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let settingSection = SettingSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        let item = settingSection.items[indexPath.row]

        // Use switch cell for specific settings
        if settingSection == .privacy {
            switch indexPath.row {
            case 1: // Notifications
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                let isEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
                cell.configure(title: item.title, icon: item.icon, isOn: isEnabled)
                cell.switchValueChanged = { isOn in
                    UserDefaults.standard.set(isOn, forKey: "notificationsEnabled")
                }
                return cell

            default:
                break
            }
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = UIImage(systemName: item.icon)

        // Add detail text for specific items
        if settingSection == .about && indexPath.row == 3 { // Version
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            config.secondaryText = version
        }

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleSettingSelection(section: indexPath.section, row: indexPath.row)
    }
}

// MARK: - Custom Cell for Switch Settings
class SwitchTableViewCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()

    var switchValueChanged: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none

        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)

        titleLabel.font = .systemFont(ofSize: 17)
        contentView.addSubview(titleLabel)

        switchControl.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        contentView.addSubview(switchControl)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        switchControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, icon: String, isOn: Bool) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
        switchControl.isOn = isOn
    }

    @objc private func switchToggled() {
        switchValueChanged?(switchControl.isOn)
    }
}