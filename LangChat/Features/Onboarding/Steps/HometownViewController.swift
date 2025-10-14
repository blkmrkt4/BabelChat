import UIKit

class HometownViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let cityTextField = UITextField()
    private let countryTextField = UITextField()
    private let timezoneLabel = UILabel()
    private let timezoneFlexibilityLabel = UILabel()
    private let privacyToggle = UISwitch()
    private let privacyLabel = UILabel()
    private let privacyDescriptionLabel = UILabel()

    // MARK: - Lifecycle
    override func configure() {
        step = .hometown
        setTitle("Where are you located?",
                subtitle: "This helps us find language partners in compatible timezones")
        setupLocationInputs()
    }

    // MARK: - Setup
    private func setupLocationInputs() {
        // City text field
        setupTextField(cityTextField, placeholder: "City")
        cityTextField.textContentType = .addressCity
        cityTextField.returnKeyType = .next
        contentView.addSubview(cityTextField)

        // Country text field
        setupTextField(countryTextField, placeholder: "Country")
        countryTextField.textContentType = .countryName
        countryTextField.returnKeyType = .done
        contentView.addSubview(countryTextField)

        // Timezone label
        timezoneLabel.text = "🌍 Your timezone will be detected automatically"
        timezoneLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timezoneLabel.textColor = .secondaryLabel
        timezoneLabel.numberOfLines = 0
        contentView.addSubview(timezoneLabel)

        // Timezone flexibility label
        timezoneFlexibilityLabel.text = "Don't worry, if you want to chat with people outside your timezone you'll get a chance to set that later!"
        timezoneFlexibilityLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timezoneFlexibilityLabel.textColor = .tertiaryLabel
        timezoneFlexibilityLabel.numberOfLines = 0
        contentView.addSubview(timezoneFlexibilityLabel)

        // Privacy toggle container
        let privacyContainer = UIView()
        privacyContainer.layer.cornerRadius = 12
        privacyContainer.backgroundColor = .secondarySystemBackground
        contentView.addSubview(privacyContainer)

        // Privacy toggle
        privacyToggle.isOn = true
        privacyToggle.onTintColor = .systemBlue
        privacyContainer.addSubview(privacyToggle)

        // Privacy label
        privacyLabel.text = "Show city to other users"
        privacyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        privacyLabel.textColor = .label
        privacyContainer.addSubview(privacyLabel)

        // Privacy description
        privacyDescriptionLabel.text = "If off, only your country will be visible"
        privacyDescriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        privacyDescriptionLabel.textColor = .secondaryLabel
        privacyDescriptionLabel.numberOfLines = 0
        privacyContainer.addSubview(privacyDescriptionLabel)

        // Layout
        cityTextField.translatesAutoresizingMaskIntoConstraints = false
        countryTextField.translatesAutoresizingMaskIntoConstraints = false
        timezoneLabel.translatesAutoresizingMaskIntoConstraints = false
        timezoneFlexibilityLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyContainer.translatesAutoresizingMaskIntoConstraints = false
        privacyToggle.translatesAutoresizingMaskIntoConstraints = false
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // City text field
            cityTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cityTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cityTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cityTextField.heightAnchor.constraint(equalToConstant: 56),

            // Country text field
            countryTextField.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 16),
            countryTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            countryTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            countryTextField.heightAnchor.constraint(equalToConstant: 56),

            // Timezone label
            timezoneLabel.topAnchor.constraint(equalTo: countryTextField.bottomAnchor, constant: 16),
            timezoneLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timezoneLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Timezone flexibility label
            timezoneFlexibilityLabel.topAnchor.constraint(equalTo: timezoneLabel.bottomAnchor, constant: 8),
            timezoneFlexibilityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timezoneFlexibilityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Privacy container
            privacyContainer.topAnchor.constraint(equalTo: timezoneFlexibilityLabel.bottomAnchor, constant: 24),
            privacyContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            privacyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Privacy toggle
            privacyToggle.centerYAnchor.constraint(equalTo: privacyContainer.centerYAnchor),
            privacyToggle.trailingAnchor.constraint(equalTo: privacyContainer.trailingAnchor, constant: -16),

            // Privacy label
            privacyLabel.topAnchor.constraint(equalTo: privacyContainer.topAnchor, constant: 16),
            privacyLabel.leadingAnchor.constraint(equalTo: privacyContainer.leadingAnchor, constant: 16),
            privacyLabel.trailingAnchor.constraint(equalTo: privacyToggle.leadingAnchor, constant: -16),

            // Privacy description
            privacyDescriptionLabel.topAnchor.constraint(equalTo: privacyLabel.bottomAnchor, constant: 4),
            privacyDescriptionLabel.leadingAnchor.constraint(equalTo: privacyContainer.leadingAnchor, constant: 16),
            privacyDescriptionLabel.trailingAnchor.constraint(equalTo: privacyToggle.leadingAnchor, constant: -16),
            privacyDescriptionLabel.bottomAnchor.constraint(equalTo: privacyContainer.bottomAnchor, constant: -16)
        ])

        // Auto-focus
        cityTextField.becomeFirstResponder()
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .label
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
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
        let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updateContinueButton(enabled: !city.isEmpty && !country.isEmpty)
    }

    override func continueButtonTapped() {
        let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = "\(city), \(country)"

        // Save privacy preference
        UserDefaults.standard.set(privacyToggle.isOn, forKey: "showCityInProfile")

        delegate?.didCompleteStep(withData: location)
    }
}

// MARK: - UITextFieldDelegate
extension HometownViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == cityTextField {
            countryTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if continueButton.isEnabled {
                continueButtonTapped()
            }
        }
        return true
    }
}
