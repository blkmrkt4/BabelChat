import UIKit

class ChatViewController: UIViewController {

    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let museButton = UIButton(type: .custom)
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

    // Subscription tier for TTS voice quality
    private var currentSubscriptionTier: SubscriptionTier = .free

    init(user: User, match: Match) {
        self.user = user
        self.match = match

        // Determine language context
        // The conversation learning language is the match's native language (what user is learning)
        self.conversationLearningLanguage = user.nativeLanguage.language

        // Get current user's native language from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            self.currentUserNativeLanguage = decoded.nativeLanguage.language
        } else {
            // Fallback to English if not found
            self.currentUserNativeLanguage = .english
        }

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
        fetchSubscriptionTier() // Get user's subscription tier for TTS
    }

    private func fetchSubscriptionTier() {
        Task {
            do {
                let tier = try await SupabaseService.shared.getCurrentSubscriptionTier()
                await MainActor.run {
                    self.currentSubscriptionTier = tier
                    // Reload visible cells to update their tier
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to fetch subscription tier: \(error)")
                // Default to free tier on error
            }
        }
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
        statusLabel.text = getStatusText()
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = getStatusColor()
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

        // Add tap gesture to show user profile
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        titleView.addGestureRecognizer(tapGesture)
        titleView.isUserInteractionEnabled = true
    }

    @objc private func headerTapped() {
        let detailVC = UserDetailViewController()
        detailVC.user = user
        detailVC.isMatched = true  // Show as matched (hides swipe actions)
        navigationController?.pushViewController(detailVC, animated: true)
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

        // Setup Muse button (AI assistant)
        let museImage = UIImage(named: "MuseChat")?.withRenderingMode(.alwaysOriginal)
        museButton.setImage(museImage, for: .normal)
        museButton.imageView?.contentMode = .scaleAspectFit
        museButton.layer.cornerRadius = 22
        museButton.clipsToBounds = true
        museButton.addTarget(self, action: #selector(museButtonTapped), for: .touchUpInside)
        inputContainerView.addSubview(museButton)

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
        museButton.translatesAutoresizingMaskIntoConstraints = false
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

            museButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 4),
            museButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            museButton.widthAnchor.constraint(equalToConstant: 44),
            museButton.heightAnchor.constraint(equalToConstant: 44),

            inputTextField.leadingAnchor.constraint(equalTo: museButton.trailingAnchor, constant: 8),
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

    @objc private func museButtonTapped() {
        // Show Muse assistant dialog with multi-line text input
        let alertVC = UIViewController()
        alertVC.modalPresentationStyle = .overCurrentContext
        alertVC.modalTransitionStyle = .crossDissolve

        // Dimmed background
        let dimmedView = UIView()
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(dimmedView)

        // Card container
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(cardView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Ask your Muse"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "What would you like to say in \(conversationLearningLanguage.name)?"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        // Text view for multi-line input
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(textView)

        // Placeholder label
        let placeholderLabel = UILabel()
        placeholderLabel.text = "e.g., How do I say 'I love this restaurant'?"
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)

        // Button stack
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(buttonStack)

        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 10
        buttonStack.addArrangedSubview(cancelButton)

        // Ask button
        let askButton = UIButton(type: .system)
        askButton.setTitle("Ask", for: .normal)
        askButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        askButton.backgroundColor = .systemBlue
        askButton.setTitleColor(.white, for: .normal)
        askButton.layer.cornerRadius = 10
        buttonStack.addArrangedSubview(askButton)

        // Constraints
        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: alertVC.view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor),

            cardView.centerYAnchor.constraint(equalTo: alertVC.view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            textView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 80),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -12),

            buttonStack.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Handle placeholder visibility
        museDialogObserver = NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: textView, queue: .main) { _ in
            placeholderLabel.isHidden = !textView.text.isEmpty
        }

        // Button actions
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.dismissMuseDialog()
        }, for: .touchUpInside)

        askButton.addAction(UIAction { [weak self] _ in
            guard let self = self, !textView.text.isEmpty else { return }
            // Capture text before dismissing
            let query = textView.text ?? ""
            self.dismissMuseDialog()
            // Wait for dismissal to complete slightly or just fire (dismiss is animated)
            // Ideally we'd pass a completion block to dismissMuseDialog, but for now this works as askMuse presents a new alert
            self.askMuse(query: query)
        }, for: .touchUpInside)

        // Dismiss on background tap
        let tapGesture = UITapGestureRecognizer(target: alertVC, action: nil)
        tapGesture.addTarget(self, action: #selector(dismissMuseDialog))
        dimmedView.addGestureRecognizer(tapGesture)

        // Store reference for dismissal
        self.museDialogVC = alertVC

        present(alertVC, animated: true) {
            textView.becomeFirstResponder()
        }
    }

    private var museDialogVC: UIViewController?
    private var museDialogObserver: NSObjectProtocol?

    @objc private func dismissMuseDialog() {
        if let observer = museDialogObserver {
            NotificationCenter.default.removeObserver(observer)
            museDialogObserver = nil
        }
        museDialogVC?.dismiss(animated: true)
        museDialogVC = nil
    }

    private func askMuse(query: String) {
        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: "Muse is thinking...",
            message: nil,
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        Task {
            do {
                // Get chatting configuration
                let config = try await AIConfigurationManager.shared.getConfiguration(for: .chatting)

                let systemPrompt = """
                You are a helpful language assistant called Muse. The user is practicing \(conversationLearningLanguage.name) and needs help composing a message.

                Respond ONLY with the phrase they need in \(conversationLearningLanguage.name). Do not add explanations, translations, or extra text unless specifically asked.
                Keep it natural and conversational.
                """

                let chatMessages = [
                    ChatMessage(role: "system", content: systemPrompt),
                    ChatMessage(role: "user", content: query)
                ]

                let response = try await OpenRouterService.shared.sendChatCompletion(
                    model: config.modelId,
                    messages: chatMessages,
                    temperature: Double(config.temperature),
                    maxTokens: config.maxTokens
                )

                guard let content = response.choices?.first?.content else {
                    throw NSError(domain: "MuseError", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Empty response from Muse"])
                }

                let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showMuseResponse(cleanedResponse)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showMuseError(error)
                    }
                }
            }
        }
    }

    private func showMuseResponse(_ response: String) {
        let alert = UIAlertController(
            title: "Muse suggests:",
            message: response,
            preferredStyle: .alert
        )

        let useAction = UIAlertAction(title: "Use This", style: .default) { [weak self] _ in
            // Insert the response into the text field
            if let currentText = self?.inputTextField.text, !currentText.isEmpty {
                self?.inputTextField.text = currentText + " " + response
            } else {
                self?.inputTextField.text = response
            }
            self?.sendButton.isEnabled = true
        }

        let copyAction = UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.string = response
        }

        alert.addAction(useAction)
        alert.addAction(copyAction)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        present(alert, animated: true)
    }

    private func showMuseError(_ error: Error) {
        let alert = UIAlertController(
            title: "Muse couldn't help",
            message: "Please try again. Error: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

        // Send to Supabase and generate AI response (only for AI bots)
        Task {
            // Update user's last_active timestamp
            await SupabaseService.shared.updateLastActive()

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

                // 2. Generate AI response ONLY for AI bots (Muses)
                // Real users will respond on their own - no auto-response
                if user.isAI {
                    // Track Muse interaction for analytics
                    await SupabaseService.shared.trackMuseInteraction(
                        museId: user.id,
                        museName: user.firstName,
                        language: user.nativeLanguage.language.name
                    )

                    await generateAIResponse(to: text, conversationId: conversationId)
                } else {
                    print("📤 Message sent to real user - waiting for their response")
                }
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }

    /// Generate AI response for Muse bots only
    private func generateAIResponse(to userMessage: String, conversationId: String) async {
        do {
            // Generate natural conversational response for AI practice partners (Muses)
            let aiResponse = try await generateConversationalResponse(userMessage: userMessage)

            // AI bot conversations are local-only (no Supabase sync)
            print("✅ Muse response generated locally")

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
            print("❌ Failed to generate Muse response: \(error)")
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

        // Get chatting configuration from Supabase
        let config: AIConfig
        do {
            config = try await AIConfigurationManager.shared.getConfiguration(for: .chatting)
        } catch {
            // Fallback to translation config if chatting not configured
            print("⚠️ Chatting config not found, falling back to translation config")
            config = try await AIConfigurationManager.shared.getConfiguration(for: .translation)
        }

        // Process prompt template with variables
        let systemPrompt = config.promptTemplate
            .replacingOccurrences(of: "{bot_name}", with: user.firstName)
            .replacingOccurrences(of: "{language}", with: conversationLearningLanguage.name)
            .replacingOccurrences(of: "{conversation_history}", with: conversationHistory)

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userMessage)
        ]

        // Try primary model, then fallbacks
        let modelIds = [
            config.modelId,
            config.fallbackModel1Id,
            config.fallbackModel2Id,
            config.fallbackModel3Id
        ].compactMap { $0 }.filter { !$0.isEmpty }

        var lastError: Error?

        for (index, modelId) in modelIds.enumerated() {
            do {
                print("🤖 Chatting with model \(index == 0 ? "primary" : "fallback \(index)"): \(modelId)")

                let response = try await OpenRouterService.shared.sendChatCompletion(
                    model: modelId,
                    messages: messages,
                    temperature: Double(config.temperature),
                    maxTokens: config.maxTokens
                )

                guard let content = response.choices?.first?.content else {
                    throw NSError(domain: "ChatViewController", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Empty response from AI"])
                }

                return content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } catch {
                lastError = error
                print("❌ Model \(modelId) failed: \(error.localizedDescription)")

                // If not the last model, try next fallback
                if index < modelIds.count - 1 {
                    print("⚠️ Trying fallback model...")
                    continue
                }
            }
        }

        // All models failed
        throw lastError ?? NSError(domain: "ChatViewController", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "All chatting models failed"])
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

    // MARK: - Status Helpers

    private func getStatusText() -> String {
        // AI Muses are always active
        if user.isAI {
            return "Your Muse is Active Now"
        }

        // Real users - check their online status
        if user.isOnline {
            return "Active now"
        } else {
            return "Offline"
        }
    }

    private func getStatusColor() -> UIColor {
        if user.isAI || user.isOnline {
            return .systemGreen
        } else {
            return .secondaryLabel
        }
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwipeableMessageCell", for: indexPath) as? SwipeableMessageCell else {
            return UITableViewCell()
        }
        let granularity = UserDefaults.standard.integer(forKey: "granularityLevel")
        cell.delegate = self
        cell.setSubscriptionTier(currentSubscriptionTier) // Set tier for TTS voice quality
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

    func cell(_ cell: SwipeableMessageCell, didRequestDeleteMessage message: Message) {
        let alert = UIAlertController(
            title: "Delete Message",
            message: "Are you sure you want to delete this message?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // Remove from array
            if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                self.messages.remove(at: index)

                // Update table
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.deleteRows(at: [indexPath], with: .fade)

                // Save messages
                self.saveMessages()

                // TODO: Delete from Supabase when real-time is implemented
            }
        })

        present(alert, animated: true)
    }

    func cell(_ cell: SwipeableMessageCell, didRequestReplyToMessage message: Message) {
        // Set placeholder text with quote
        let quotedText = "Replying to: \"\(message.text)\"\n"
        inputTextField.text = quotedText

        // Move cursor to end
        inputTextField.becomeFirstResponder()

        // Move cursor after the quote
        if let newPosition = inputTextField.position(from: inputTextField.endOfDocument, offset: 0) {
            inputTextField.selectedTextRange = inputTextField.textRange(from: newPosition, to: newPosition)
        }
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
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