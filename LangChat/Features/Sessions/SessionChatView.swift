import UIKit

class SessionChatView: UIView {

    // MARK: - Properties
    private let sessionId: String
    private var messages: [SessionMessage] = []

    // MARK: - UI
    private let tableView = UITableView()
    private let inputBar = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    // MARK: - Init
    init(sessionId: String) {
        self.sessionId = sessionId
        super.init(frame: .zero)
        setupViews()
        loadMessages()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .systemBackground

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SessionMessageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        // Input bar
        inputBar.backgroundColor = .secondarySystemBackground
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputBar)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(separator)

        textField.placeholder = "session_chat_placeholder".localized
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 15)
        textField.returnKeyType = .send
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(textField)

        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(sendButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 52),

            separator.topAnchor.constraint(equalTo: inputBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            textField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            textField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 36),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    // MARK: - Data

    private func loadMessages() {
        Task {
            if let messages = try? await SessionService.shared.getSessionMessages(sessionId: sessionId) {
                await MainActor.run {
                    self.messages = messages
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }
        }
    }

    func addMessage(_ message: SessionMessage) {
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        sendMessage()
    }

    private func sendMessage() {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let detectedLang = Language.detect(from: text)?.name ?? "Unknown"
        textField.text = ""

        Task {
            try? await SessionService.shared.sendMessage(
                sessionId: sessionId,
                text: text,
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionMessageCell", for: indexPath)
        let message = messages[indexPath.row]

        let currentUserId = SupabaseService.shared.currentUserId?.uuidString ?? ""
        let isMe = message.senderId == currentUserId
        let senderName = message.senderName ?? (isMe ? "You" : "User")

        var content = cell.defaultContentConfiguration()
        content.text = message.originalText
        content.secondaryText = senderName
        content.textProperties.font = .systemFont(ofSize: 15)
        content.secondaryTextProperties.font = .systemFont(ofSize: 12)
        content.secondaryTextProperties.color = .secondaryLabel

        if isMe {
            content.textProperties.color = .systemBlue
        }

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SessionChatView: UITableViewDelegate {}

// MARK: - UITextFieldDelegate
extension SessionChatView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
