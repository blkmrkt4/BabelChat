import UIKit

class BirthYearViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let datePicker = UIDatePicker()
    private let ageRestrictionLabel = UILabel()
    private let selectedYearLabel = UILabel()

    // MARK: - Properties
    private var selectedYear: Int = 2000

    // MARK: - Lifecycle
    override func configure() {
        step = .birthYear
        setTitle("When were you born?",
                subtitle: "We use this to match you with appropriate language partners")
        setupDatePicker()
    }

    // MARK: - Setup
    private func setupDatePicker() {
        // Selected year label
        selectedYearLabel.font = .systemFont(ofSize: 48, weight: .bold)
        selectedYearLabel.textColor = .label
        selectedYearLabel.textAlignment = .center
        selectedYearLabel.text = "\(selectedYear)"
        contentView.addSubview(selectedYearLabel)

        // Date picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        // Set minimum and maximum dates
        var dateComponents = DateComponents()
        dateComponents.year = 1920
        let minDate = Calendar.current.date(from: dateComponents)
        datePicker.minimumDate = minDate

        // Maximum date: Must be at least 13 years old
        let maxDate = Calendar.current.date(byAdding: .year, value: -13, to: Date())
        datePicker.maximumDate = maxDate

        // Set default date to 25 years ago
        let defaultDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())
        datePicker.date = defaultDate ?? Date()
        selectedYear = Calendar.current.component(.year, from: datePicker.date)
        selectedYearLabel.text = "\(selectedYear)"

        contentView.addSubview(datePicker)

        // Age restriction label
        ageRestrictionLabel.text = "You must be at least 13 years old to use Fluenca"
        ageRestrictionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        ageRestrictionLabel.textColor = .tertiaryLabel
        ageRestrictionLabel.textAlignment = .center
        ageRestrictionLabel.numberOfLines = 0
        contentView.addSubview(ageRestrictionLabel)

        // Layout
        selectedYearLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        ageRestrictionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Selected year label
            selectedYearLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            selectedYearLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedYearLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Date picker
            datePicker.topAnchor.constraint(equalTo: selectedYearLabel.bottomAnchor, constant: 24),
            datePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 200),

            // Age restriction label
            ageRestrictionLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 24),
            ageRestrictionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ageRestrictionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        updateContinueButton(enabled: true)
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

    override func continueButtonTapped() {
        delegate?.didCompleteStep(withData: selectedYear)
    }
}
