import UIKit

class BioViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let characterCountLabel = UILabel()
    private let promptsContainer = UIView()
    private let promptButtons: [UIButton] = []

    // MARK: - Properties
    private let maxCharacters = 500
    private let prompts = [
        "What's your language learning story?",
        "What motivates you to learn languages?",
        "Share a fun fact about yourself",
        "What are your hobbies and interests?"
    ]

    // MARK: - Lifecycle
    override func configure() {
        step = .bio
        setTitle("Tell us about yourself",
                subtitle: "Help others get to know you better")
        setupViews()
        setupKeyboardObservers()
    }

    // MARK: - Setup
    private func setupViews() {
        // Prompts container
        promptsContainer.backgroundColor = .secondarySystemBackground
        promptsContainer.layer.cornerRadius = 12
        contentView.addSubview(promptsContainer)

        // Prompts label
        let promptsLabel = UILabel()
        promptsLabel.text = "Need inspiration? Try these prompts:"
        promptsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        promptsLabel.textColor = .secondaryLabel
        promptsContainer.addSubview(promptsLabel)

        // Prompt buttons stack
        let promptsStack = UIStackView()
        promptsStack.axis = .vertical
        promptsStack.spacing = 8
        promptsStack.distribution = .fillEqually

        for prompt in prompts {
            let button = UIButton(type: .system)
            button.setTitle(prompt, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(promptTapped), for: .touchUpInside)
            promptsStack.addArrangedSubview(button)
        }

        promptsContainer.addSubview(promptsStack)

        // Text view
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        contentView.addSubview(textView)

        // Placeholder
        placeholderLabel.text = "Write something about yourself..."
        placeholderLabel.font = .systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)

        // Character count
        characterCountLabel.text = "0/\(maxCharacters)"
        characterCountLabel.font = .systemFont(ofSize: 12, weight: .regular)
        characterCountLabel.textColor = .secondaryLabel
        characterCountLabel.textAlignment = .right
        contentView.addSubview(characterCountLabel)

        // Layout
        promptsContainer.translatesAutoresizingMaskIntoConstraints = false
        promptsLabel.translatesAutoresizingMaskIntoConstraints = false
        promptsStack.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Prompts container
            promptsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            promptsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            promptsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Prompts label
            promptsLabel.topAnchor.constraint(equalTo: promptsContainer.topAnchor, constant: 16),
            promptsLabel.leadingAnchor.constraint(equalTo: promptsContainer.leadingAnchor, constant: 16),
            promptsLabel.trailingAnchor.constraint(equalTo: promptsContainer.trailingAnchor, constant: -16),

            // Prompts stack
            promptsStack.topAnchor.constraint(equalTo: promptsLabel.bottomAnchor, constant: 12),
            promptsStack.leadingAnchor.constraint(equalTo: promptsContainer.leadingAnchor, constant: 16),
            promptsStack.trailingAnchor.constraint(equalTo: promptsContainer.trailingAnchor, constant: -16),
            promptsStack.bottomAnchor.constraint(equalTo: promptsContainer.bottomAnchor, constant: -16),

            // Text view
            textView.topAnchor.constraint(equalTo: promptsContainer.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 150),

            // Placeholder
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -16),

            // Character count
            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Initially disable continue button
        updateContinueButton(enabled: false)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Actions
    @objc private func promptTapped(_ sender: UIButton) {
        guard let prompt = sender.titleLabel?.text else { return }

        if textView.text.isEmpty {
            textView.text = prompt + " "
        } else {
            textView.text += "\n\n" + prompt + " "
        }

        updatePlaceholder()
        updateCharacterCount()
        textView.becomeFirstResponder()

        // Move cursor to end
        if let endPosition = textView.position(from: textView.endOfDocument, offset: 0) {
            textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
        }
    }

    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        // Keyboard handling is done by BaseOnboardingViewController
        // Just ensure text view is visible
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        // Keyboard handling is done by BaseOnboardingViewController
    }

    private func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateCharacterCount() {
        let count = textView.text.count
        characterCountLabel.text = "\(count)/\(maxCharacters)"

        if count > Int(Double(maxCharacters) * 0.9) {
            characterCountLabel.textColor = .systemOrange
        } else {
            characterCountLabel.textColor = .secondaryLabel
        }

        // Enable continue if there's at least 20 characters
        updateContinueButton(enabled: count >= 20)
    }

    override func continueButtonTapped() {
        let bio = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        delegate?.didCompleteStep(withData: bio)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextViewDelegate
extension BioViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateCharacterCount()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        return updatedText.count <= maxCharacters
    }
}
