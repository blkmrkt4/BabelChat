import UIKit

protocol SessionChatViewDelegate: AnyObject {
    func sessionChatView(_ chatView: SessionChatView, didRequestMuseWithLanguage language: Language)
    func sessionChatView(_ chatView: SessionChatView, didTapUserWithId userId: String)
    func sessionChatViewParentViewController(_ chatView: SessionChatView) -> UIViewController?
    func sessionChatViewParticipants(_ chatView: SessionChatView) -> [SessionParticipant]
    func sessionChatViewHostId(_ chatView: SessionChatView) -> String
}

class SessionChatView: UIView {

    // MARK: - Properties
    private let sessionId: String
    private var messages: [Message] = []
    private var sessionMessages: [SessionMessage] = []
    private var currentUserId: String
    weak var delegate: SessionChatViewDelegate?

    // Language context for swipeable cells
    private var learningLanguage: Language
    private var nativeLanguage: Language
    private var currentSubscriptionTier: SubscriptionTier = .free

    // MARK: - UI
    private let tableView = UITableView()
    private let inputBar = UIView()
    private let museButton = UIButton(type: .custom)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    // MARK: - Init
    init(sessionId: String, learningLanguage: Language, nativeLanguage: Language) {
        self.sessionId = sessionId
        self.currentUserId = SupabaseService.shared.currentUserId?.uuidString ?? ""
        self.learningLanguage = learningLanguage
        self.nativeLanguage = nativeLanguage
        super.init(frame: .zero)
        setupViews()
        loadMessages()
        fetchSubscriptionTier()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .systemBackground

        // Table view — register SwipeableMessageCell for swipe-to-translate/grammar
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SwipeableMessageCell.self, forCellReuseIdentifier: "SwipeableMessageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        // Input bar
        inputBar.backgroundColor = .systemBackground
        inputBar.layer.borderWidth = 1
        inputBar.layer.borderColor = UIColor.separator.cgColor
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputBar)

        // Muse button (AI assistant)
        let museImage = UIImage(named: "MuseChat")?.withRenderingMode(.alwaysOriginal)
        museButton.setImage(museImage, for: .normal)
        museButton.imageView?.contentMode = .scaleAspectFit
        museButton.layer.cornerRadius = 22
        museButton.clipsToBounds = true
        museButton.addTarget(self, action: #selector(museTapped), for: .touchUpInside)
        museButton.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(museButton)

        // Text field
        textField.placeholder = "session_chat_placeholder".localized
        textField.font = .systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.returnKeyType = .send
        textField.delegate = self
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(textField)

        // Send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(sendButton)

        // Tap to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 50),

            museButton.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 4),
            museButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            museButton.widthAnchor.constraint(equalToConstant: 44),
            museButton.heightAnchor.constraint(equalToConstant: 44),

