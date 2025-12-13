import UIKit

class FeatureRequestViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let textView = UITextView()
    private let characterCountLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    private let maxCharacters = 1000
    private let minCharacters = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupKeyboardHandling()
    }

    private func setupViews() {
        title = "Request a Feature"
        view.backgroundColor = .systemBackground

        // Navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        // Scroll view setup
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        titleLabel.text = "What feature would you like to see?"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)

        // Description label
        descriptionLabel.text = "Tell us about a feature that would improve your language learning experience. We read every suggestion!"
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)

        // Text view for feature description
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        contentView.addSubview(textView)

        // Character count label
        characterCountLabel.text = "0/\(maxCharacters)"
        characterCountLabel.font = .systemFont(ofSize: 12)
        characterCountLabel.textColor = .secondaryLabel
        characterCountLabel.textAlignment = .right
        contentView.addSubview(characterCountLabel)

        // Submit button
        submitButton.setTitle("Submit Feature Request", for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        submitButton.layer.cornerRadius = 12
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.isEnabled = false
        contentView.addSubview(submitButton)

        // Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),

            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),

            submitButton.topAnchor.constraint(equalTo: characterCountLabel.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupKeyboardHandling() {
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

        // Tap to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets.bottom = keyboardFrame.height
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func submitTapped() {
        guard let message = textView.text, message.count >= minCharacters else {
            showAlert(title: "Too Short", message: "Please write at least \(minCharacters) characters describing the feature.")
            return
        }

        submitButton.isEnabled = false
        submitButton.setTitle("Submitting...", for: .normal)

        Task {
            do {
                try await SupabaseService.shared.submitFeedback(
                    type: "feature_request",
                    message: message
                )
                await MainActor.run {
                    self.showSuccessAndDismiss()
                }
            } catch {
                print("Error submitting feature request: \(error)")
                await MainActor.run {
                    self.submitButton.isEnabled = true
                    self.submitButton.setTitle("Submit Feature Request", for: .normal)
                    self.showAlert(title: "Error", message: "Failed to submit your feature request. Please try again.")
                }
            }
        }
    }

    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Thank You!",
            message: "Your feature request has been submitted. We appreciate your feedback!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateSubmitButtonState() {
        let characterCount = textView.text.count
        submitButton.isEnabled = characterCount >= minCharacters && characterCount <= maxCharacters
        submitButton.backgroundColor = submitButton.isEnabled ? .systemBlue : .systemGray4
    }
}

// MARK: - UITextViewDelegate
extension FeatureRequestViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let characterCount = textView.text.count
        characterCountLabel.text = "\(characterCount)/\(maxCharacters)"

        // Update color based on limit
        if characterCount > maxCharacters {
            characterCountLabel.textColor = .systemRed
        } else if characterCount >= minCharacters {
            characterCountLabel.textColor = .systemGreen
        } else {
            characterCountLabel.textColor = .secondaryLabel
        }

        updateSubmitButtonState()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= maxCharacters
    }
}
