import UIKit

class ChatViewController: UIViewController {

    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var messages: [Message] = []
    private var inputBottomConstraint: NSLayoutConstraint!

    let user: User
    let match: Match

    // Supabase conversation ID
    private var conversationId: String?
    private var isConversationReady = false

    // Language context for translations and grammar checks
    private var conversationLearningLanguage: Language // The language being practiced
    private var currentUserNativeLanguage: Language // Current user's native language

    // Full-screen expansion tracking
    private var expandedIndexPath: IndexPath?
    private var expandedPaneIndex: Int = 1 // 0=grammar, 1=center, 2=translation

    init(user: User, match: Match) {
        self.user = user
        self.match = match

        // Determine language context
        // The conversation learning language is the match's native language (what user is learning)
        self.conversationLearningLanguage = user.nativeLanguage.language

        // TODO: Get actual current user's native language from UserDefaults or global state
        // For now, assume English as fallback
        self.currentUserNativeLanguage = .english

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupKeyboardObservers()
        loadMessages()
        saveUserData() // Save user data for chat list
        setupConversation() // Get or create Supabase conversation
    }

    private func saveUserData() {
        // Save user data so chat list can load it
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_\(user.id)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        saveMessages() // Save messages when leaving chat
    }

    private func setupNavigationBar() {
        title = user.firstName
        navigationItem.largeTitleDisplayMode = .never

        // Create custom title view with user info
        let titleView = UIView()

        let nameLabel = UILabel()
        nameLabel.text = user.firstName
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textAlignment = .center

        let statusLabel = UILabel()
        statusLabel.text = user.isOnline ? "Active now" : "Offline"
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = user.isOnline ? .systemGreen : .secondaryLabel
        statusLabel.textAlignment = .center

        titleView.addSubview(nameLabel)
        titleView.addSubview(statusLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: titleView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor)
        ])

        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        navigationItem.titleView = titleView

        // Add right bar button items
        let videoCallButton = UIBarButtonItem(
            image: UIImage(systemName: "video"),
            style: .plain,
            target: self,
            action: #selector(videoCallTapped)
        )

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreOptionsTapped)
        )

        navigationItem.rightBarButtonItems = [moreButton, videoCallButton]
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.register(SwipeableMessageCell.self, forCellReuseIdentifier: "SwipeableMessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        view.addSubview(tableView)

        // Setup input container
        inputContainerView.backgroundColor = .systemBackground
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = UIColor.separator.cgColor

        view.addSubview(inputContainerView)

        // Setup input text field
        inputTextField.placeholder = "Type a message..."
        inputTextField.font = .systemFont(ofSize: 16)
        inputTextField.borderStyle = .none
        inputTextField.returnKeyType = .send
        inputTextField.delegate = self
        inputTextField.enablesReturnKeyAutomatically = true

        inputContainerView.addSubview(inputTextField)

        // Setup send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.isEnabled = false

        inputContainerView.addSubview(sendButton)

        // Setup constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,
            inputContainerView.heightAnchor.constraint(equalToConstant: 50),

            inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        // Monitor text field changes
        inputTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    // MARK: - Message Persistence

    private func conversationKey() -> String {
        return "conversation_\(user.id)"
    }

    private func saveMessages() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: conversationKey())
            print("💾 Saved \(messages.count) messages for \(user.firstName)")
        } catch {
            print("❌ Failed to save messages: \(error)")
        }
    }

    private func loadSavedMessages() -> [Message]? {
        guard let data = UserDefaults.standard.data(forKey: conversationKey()) else {
            return nil
        }

        do {
            let loadedMessages = try JSONDecoder().decode([Message].self, from: data)
            print("📬 Loaded \(loadedMessages.count) messages for \(user.firstName)")
            return loadedMessages
        } catch {
            print("❌ Failed to load messages: \(error)")
            return nil
        }
    }

    private func loadMessages() {
        // Try to load saved messages first
        if let savedMessages = loadSavedMessages(), !savedMessages.isEmpty {
            messages = savedMessages
            tableView.reloadData()
            scrollToBottom(animated: false)
            return
        }

        // Load sample messages with language learning features (first time only)
        let userLanguage = user.nativeLanguage.language

        messages = [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Hi! I saw you're learning \(user.learningLanguages.first?.language.name ?? "languages"). I'm a native speaker and would love to help!",
                timestamp: Date(timeIntervalSinceNow: -3600),
                isRead: true,
                originalLanguage: .english,
                translatedText: "¡Hola! Vi que estás aprendiendo español. ¡Soy hablante nativo y me encantaría ayudarte!",
                grammarSuggestions: nil,
                alternatives: ["I'd be happy to help!", "I can help you practice!", "Let's practice together!"],
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: "currentUser",
                recipientId: user.id,
                text: "That would be amazing! I'm really trying to improve my conversational skills.",
                timestamp: Date(timeIntervalSinceNow: -3000),
                isRead: true,
                originalLanguage: .english,
                translatedText: "¡Eso sería increíble! Realmente estoy tratando de mejorar mis habilidades conversacionales.",
                grammarSuggestions: ["Consider: 'That would be wonderful' for more formal tone"],
                alternatives: ["That sounds great!", "I'd really appreciate that!", "Yes please!"],
                culturalNotes: nil
            ),
            Message(
                id: "3",
                senderId: user.id,
                recipientId: "currentUser",
                text: "¿Te gustaría empezar con frases básicas o prefieres un tema específico?",
                timestamp: Date(timeIntervalSinceNow: -2400),
                isRead: true,
                originalLanguage: userLanguage,
                translatedText: "Would you like to start with basic phrases or prefer a specific topic?",
                grammarSuggestions: ["Perfect use of conditional!", "Good formal register"],
                alternatives: ["¿Qué tal si empezamos con...?", "¿Por dónde quieres empezar?"],
                culturalNotes: "Using 'usted' form shows respect in initial conversations"
            ),
            Message(
                id: "4",
                senderId: "currentUser",
                recipientId: user.id,
                text: "Let's start with everyday conversation. I struggle with informal speech.",
                timestamp: Date(timeIntervalSinceNow: -1800),
                isRead: true,
                originalLanguage: .english,
                translatedText: "Empecemos con conversación diaria. Tengo problemas con el habla informal.",
                grammarSuggestions: ["Good structure!", "Consider: 'I have difficulty with' instead of 'struggle'"],
                alternatives: ["Daily conversations would be great", "I need help with casual talk"],
                culturalNotes: nil
            ),
            Message(
                id: "5",
                senderId: user.id,
                recipientId: "currentUser",
                text: "¡Buena elección! El habla informal es muy importante. Te enseñaré expresiones comunes.",
                timestamp: Date(timeIntervalSinceNow: -1200),
                isRead: true,
                originalLanguage: userLanguage,
                translatedText: "Great choice! Informal speech is very important. I'll teach you common expressions.",
                grammarSuggestions: nil,
                alternatives: ["¡Perfecto!", "¡Excelente decisión!", "¡Me parece genial!"],
                culturalNotes: "Exclamation marks are commonly used in Spanish to show enthusiasm"
            )
        ]

        tableView.reloadData()
        scrollToBottom(animated: false)
    }

    // MARK: - Supabase Integration

    private func setupConversation() {
        Task {
            do {
                // Disable send button while setting up
                await MainActor.run {
                    sendButton.isEnabled = false
                    inputTextField.placeholder = "Setting up conversation..."
                }

                let conversation = try await SupabaseService.shared.getOrCreateConversation(with: user.id)

                await MainActor.run {
                    self.conversationId = conversation.id
                    self.isConversationReady = true
                    self.inputTextField.placeholder = "Type a message..."
                    // Re-enable if there's text
                    self.sendButton.isEnabled = !(self.inputTextField.text?.isEmpty ?? true)
                    print("✅ Conversation ready: \(conversation.id)")
                }
            } catch {
                await MainActor.run {
                    self.inputTextField.placeholder = "Failed to connect"
                    print("❌ Failed to setup conversation: \(error)")

                    // Show error alert
                    let alert = UIAlertController(
                        title: "Connection Error",
                        message: "Failed to setup conversation. Please check your connection and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                        self.setupConversation()
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func sendButtonTapped() {
        guard let text = inputTextField.text, !text.isEmpty else { return }

        // Wait for conversation to be ready
        guard isConversationReady, let conversationId = conversationId else {
            print("❌ Conversation not ready yet")
            let alert = UIAlertController(
                title: "Please Wait",
                message: "Setting up conversation...",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Create and display user message immediately
        let newMessage = Message(
            id: UUID().uuidString,
            senderId: "currentUser",
            recipientId: user.id,
            text: text,
            timestamp: Date(),
            isRead: false,
            originalLanguage: conversationLearningLanguage,
            translatedText: nil,
            grammarSuggestions: nil,
            alternatives: nil,
            culturalNotes: nil
        )

        messages.append(newMessage)
        saveMessages()
        inputTextField.text = ""
        sendButton.isEnabled = false

        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        scrollToBottom(animated: true)

        // Send to Supabase and generate AI response
        Task {
            do {
                // 1. Send user message to Supabase
                try await SupabaseService.shared.sendMessage(conversationId: conversationId, text: text)
                print("✅ User message sent to Supabase")

                // 2. Generate AI response using Scoring model
                await generateAIResponse(to: text, conversationId: conversationId)
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }

    private func generateAIResponse(to userMessage: String, conversationId: String) async {
        do {
            // Use the Scoring model/prompt to generate a response
            // User is writing in learning language, AI responds in same language
            let aiResponse = try await AIConfigurationManager.shared.scoreText(
                text: userMessage,
                learningLanguage: conversationLearningLanguage.name,
                nativeLanguage: currentUserNativeLanguage.name
            )

            // Send AI response to Supabase
            try await SupabaseService.shared.sendMessage(conversationId: conversationId, text: aiResponse)
            print("✅ AI response sent to Supabase")

            // Display AI response in UI
            await MainActor.run {
                let aiMessage = Message(
                    id: UUID().uuidString,
                    senderId: user.id,
                    recipientId: "currentUser",
                    text: aiResponse,
                    timestamp: Date(),
                    isRead: false,
                    originalLanguage: conversationLearningLanguage,
                    translatedText: nil,
                    grammarSuggestions: nil,
                    alternatives: nil,
                    culturalNotes: nil
                )

                messages.append(aiMessage)
                saveMessages()

                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: .bottom)
                scrollToBottom(animated: true)
            }
        } catch {
            print("❌ Failed to generate AI response: \(error)")
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        inputBottomConstraint.constant = -keyboardHeight + view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }

        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        inputBottomConstraint.constant = 0

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func textFieldDidChange() {
        // Only enable send button if conversation is ready AND text is not empty
        let hasText = !(inputTextField.text?.isEmpty ?? true)
        sendButton.isEnabled = hasText && isConversationReady
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func videoCallTapped() {
        let alert = UIAlertController(
            title: "Video Call",
            message: "Video calling will be available in a future update",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func moreOptionsTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "View Profile", style: .default) { _ in
            // Navigate to user profile
        })

        actionSheet.addAction(UIAlertAction(title: "Search in Conversation", style: .default) { _ in
            // Implement search
        })

        actionSheet.addAction(UIAlertAction(title: "Mute Notifications", style: .default) { _ in
            // Implement mute
        })

        actionSheet.addAction(UIAlertAction(title: "Block User", style: .destructive) { _ in
            // Implement block
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }

        present(actionSheet, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        // Use SwipeableMessageCell for all messages now (to enable translation/grammar on demand)
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwipeableMessageCell", for: indexPath) as! SwipeableMessageCell
        let granularity = UserDefaults.standard.integer(forKey: "granularityLevel")
        cell.delegate = self
        cell.configure(
            with: message,
            user: user,
            granularity: max(1, granularity),
            learningLanguage: conversationLearningLanguage,
            nativeLanguage: currentUserNativeLanguage
        )

        // Hide cell if another cell is expanded and this isn't it
        if let expandedPath = expandedIndexPath, expandedPath != indexPath, expandedPaneIndex != 1 {
            cell.alpha = 0
            cell.isUserInteractionEnabled = false
        } else {
            cell.alpha = 1
            cell.isUserInteractionEnabled = true
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // If this cell is expanded to full screen (grammar/translation pane)
        if let expandedPath = expandedIndexPath, expandedPath == indexPath, expandedPaneIndex != 1 {
            return view.bounds.height - view.safeAreaInsets.top
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - SwipeableMessageCellDelegate
extension ChatViewController: SwipeableMessageCellDelegate {
    func cell(_ cell: SwipeableMessageCell, didSwipeToPaneIndex paneIndex: Int) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        expandedPaneIndex = paneIndex

        if paneIndex == 1 {
            // Returned to center pane - collapse
            expandedIndexPath = nil
            UIView.animate(withDuration: 0.3) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        } else {
            // Swiped to grammar (0) or translation (2) - expand
            expandedIndexPath = indexPath

            // Scroll to position this cell at the top
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)

            // Reload to apply new heights and hide other cells
            UIView.animate(withDuration: 0.3) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.text!.isEmpty {
            sendButtonTapped()
        }
        return true
    }
}

// MARK: - Message Cell
class MessageCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let profileImageView = UIImageView()

    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var profileLeadingConstraint: NSLayoutConstraint!
    private var profileTrailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        // Setup bubble view
        bubbleView.layer.cornerRadius = 16
        contentView.addSubview(bubbleView)

        // Setup message label
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        bubbleView.addSubview(messageLabel)

        // Setup time label
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabel
        contentView.addSubview(timeLabel)

        // Setup profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 16
        contentView.addSubview(profileImageView)

        // Setup constraints
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        profileLeadingConstraint = profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        profileTrailingConstraint = profileImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -2),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),  // Fixed width instead of UIScreen.main

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),

            timeLabel.heightAnchor.constraint(equalToConstant: 14),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    func configure(with message: Message, user: User) {
        messageLabel.text = message.text
        timeLabel.text = message.formattedTime

        if message.isSentByCurrentUser {
            // Sent message
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white

            bubbleLeadingConstraint.isActive = false
            profileLeadingConstraint.isActive = false
            bubbleTrailingConstraint.isActive = true
            profileTrailingConstraint.isActive = false

            bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
            bubbleLeadingConstraint.isActive = true

            timeLabel.textAlignment = .right
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true

            profileImageView.isHidden = true
        } else {
            // Received message
            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label

            bubbleTrailingConstraint.isActive = false
            profileTrailingConstraint.isActive = false
            bubbleLeadingConstraint.isActive = true
            profileLeadingConstraint.isActive = true

            bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
            bubbleTrailingConstraint.isActive = true

            timeLabel.textAlignment = .left
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true

            profileImageView.isHidden = false
            if let profileURL = user.profileImageURL {
                ImageService.shared.loadImage(
                    from: profileURL,
                    into: profileImageView,
                    placeholder: UIImage(systemName: "person.circle.fill")
                )
            } else {
                profileImageView.image = UIImage(systemName: "person.circle.fill")
            }
        }
    }
}