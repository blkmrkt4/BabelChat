import UIKit

class DataPrivacyViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case dataCollected
        case dataUsage
        case yourRights

        var title: String {
            switch self {
            case .dataCollected: return "privacy_data_collect_header".localized
            case .dataUsage: return "privacy_data_usage_header".localized
            case .yourRights: return "privacy_rights_header".localized
            }
        }

        var items: [String] {
            switch self {
            case .dataCollected:
                return [
                    "privacy_data_collect_profile".localized,
                    "privacy_data_collect_messages".localized,
                    "privacy_data_collect_learning".localized,
                    "privacy_data_collect_device".localized,
                    "privacy_data_collect_analytics".localized
                ]
            case .dataUsage:
                return [
                    "privacy_data_usage_matching".localized,
                    "privacy_data_usage_translation".localized,
                    "privacy_data_usage_personalize".localized,
                    "privacy_data_usage_notifications".localized,
                    "privacy_data_usage_fraud".localized
                ]
            case .yourRights:
                return [
                    "privacy_rights_delete".localized,
                    "privacy_rights_notifications".localized,
                    "privacy_rights_blocked".localized
                ]
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "privacy_data_title".localized
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DataPrivacyCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add footer with delete account button
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))

        let deleteButton = createButton(title: "privacy_delete_my_account".localized, action: #selector(deleteAccount))
        deleteButton.backgroundColor = .systemRed

        footerView.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20),
            deleteButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        tableView.tableFooterView = footerView
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func deleteAccount() {
        let alert = UIAlertController(
            title: "privacy_delete_account_title".localized,
            message: "privacy_delete_account_message".localized,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "common_delete".localized, style: .destructive) { _ in
            self.confirmDeleteAccount()
        })

        present(alert, animated: true)
    }

    private func confirmDeleteAccount() {
        let confirmAlert = UIAlertController(
            title: "privacy_delete_confirm_title".localized,
            message: "privacy_delete_confirm_message".localized,
            preferredStyle: .alert
        )

        confirmAlert.addTextField { textField in
            textField.placeholder = "delete_account_confirm_placeholder".localized
            textField.autocapitalizationType = .allCharacters
        }

        confirmAlert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "common_confirm".localized, style: .destructive) { [weak confirmAlert, weak self] _ in
            guard let self = self else { return }
            guard let text = confirmAlert?.textFields?.first?.text, text == "DELETE" else {
                let errorAlert = UIAlertController(
                    title: "privacy_delete_incorrect".localized,
                    message: "privacy_delete_incorrect_message".localized,
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                self.present(errorAlert, animated: true)
                return
            }

            self.performAccountDeletion()
        })

        present(confirmAlert, animated: true)
    }

    private func performAccountDeletion() {
        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: nil,
            message: "privacy_deleting_account".localized,
            preferredStyle: .alert
        )
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loadingAlert.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        // Add height constraint so spinner is visible
        loadingAlert.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        present(loadingAlert, animated: true)

        Task {
            do {
                // Delete account from server
                try await SupabaseService.shared.deleteAccount()

                await MainActor.run {
                    // Clear all local user data
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()

                    // Dismiss loading and navigate to landing screen
                    loadingAlert.dismiss(animated: false) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let landingVC = LandingViewController()
                            let navController = UINavigationController(rootViewController: landingVC)
                            navController.setNavigationBarHidden(true, animated: false)
                            window.rootViewController = navController

                            UIView.transition(with: window,
                                            duration: 0.5,
                                            options: .transitionCrossDissolve,
                                            animations: nil,
                                            completion: nil)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(
                            title: "privacy_delete_error_title".localized,
                            message: "privacy_delete_error_message".localized,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension DataPrivacyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let privacySection = Section(rawValue: section) else { return 0 }
        return privacySection.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let privacySection = Section(rawValue: section) else { return nil }
        return privacySection.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataPrivacyCell", for: indexPath)
        guard let privacySection = Section(rawValue: indexPath.section) else { return cell }

        var config = cell.defaultContentConfiguration()
        config.text = privacySection.items[indexPath.row]
        config.textProperties.numberOfLines = 0

        // Add checkmark for items in "Data We Collect"
        if privacySection == .dataCollected {
            config.image = UIImage(systemName: "circle.fill")
            config.imageProperties.tintColor = .systemBlue
        }

        cell.contentConfiguration = config
        cell.selectionStyle = .none

        return cell
    }
}

// MARK: - UITableViewDelegate
extension DataPrivacyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
