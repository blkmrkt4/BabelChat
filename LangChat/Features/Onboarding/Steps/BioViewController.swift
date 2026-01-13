import UIKit

class BioViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let characterCountLabel = UILabel()
    private let promptsHeader = UIButton(type: .system)
    private let promptsContainer = UIView()
    private let promptsStack = UIStackView()
    private var promptsHeightConstraint: NSLayoutConstraint!
    private let skipLabel = UILabel()

    // MARK: - Properties
    private let maxCharacters = 500
    private var isPromptsExpanded = false
    private let prompts = [
        "What's your language learning story?",
        "What motivates you to learn?",
        "What are your hobbies?",
        "Describe yourself in 3 words",
        "Share a fun fact about yourself"
    ]

    // MARK: - Lifecycle
    override func configure() {
        step = .bio
        setTitle("About you?")
        setupViews()
        setupKeyboardToolbar()
    }

    // MARK: - Setup
    private func setupViews() {
        // Text view - AT THE TOP
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .white
        textView.backgroundColor = .white.withAlphaComponent(0.08)
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = self
        contentView.addSubview(textView)

        // Placeholder
        placeholderLabel.text = "Share your story, interests, personality..."
        placeholderLabel.font = .systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = .white.withAlphaComponent(0.4)
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)

        // Character count
        characterCountLabel.text = "0/\(maxCharacters)"
        characterCountLabel.font = .systemFont(ofSize: 12, weight: .regular)
        characterCountLabel.textColor = .white.withAlphaComponent(0.6)
        characterCountLabel.textAlignment = .right
        contentView.addSubview(characterCountLabel)

        // Prompts header (expandable)
        promptsHeader.setTitle("💡 Need inspiration? Tap for prompts", for: .normal)
        promptsHeader.setTitleColor(.white.withAlphaComponent(0.7), for: .normal)
        promptsHeader.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        promptsHeader.contentHorizontalAlignment = .left
        promptsHeader.addTarget(self, action: #selector(togglePrompts), for: .touchUpInside)
        contentView.addSubview(promptsHeader)

        // Chevron indicator
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .white.withAlphaComponent(0.5)
        chevron.tag = 999
        promptsHeader.addSubview(chevron)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: promptsHeader.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: promptsHeader.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 12)
        ])

        // Prompts container (collapsible)
        promptsContainer.backgroundColor = .white.withAlphaComponent(0.05)
        promptsContainer.layer.cornerRadius = 12
        promptsContainer.clipsToBounds = true
        promptsContainer.alpha = 0
        contentView.addSubview(promptsContainer)

        // Prompts stack
        promptsStack.axis = .vertical
        promptsStack.spacing = 4
        promptsStack.distribution = .fillEqually
        promptsContainer.addSubview(promptsStack)

        for prompt in prompts {
            let button = UIButton(type: .system)
            button.setTitle("• " + prompt, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
            button.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(promptTapped), for: .touchUpInside)
            promptsStack.addArrangedSubview(button)
        }

        // Skip label
        skipLabel.text = "This field is optional - feel free to skip"
        skipLabel.font = .systemFont(ofSize: 13, weight: .regular)
        skipLabel.textColor = .white.withAlphaComponent(0.5)
        skipLabel.textAlignment = .center
        contentView.addSubview(skipLabel)

        // Layout
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        promptsHeader.translatesAutoresizingMaskIntoConstraints = false
        promptsContainer.translatesAutoresizingMaskIntoConstraints = false
        promptsStack.translatesAutoresizingMaskIntoConstraints = false
        skipLabel.translatesAutoresizingMaskIntoConstraints = false

        promptsHeightConstraint = promptsContainer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Text view - AT THE TOP
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 140),

            // Placeholder
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 21),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -21),

            // Character count
            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Prompts header
            promptsHeader.topAnchor.constraint(equalTo: characterCountLabel.bottomAnchor, constant: 16),
            promptsHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            promptsHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            promptsHeader.heightAnchor.constraint(equalToConstant: 32),

            // Prompts container (expandable)
            promptsContainer.topAnchor.constraint(equalTo: promptsHeader.bottomAnchor, constant: 8),
            promptsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            promptsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            promptsHeightConstraint,

            // Prompts stack
            promptsStack.topAnchor.constraint(equalTo: promptsContainer.topAnchor, constant: 12),
            promptsStack.leadingAnchor.constraint(equalTo: promptsContainer.leadingAnchor, constant: 12),
            promptsStack.trailingAnchor.constraint(equalTo: promptsContainer.trailingAnchor, constant: -12),
            promptsStack.bottomAnchor.constraint(equalTo: promptsContainer.bottomAnchor, constant: -12),

            // Skip label
            skipLabel.topAnchor.constraint(equalTo: promptsContainer.bottomAnchor, constant: 20),
            skipLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skipLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Bio is OPTIONAL - enable continue button immediately
        updateContinueButton(enabled: true)
    }

    private func setupKeyboardToolbar() {
        // Create toolbar with "Done" button to dismiss keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = .systemBlue

        // Flexible space to push button to the right
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Lightbulb button to show prompts (dismisses keyboard + expands prompts)
        let promptsButton = UIBarButtonItem(
            image: UIImage(systemName: "lightbulb"),
            style: .plain,
            target: self,
            action: #selector(showPromptsFromToolbar)
        )
        promptsButton.tintColor = .systemYellow

        // Done button to dismiss keyboard
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )

        toolbar.items = [promptsButton, flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    @objc private func showPromptsFromToolbar() {
        // Dismiss keyboard first
        textView.resignFirstResponder()

        // Expand prompts if not already expanded
        if !isPromptsExpanded {
            // Small delay to let keyboard dismiss animation start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.togglePrompts()
            }
        }
    }
    @objc private func togglePrompts() {
        isPromptsExpanded.toggle()

        // Animate expansion/collapse
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            if self.isPromptsExpanded {
                self.promptsHeightConstraint.constant = CGFloat(self.prompts.count * 32 + 24)
                self.promptsContainer.alpha = 1
                // Rotate chevron
                if let chevron = self.promptsHeader.viewWithTag(999) {
                    chevron.transform = CGAffineTransform(rotationAngle: .pi)
                }
            } else {
                self.promptsHeightConstraint.constant = 0
                self.promptsContainer.alpha = 0
                // Reset chevron
                if let chevron = self.promptsHeader.viewWithTag(999) {
                    chevron.transform = .identity
                }
            }
            self.view.layoutIfNeeded()
        }
    }

    @objc private func promptTapped(_ sender: UIButton) {
        guard let promptText = sender.titleLabel?.text else { return }
        // Remove the bullet point prefix
        let prompt = promptText.replacingOccurrences(of: "• ", with: "")

        if textView.text.isEmpty {
            textView.text = prompt + " "
        } else {
            textView.text += "\n\n" + prompt + " "
        }

        updatePlaceholder()
        updateCharacterCount()
        textView.becomeFirstResponder()

        // Collapse prompts after selection
        if isPromptsExpanded {
            togglePrompts()
        }

        // Move cursor to end
        if let endPosition = textView.position(from: textView.endOfDocument, offset: 0) {
            textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
        }
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
            characterCountLabel.textColor = .white.withAlphaComponent(0.6)
        }
    }

    override func continueButtonTapped() {
        view.endEditing(true)
        let bio = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.delegate?.didCompleteStep(withData: bio)
        }
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

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Collapse prompts when user starts typing
        if isPromptsExpanded {
            togglePrompts()
        }
        // Hide skip label when editing
        skipLabel.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        // Show skip label again if empty
        skipLabel.isHidden = !textView.text.isEmpty
    }
}
