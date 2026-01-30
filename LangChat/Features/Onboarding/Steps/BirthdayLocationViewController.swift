import UIKit

class BirthdayLocationViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let innerScrollView = UIScrollView()
    private let stackView = UIStackView()

    // Birthday section
    private let birthdayLabel = UILabel()
    private let selectedYearLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let ageRestrictionLabel = UILabel()

    // Location section
    private let locationLabel = UILabel()
    private let cityTextField = UITextField()
    private let countryTextField = UITextField()
    private let timezoneLabel = UILabel()

    // MARK: - Properties
    private var selectedYear: Int = 2000

    // MARK: - Lifecycle
    override func configure() {
        step = .birthYear  // Note: This combined screen is deprecated, use separate screens instead
        setTitle("auto_about_you".localized)
        setupScrollableContent()
    }

    // MARK: - Setup
    private func setupScrollableContent() {
        // Add scroll view
        innerScrollView.showsVerticalScrollIndicator = false
        innerScrollView.alwaysBounceVertical = true
        contentView.addSubview(innerScrollView)

        // Add stack view
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .fill
        innerScrollView.addSubview(stackView)

        // Setup sections
        setupBirthdaySection()
        setupLocationSection()

        // Layout
        innerScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view
            innerScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            innerScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            innerScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            innerScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Stack view
            stackView.topAnchor.constraint(equalTo: innerScrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: innerScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: innerScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: innerScrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: innerScrollView.widthAnchor)
        ])
    }

    private func setupBirthdaySection() {
        let birthdayContainer = UIView()

        // Section label
        birthdayLabel.text = "onboarding_birthday".localized
        birthdayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        birthdayLabel.textColor = .secondaryLabel
        birthdayContainer.addSubview(birthdayLabel)

        // Selected year label
        selectedYearLabel.font = .systemFont(ofSize: 42, weight: .bold)
        selectedYearLabel.textColor = .label
        selectedYearLabel.textAlignment = .center
        selectedYearLabel.text = "\(selectedYear)"
        birthdayContainer.addSubview(selectedYearLabel)

        // Date picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        // Set minimum and maximum dates
        var dateComponents = DateComponents()
        dateComponents.year = 1920
        let minDate = Calendar.current.date(from: dateComponents)
        datePicker.minimumDate = minDate

        // Maximum date: Must be at least 18 years old
        let maxDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        datePicker.maximumDate = maxDate

        // Set default date to 25 years ago
        let defaultDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())
        datePicker.date = defaultDate ?? Date()
        selectedYear = Calendar.current.component(.year, from: datePicker.date)
        selectedYearLabel.text = "\(selectedYear)"

        birthdayContainer.addSubview(datePicker)

        // Age restriction label
        ageRestrictionLabel.text = "onboarding_age_restriction".localized
        ageRestrictionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        ageRestrictionLabel.textColor = .tertiaryLabel
        ageRestrictionLabel.textAlignment = .center
        ageRestrictionLabel.numberOfLines = 0
        birthdayContainer.addSubview(ageRestrictionLabel)

        // Layout
        birthdayLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedYearLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        ageRestrictionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            birthdayLabel.topAnchor.constraint(equalTo: birthdayContainer.topAnchor),
            birthdayLabel.leadingAnchor.constraint(equalTo: birthdayContainer.leadingAnchor),
            birthdayLabel.trailingAnchor.constraint(equalTo: birthdayContainer.trailingAnchor),

            selectedYearLabel.topAnchor.constraint(equalTo: birthdayLabel.bottomAnchor, constant: 16),
            selectedYearLabel.leadingAnchor.constraint(equalTo: birthdayContainer.leadingAnchor),
            selectedYearLabel.trailingAnchor.constraint(equalTo: birthdayContainer.trailingAnchor),

            datePicker.topAnchor.constraint(equalTo: selectedYearLabel.bottomAnchor, constant: 16),
            datePicker.leadingAnchor.constraint(equalTo: birthdayContainer.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: birthdayContainer.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 180),

            ageRestrictionLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 16),
            ageRestrictionLabel.leadingAnchor.constraint(equalTo: birthdayContainer.leadingAnchor),
            ageRestrictionLabel.trailingAnchor.constraint(equalTo: birthdayContainer.trailingAnchor),
            ageRestrictionLabel.bottomAnchor.constraint(equalTo: birthdayContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(birthdayContainer)
    }

    private func setupLocationSection() {
        let locationContainer = UIView()

        // Section label
        locationLabel.text = "common_location".localized
        locationLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        locationLabel.textColor = .secondaryLabel
        locationContainer.addSubview(locationLabel)

        // City text field
        setupTextField(cityTextField, placeholder: "City")
        cityTextField.textContentType = .addressCity
        cityTextField.returnKeyType = .next
        locationContainer.addSubview(cityTextField)

        // Country text field
        setupTextField(countryTextField, placeholder: "Country")
        countryTextField.textContentType = .countryName
        countryTextField.returnKeyType = .done
        locationContainer.addSubview(countryTextField)

        // Timezone label
        timezoneLabel.text = "auto_well_use_this_to_match_you_with_partners".localized
        timezoneLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timezoneLabel.textColor = .tertiaryLabel
        timezoneLabel.numberOfLines = 0
        locationContainer.addSubview(timezoneLabel)

        // Layout
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        cityTextField.translatesAutoresizingMaskIntoConstraints = false
        countryTextField.translatesAutoresizingMaskIntoConstraints = false
        timezoneLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),

            cityTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            cityTextField.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            cityTextField.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            cityTextField.heightAnchor.constraint(equalToConstant: 56),

            countryTextField.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 12),
            countryTextField.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            countryTextField.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            countryTextField.heightAnchor.constraint(equalToConstant: 56),

            timezoneLabel.topAnchor.constraint(equalTo: countryTextField.bottomAnchor, constant: 16),
            timezoneLabel.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            timezoneLabel.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            timezoneLabel.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(locationContainer)

        // Enable continue button validation
        textFieldChanged()
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
    @objc private func dateChanged() {
        selectedYear = Calendar.current.component(.year, from: datePicker.date)
        selectedYearLabel.text = "\(selectedYear)"

        // Animate the change
        UIView.animate(withDuration: 0.2) {
            self.selectedYearLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.selectedYearLabel.transform = .identity
            }
        }
    }

    @objc private func textFieldChanged() {
        let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updateContinueButton(enabled: !city.isEmpty && !country.isEmpty)
    }

    override func continueButtonTapped() {
        let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = "\(city), \(country)"

        print("Continue button tapped - Birthday: \(selectedYear), Location: \(location)")
        delegate?.didCompleteStep(withData: (selectedYear, location))
    }
}

// MARK: - UITextFieldDelegate
extension BirthdayLocationViewController: UITextFieldDelegate {
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
