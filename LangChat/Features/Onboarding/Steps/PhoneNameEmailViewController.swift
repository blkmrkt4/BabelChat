import UIKit

class PhoneNameEmailViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // Phone section
    private let phoneLabel = UILabel()
    private let countryCodeButton = UIButton(type: .system)
    private let phoneTextField = UITextField()
    private let phoneUnderlineView = UIView()

    // Name section
    private let nameLabel = UILabel()
    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()

    // Email section
    private let emailLabel = UILabel()
    private let emailTextField = UITextField()
    private let privacyLabel = UILabel()

    // MARK: - Properties
    private var selectedCountryCode = "+1" // Default to US

    // MARK: - Lifecycle
    override func configure() {
        step = .phoneNumber  // Note: This combined screen is deprecated, use separate screens instead
        setTitle("Let's get started",
                subtitle: "We'll need a few details to create your account")
        setupScrollableContent()
    }

    // MARK: - Setup
    private func setupScrollableContent() {
        // Add scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        contentView.addSubview(scrollView)

        // Add stack view
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .fill
        scrollView.addSubview(stackView)

        // Setup sections
        setupPhoneSection()
        setupNameSection()
        setupEmailSection()

        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Stack view
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Auto-focus first field
        phoneTextField.becomeFirstResponder()
    }

    private func setupPhoneSection() {
        let phoneContainer = UIView()

        // Section label
        phoneLabel.text = "Phone Number"
        phoneLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        phoneLabel.textColor = .secondaryLabel
        phoneContainer.addSubview(phoneLabel)

        // Country code button
        countryCodeButton.setTitle("\(selectedCountryCode) 🇺🇸", for: .normal)
        countryCodeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        countryCodeButton.setTitleColor(.label, for: .normal)
        countryCodeButton.layer.borderWidth = 1
        countryCodeButton.layer.borderColor = UIColor.systemGray4.cgColor
        countryCodeButton.layer.cornerRadius = 12
        countryCodeButton.addTarget(self, action: #selector(countryCodeTapped), for: .touchUpInside)
        phoneContainer.addSubview(countryCodeButton)

        // Phone text field
        phoneTextField.placeholder = "Phone number"
        phoneTextField.font = .systemFont(ofSize: 18, weight: .regular)
        phoneTextField.textColor = .label
        phoneTextField.keyboardType = .phonePad
        phoneTextField.textContentType = .telephoneNumber
        phoneTextField.borderStyle = .none
        phoneTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        phoneTextField.delegate = self
        phoneContainer.addSubview(phoneTextField)

        // Underline
        phoneUnderlineView.backgroundColor = .systemGray4
        phoneContainer.addSubview(phoneUnderlineView)

        // Layout
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        countryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneUnderlineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            phoneLabel.topAnchor.constraint(equalTo: phoneContainer.topAnchor),
            phoneLabel.leadingAnchor.constraint(equalTo: phoneContainer.leadingAnchor),
            phoneLabel.trailingAnchor.constraint(equalTo: phoneContainer.trailingAnchor),

            countryCodeButton.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 8),
            countryCodeButton.leadingAnchor.constraint(equalTo: phoneContainer.leadingAnchor),
            countryCodeButton.widthAnchor.constraint(equalToConstant: 100),
            countryCodeButton.heightAnchor.constraint(equalToConstant: 50),

            phoneTextField.leadingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: 12),
            phoneTextField.trailingAnchor.constraint(equalTo: phoneContainer.trailingAnchor),
            phoneTextField.centerYAnchor.constraint(equalTo: countryCodeButton.centerYAnchor),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),

            phoneUnderlineView.leadingAnchor.constraint(equalTo: phoneTextField.leadingAnchor),
            phoneUnderlineView.trailingAnchor.constraint(equalTo: phoneTextField.trailingAnchor),
            phoneUnderlineView.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 2),
            phoneUnderlineView.heightAnchor.constraint(equalToConstant: 1),
            phoneUnderlineView.bottomAnchor.constraint(equalTo: phoneContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(phoneContainer)
    }

    private func setupNameSection() {
        let nameContainer = UIView()

        // Section label
        nameLabel.text = "Full Name"
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameContainer.addSubview(nameLabel)

        // First name
        setupTextField(firstNameTextField, placeholder: "First name", contentType: .givenName)
        nameContainer.addSubview(firstNameTextField)

        // Last name
        setupTextField(lastNameTextField, placeholder: "Last name", contentType: .familyName)
        nameContainer.addSubview(lastNameTextField)

        // Layout
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: nameContainer.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor),

            firstNameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            firstNameTextField.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor),
            firstNameTextField.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 56),

            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 12),
            lastNameTextField.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor),
            lastNameTextField.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 56),
            lastNameTextField.bottomAnchor.constraint(equalTo: nameContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(nameContainer)
    }

    private func setupEmailSection() {
        let emailContainer = UIView()

        // Section label
        emailLabel.text = "Email Address"
        emailLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        emailLabel.textColor = .secondaryLabel
        emailContainer.addSubview(emailLabel)

        // Email text field
        emailTextField.placeholder = "your.email@example.com"
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
        emailTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emailContainer.addSubview(emailTextField)

        // Privacy label
        privacyLabel.text = "Your contact information is private and secure"
        privacyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        privacyLabel.textColor = .tertiaryLabel
        privacyLabel.textAlignment = .center
        privacyLabel.numberOfLines = 0
        emailContainer.addSubview(privacyLabel)

        // Layout
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emailLabel.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),

            emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            emailTextField.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 56),

            privacyLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            privacyLabel.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            privacyLabel.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor),
            privacyLabel.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(emailContainer)
    }

    private func setupTextField(_ textField: UITextField, placeholder: String, contentType: UITextContentType) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .label
        textField.textContentType = contentType
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .next
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }

    // MARK: - Actions
    @objc private func countryCodeTapped() {
        let actionSheet = UIAlertController(title: "Select Country Code", message: nil, preferredStyle: .actionSheet)

        let countryCodes = [
            ("+1", "🇺🇸", "United States"),
            ("+1", "🇨🇦", "Canada"),
            ("+44", "🇬🇧", "United Kingdom"),
            ("+34", "🇪🇸", "Spain"),
            ("+33", "🇫🇷", "France"),
            ("+49", "🇩🇪", "Germany"),
            ("+39", "🇮🇹", "Italy"),
            ("+81", "🇯🇵", "Japan"),
            ("+82", "🇰🇷", "South Korea"),
            ("+86", "🇨🇳", "China"),
            ("+91", "🇮🇳", "India"),
            ("+52", "🇲🇽", "Mexico"),
            ("+55", "🇧🇷", "Brazil")
        ]

        for (code, flag, country) in countryCodes {
            actionSheet.addAction(UIAlertAction(title: "\(flag) \(country) (\(code))", style: .default) { _ in
                self.selectedCountryCode = code
                self.countryCodeButton.setTitle("\(code) \(flag)", for: .normal)
                self.textFieldChanged()
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = countryCodeButton
            popover.sourceRect = countryCodeButton.bounds
        }

        present(actionSheet, animated: true)
    }

    @objc private func textFieldChanged() {
        // Validate all fields
        let phoneNumber = phoneTextField.text ?? ""
        let cleanPhone = phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let digitCount = cleanPhone.filter { $0.isNumber }.count
        let minDigits = selectedCountryCode == "+1" ? 10 : 7
        let isPhoneValid = digitCount >= minDigits

        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let isNameValid = !firstName.isEmpty && !lastName.isEmpty
        let isEmailValid = isValidEmail(email)

        updateContinueButton(enabled: isPhoneValid && isNameValid && isEmailValid)
    }

    override func continueButtonTapped() {
        let phoneNumber = phoneTextField.text ?? ""
        let cleanPhone = phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let fullPhone = selectedCountryCode + cleanPhone

        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        print("Continue button tapped - Phone: \(fullPhone), Name: \(firstName) \(lastName), Email: \(email)")
        delegate?.didCompleteStep(withData: (fullPhone, firstName, lastName, email))
    }
}

// MARK: - UITextFieldDelegate
extension PhoneNameEmailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Phone field - only allow numbers
        if textField == phoneTextField {
            // Get current text safely
            let currentText = textField.text ?? ""

            // Validate range before using it (critical for physical devices)
            guard range.location >= 0,
                  range.location <= currentText.count,
                  range.location + range.length <= currentText.count else {
                return false
            }

            if !string.isEmpty && !string.allSatisfy({ $0.isNumber || $0 == " " || $0 == "-" }) {
                return false
            }

            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            let cleanText = newText.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")

            return cleanText.count <= 15
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            emailTextField.resignFirstResponder()
            if continueButton.isEnabled {
                continueButtonTapped()
            }
        }
        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == phoneTextField {
            textFieldChanged()
        }
    }
}
