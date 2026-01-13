import UIKit

/// Data structure to hold birth month and year
struct BirthDate: Codable {
    let month: Int  // 1-12
    let year: Int

    /// Calculate age accounting for whether birthday has passed this year
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        var age = currentYear - year

        // If birthday hasn't occurred yet this year, subtract 1
        if currentMonth < month {
            age -= 1
        }

        return age
    }

    /// Format as "Month Year" (e.g., "March 1990")
    var displayString: String {
        let monthName = DateFormatter().monthSymbols[month - 1]
        return "\(monthName) \(year)"
    }
}

class BirthYearViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let datePicker = UIDatePicker()
    private let ageRestrictionLabel = UILabel()
    private let selectedDateLabel = UILabel()

    // MARK: - Properties
    private var selectedMonth: Int = 1
    private var selectedYear: Int = 2000

    // MARK: - Lifecycle
    override func configure() {
        step = .birthYear
        setTitle("Birthday?")
        setupDatePicker()
    }

    // MARK: - Setup
    private func setupDatePicker() {
        // Selected date label (shows "Month Year")
        selectedDateLabel.font = .systemFont(ofSize: 36, weight: .bold)
        selectedDateLabel.textColor = .label
        selectedDateLabel.textAlignment = .center
        selectedDateLabel.adjustsFontSizeToFitWidth = true
        selectedDateLabel.minimumScaleFactor = 0.7
        contentView.addSubview(selectedDateLabel)

        // Date picker - use .date mode to get month and year
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        // Set minimum and maximum dates
        var dateComponents = DateComponents()
        dateComponents.year = 1920
        dateComponents.month = 1
        dateComponents.day = 1
        let minDate = Calendar.current.date(from: dateComponents)
        datePicker.minimumDate = minDate

        // Maximum date: Must be at least 13 years old
        let maxDate = Calendar.current.date(byAdding: .year, value: -13, to: Date())
        datePicker.maximumDate = maxDate

        // Set default date to 25 years ago
        let defaultDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())
        datePicker.date = defaultDate ?? Date()
        updateSelectedDate(from: datePicker.date)

        contentView.addSubview(datePicker)

        // Age restriction label
        ageRestrictionLabel.text = "You must be at least 13 years old to use Fluenca"
        ageRestrictionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        ageRestrictionLabel.textColor = .tertiaryLabel
        ageRestrictionLabel.textAlignment = .center
        ageRestrictionLabel.numberOfLines = 0
        contentView.addSubview(ageRestrictionLabel)

        // Layout
        selectedDateLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        ageRestrictionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Selected date label
            selectedDateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            selectedDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectedDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Date picker
            datePicker.topAnchor.constraint(equalTo: selectedDateLabel.bottomAnchor, constant: 24),
            datePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 200),

            // Age restriction label
            ageRestrictionLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 24),
            ageRestrictionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ageRestrictionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ageRestrictionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        updateContinueButton(enabled: true)
    }

    private func updateSelectedDate(from date: Date) {
        let calendar = Calendar.current
        selectedMonth = calendar.component(.month, from: date)
        selectedYear = calendar.component(.year, from: date)

        let monthName = DateFormatter().monthSymbols[selectedMonth - 1]
        selectedDateLabel.text = "\(monthName) \(selectedYear)"
    }

    // MARK: - Actions
    @objc private func dateChanged() {
        updateSelectedDate(from: datePicker.date)

        // Animate the change
        UIView.animate(withDuration: 0.2) {
            self.selectedDateLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.selectedDateLabel.transform = .identity
            }
        }
    }

    override func continueButtonTapped() {
        let birthDate = BirthDate(month: selectedMonth, year: selectedYear)
        delegate?.didCompleteStep(withData: birthDate)
    }
}
