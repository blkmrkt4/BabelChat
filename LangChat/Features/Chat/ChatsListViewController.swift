import UIKit

class ChatsListViewController: UIViewController {

    private let tableView = UITableView()
    private var chats: [Match] = []
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupEmptyState()
        loadChats()
    }

    private func setupNavigationBar() {
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add "New Chat" button
        let newChatButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(newChatTapped)
        )
        navigationItem.rightBarButtonItem = newChatButton
    }

    @objc private func newChatTapped() {
        showMatchSelection()
    }

    private func showMatchSelection() {
        // Get existing chat user IDs to filter them out
        let existingChatUserIds = Set(chats.map { $0.user.id })

        // Load matches from Supabase
        Task {
            do {
                // Get match records
                let matchResponses = try await SupabaseService.shared.getMatches()

                // Filter for mutual matches only
                let mutualMatches = matchResponses.filter { $0.isMutual }

                guard !mutualMatches.isEmpty else {
                    await MainActor.run {
                        self.showMuseSelectionWithMessage("No matches yet. Practice with a Muse while you wait!")
                    }
                    return
                }

                // Get current user ID
                guard let currentUserId = SupabaseService.shared.currentUserId else {
                    await MainActor.run { self.showMuseSelection() }
                    return
                }
                let currentUserIdString = currentUserId.uuidString

                // Get the other user's ID from each match
                var matchedUsers: [(matchId: String, user: User)] = []

                for matchResponse in mutualMatches {
                    let otherUserId = matchResponse.user1Id == currentUserIdString
                        ? matchResponse.user2Id
                        : matchResponse.user1Id

                    // Skip if already have a chat with this user
                    if existingChatUserIds.contains(otherUserId) {
                        continue
                    }

                    // Try to fetch user profile
                    if let userProfile = try? await SupabaseService.shared.fetchUserProfile(userId: otherUserId) {
                        matchedUsers.append((matchId: matchResponse.id, user: userProfile))
                    }
                }

                await MainActor.run {
                    if matchedUsers.isEmpty {
                        self.showMuseSelectionWithMessage("You've started chats with all your matches. Practice with a Muse!")
                    } else {
                        self.presentMatchSelectionSheet(matchedUsers: matchedUsers)
                    }
                }
            } catch {
                await MainActor.run {
                    print("Failed to load matches: \(error)")
                    self.showMuseSelection()
                }
            }
        }
    }

    private func presentMatchSelectionSheet(matchedUsers: [(matchId: String, user: User)]) {
        let alert = UIAlertController(
            title: "Start a New Chat",
            message: "Choose someone to chat with",
            preferredStyle: .actionSheet
        )

        // Add matches
        for (matchId, user) in matchedUsers {
            let action = UIAlertAction(
                title: "\(user.firstName) - \(user.nativeLanguage.language.name)",
                style: .default
            ) { [weak self] _ in
                self?.startChatWithMatchedUser(matchId: matchId, user: user)
            }
            alert.addAction(action)
        }

        // Add Muse option
        alert.addAction(UIAlertAction(title: "Practice with a Muse ✨", style: .default) { [weak self] _ in
            self?.showMuseSelection()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func showMuseSelectionWithMessage(_ message: String) {
        let alert = UIAlertController(
            title: "Meet your Muse",
            message: message,
            preferredStyle: .actionSheet
        )

        let muses = AIBotFactory.createAIBots()
        for muse in muses {
            let action = UIAlertAction(
                title: "\(muse.firstName) - \(muse.nativeLanguage.language.name)",
                style: .default
            ) { [weak self] _ in
                self?.startChatWithMuse(muse)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func showMuseSelection() {
        let alert = UIAlertController(
            title: "Meet your Muse",
            message: "Choose a language to practice",
            preferredStyle: .actionSheet
        )

        let muses = AIBotFactory.createAIBots()
        for muse in muses {
            let action = UIAlertAction(
                title: "\(muse.firstName) - \(muse.nativeLanguage.language.name)",
                style: .default
            ) { [weak self] _ in
                self?.startChatWithMuse(muse)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func startChat(with match: Match) {
        // Save user data for later retrieval
        if let userData = try? JSONEncoder().encode(match.user) {
            UserDefaults.standard.set(userData, forKey: "user_\(match.user.id)")
        }

        let chatVC = ChatViewController(user: match.user, match: match)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func startChatWithMuse(_ muse: User) {
        let match = Match(
            id: muse.id,
            user: muse,
            matchedAt: Date(),
            hasNewMessage: false,
            lastMessage: nil,
            lastMessageTime: nil
        )

        let chatVC = ChatViewController(user: muse, match: match)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func startChatWithMatchedUser(matchId: String, user: User) {
        // Save user data for later retrieval
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "user_\(user.id)")
        }

        let match = Match(
            id: matchId,
            user: user,
            matchedAt: Date(),
            hasNewMessage: false,
            lastMessage: nil,
            lastMessageTime: nil
        )

        let chatVC = ChatViewController(user: user, match: match)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        emptyStateView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        emptyStateLabel.text = "No conversations yet"
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center

        emptyStateButton.setTitle("Start a Chat", for: .normal)
        emptyStateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        emptyStateButton.addTarget(self, action: #selector(newChatTapped), for: .touchUpInside)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(emptyStateLabel)
        stackView.addArrangedSubview(emptyStateButton)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !chats.isEmpty
        tableView.isHidden = chats.isEmpty
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadChats()
    }

    private func loadChats() {
        var loadedChats: [Match] = []

        // Scan UserDefaults for all conversation keys
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        #if DEBUG
        let conversationKeys = allKeys.filter { $0.hasPrefix("conversation_") }
        print("📱 ChatsListVC: Found \(conversationKeys.count) conversation keys in UserDefaults")
        #endif

        for key in allKeys {
            guard key.hasPrefix("conversation_") else { continue }

            // Extract user ID from key
            let userId = String(key.dropFirst("conversation_".count))

            // Load messages for this conversation
            guard let data = defaults.data(forKey: key),
                  let messages = try? JSONDecoder().decode([Message].self, from: data),
                  !messages.isEmpty else {
                #if DEBUG
                print("  ⚠️ Skipping \(key): no data or empty messages")
                #endif
                continue
            }

            // Get last message
            let lastMessage = messages.last!

            // Try to load saved user data for this conversation
            if let savedUser = loadSavedUser(userId: userId) {
                // Use a local match ID format for conversations without a match record
                let match = Match(
                    id: "local_match_\(userId)",  // Local-only match ID
                    user: savedUser,
                    matchedAt: messages.first?.timestamp ?? Date(),
                    hasNewMessage: false, // Could be enhanced to track unread
                    lastMessage: lastMessage.text,
                    lastMessageTime: lastMessage.timestamp
                )
                loadedChats.append(match)
                #if DEBUG
                print("  ✅ Loaded chat with \(savedUser.firstName) (\(messages.count) messages)")
                #endif
            } else {
                #if DEBUG
                print("  ⚠️ Skipping \(key): no user data found for userId \(userId)")
                #endif
            }
        }

        // Sort by last message time (most recent first), Muses without messages stay at end
        loadedChats.sort { (match1, match2) -> Bool in
            let time1 = match1.lastMessageTime ?? Date.distantPast
            let time2 = match2.lastMessageTime ?? Date.distantPast
            return time1 > time2
        }

        chats = loadedChats
        tableView.reloadData()
        updateEmptyState()

        #if DEBUG
        print("📱 ChatsListVC: Displaying \(chats.count) chats")
        #endif
    }

    private func loadSavedUser(userId: String) -> User? {
        // Check if this is a Muse
        if userId.hasPrefix("ai_bot_") {
            // Load Muse from factory
            let muses = AIBotFactory.createAIBots()
            return muses.first(where: { $0.id == userId })
        }

        // Try to load from saved match data for real users
        guard let data = UserDefaults.standard.data(forKey: "user_\(userId)"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            // No saved user data - return nil instead of placeholder
            return nil
        }
        return user
    }
}

extension ChatsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        cell.configure(with: chats[indexPath.row])
        return cell
    }
}

extension ChatsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let match = chats[indexPath.row]
        let chatViewController = ChatViewController(user: match.user, match: match)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

class ChatTableViewCell: UITableViewCell {

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UIView()
    private let onlineIndicator = UIView()
    private let aiBadge = UILabel()

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

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 28
        profileImageView.backgroundColor = .systemGray5
        contentView.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        contentView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .tertiaryLabel
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        unreadBadge.backgroundColor = .systemBlue
        unreadBadge.layer.cornerRadius = 4
        contentView.addSubview(unreadBadge)
        unreadBadge.translatesAutoresizingMaskIntoConstraints = false

        onlineIndicator.backgroundColor = .systemGreen
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.layer.borderWidth = 2
        onlineIndicator.layer.borderColor = UIColor.white.cgColor
        contentView.addSubview(onlineIndicator)
        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false

        aiBadge.text = "AI"
        aiBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        aiBadge.textColor = .white
        aiBadge.backgroundColor = .systemPurple
        aiBadge.textAlignment = .center
        aiBadge.layer.cornerRadius = 8
        aiBadge.clipsToBounds = true
        contentView.addSubview(aiBadge)
        aiBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 56),
            profileImageView.heightAnchor.constraint(equalToConstant: 56),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadBadge.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            unreadBadge.widthAnchor.constraint(equalToConstant: 8),
            unreadBadge.heightAnchor.constraint(equalToConstant: 8),

            onlineIndicator.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor),
            onlineIndicator.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 10),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 10),

            aiBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            aiBadge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            aiBadge.widthAnchor.constraint(equalToConstant: 24),
            aiBadge.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(with match: Match) {
        nameLabel.text = match.user.firstName
        messageLabel.text = match.lastMessage
        unreadBadge.isHidden = !match.hasNewMessage
        onlineIndicator.isHidden = !match.user.isOnline
        aiBadge.isHidden = !match.user.isAI

        if let lastMessageTime = match.lastMessageTime {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            timeLabel.text = formatter.localizedString(for: lastMessageTime, relativeTo: Date())
        } else {
            timeLabel.text = ""
        }

        // Load profile image
        loadProfileImage(for: match.user)
    }

    private func loadProfileImage(for user: User) {
        // Set appropriate placeholder first
        if user.isAI {
            profileImageView.image = UIImage(systemName: "sparkles")
            profileImageView.tintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)  // Gold
        } else {
            profileImageView.image = UIImage(systemName: "person.fill")
            profileImageView.tintColor = .systemGray3
        }

        // Try to load actual profile image
        guard let profileImagePath = user.profileImageURL, !profileImagePath.isEmpty else {
            return
        }

        Task {
            do {
                let imageURL: String
                if !profileImagePath.hasPrefix("http") {
                    // It's a storage path, generate signed URL
                    imageURL = try await SupabaseService.shared.getSignedPhotoURL(path: profileImagePath)
                } else {
                    imageURL = profileImagePath
                }

                await MainActor.run {
                    ImageService.shared.loadImage(
                        from: imageURL,
                        into: self.profileImageView,
                        placeholder: user.isAI
                            ? UIImage(systemName: "sparkles")
                            : UIImage(systemName: "person.fill")
                    )
                }
            } catch {
                print("Failed to load profile image for \(user.firstName): \(error)")
            }
        }
    }
}