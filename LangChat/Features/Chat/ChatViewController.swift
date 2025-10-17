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

        // Load language-specific sample messages (first time only)
        let userLanguage = user.nativeLanguage.language

        // Generate appropriate welcome messages based on the bot's language
        switch userLanguage {
        case .spanish:
            messages = createSpanishWelcomeMessages()
        case .french:
            messages = createFrenchWelcomeMessages()
        case .japanese:
            messages = createJapaneseWelcomeMessages()
        case .german:
            messages = createGermanWelcomeMessages()
        case .chinese:
            messages = createChineseWelcomeMessages()
        default:
            // Generic English messages for other languages
            messages = createGenericWelcomeMessages(language: userLanguage)
        }

        tableView.reloadData()
        scrollToBottom(animated: false)
    }

    // MARK: - Language-Specific Welcome Messages

    private func createSpanishWelcomeMessages() -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "¡Hola! Soy María. ¿Cómo estás?",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .spanish,
                translatedText: "Hello! I'm María. How are you?",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Estoy aquí para ayudarte a practicar español. ¡Empecemos!",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .spanish,
                translatedText: "I'm here to help you practice Spanish. Let's get started!",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    private func createFrenchWelcomeMessages() -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Bonjour ! Je m'appelle Sophie. Comment vas-tu ?",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .french,
                translatedText: "Hello! My name is Sophie. How are you?",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Je suis là pour t'aider à pratiquer le français. Commençons !",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .french,
                translatedText: "I'm here to help you practice French. Let's begin!",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    private func createJapaneseWelcomeMessages() -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "こんにちは！ゆきです。元気ですか？",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .japanese,
                translatedText: "Hello! I'm Yuki. How are you?",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "日本語の練習を手伝います。始めましょう！",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .japanese,
                translatedText: "I'll help you practice Japanese. Let's begin!",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    private func createGermanWelcomeMessages() -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Hallo! Ich bin Max. Wie geht es dir?",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .german,
                translatedText: "Hello! I'm Max. How are you?",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Ich bin hier, um dir beim Deutschlernen zu helfen. Lass uns anfangen!",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .german,
                translatedText: "I'm here to help you learn German. Let's start!",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    private func createChineseWelcomeMessages() -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "你好！我是林。你好吗？",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .chinese,
                translatedText: "Hello! I'm Lin. How are you?",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "我会帮你练习中文。我们开始吧！",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .chinese,
                translatedText: "I'll help you practice Chinese. Let's begin!",
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    private func createGenericWelcomeMessages(language: Language) -> [Message] {
        return [
            Message(
                id: "1",
                senderId: user.id,
                recipientId: "currentUser",
                text: "Hello! I'm \(user.firstName). Ready to practice \(language.name)?",
                timestamp: Date(timeIntervalSinceNow: -300),
                isRead: true,
                originalLanguage: .english,
                translatedText: nil,
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            ),
            Message(
                id: "2",
                senderId: user.id,
                recipientId: "currentUser",
                text: "I'm here to help you learn. Let's start!",
                timestamp: Date(timeIntervalSinceNow: -240),
                isRead: true,
                originalLanguage: .english,
                translatedText: nil,
                grammarSuggestions: nil,
                alternatives: nil,
                culturalNotes: nil
            )
        ]
    }

    // MARK: - Supabase Integration

    private func setupConversation() {
        // AI bots don't need Supabase - they're local only
        if user.isAI {
            // Use local ID for AI bot conversations
            conversationId = "local_\(user.id)"
            isConversationReady = true
            inputTextField.placeholder = "Type a message..."
            sendButton.isEnabled = !(inputTextField.text?.isEmpty ?? true)
            print("✅ AI bot conversation ready (local only): \(user.firstName)")
            return
        }

        // Check if this is a local-only conversation (no Supabase match)
        if match.id.hasPrefix("local_match_") {
            // Local conversation without a match record
            conversationId = "local_conv_\(user.id)"
            isConversationReady = true
            inputTextField.placeholder = "Type a message..."
            sendButton.isEnabled = !(inputTextField.text?.isEmpty ?? true)
            print("✅ Local conversation ready (no Supabase): \(user.firstName)")
            return
        }

        // For real users with matches, set up Supabase conversation
        Task {
            do {
                // Disable send button while setting up
                await MainActor.run {
                    sendButton.isEnabled = false
                    inputTextField.placeholder = "Setting up conversation..."
                }

                print("🔍 Setting up conversation for match: \(match.id)")
                print("🔍 User: \(user.firstName) (\(user.id))")
                print("🔍 Current user ID: \(SupabaseService.shared.currentUserId?.uuidString ?? "nil")")
                print("🔍 Is authenticated: \(SupabaseService.shared.isAuthenticated)")

                let conversation = try await SupabaseService.shared.getOrCreateConversation(forMatchId: match.id)

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
                    print("❌ Error details: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("❌ Decoding error: \(decodingError)")
                    }

                    // Show error alert with detailed message
                    let alert = UIAlertController(
                        title: "Connection Error",
                        message: "Failed to setup conversation: \(error.localizedDescription)\n\nUser: \(self.user.id)\nAuthenticated: \(SupabaseService.shared.isAuthenticated)",
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
                // Check if this is a local-only conversation
                let isLocalConversation = user.isAI || match.id.hasPrefix("local_match_")

                // 1. Send user message to Supabase (skip for local conversations)
                if !isLocalConversation {
                    try await SupabaseService.shared.sendMessage(
                        conversationId: conversationId,
                        receiverId: user.id,
                        text: text,
                        language: conversationLearningLanguage.name
                    )
                    print("✅ User message sent to Supabase")
                } else {
                    print("✅ Local conversation (no Supabase sync)")
                }

                // 2. Generate AI response using Scoring model
                await generateAIResponse(to: text, conversationId: conversationId)
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }

    private func generateAIResponse(to userMessage: String, conversationId: String) async {
        do {
            // Check if chatting with AI bot - use conversational prompt
            let aiResponse: String
            if user.isAI {
                // Generate natural conversational response for AI practice partners
                aiResponse = try await generateConversationalResponse(userMessage: userMessage)
            } else {
                // Use the Scoring model for grammar-focused feedback (real users)
                aiResponse = try await AIConfigurationManager.shared.scoreText(
                    text: userMessage,
                    learningLanguage: conversationLearningLanguage.name,
                    nativeLanguage: currentUserNativeLanguage.name
                )
            }

            // Send AI response to Supabase (skip for local conversations)
            let isLocalConversation = user.isAI || match.id.hasPrefix("local_match_")

            if !isLocalConversation {
                guard let currentUserId = SupabaseService.shared.currentUserId else { return }
                try await SupabaseService.shared.sendMessageAs(
                    senderId: user.id,
                    conversationId: conversationId,
                    receiverId: currentUserId.uuidString,
                    text: aiResponse,
                    language: conversationLearningLanguage.name
                )
                print("✅ AI response sent to Supabase (as \(user.firstName))")
            } else {
                print("✅ Local conversation - response generated locally")
            }

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

    /// Generate a natural conversational response for AI practice partners
    private func generateConversationalResponse(userMessage: String) async throws -> String {
        // Build conversation history for context (last 5 messages)
        let recentMessages = messages.suffix(5)
        var conversationHistory = ""
        for msg in recentMessages {
            let speaker = msg.isSentByCurrentUser ? "Student" : user.firstName
            conversationHistory += "\(speaker): \(msg.text)\n"
        }

        // Create conversational prompt
        let systemPrompt = """
        You are \(user.firstName), a friendly and patient native \(conversationLearningLanguage.name) speaker helping someone learn your language.

        IMPORTANT: You MUST respond ONLY in \(conversationLearningLanguage.name). Never use English or any other language in your response.

        Your role:
        - Have natural, engaging conversations in \(conversationLearningLanguage.name)
        - Adjust your language level to match the student's proficiency
        - Use common expressions and natural phrasing
        - Keep responses concise (1-3 sentences)
        - Be encouraging and supportive
        - If the student makes an error, gently model the correct form in your response without explicitly correcting

        Context: You are chatting with a language learner who wants to practice \(conversationLearningLanguage.name).

        Conversation so far:
        \(conversationHistory)

        Respond naturally to continue the conversation.
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userMessage)
        ]

        // Use the translation model if available, otherwise use a default model
        let modelId: String
        if let config = AIConfigurationManager.shared.getConfiguration(for: .translation) {
            modelId = config.modelId
        } else {
            // Fallback to a capable model
            modelId = "anthropic/claude-3.5-sonnet"
        }

        let response = try await OpenRouterService.shared.sendChatCompletion(
            model: modelId,
            messages: messages,
            temperature: 0.8,  // Higher temperature for more natural, varied responses
            maxTokens: 150
        )

        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "ChatViewController", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty response from AI"])
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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