import UIKit

class BlockedUsersViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var blockedUsers: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadBlockedUsers()
    }

    private func setupViews() {
        title = "Blocked Users"
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BlockedUserCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadBlockedUsers() {
        if let data = UserDefaults.standard.data(forKey: "blockedUsers"),
           let users = try? JSONDecoder().decode([String].self, from: data) {
            blockedUsers = users
        }
        tableView.reloadData()
    }

    private func saveBlockedUsers() {
        if let data = try? JSONEncoder().encode(blockedUsers) {
            UserDefaults.standard.set(data, forKey: "blockedUsers")
        }
    }

    private func unblockUser(at indexPath: IndexPath) {
        let userName = blockedUsers[indexPath.row]

        let alert = UIAlertController(
            title: "Unblock User",
            message: "Are you sure you want to unblock \(userName)?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "common_unblock".localized, style: .destructive) { [weak self] _ in
            self?.blockedUsers.remove(at: indexPath.row)
            self?.saveBlockedUsers()
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
        })

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension BlockedUsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.isEmpty ? 1 : blockedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedUserCell", for: indexPath)

        if blockedUsers.isEmpty {
            var config = cell.defaultContentConfiguration()
            config.text = "blocked_users_empty".localized
            config.textProperties.color = .secondaryLabel
            config.textProperties.alignment = .center
            cell.contentConfiguration = config
            cell.selectionStyle = .none
        } else {
            var config = cell.defaultContentConfiguration()
            config.text = blockedUsers[indexPath.row]
            config.image = UIImage(systemName: "person.crop.circle.badge.xmark")
            cell.contentConfiguration = config
            cell.accessoryType = .none
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension BlockedUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if !blockedUsers.isEmpty {
            unblockUser(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !blockedUsers.isEmpty else { return nil }

        let unblockAction = UIContextualAction(style: .destructive, title: "Unblock") { [weak self] (_, _, completion) in
            self?.unblockUser(at: indexPath)
            completion(true)
        }

        unblockAction.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [unblockAction])
    }
}
