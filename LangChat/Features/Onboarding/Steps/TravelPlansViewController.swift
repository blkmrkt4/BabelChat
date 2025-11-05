import UIKit
import SwiftUI

class TravelPlansViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private let infoLabel = UILabel()
    private let iconView = UIImageView()

    // Destination section
    private let destinationLabel = UILabel()
    private let cityTextField = UITextField()
    private let countryTextField = UITextField()

    // Dates section
    private let datesLabel = UILabel()
    private let datesInfoLabel = UILabel()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()

    // MARK: - Properties
    private var hasAddedDestination: Bool = false

    // MARK: - Lifecycle
    override func configure() {
        step = .travelPlans
        setTitle("Planning to travel?",
                subtitle: "Connect with locals where you're heading")
        setupScrollableContent()

        // Can skip this step
        continueButton.setTitle("Skip for Now", for: .normal)
        updateContinueButton(enabled: true)
    }

    // MARK: - Setup
    private func setupScrollableContent() {
        // Add scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        contentView.addSubview(scrollView)

        // Add stack view
        stackView.axis = .vertical
        stackView.spacing = 28
        stackView.alignment = .fill
        scrollView.addSubview(stackView)

        // Setup sections
        setupIconSection()
        setupDestinationSection()
        setupDatesSection()

        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupIconSection() {
        let iconContainer = UIView()

        // Icon
        iconView.image = UIImage(systemName: "airplane.departure")
        iconView.tintColor = Color(hex: "FFD700").uiColor
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        // Info label
        infoLabel.text = "Optional: Add your travel plans to match with people in those locations"
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .white.withAlphaComponent(0.7)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        iconContainer.addSubview(infoLabel)

        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 70),
            iconView.heightAnchor.constraint(equalToConstant: 70),

            infoLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(iconContainer)
    }

    private func setupDestinationSection() {
        let destinationContainer = UIView()

        // Section label
        destinationLabel.text = "Destination"
        destinationLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        destinationLabel.textColor = .white.withAlphaComponent(0.8)
        destinationContainer.addSubview(destinationLabel)

        // City text field
        setupTextField(cityTextField, placeholder: "City (Optional)")
        cityTextField.textContentType = .addressCity
        cityTextField.returnKeyType = .next
        destinationContainer.addSubview(cityTextField)

        // Country text field
        setupTextField(countryTextField, placeholder: "Country")
        countryTextField.textContentType = .countryName
        countryTextField.returnKeyType = .done
        destinationContainer.addSubview(countryTextField)

        // Layout
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        cityTextField.translatesAutoresizingMaskIntoConstraints = false
        countryTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            destinationLabel.topAnchor.constraint(equalTo: destinationContainer.topAnchor),
            destinationLabel.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            destinationLabel.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),

            cityTextField.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 8),
            cityTextField.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            cityTextField.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),
            cityTextField.heightAnchor.constraint(equalToConstant: 56),

            countryTextField.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 12),
            countryTextField.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            countryTextField.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),
            countryTextField.heightAnchor.constraint(equalToConstant: 56),
            countryTextField.bottomAnchor.constraint(equalTo: destinationContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(destinationContainer)
    }

    private func setupDatesSection() {
        let datesContainer = UIView()

        // Section label
        datesLabel.text = "Travel Dates (Optional)"
        datesLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        datesLabel.textColor = .white.withAlphaComponent(0.8)
        datesContainer.addSubview(datesLabel)

        // Dates info
        datesInfoLabel.text = "When will you be there?"
        datesInfoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        datesInfoLabel.textColor = .white.withAlphaComponent(0.6)
        datesContainer.addSubview(datesInfoLabel)

        // Start date
        startDateLabel.text = "Arriving"
        startDateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        startDateLabel.textColor = .white.withAlphaComponent(0.7)
        datesContainer.addSubview(startDateLabel)

        startDatePicker.datePickerMode = .date
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.minimumDate = Date()
        startDatePicker.tintColor = Color(hex: "FFD700").uiColor
        if #available(iOS 14.0, *) {
            startDatePicker.backgroundColor = .white.withAlphaComponent(0.1)
            startDatePicker.layer.cornerRadius = 8
        }
        startDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datesContainer.addSubview(startDatePicker)

        // End date
        endDateLabel.text = "Departing"
        endDateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        endDateLabel.textColor = .white.withAlphaComponent(0.7)
        datesContainer.addSubview(endDateLabel)

        endDatePicker.datePickerMode = .date
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.minimumDate = Date()
        endDatePicker.tintColor = Color(hex: "FFD700").uiColor
        if #available(iOS 14.0, *) {
            endDatePicker.backgroundColor = .white.withAlphaComponent(0.1)
            endDatePicker.layer.cornerRadius = 8
        }
        endDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datesContainer.addSubview(endDatePicker)

        // Layout
        datesLabel.translatesAutoresizingMaskIntoConstraints = false
        datesInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            datesLabel.topAnchor.constraint(equalTo: datesContainer.topAnchor),
            datesLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            datesLabel.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),

            datesInfoLabel.topAnchor.constraint(equalTo: datesLabel.bottomAnchor, constant: 4),
            datesInfoLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            datesInfoLabel.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),

            startDateLabel.topAnchor.constraint(equalTo: datesInfoLabel.bottomAnchor, constant: 16),
            startDateLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),

            startDatePicker.centerYAnchor.constraint(equalTo: startDateLabel.centerYAnchor),
            startDatePicker.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),

            endDateLabel.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 20),
            endDateLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),

            endDatePicker.centerYAnchor.constraint(equalTo: endDateLabel.centerYAnchor),
            endDatePicker.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),
            endDatePicker.bottomAnchor.constraint(equalTo: datesContainer.bottomAnchor)
        ])

        stackView.addArrangedSubview(datesContainer)
    }

    private func setupTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        textField.layer.cornerRadius = 12
        textField.backgroundColor = .white.withAlphaComponent(0.05)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }

    // MARK: - Actions
    @objc private func textFieldChanged() {
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        hasAddedDestination = !country.isEmpty

        // Update button text
        if hasAddedDestination {
            continueButton.setTitle("Continue", for: .normal)
        } else {
            continueButton.setTitle("Skip for Now", for: .normal)
        }
    }

    @objc private func dateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date <= startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
    }

    override func continueButtonTapped() {
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // If no country entered, skip
        guard !country.isEmpty else {
            delegate?.didCompleteStep(withData: nil as TravelDestination?)
            return
        }

        // Create travel destination
        let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cityValue = (city?.isEmpty ?? true) ? nil : city

        // For now, use country name as both country code and name
        // In a real app, you'd have a country picker with proper ISO codes
        let travelDestination = TravelDestination(
            city: cityValue,
            country: country.uppercased().prefix(2).description, // Simplified ISO code
            countryName: country,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date
        )

        delegate?.didCompleteStep(withData: travelDestination as TravelDestination?)
    }
}

// MARK: - UITextFieldDelegate
extension TravelPlansViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == cityTextField {
            countryTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - Color Extension Helper
private extension Color {
    var uiColor: UIColor {
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
            // Fallback for older iOS versions
            let components = self.components()
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }
    }

    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1

        if scanner.scanHexInt64(&hexNumber) {
            r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000ff) / 255
        }
        return (r, g, b, a)
    }
}
