import UIKit

class DataPrivacyViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case dataCollected
        case dataUsage
        case yourRights

        var title: String {
            switch self {
            case .dataCollected: return "Data We Collect"
            case .dataUsage: return "How We Use Your Data"
            case .yourRights: return "Your Privacy Rights"
            }
        }

        var items: [String] {
            switch self {
            case .dataCollected:
                return [
                    "Profile information (name, photo, languages)",
                    "Messages and chat history",
                    "Learning preferences and progress",
                    "Device information",
                    "Usage analytics"
                ]
            case .dataUsage:
                return [
                    "Provide language matching services",
                    "Improve translation accuracy",
                    "Personalize your experience",
                    "Send notifications about matches",
                    "Prevent fraud and abuse"
                ]
            case .yourRights:
                return [
                    "Request a copy of your data",
                    "Delete your account and data",
                    "Opt out of analytics",
                    "Control notification preferences",
                    "Manage blocked users"
                ]
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "Data & Privacy"
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

        // Add footer with action buttons
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 160))

        let downloadButton = createButton(title: "Download My Data", action: #selector(downloadData))
        let deleteButton = createButton(title: "Delete My Account", action: #selector(deleteAccount))
        deleteButton.backgroundColor = .systemRed

        footerView.addSubview(downloadButton)
        footerView.addSubview(deleteButton)

        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20),
            downloadButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            downloadButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            downloadButton.heightAnchor.constraint(equalToConstant: 50),

            deleteButton.topAnchor.constraint(equalTo: downloadButton.bottomAnchor, constant: 12),
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

    @objc private func downloadData() {
        let alert = UIAlertController(
            title: "Download Your Data",
            message: "We'll prepare a copy of your data and send it to your email address within 48 hours.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Request Data", style: .default) { _ in
            let confirmAlert = UIAlertController(
                title: "Request Sent",
                message: "You'll receive an email with your data within 48 hours.",
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(confirmAlert, animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func deleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This will permanently delete your account and all associated data. This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.confirmDeleteAccount()
        })

        present(alert, animated: true)
    }

    private func confirmDeleteAccount() {
        let confirmAlert = UIAlertController(
            title: "Are You Sure?",
            message: "Type 'DELETE' to confirm",
            preferredStyle: .alert
        )

        confirmAlert.addTextField { textField in
            textField.placeholder = "Type DELETE"
            textField.autocapitalizationType = .allCharacters
        }

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak confirmAlert] _ in
            guard let text = confirmAlert?.textFields?.first?.text, text == "DELETE" else {
                let errorAlert = UIAlertController(
                    title: "Incorrect",
                    message: "Please type 'DELETE' to confirm account deletion.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errorAlert, animated: true)
                return
            }

            // Clear all user data
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()

            // Navigate back to landing screen
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
        })

        present(confirmAlert, animated: true)
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
