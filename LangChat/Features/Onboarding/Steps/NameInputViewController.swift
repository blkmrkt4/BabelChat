import UIKit

class NameInputViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()

    // MARK: - Lifecycle
    override func configure() {
        step = .name
        setTitle("What's your name?",
                subtitle: "This is how you'll appear to language partners")
        setupNameInputs()
    }

    // MARK: - Setup
    private func setupNameInputs() {
        // First name
        setupTextField(firstNameTextField, placeholder: "First name")
        contentView.addSubview(firstNameTextField)

        // Last name
        setupTextField(lastNameTextField, placeholder: "Last name")
        contentView.addSubview(lastNameTextField)

        // Layout
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // First name
            firstNameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 56),

            // Last name
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 16),
            lastNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            lastNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Auto-focus
        firstNameTextField.becomeFirstResponder()
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .label
        textField.textContentType = placeholder == "First name" ? .givenName : .familyName
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = placeholder == "First name" ? .next : .done
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }

    // MARK: - Actions
    @objc private func textFieldChanged() {
        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updateContinueButton(enabled: !firstName.isEmpty && !lastName.isEmpty)
    }

    override func continueButtonTapped() {
        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        delegate?.didCompleteStep(withData: (firstName, lastName))
    }
}

// MARK: - UITextFieldDelegate
extension NameInputViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if continueButton.isEnabled {
                continueButtonTapped()
            }
        }
        return true
    }
}