            textField.leadingAnchor.constraint(equalTo: museButton.trailingAnchor, constant: 8),
            textField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
        ])
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

    // MARK: - Data

    private func loadMessages() {
        Task {
            if let loaded = try? await SessionService.shared.getSessionMessages(sessionId: sessionId) {
                await MainActor.run {
                    self.sessionMessages = loaded
                    self.messages = loaded.map { self.convertToMessage($0) }
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            }
        }
    }

    func addMessage(_ sessionMessage: SessionMessage) {
        // Avoid duplicates — if we already optimistically added this message, skip
        if messages.contains(where: { $0.id == sessionMessage.id }) {
            return
        }
        // Also skip if this is our own message echoed back (already displayed optimistically)
        if sessionMessage.senderId == currentUserId,
           messages.contains(where: { $0.text == sessionMessage.originalText && $0.id.hasPrefix("local_") }) {
            // Replace local placeholder with real message
            if let index = messages.firstIndex(where: { $0.text == sessionMessage.originalText && $0.id.hasPrefix("local_") }) {
                messages[index] = convertToMessage(sessionMessage)
                sessionMessages.append(sessionMessage)
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                return
            }
        }

        sessionMessages.append(sessionMessage)
        let message = convertToMessage(sessionMessage)
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)
    }

    private func convertToMessage(_ sessionMessage: SessionMessage) -> Message {
        let isMe = sessionMessage.senderId == currentUserId
        // Use "currentUser" for own messages so SwipeableMessageCell renders them on the right
        let senderId = isMe ? "currentUser" : sessionMessage.senderId
        let recipientId = isMe ? sessionId : "currentUser"

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

    /// Look up the sender name and role for display
    private func senderInfo(for senderId: String) -> (name: String, role: SessionRole?) {
        if senderId == currentUserId || senderId == "currentUser" {
            let hostId = delegate?.sessionChatViewHostId(self) ?? ""
            let isHost = currentUserId == hostId
            return ("You", isHost ? .host : nil)
        }

        let participants = delegate?.sessionChatViewParticipants(self) ?? []
        if let participant = participants.first(where: { $0.userId == senderId }) {
            let name = participant.user?.firstName ?? "User"
            return (name, participant.role)
        }
        return ("User", nil)
    }

    /// Create a dummy User for SwipeableMessageCell (it needs a User for received messages)
    private func userForSender(_ senderId: String) -> User? {
        let participants = delegate?.sessionChatViewParticipants(self) ?? []
        if let participant = participants.first(where: { $0.userId == senderId }) {
            return participant.user
        }
        return nil
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        sendMessage()
    }

    @objc private func museTapped() {
        delegate?.sessionChatView(self, didRequestMuseWithLanguage: learningLanguage)
    }

    /// Insert Muse-generated text into the text field
    func insertMuseText(_ text: String) {
        textField.text = text
    }

    private func sendMessage() {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Content filter check (Apple Guideline 1.2 compliance)
        let contentCheck = ContentFilterService.shared.checkContent(text)
        if contentCheck.shouldBlock {
            if let parentVC = delegate?.sessionChatViewParentViewController(self) {
                let alert = UIAlertController(
                    title: "content_blocked_title".localized,
                    message: "content_blocked_message".localized,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                parentVC.present(alert, animated: true)
            }
            return
        }

        let filteredText = contentCheck.isClean ? text : ContentFilterService.shared.filterProfanity(text)
        let detectedLang = Language.detect(from: filteredText)?.name ?? learningLanguage.name

        // Optimistic insert — show the message immediately
        let localMessage = Message(
            id: "local_\(UUID().uuidString)",
            senderId: "currentUser",
            recipientId: sessionId,
            text: filteredText,
            timestamp: Date(),
            isRead: true,
            originalLanguage: Language.from(name: detectedLang),
            translatedText: nil,
            grammarSuggestions: nil,
            alternatives: nil,
            culturalNotes: nil
        )
        messages.append(localMessage)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom(animated: true)

        textField.text = ""

        // Send to server
        Task {
            try? await SessionService.shared.sendMessage(
                sessionId: sessionId,
                text: filteredText,
                language: detectedLang
            )
        }
    }
}

// MARK: - UITableViewDataSource
extension SessionChatView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwipeableMessageCell", for: indexPath) as? SwipeableMessageCell else {
            return UITableViewCell()
        }

        let message = messages[indexPath.row]
        let granularity = UserDefaults.standard.integer(forKey: "granularityLevel")

        // For received messages, find the sender's user object
        let senderUser: User
        if message.isSentByCurrentUser {
            // SwipeableMessageCell uses this for received messages only; for sent messages it doesn't matter much
            senderUser = User.placeholder
        } else {
            senderUser = userForSender(message.senderId) ?? User.placeholder
        }

        cell.delegate = self
        cell.setSubscriptionTier(currentSubscriptionTier)
        cell.configure(
            with: message,
            user: senderUser,
            granularity: max(1, granularity),
            learningLanguage: learningLanguage,
            nativeLanguage: nativeLanguage
        )

        // Show sender info for received messages (flag + name + native language)
        if !message.isSentByCurrentUser {
            let info = senderInfo(for: message.senderId)
            let user = userForSender(message.senderId)
            let flag = user?.nativeLanguage.language.flag ?? ""
            let nativeLangName = user?.nativeLanguage.language.name ?? ""
            let senderText = "\(flag) \(info.name) · \(nativeLangName)"
            cell.setSenderInfo(senderText)
        } else {
            cell.setSenderInfo(nil)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SessionChatView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        // Don't trigger for own messages
        guard !message.isSentByCurrentUser else { return }
        // Find the real senderId (not "currentUser")
        let sessionMsg = sessionMessages.first(where: { $0.id == message.id })
        let senderId = sessionMsg?.senderId ?? message.senderId
        delegate?.sessionChatView(self, didTapUserWithId: senderId)
    }
}

// MARK: - SwipeableMessageCellDelegate
extension SessionChatView: SwipeableMessageCellDelegate {
    func cell(_ cell: SwipeableMessageCell, didSwipeToPaneIndex paneIndex: Int) {
        // No full-screen expansion in sessions — just allow normal swiping
    }

    func cell(_ cell: SwipeableMessageCell, didRequestDeleteMessage message: Message) {
        // Not supported in sessions
    }

    func cell(_ cell: SwipeableMessageCell, didRequestReplyToMessage message: Message) {
        textField.text = "Replying to: \"\(message.text)\"\n"
        textField.becomeFirstResponder()
    }

    func cell(_ cell: SwipeableMessageCell, didRequestReportMessage message: Message) {
        // Could wire into content reporting — skip for now
    }
}

// MARK: - UITextFieldDelegate
extension SessionChatView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
