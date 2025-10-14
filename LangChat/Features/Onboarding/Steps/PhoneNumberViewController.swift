import UIKit

class PhoneNumberViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let phoneTextField = UITextField()
    private let countryCodeButton = UIButton(type: .system)
    private let privacyLabel = UILabel()

    // MARK: - Properties
    private var selectedCountryCode = "+1" // Default to US

    // MARK: - Lifecycle
    override func configure() {
        step = .phoneNumber
        setTitle("What's your phone number?",
                subtitle: "We'll send you a verification code to confirm it's you")
        setupPhoneInput()
    }

    // MARK: - Setup
    private func setupPhoneInput() {
        // Country code button
        countryCodeButton.setTitle("\(selectedCountryCode) 🇺🇸", for: .normal)
        countryCodeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        countryCodeButton.setTitleColor(.label, for: .normal)
        countryCodeButton.layer.borderWidth = 1
        countryCodeButton.layer.borderColor = UIColor.systemGray4.cgColor
        countryCodeButton.layer.cornerRadius = 12
        countryCodeButton.addTarget(self, action: #selector(countryCodeTapped), for: .touchUpInside)
        contentView.addSubview(countryCodeButton)

        // Phone text field
        phoneTextField.placeholder = "Phone number"
        phoneTextField.font = .systemFont(ofSize: 18, weight: .regular)
        phoneTextField.textColor = .label
        phoneTextField.keyboardType = .phonePad
        phoneTextField.textContentType = .telephoneNumber
        phoneTextField.borderStyle = .none
        phoneTextField.addTarget(self, action: #selector(phoneNumberChanged), for: .editingChanged)
        phoneTextField.delegate = self
        contentView.addSubview(phoneTextField)

        // Underline for text field
        let underlineView = UIView()
        underlineView.backgroundColor = .systemGray4
        contentView.addSubview(underlineView)

        // Privacy label
        privacyLabel.text = "Your phone number will not be visible to other users"
        privacyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        privacyLabel.textColor = .tertiaryLabel
        privacyLabel.textAlignment = .center
        privacyLabel.numberOfLines = 0
        contentView.addSubview(privacyLabel)

        // Layout
        countryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Country code button
            countryCodeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            countryCodeButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            countryCodeButton.widthAnchor.constraint(equalToConstant: 100),
            countryCodeButton.heightAnchor.constraint(equalToConstant: 50),

            // Phone text field
            phoneTextField.leadingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor, constant: 12),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            phoneTextField.centerYAnchor.constraint(equalTo: countryCodeButton.centerYAnchor),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),

            // Underline
            underlineView.leadingAnchor.constraint(equalTo: phoneTextField.leadingAnchor),
            underlineView.trailingAnchor.constraint(equalTo: phoneTextField.trailingAnchor),
            underlineView.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 2),
            underlineView.heightAnchor.constraint(equalToConstant: 1),

            // Privacy label
            privacyLabel.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 24),
            privacyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            privacyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Auto-focus
        phoneTextField.becomeFirstResponder()
    }

    // MARK: - Actions
    @objc private func countryCodeTapped() {
        // For now, just show a simple action sheet with common country codes
        let actionSheet = UIAlertController(title: "Select Country Code", message: nil, preferredStyle: .actionSheet)

        let countryCodes = [
            ("+1", "🇺🇸", "United States"),
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
                self.phoneNumberChanged()
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = countryCodeButton
            popover.sourceRect = countryCodeButton.bounds
        }

        present(actionSheet, animated: true)
    }

    @objc private func phoneNumberChanged() {
        let phoneNumber = phoneTextField.text ?? ""
        let cleanNumber = phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Just check if we have a reasonable number of digits
        let digitCount = cleanNumber.filter { $0.isNumber }.count

        // For US numbers, we need 10 digits, for others be more flexible
        let minDigits = selectedCountryCode == "+1" ? 10 : 7
        updateContinueButton(enabled: digitCount >= minDigits)
    }

    override func continueButtonTapped() {
        let phoneNumber = phoneTextField.text ?? ""
        let cleanNumber = phoneNumber
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let fullNumber = selectedCountryCode + cleanNumber

        print("Continue button tapped with phone: \(fullNumber)")
        delegate?.didCompleteStep(withData: fullNumber)
    }

    // MARK: - Formatting
    private func formatPhoneNumber(_ number: String) -> String {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")

        if selectedCountryCode == "+1" && cleanNumber.count == 10 {
            // Format as US number: (123) 456-7890
            let areaCode = String(cleanNumber.prefix(3))
            let middle = String(cleanNumber.dropFirst(3).prefix(3))
            let last = String(cleanNumber.dropFirst(6))
            return "(\(areaCode)) \(middle)-\(last)"
        }

        // Basic formatting for other countries
        var formatted = ""
        for (index, char) in cleanNumber.enumerated() {
            if index > 0 && index % 3 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }
}

// MARK: - UITextFieldDelegate
extension PhoneNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only allow numbers
        if !string.isEmpty && !string.allSatisfy({ $0.isNumber || $0 == " " || $0 == "-" }) {
            return false
        }

        // Limit length
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        let cleanText = newText.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")

        if cleanText.count > 15 {
            return false
        }

        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        phoneNumberChanged()
    }
}