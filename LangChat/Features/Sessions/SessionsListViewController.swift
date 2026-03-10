import UIKit

class SessionsListViewController: UIViewController {

    // MARK: - Filter

    private enum SessionFilter: Equatable {
        case mySessions
        case liveNow
        case nextHour
        case today
        case futureDay(Date) // specific future date
        case pastSessions
        case invites

        var title: String {
            switch self {
            case .mySessions: return "sessions_my_sessions".localized
            case .liveNow: return "sessions_live_now".localized
            case .nextHour: return "sessions_filter_next_hour".localized
            case .today: return "sessions_filter_today".localized
            case .futureDay(let date):
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, MMM d"
                return formatter.string(from: date)
            case .pastSessions: return "sessions_past_sessions".localized
            case .invites: return "sessions_your_invites".localized
            }
        }
    }

    // MARK: - UI
    private let chipCollectionView: UICollectionView
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    // MARK: - Data
    private var allSessions: [Session] = []
    private var filteredSessions: [Session] = []
    private var pastSessions: [Session] = []
    private var invites: [SessionInvite] = []
    private var filters: [SessionFilter] = []
    private var selectedFilterIndex = 0

    // MARK: - Init

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        chipCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupEmptyState()
        loadSessions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSessions()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false

        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "tab_sessions".localized
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleStack.addArrangedSubview(titleLabel)

        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.addTarget(self, action: #selector(createSessionTapped), for: .touchUpInside)
        titleStack.addArrangedSubview(addButton)

        navigationItem.titleView = titleStack

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        navigationItem.leftBarButtonItem = profileButton

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }

