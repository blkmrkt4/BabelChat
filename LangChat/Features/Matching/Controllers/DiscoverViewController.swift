import UIKit

class DiscoverViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var categories: [DiscoverCategory] = []
    private var dataSource: UICollectionViewDiffableDataSource<String, String>!

    private let emptyStateLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // Store all scored profiles for lookup
    private var allScoredProfiles: [(user: User, score: Int, reasons: [String])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        configureDataSource()
        loadProfiles()

        AnalyticsService.shared.track(.discoverViewed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload to remove profiles the user already swiped on
        if !loadingIndicator.isAnimating && !allScoredProfiles.isEmpty {
            loadProfiles()
        }
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = "tab_discover".localized
        navigationController?.navigationBar.prefersLargeTitles = false

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        navigationItem.leftBarButtonItems = [profileButton]

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(filterTapped)
        )
        navigationItem.rightBarButtonItems = [settingsButton, filterButton]
    }

    @objc private func profileTapped() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    @objc private func filterTapped() {
        let preferencesVC = PreferencesViewController()
        let navController = UINavigationController(rootViewController: preferencesVC)
        present(navController, animated: true)
    }

    // MARK: - Views

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Collection view with compositional layout
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.register(DiscoverProfileCell.self, forCellWithReuseIdentifier: DiscoverProfileCell.reuseIdentifier)
        collectionView.register(
            DiscoverSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DiscoverSectionHeaderView.reuseIdentifier
        )
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        // Empty state
        emptyStateLabel.text = "discover_no_profiles".localized + "\n" + "discover_users_joining".localized
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        reloadButton.setTitle("discover_reload".localized, for: .normal)
        reloadButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
        reloadButton.isHidden = true
        view.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            reloadButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 20),
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self, sectionIndex < self.categories.count else {
                return self?.createDefaultSection()
            }
            return self.createHorizontalSection()
        }
    }

    private func createHorizontalSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(140),
            heightDimension: .absolute(210)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(140),
            heightDimension: .absolute(210)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16)

        // Header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func createDefaultSection() -> NSCollectionLayoutSection {
        return createHorizontalSection()
    }

    // MARK: - Data Source

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<String, String>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(
                      withReuseIdentifier: DiscoverProfileCell.reuseIdentifier,
                      for: indexPath
                  ) as? DiscoverProfileCell else {
                return UICollectionViewCell()
            }

            let category = self.categories[indexPath.section]
            let profileData = category.users[indexPath.item]
            cell.configure(with: profileData.user, score: profileData.score)
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self,
                  kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: DiscoverSectionHeaderView.reuseIdentifier,
                      for: indexPath
                  ) as? DiscoverSectionHeaderView else {
                return UICollectionReusableView()
            }

            let category = self.categories[indexPath.section]
            // titleKey is either a localization key or an already-localized string (for dynamic titles)
            let localized = category.titleKey.localized
            header.configure(title: localized)
            return header
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()

        for category in categories {
            snapshot.appendSections([category.id])
            // Create unique item identifiers: categoryId_userId
            let itemIds = category.users.enumerated().map { index, profile in
                "\(category.id)_\(profile.user.id)_\(index)"
            }
            snapshot.appendItems(itemIds, toSection: category.id)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Loading

    private func loadProfiles() {
        loadingIndicator.startAnimating()
        collectionView.isHidden = true
        emptyStateLabel.isHidden = true
        reloadButton.isHidden = true

        Task {
            do {
                let profiles = try await SupabaseService.shared.getMatchedDiscoveryProfiles(limit: 100)
                let currentProfile = try await SupabaseService.shared.getCurrentProfile()

                guard let currentUser = currentProfile.toUser() else {
                    await MainActor.run {
                        loadingIndicator.stopAnimating()
                        showEmptyState()
                    }
                    return
                }

                // Enrich profiles with session host counts
                let userIds = profiles.map { $0.user.id }
                let hostCounts = (try? await SupabaseService.shared.getSessionHostCounts(for: userIds)) ?? [:]
                let enrichedProfiles = profiles.map { profile -> (user: User, score: Int, reasons: [String]) in
                    var user = profile.user
                    user.sessionsHostedCount = hostCounts[user.id] ?? 0
                    return (user: user, score: profile.score, reasons: profile.reasons)
                }

                let builtCategories = DiscoverCategoryBuilder.buildCategories(
                    from: enrichedProfiles,
                    currentUser: currentUser
                )

                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    collectionView.refreshControl?.endRefreshing()
                    allScoredProfiles = profiles
                    categories = builtCategories

                    if categories.isEmpty {
                        showEmptyState()
                    } else {
                        collectionView.isHidden = false
                        emptyStateLabel.isHidden = true
                        reloadButton.isHidden = true
                        applySnapshot()

                        // Track browse session for deferred pricing trigger
                        let count = UserDefaults.standard.integer(forKey: "swipe_session_count")
                        UserDefaults.standard.set(count + 1, forKey: "swipe_session_count")
                    }
                }
            } catch {
                print("Error loading discovery profiles: \(error)")
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    collectionView.refreshControl?.endRefreshing()

                    let errorMessage: String
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        errorMessage = "discover_check_connection".localized
                    } else {
                        errorMessage = "discover_couldnt_load".localized
                    }

                    let alert = UIAlertController(
                        title: "discover_unable_to_load".localized,
                        message: errorMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "discover_try_again".localized, style: .default) { _ in
                        self.loadProfiles()
                    })
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .cancel) { _ in
                        self.showEmptyState()
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func showEmptyState() {
        collectionView.isHidden = true
        emptyStateLabel.isHidden = false
        reloadButton.isHidden = false
    }

    @objc private func reloadTapped() {
        emptyStateLabel.isHidden = true
        reloadButton.isHidden = true
        loadProfiles()
    }

    @objc private func pullToRefresh() {
        loadProfiles()
    }
}

// MARK: - UICollectionViewDelegate

extension DiscoverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section < categories.count else { return }
        let category = categories[indexPath.section]
        guard indexPath.item < category.users.count else { return }

        let profileData = category.users[indexPath.item]
        let user = profileData.user

        let detailVC = UserDetailViewController()
        detailVC.user = user
        detailVC.isMatched = false
        detailVC.isFromDiscover = true

        // Build flat user list from all categories (deduplicated)
        var seenIds = Set<String>()
        var flatUsers: [User] = []
        var targetIndex = 0

        for (catIdx, cat) in categories.enumerated() {
            for (itemIdx, profile) in cat.users.enumerated() {
                if seenIds.insert(profile.user.id).inserted {
                    if catIdx == indexPath.section && itemIdx == indexPath.item {
                        targetIndex = flatUsers.count
                    }
                    flatUsers.append(profile.user)
                }
            }
        }

        detailVC.allUsers = flatUsers
        detailVC.currentUserIndex = targetIndex
        detailVC.allCategories = categories

        // Pass the user's per-photo blur settings
        detailVC.viewingUserBlurSettings = user.photoBlurSettings

        navigationController?.pushViewController(detailVC, animated: true)
    }
}
