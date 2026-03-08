import UIKit

class SelectMatchViewController: UIViewController {

    var onSelectUser: ((User) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var matches: [User] = []
    private var filteredMatches: [User] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let excludedUserIds: Set<String>

    init(excludedUserIds: [String] = []) {
        self.excludedUserIds = Set(excludedUserIds)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "session_select_participant".localized
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "session_search_matches".localized
        navigationItem.searchController = searchController
        definesPresentationContext = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        loadMatches()
    }

    private func loadMatches() {
        Task {
            do {
                guard let userId = SupabaseService.shared.currentUserId else { return }
                let matchResponses = try await SupabaseService.shared.getMatches()
                let users: [User] = matchResponses.compactMap { match in
                    let otherProfile = match.user1Id == userId.uuidString ? match.user2 : match.user1
                    guard let user = otherProfile?.toUser(), !excludedUserIds.contains(user.id) else { return nil }
                    return user
                }

                await MainActor.run {
                    self.matches = users
                    self.filteredMatches = users
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to load matches: \(error)")
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SelectMatchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMatches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        let user = filteredMatches[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = user.firstName
        config.secondaryText = "\("profile_native_language".localized): \(user.nativeLanguage.language.name)"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = filteredMatches[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onSelectUser?(user)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension SelectMatchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            filteredMatches = matches
        } else {
            filteredMatches = matches.filter { user in
                user.firstName.lowercased().contains(query)
            }
        }
        tableView.reloadData()
    }
}
