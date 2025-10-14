import UIKit

class EmailInputViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let emailTextField = UITextField()
    private let privacyLabel = UILabel()

    // MARK: - Lifecycle
    override func configure() {
        step = .email
        setTitle("What's your email?",
                subtitle: "We'll use this to secure your account and help you recover access")
        setupEmailInput()
    }

    // MARK: - Setup
    private func setupEmailInput() {
        // Email text field
        emailTextField.placeholder = "Email address"
        emailTextField.font = .systemFont(ofSize: 18, weight: .regular)
        emailTextField.textColor = .label
        emailTextField.keyboardType = .emailAddress
        emailTextField.textContentType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .done
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.systemGray4.cgColor
        emailTextField.layer.cornerRadius = 12
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        emailTextField.leftViewMode = .always
        emailTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        contentView.addSubview(emailTextField)

        // Privacy label
        privacyLabel.text = "Your email will not be shared with other users"
        privacyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        privacyLabel.textColor = .tertiaryLabel
        privacyLabel.textAlignment = .center
        privacyLabel.numberOfLines = 0
        contentView.addSubview(privacyLabel)

        // Layout
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Email text field
            emailTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

            // Privacy label
            privacyLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 24),
            privacyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            privacyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Auto-focus
        emailTextField.becomeFirstResponder()
    }

    // MARK: - Actions
    @objc private func emailChanged() {
        let email = emailTextField.text ?? ""
        updateContinueButton(enabled: isValidEmail(email))
    }

    override func continueButtonTapped() {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        delegate?.didCompleteStep(withData: email)
    }
}

// MARK: - UITextFieldDelegate
extension EmailInputViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if continueButton.isEnabled {
            continueButtonTapped()
        }
        return true
    }
}
