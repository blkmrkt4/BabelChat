import UIKit

class NameInputViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()

    // MARK: - Lifecycle
    override func configure() {
        step = .name
        setTitle("onboarding_name_title".localized)
        setupNameInputs()
    }

    // MARK: - Setup
    private func setupNameInputs() {
        // First name
        setupTextField(firstNameTextField, placeholder: "common_first_name".localized, isFirstName: true)
        contentView.addSubview(firstNameTextField)

        // Last name
        setupTextField(lastNameTextField, placeholder: "common_last_name".localized, isFirstName: false)
        contentView.addSubview(lastNameTextField)

        // Pre-fill with Apple-provided name if available (fallback in case skip logic didn't trigger)
        if let appleFirstName = UserDefaults.standard.string(forKey: "appleProvidedFirstName"), !appleFirstName.isEmpty {
            firstNameTextField.text = appleFirstName
            lastNameTextField.text = UserDefaults.standard.string(forKey: "appleProvidedLastName") ?? ""
        }

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
            lastNameTextField.heightAnchor.constraint(equalToConstant: 56),
            lastNameTextField.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Auto-focus
        firstNameTextField.becomeFirstResponder()
    }

    private func setupTextField(_ textField: UITextField, placeholder: String, isFirstName: Bool) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .label
        textField.textContentType = isFirstName ? .givenName : .familyName
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = isFirstName ? .next : .done
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
        print("📝 NameInputViewController: continueButtonTapped called")

        // Dismiss keyboard first to prevent animation conflicts
        view.endEditing(true)

        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        print("📝 NameInputViewController: Calling delegate with name: \(firstName) \(lastName)")

        // Small delay to let keyboard dismiss animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            print("📝 NameInputViewController: Dispatching to delegate")
            self?.delegate?.didCompleteStep(withData: (firstName, lastName))
        }
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