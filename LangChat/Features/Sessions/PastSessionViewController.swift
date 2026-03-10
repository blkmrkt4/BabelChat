import UIKit

class PastSessionViewController: UIViewController {

    // MARK: - Properties
    private let session: Session
    private var messages: [Message] = []
    private var sessionMessages: [SessionMessage] = []
    private var currentUserId: String

    // Language context for swipeable cells
    private var learningLanguage: Language
    private var nativeLanguage: Language
    private var currentSubscriptionTier: SubscriptionTier = .free

    // MARK: - UI
    private let headerView = UIView()
    private let hostAvatarView = UIImageView()
    private let hostNameLabel = UILabel()
    private let titleLabel = UILabel()
    private let languagePairLabel = UILabel()
    private let endedLabel = UILabel()
    private let durationLabel = UILabel()
    private let tableView = UITableView()

    // MARK: - Init
    init(session: Session) {
        self.session = session
        self.currentUserId = SupabaseService.shared.currentUserId?.uuidString ?? ""
        self.learningLanguage = Language.from(name: session.languagePair.learning) ?? .english
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            self.nativeLanguage = decoded.nativeLanguage.language
        } else {
            self.nativeLanguage = Language.from(name: session.languagePair.native) ?? .english
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureHeader()
        loadMessages()
        fetchSubscriptionTier()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = "session_past_chat_title".localized

        // Header
        headerView.backgroundColor = .secondarySystemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Host avatar
        hostAvatarView.contentMode = .scaleAspectFill
        hostAvatarView.clipsToBounds = true
        hostAvatarView.layer.cornerRadius = 24
        hostAvatarView.backgroundColor = .systemGray5
        hostAvatarView.image = UIImage(systemName: "person.circle.fill")
        hostAvatarView.tintColor = .systemGray3
        hostAvatarView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(hostAvatarView)

        // Host name
        hostNameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        hostNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(hostNameLabel)

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Language pair
        languagePairLabel.font = .systemFont(ofSize: 14, weight: .medium)
        languagePairLabel.textColor = .systemBlue
        languagePairLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(languagePairLabel)

        // Ended label
        endedLabel.font = .systemFont(ofSize: 13, weight: .regular)
        endedLabel.textColor = .secondaryLabel
        endedLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(endedLabel)

        // Duration label
        durationLabel.font = .systemFont(ofSize: 13, weight: .regular)
        durationLabel.textColor = .tertiaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(durationLabel)

        // Table view for messages
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SwipeableMessageCell.self, forCellReuseIdentifier: "SwipeableMessageCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            hostAvatarView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            hostAvatarView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            hostAvatarView.widthAnchor.constraint(equalToConstant: 48),
            hostAvatarView.heightAnchor.constraint(equalToConstant: 48),

            hostNameLabel.topAnchor.constraint(equalTo: hostAvatarView.topAnchor),
            hostNameLabel.leadingAnchor.constraint(equalTo: hostAvatarView.trailingAnchor, constant: 12),
            hostNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: hostNameLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: hostNameLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            languagePairLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            languagePairLabel.leadingAnchor.constraint(equalTo: hostNameLabel.leadingAnchor),

            endedLabel.topAnchor.constraint(equalTo: languagePairLabel.bottomAnchor, constant: 4),
            endedLabel.leadingAnchor.constraint(equalTo: hostNameLabel.leadingAnchor),

            durationLabel.topAnchor.constraint(equalTo: endedLabel.topAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: endedLabel.trailingAnchor, constant: 12),

            headerView.bottomAnchor.constraint(equalTo: endedLabel.bottomAnchor, constant: 12),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureHeader() {
        hostNameLabel.text = session.host?.firstName ?? "session_role_host".localized
        titleLabel.text = session.displayTitle
        languagePairLabel.text = session.languagePair.displayString

        // Load host profile picture
        if let host = session.host, let urlString = host.profileImageURL {
            ImageService.shared.loadImage(from: urlString, into: hostAvatarView)
        }

        // Ended relative time
        if let endedAt = session.endedAt {
            let elapsed = Date().timeIntervalSince(endedAt)
            let hours = Int(elapsed / 3600)
            let minutes = Int(elapsed / 60) % 60
            let relativeTime: String
            if hours > 0 {
                relativeTime = "\(hours)h"
            } else {
                relativeTime = "\(minutes)m"
            }
            endedLabel.text = String(format: "session_ended_ago".localized, relativeTime)
        }

        // Duration
        if let startedAt = session.startedAt, let endedAt = session.endedAt {
            let duration = endedAt.timeIntervalSince(startedAt)
            let durationMinutes = Int(duration / 60)
            durationLabel.text = "\("session_duration_label".localized): \(durationMinutes)m"
        }
    }

    // MARK: - Data

    private func loadMessages() {
        Task {
            if let loaded = try? await SessionService.shared.getSessionMessages(sessionId: session.id, limit: 200) {
                await MainActor.run {
                    self.sessionMessages = loaded
                    self.messages = loaded.map { self.convertToMessage($0) }
                    self.tableView.reloadData()
                    if !self.messages.isEmpty {
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                }
            }
        }
    }

    private func fetchSubscriptionTier() {
        Task {
            if let tier = try? await SupabaseService.shared.getCurrentSubscriptionTier() {
                await MainActor.run {
                    self.currentSubscriptionTier = tier
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func convertToMessage(_ sessionMessage: SessionMessage) -> Message {
        let isMe = sessionMessage.senderId == currentUserId
        let senderId = isMe ? "currentUser" : sessionMessage.senderId
        let recipientId = isMe ? session.id : "currentUser"

        return Message(
            id: sessionMessage.id,
            senderId: senderId,
            recipientId: recipientId,
            text: sessionMessage.originalText,
            timestamp: sessionMessage.createdAt,
            isRead: true,
            originalLanguage: Language.from(name: sessionMessage.originalLanguage),
            translatedText: sessionMessage.translatedText.values.first,
            grammarSuggestions: nil,
            alternatives: nil,
            culturalNotes: nil
        )
    }
}

// MARK: - UITableViewDataSource
extension PastSessionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwipeableMessageCell", for: indexPath) as? SwipeableMessageCell else {
            return UITableViewCell()
        }

        let message = messages[indexPath.row]
        let granularity = UserDefaults.standard.integer(forKey: "granularityLevel")

        cell.setSubscriptionTier(currentSubscriptionTier)
        cell.configure(
            with: message,
            user: User.placeholder,
            granularity: max(1, granularity),
            learningLanguage: learningLanguage,
            nativeLanguage: nativeLanguage
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension PastSessionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