    @objc private func profileTapped() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        // Filter chips
        chipCollectionView.backgroundColor = .systemGroupedBackground
        chipCollectionView.showsHorizontalScrollIndicator = false
        chipCollectionView.delegate = self
        chipCollectionView.dataSource = self
        chipCollectionView.register(MatchFilterChipCell.self, forCellWithReuseIdentifier: "ChipCell")
        chipCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chipCollectionView)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SessionCell.self, forCellReuseIdentifier: SessionCell.reuseIdentifier)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshSessions), for: .valueChanged)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            chipCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chipCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipCollectionView.heightAnchor.constraint(equalToConstant: 46),

            tableView.topAnchor.constraint(equalTo: chipCollectionView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyStateLabel.text = "sessions_empty_state".localized
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true

        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    // MARK: - Data Loading

    private func loadSessions() {
        Task {
            // Fetch each source independently so one failure doesn't block the others
            var discoverable: [Session] = []
            var mySessions: [Session] = []
            var fetchedInvites: [SessionInvite] = []
            var fetchedPastSessions: [Session] = []

            async let discoverableTask: Void = {
                do {
                    discoverable = try await SessionService.shared.getDiscoverableSessions()
                } catch {
                    print("Failed to load discoverable sessions: \(error)")
                }
            }()

            async let mySessionsTask: Void = {
                do {
                    mySessions = try await SessionService.shared.getMySessions()
                } catch {
                    print("Failed to load my sessions: \(error)")
                }
            }()

            async let invitesTask: Void = {
                do {
                    fetchedInvites = try await SessionService.shared.getMyInvites()
                } catch {
                    print("Failed to load invites: \(error)")
                }
            }()

            async let pastSessionsTask: Void = {
                do {
                    fetchedPastSessions = try await SessionService.shared.getMyPastSessions()
                } catch {
                    print("Failed to load past sessions: \(error)")
                }
            }()

            // Wait for all to complete (none will throw)
            _ = await (discoverableTask, mySessionsTask, invitesTask, pastSessionsTask)

            // Merge and deduplicate (my sessions may already be in discoverable)
            var sessionMap: [String: Session] = [:]
            for session in discoverable { sessionMap[session.id] = session }
            for session in mySessions { sessionMap[session.id] = session }

            await MainActor.run {
                self.allSessions = Array(sessionMap.values)
                self.invites = fetchedInvites
                self.pastSessions = fetchedPastSessions
                self.buildFilters()
                self.autoSelectBestFilter()
                self.applyFilter()
                self.refreshControl.endRefreshing()
            }
        }
    }

    // MARK: - Filtering

    private func buildFilters() {
        var newFilters: [SessionFilter] = []

        // "My Sessions" always first — shows everything the user hosts or participates in
        newFilters.append(.mySessions)

        // Live Now
        newFilters.append(.liveNow)
        newFilters.append(.nextHour)
        newFilters.append(.today)

        // Collect unique future dates from scheduled sessions
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        var futureDays = Set<Date>()

        for session in allSessions where session.status == .scheduled {
            guard let scheduledAt = session.scheduledAt else { continue }
            let dayStart = calendar.startOfDay(for: scheduledAt)
            if dayStart >= tomorrow {
                futureDays.insert(dayStart)
            }
        }

        // Add future days sorted chronologically (up to 7 days out)
        let sortedDays = futureDays.sorted()
        for day in sortedDays.prefix(7) {
            newFilters.append(.futureDay(day))
        }

        // Past sessions tab — always shown so users know it exists
        newFilters.append(.pastSessions)

        // Invites tab if any pending
        if !invites.isEmpty {
            newFilters.append(.invites)
        }

        filters = newFilters

        // Keep selected index in bounds
        if selectedFilterIndex >= filters.count {
            selectedFilterIndex = 0
        }

        chipCollectionView.reloadData()
    }

    /// Auto-select the most relevant filter based on available data
    private func autoSelectBestFilter() {
        let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""

        // If user has any sessions (hosting or participating), default to "My Sessions"
        let mySessionCount = allSessions.filter { session in
            session.hostId.lowercased() == currentUserId || session.status == .live || session.status == .scheduled
        }.count
        if mySessionCount > 0 {
            if let myIndex = filters.firstIndex(of: .mySessions) {
                selectedFilterIndex = myIndex
                return
            }
        }

        // If there are live sessions, show those
        let liveCount = allSessions.filter { $0.status == .live }.count
        if liveCount > 0 {
            if let liveIndex = filters.firstIndex(of: .liveNow) {
                selectedFilterIndex = liveIndex
                return
            }
        }

        // Default to "My Sessions"
        selectedFilterIndex = 0
    }

    private func applyFilter() {
        guard selectedFilterIndex < filters.count else {
            filteredSessions = []
            updateUI()
            return
        }

        let filter = filters[selectedFilterIndex]
        let calendar = Calendar.current
        let now = Date()
        let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""

        switch filter {
        case .mySessions:
            // Show all sessions the user hosts or is a participant in, sorted by date
            // Exclude expired sessions whose duration has been exceeded
            filteredSessions = allSessions.filter { session in
                guard !session.isExpired else { return false }
                return session.hostId.lowercased() == currentUserId ||
                    session.status == .live ||
                    session.status == .scheduled
            }

        case .liveNow:
            filteredSessions = allSessions.filter { $0.status == .live && !$0.isExpired }

        case .nextHour:
            let oneHourLater = calendar.date(byAdding: .hour, value: 1, to: now)!
            filteredSessions = allSessions.filter { session in
                guard session.status == .scheduled, let scheduledAt = session.scheduledAt else { return false }
                return scheduledAt >= now && scheduledAt <= oneHourLater
            }

        case .today:
            filteredSessions = allSessions.filter { session in
                guard session.status == .scheduled, let scheduledAt = session.scheduledAt else { return false }
                return calendar.isDateInToday(scheduledAt) && scheduledAt >= now
            }

        case .futureDay(let day):
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            filteredSessions = allSessions.filter { session in
                guard session.status == .scheduled, let scheduledAt = session.scheduledAt else { return false }
                return scheduledAt >= day && scheduledAt < dayEnd
            }

        case .pastSessions:
            filteredSessions = pastSessions

        case .invites:
            filteredSessions = []
        }

        // Sort: live first, then by scheduled time
        filteredSessions.sort { s1, s2 in
            if s1.status == .live && s2.status != .live { return true }
            if s1.status != .live && s2.status == .live { return false }
            return (s1.scheduledAt ?? s1.createdAt) < (s2.scheduledAt ?? s2.createdAt)
        }

        updateUI()
    }

    private func updateUI() {
        let currentFilter = filters.indices.contains(selectedFilterIndex) ? filters[selectedFilterIndex] : .mySessions
        let isEmpty: Bool
        if currentFilter == .invites {
            isEmpty = invites.isEmpty
        } else if currentFilter == .pastSessions {
            isEmpty = pastSessions.isEmpty
        } else {
            isEmpty = filteredSessions.isEmpty
        }
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = false
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func createSessionTapped() {
        let tier = SubscriptionService.shared.currentStatus.tier
        guard tier.canHostSession else {
            let alert = UIAlertController(
                title: "upgrade_session_host_title".localized,
                message: "upgrade_session_host_message".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "button_upgrade_pro".localized, style: .default) { [weak self] _ in
                let pricingVC = PricingViewController()
                let nav = UINavigationController(rootViewController: pricingVC)
                nav.modalPresentationStyle = .pageSheet
                self?.present(nav, animated: true)
            })
            alert.addAction(UIAlertAction(title: "button_maybe_later".localized, style: .cancel))
            present(alert, animated: true)
            return
        }

        // Check monthly hosting limit
        let hostResult = UsageLimitService.shared.canHostSession(tier: tier)
        if !hostResult.isAllowed {
            let limit = tier.monthlySessionHostLimit ?? 0
            let used = UsageLimitService.shared.getMonthlyHostCount()
            let alert = UIAlertController(
                title: "session_host_limit_title".localized,
                message: String(format: "session_host_limit_message".localized, used, limit),
                preferredStyle: .alert
            )
            if tier == .pro {
                alert.addAction(UIAlertAction(title: "button_upgrade_broadcaster".localized, style: .default) { [weak self] _ in
                    let pricingVC = PricingViewController()
                    let nav = UINavigationController(rootViewController: pricingVC)
                    nav.modalPresentationStyle = .pageSheet
                    self?.present(nav, animated: true)
                })
            }
            alert.addAction(UIAlertAction(title: "common_ok".localized, style: .cancel))
            present(alert, animated: true)
            return
        }

        let createVC = CreateSessionViewController()
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func refreshSessions() {
        loadSessions()
    }
}

// MARK: - UICollectionViewDataSource & Delegate (Filter Chips)
extension SessionsListViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChipCell", for: indexPath) as? MatchFilterChipCell else {
            return UICollectionViewCell()
        }

        let filter = filters[indexPath.item]
        var title = filter.title

        // Show count badge for certain filters
        switch filter {
        case .mySessions:
            let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""
            let count = allSessions.filter { $0.hostId.lowercased() == currentUserId || $0.status == .live || $0.status == .scheduled }.count
            if count > 0 { title += " (\(count))" }
        case .liveNow:
            let count = allSessions.filter { $0.status == .live }.count
            if count > 0 { title += " (\(count))" }
        case .pastSessions:
            if !pastSessions.isEmpty { title += " (\(pastSessions.count))" }
        case .invites:
            if !invites.isEmpty { title += " (\(invites.count))" }
        default:
            break
        }

        cell.configure(title: title, isSelected: indexPath.item == selectedFilterIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        chipCollectionView.reloadData()
        applyFilter()
    }
}

