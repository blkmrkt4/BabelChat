import UIKit

class ChatsListViewController: UIViewController {

    private let tableView = UITableView()
    private var chats: [Match] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadChats()
    }

    private func setupNavigationBar() {
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadChats()
    }

    private func loadChats() {
        var loadedChats: [Match] = []

        // Add AI practice partners first (always available)
        let aiBots = AIBotFactory.createAIBots()
        for bot in aiBots {
            let match = Match(
                id: bot.id,
                user: bot,
                matchedAt: Date(),
                hasNewMessage: false,
                lastMessage: "Start practicing \(bot.nativeLanguage.language.name)!",
                lastMessageTime: nil // AI bots always appear at bottom
            )
            loadedChats.append(match)
        }

        // Scan UserDefaults for all conversation keys
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        for key in allKeys {
            guard key.hasPrefix("conversation_") else { continue }

            // Extract user ID from key
            let userId = String(key.dropFirst("conversation_".count))

            // Skip if this is an AI bot (already added above)
            if userId.hasPrefix("ai_bot_") {
                continue
            }

            // Load messages for this conversation
            guard let data = defaults.data(forKey: key),
                  let messages = try? JSONDecoder().decode([Message].self, from: data),
                  !messages.isEmpty else {
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
            }
        }

        // Sort by last message time (most recent first), but AI bots without messages stay at end
        loadedChats.sort { (match1, match2) -> Bool in
            let time1 = match1.lastMessageTime ?? Date.distantPast
            let time2 = match2.lastMessageTime ?? Date.distantPast
            return time1 > time2
        }

        chats = loadedChats
        tableView.reloadData()
    }

    private func loadSavedUser(userId: String) -> User? {
        // Try to load from saved match data
        guard let data = UserDefaults.standard.data(forKey: "user_\(userId)"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            // If no saved user, create a placeholder
            return createPlaceholderUser(userId: userId)
        }
        return user
    }

    private func createPlaceholderUser(userId: String) -> User {
        // Create placeholder user for conversations where user data wasn't saved
        return User(
            id: userId,
            username: "user_\(userId)",
            firstName: "User",
            lastName: "",
            bio: "",
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: UserLanguage(language: .korean, proficiency: .native, isNative: true),
            learningLanguages: [UserLanguage(language: .english, proficiency: .intermediate, isNative: false)],
            openToLanguages: [.english],
            practiceLanguages: nil,
            location: "Unknown",
            matchedDate: Date(),
            isOnline: false
        )
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

        // Use robot icon for AI bots
        if match.user.isAI {
            profileImageView.image = UIImage(systemName: "brain.head.profile")
            profileImageView.tintColor = .systemPurple
        } else {
            profileImageView.image = UIImage(systemName: "person.fill")
            profileImageView.tintColor = .systemGray3
        }
    }
}