// MARK: - UITableViewDataSource
extension SessionsListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentFilter = filters.indices.contains(selectedFilterIndex) ? filters[selectedFilterIndex] : .mySessions
        if currentFilter == .invites {
            return invites.count
        }
        return filteredSessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SessionCell.reuseIdentifier, for: indexPath) as? SessionCell else {
            return UITableViewCell()
        }

        let currentFilter = filters.indices.contains(selectedFilterIndex) ? filters[selectedFilterIndex] : .mySessions
        if currentFilter == .invites {
            cell.configureForInvite(with: invites[indexPath.row])
        } else {
            cell.configure(with: filteredSessions[indexPath.row])
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SessionsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let currentFilter = filters.indices.contains(selectedFilterIndex) ? filters[selectedFilterIndex] : .mySessions
        if currentFilter == .invites {
            let invite = invites[indexPath.row]
            showInviteResponse(invite)
        } else {
            let session = filteredSessions[indexPath.row]
            showSessionDetail(session)
        }
    }

    private func showSessionDetail(_ session: Session) {
        if session.status == .ended {
            let pastVC = PastSessionViewController(session: session)
            navigationController?.pushViewController(pastVC, animated: true)
        } else {
            let detailVC = SessionDetailViewController(session: session)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    private func showInviteResponse(_ invite: SessionInvite) {
        let alert = UIAlertController(
            title: "session_invite".localized,
            message: "session_invite_accept_message".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "session_invite_accept".localized, style: .default) { [weak self] _ in
            Task {
                try? await SessionService.shared.respondToInvite(inviteId: invite.id, accept: true)
                self?.loadSessions()
            }
        })
        alert.addAction(UIAlertAction(title: "session_invite_decline".localized, style: .destructive) { [weak self] _ in
            Task {
                try? await SessionService.shared.respondToInvite(inviteId: invite.id, accept: false)
                self?.loadSessions()
            }
        })
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - CreateSessionDelegate
extension SessionsListViewController: CreateSessionDelegate {
    func didCreateSession(_ session: Session) {
        if session.isLive {
            loadSessions()
            let sessionVC = SessionViewController(session: session)
            navigationController?.pushViewController(sessionVC, animated: true)
        } else {
            // Scheduled session — reload and show in "My Sessions"
            selectFilterForSession(session)
        }
    }

    private func selectFilterForSession(_ session: Session) {
        Task {
            // Fetch each source independently
            var discoverable: [Session] = []
            var mySessions: [Session] = []
            var fetchedInvites: [SessionInvite] = []

            do { discoverable = try await SessionService.shared.getDiscoverableSessions() } catch { }
            do { mySessions = try await SessionService.shared.getMySessions() } catch { }
            do { fetchedInvites = try await SessionService.shared.getMyInvites() } catch { }

            var sessionMap: [String: Session] = [:]
            for s in discoverable { sessionMap[s.id] = s }
            for s in mySessions { sessionMap[s.id] = s }

            await MainActor.run {
                self.allSessions = Array(sessionMap.values)
                self.invites = fetchedInvites
                self.buildFilters()

                // Default to "My Sessions" so the newly created session is visible
                if let myIndex = self.filters.firstIndex(of: .mySessions) {
                    self.selectedFilterIndex = myIndex
                } else if let scheduledAt = session.scheduledAt {
                    // Fallback: find the right date filter
                    let calendar = Calendar.current
                    if calendar.isDateInToday(scheduledAt) {
                        if let todayIndex = self.filters.firstIndex(of: .today) {
                            self.selectedFilterIndex = todayIndex
                        }
                    } else {
                        let dayStart = calendar.startOfDay(for: scheduledAt)
                        if let dayIndex = self.filters.firstIndex(of: .futureDay(dayStart)) {
                            self.selectedFilterIndex = dayIndex
                        }
                    }
                }

                self.chipCollectionView.reloadData()
                self.applyFilter()
            }
        }
    }
}
