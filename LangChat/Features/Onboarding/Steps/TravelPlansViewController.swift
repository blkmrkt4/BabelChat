import UIKit
import MapKit
import SwiftUI

class TravelPlansViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let travelScrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Icon section
    private let iconView = UIImageView()
    private let infoLabel = UILabel()

    // Location search section
    private let destinationContainer = UIView()
    private let destinationLabel = UILabel()
    private let searchTextField = UITextField()
    private let suggestionsTableView = UITableView()
    private let selectedLocationView = UIView()
    private let selectedLocationLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private var suggestionsHeightConstraint: NSLayoutConstraint!

    // Dates section
    private let datesContainer = UIView()
    private let datesLabel = UILabel()
    private let datesInfoLabel = UILabel()
    private let startDateLabel = UILabel()
    private let startDatePicker = UIDatePicker()
    private let endDateLabel = UILabel()
    private let endDatePicker = UIDatePicker()

    // MARK: - MapKit
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []

    // MARK: - Selected Location Data
    private var selectedLocation: TravelLocationData?

    struct TravelLocationData {
        let displayName: String   // e.g., "Paris, France"
        let city: String?         // e.g., "Paris"
        let country: String       // e.g., "France"
        let countryCode: String   // e.g., "FR"
    }

    // MARK: - Edit Mode (for use from Settings)
    var isEditMode: Bool = false
    var onSave: (() -> Void)?

    // MARK: - Lifecycle
    override func configure() {
        step = .travelPlans
        setTitle("onboarding_travel_title".localized)
        setupSearchCompleter()
        setupScrollableContent()

        // Can skip this step
        continueButton.setTitle(isEditMode ? "common_save".localized : "common_skip_for_now".localized, for: .normal)
        updateContinueButton(enabled: true)

        // Load existing travel destination in edit mode
        if isEditMode {
            loadExistingTravelDestination()
        }
    }

    private func loadExistingTravelDestination() {
        guard let data = UserDefaults.standard.data(forKey: "travelDestination"),
              let destination = try? JSONDecoder().decode(TravelDestination.self, from: data) else {
            return
        }

        // Populate the UI with existing data
        selectedLocation = TravelLocationData(
            displayName: destination.displayName,
            city: destination.city,
            country: destination.countryName ?? destination.country,
            countryCode: destination.country
        )

        selectedLocationLabel.text = destination.displayName
        selectedLocationView.isHidden = false
        searchTextField.isHidden = true
        datesContainer.isHidden = false

        if let startDate = destination.startDate {
            startDatePicker.date = startDate
        }
        if let endDate = destination.endDate {
            endDatePicker.date = endDate
        }

        continueButton.setTitle("common_save".localized, for: .normal)
    }

    // MARK: - Setup
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    private func setupScrollableContent() {
        travelScrollView.showsVerticalScrollIndicator = false
        travelScrollView.alwaysBounceVertical = true
        travelScrollView.keyboardDismissMode = .onDrag
        contentView.addSubview(travelScrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        travelScrollView.addSubview(contentStack)

        // Setup sections
        setupIconSection()
        setupDestinationSection()
        setupDatesSection()

        // Layout
        travelScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            travelScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            travelScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            travelScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            travelScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: travelScrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: travelScrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: travelScrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: travelScrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: travelScrollView.widthAnchor)
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
        infoLabel.text = "onboarding_travel_info".localized
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
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            infoLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor)
        ])

        contentStack.addArrangedSubview(iconContainer)
    }

    private func setupDestinationSection() {
        // Section label
        destinationLabel.text = "onboarding_travel_where".localized
        destinationLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        destinationLabel.textColor = .white
        destinationContainer.addSubview(destinationLabel)

        // Search text field
        let searchPlaceholder = "onboarding_travel_search".localized
        searchTextField.placeholder = searchPlaceholder
        searchTextField.font = .systemFont(ofSize: 17, weight: .regular)
        searchTextField.textColor = .white
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: searchPlaceholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        searchTextField.autocapitalizationType = .words
        searchTextField.autocorrectionType = .no
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        searchTextField.layer.cornerRadius = 12
        searchTextField.backgroundColor = .white.withAlphaComponent(0.08)
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        // Add search icon
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .white.withAlphaComponent(0.5)
        searchIcon.frame = CGRect(x: 12, y: 0, width: 20, height: 20)
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 20))
        leftContainer.addSubview(searchIcon)
        searchTextField.leftView = leftContainer
        searchTextField.leftViewMode = .always

        destinationContainer.addSubview(searchTextField)

        // Suggestions table view - show above other content with higher z-order
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(TravelLocationSuggestionCell.self, forCellReuseIdentifier: "SuggestionCell")
        suggestionsTableView.layer.cornerRadius = 12
        suggestionsTableView.layer.borderWidth = 1
        suggestionsTableView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        suggestionsTableView.isHidden = true
        suggestionsTableView.backgroundColor = UIColor(white: 0.12, alpha: 0.98)
        suggestionsTableView.separatorStyle = .singleLine
        suggestionsTableView.separatorColor = .white.withAlphaComponent(0.15)
        suggestionsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        suggestionsTableView.layer.shadowColor = UIColor.black.cgColor
        suggestionsTableView.layer.shadowOffset = CGSize(width: 0, height: 4)
        suggestionsTableView.layer.shadowRadius = 8
        suggestionsTableView.layer.shadowOpacity = 0.3
        suggestionsTableView.clipsToBounds = false
        destinationContainer.addSubview(suggestionsTableView)

        // Selected location view (shown after selection)
        selectedLocationView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        selectedLocationView.layer.cornerRadius = 12
        selectedLocationView.layer.borderWidth = 1
        selectedLocationView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        selectedLocationView.isHidden = true
        destinationContainer.addSubview(selectedLocationView)

        // Pin icon in selected location view
        let pinIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        pinIcon.tintColor = .systemGreen
        pinIcon.tag = 100
        selectedLocationView.addSubview(pinIcon)

        // Selected location label
        selectedLocationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        selectedLocationLabel.textColor = .white
        selectedLocationLabel.numberOfLines = 2
        selectedLocationView.addSubview(selectedLocationLabel)

        // Clear button
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .white.withAlphaComponent(0.6)
        clearButton.addTarget(self, action: #selector(clearSelection), for: .touchUpInside)
        selectedLocationView.addSubview(clearButton)

        // Layout
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        pinIcon.translatesAutoresizingMaskIntoConstraints = false

        // Dynamic height for suggestions (0 when hidden, 260 when visible)
        suggestionsHeightConstraint = suggestionsTableView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            destinationLabel.topAnchor.constraint(equalTo: destinationContainer.topAnchor),
            destinationLabel.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            destinationLabel.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),

            searchTextField.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 52),

            suggestionsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),
            suggestionsHeightConstraint,

            selectedLocationView.topAnchor.constraint(equalTo: suggestionsTableView.bottomAnchor, constant: 12),
            selectedLocationView.leadingAnchor.constraint(equalTo: destinationContainer.leadingAnchor),
            selectedLocationView.trailingAnchor.constraint(equalTo: destinationContainer.trailingAnchor),

            pinIcon.leadingAnchor.constraint(equalTo: selectedLocationView.leadingAnchor, constant: 16),
            pinIcon.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 24),
            pinIcon.heightAnchor.constraint(equalToConstant: 24),

            selectedLocationLabel.topAnchor.constraint(equalTo: selectedLocationView.topAnchor, constant: 16),
            selectedLocationLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 12),
            selectedLocationLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
            selectedLocationLabel.bottomAnchor.constraint(equalTo: selectedLocationView.bottomAnchor, constant: -16),

            clearButton.trailingAnchor.constraint(equalTo: selectedLocationView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 24),
            clearButton.heightAnchor.constraint(equalToConstant: 24),

            // Container bottom constraint - account for visible content
            destinationContainer.bottomAnchor.constraint(greaterThanOrEqualTo: searchTextField.bottomAnchor, constant: 8),
            destinationContainer.bottomAnchor.constraint(greaterThanOrEqualTo: suggestionsTableView.bottomAnchor, constant: 8),
            destinationContainer.bottomAnchor.constraint(greaterThanOrEqualTo: selectedLocationView.bottomAnchor, constant: 8)
        ])

        contentStack.addArrangedSubview(destinationContainer)
    }

    private func setupDatesSection() {
        // Initially hidden until location is selected
        datesContainer.isHidden = true

        // Section label
        datesLabel.text = "onboarding_travel_when".localized
        datesLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        datesLabel.textColor = .white
        datesContainer.addSubview(datesLabel)

        // Dates info
        datesInfoLabel.text = "onboarding_travel_dates_info".localized
        datesInfoLabel.font = .systemFont(ofSize: 14, weight: .regular)
        datesInfoLabel.textColor = .white.withAlphaComponent(0.6)
        datesInfoLabel.numberOfLines = 0
        datesContainer.addSubview(datesInfoLabel)

        // Start date row
        let startRow = createDateRow(label: "onboarding_travel_arriving".localized, datePicker: startDatePicker)
        datesContainer.addSubview(startRow)

        // End date row
        let endRow = createDateRow(label: "onboarding_travel_departing".localized, datePicker: endDatePicker)
        datesContainer.addSubview(endRow)

        // Configure date pickers
        startDatePicker.datePickerMode = .date
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.minimumDate = Date()
        startDatePicker.tintColor = Color(hex: "FFD700").uiColor
        startDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        endDatePicker.datePickerMode = .date
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.minimumDate = Date()
        endDatePicker.tintColor = Color(hex: "FFD700").uiColor
        endDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        // Set default end date to 1 week from now
        endDatePicker.date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()

        // Layout
        datesLabel.translatesAutoresizingMaskIntoConstraints = false
        datesInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        startRow.translatesAutoresizingMaskIntoConstraints = false
        endRow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            datesLabel.topAnchor.constraint(equalTo: datesContainer.topAnchor),
            datesLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            datesLabel.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),

            datesInfoLabel.topAnchor.constraint(equalTo: datesLabel.bottomAnchor, constant: 6),
            datesInfoLabel.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            datesInfoLabel.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),

            startRow.topAnchor.constraint(equalTo: datesInfoLabel.bottomAnchor, constant: 16),
            startRow.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            startRow.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),
            startRow.heightAnchor.constraint(equalToConstant: 50),

            endRow.topAnchor.constraint(equalTo: startRow.bottomAnchor, constant: 12),
            endRow.leadingAnchor.constraint(equalTo: datesContainer.leadingAnchor),
            endRow.trailingAnchor.constraint(equalTo: datesContainer.trailingAnchor),
            endRow.heightAnchor.constraint(equalToConstant: 50),
            endRow.bottomAnchor.constraint(equalTo: datesContainer.bottomAnchor)
        ])

        contentStack.addArrangedSubview(datesContainer)
    }

    private func createDateRow(label: String, datePicker: UIDatePicker) -> UIView {
        let row = UIView()
        row.backgroundColor = .white.withAlphaComponent(0.08)
        row.layer.cornerRadius = 12

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 16, weight: .medium)
        labelView.textColor = .white
        row.addSubview(labelView)

        row.addSubview(datePicker)

        labelView.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            datePicker.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            datePicker.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    // MARK: - Actions
    @objc private func searchTextChanged() {
        guard let query = searchTextField.text, !query.isEmpty else {
            searchResults = []
            suggestionsTableView.reloadData()
            showSuggestionsAnimated(false)
            return
        }

        searchCompleter.queryFragment = query
    }

    private func showSuggestionsAnimated(_ show: Bool) {
        let targetHeight: CGFloat = show ? CGFloat(min(searchResults.count, 5) * 52 + 8) : 0

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.suggestionsHeightConstraint.constant = targetHeight
            self.suggestionsTableView.isHidden = !show
            self.suggestionsTableView.alpha = show ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func clearSelection() {
        selectedLocation = nil
        selectedLocationView.isHidden = true
        searchTextField.isHidden = false
        searchTextField.text = ""
        datesContainer.isHidden = true

        continueButton.setTitle("common_skip_for_now".localized, for: .normal)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date <= startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        // Dismiss keyboard
        searchTextField.resignFirstResponder()

        // Hide suggestions
        showSuggestionsAnimated(false)

        // Show loading state
        selectedLocationLabel.text = "onboarding_travel_finding".localized
        selectedLocationView.isHidden = false
        searchTextField.isHidden = true

        // Geocode the selected location to get details
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        search.start { [weak self] response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.showGeocodeError()
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    self.showGeocodeError()
                    return
                }

                // Extract location components
                let placemark = mapItem.placemark
                let city = placemark.locality ?? placemark.subAdministrativeArea
                let country = placemark.country ?? ""
                let countryCode = placemark.isoCountryCode ?? ""

                // Build display name
                var displayComponents: [String] = []
                if let locality = placemark.locality {
                    displayComponents.append(locality)
                }
                if let adminArea = placemark.administrativeArea {
                    displayComponents.append(adminArea)
                }
                if let countryName = placemark.country {
                    displayComponents.append(countryName)
                }
                let displayName = displayComponents.isEmpty ? completion.title : displayComponents.joined(separator: ", ")

                // Store selected location
                self.selectedLocation = TravelLocationData(
                    displayName: displayName,
                    city: city,
                    country: country,
                    countryCode: countryCode
                )

                // Update UI
                self.selectedLocationLabel.text = displayName
                self.continueButton.setTitle("common_continue".localized, for: .normal)

                // Show dates section with animation
                UIView.animate(withDuration: 0.3) {
                    self.datesContainer.isHidden = false
                    self.view.layoutIfNeeded()
                }

                print("Travel destination selected: \(displayName)")
            }
        }
    }

    private func showGeocodeError() {
        selectedLocationView.isHidden = true
        searchTextField.isHidden = false

        let alert = UIAlertController(
            title: "onboarding_travel_not_found_title".localized,
            message: "onboarding_travel_not_found_message".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
        present(alert, animated: true)
    }

    override func continueButtonTapped() {
        view.endEditing(true)

        // If no location selected, skip/clear
        guard let location = selectedLocation else {
            if isEditMode {
                // Clear travel destination in edit mode
                UserDefaults.standard.removeObject(forKey: "travelDestination")
                onSave?()
                navigationController?.popViewController(animated: true)
            } else {
                delegate?.didCompleteStep(withData: nil as TravelDestination?)
            }
            return
        }

        // Create travel destination
        let travelDestination = TravelDestination(
            city: location.city,
            country: location.countryCode.isEmpty ? location.country.prefix(2).uppercased() : location.countryCode,
            countryName: location.country,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date
        )

        if isEditMode {
            // Save to UserDefaults in edit mode
            if let encoded = try? JSONEncoder().encode(travelDestination) {
                UserDefaults.standard.set(encoded, forKey: "travelDestination")
            }
            onSave?()
            navigationController?.popViewController(animated: true)
        } else {
            delegate?.didCompleteStep(withData: travelDestination as TravelDestination?)
        }
    }
}

// MARK: - UITextFieldDelegate
extension TravelPlansViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // If there are suggestions, select the first one
        if !searchResults.isEmpty {
            selectLocation(searchResults[0])
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Show suggestions if we have any
        if !searchResults.isEmpty {
            showSuggestionsAnimated(true)
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension TravelPlansViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to show only city/region results (not businesses)
        searchResults = completer.results.filter { result in
            let subtitle = result.subtitle.lowercased()
            return !subtitle.contains("search nearby") &&
                   !subtitle.contains("restaurant") &&
                   !subtitle.contains("store") &&
                   !subtitle.contains("shop") &&
                   !subtitle.contains("hotel")
        }

        suggestionsTableView.reloadData()
        showSuggestionsAnimated(!searchResults.isEmpty)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        searchResults = []
        suggestionsTableView.reloadData()
        showSuggestionsAnimated(false)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension TravelPlansViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(searchResults.count, 5)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath) as? TravelLocationSuggestionCell else {
            return UITableViewCell()
        }
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        selectLocation(result)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}

// MARK: - Travel Location Suggestion Cell
class TravelLocationSuggestionCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        // Highlight on selection
        let selectedBg = UIView()
        selectedBg.backgroundColor = .white.withAlphaComponent(0.1)
        selectedBackgroundView = selectedBg

        // Icon
        iconView.image = UIImage(systemName: "mappin.circle")
        iconView.tintColor = .white.withAlphaComponent(0.6)
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.6)
        contentView.addSubview(subtitleLabel)

        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            subtitleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(with result: MKLocalSearchCompletion) {
        titleLabel.text = result.title
        subtitleLabel.text = result.subtitle.isEmpty ? "common_location".localized : result.subtitle
    }
}

// MARK: - Color Extension Helper
private extension Color {
    var uiColor: UIColor {
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
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
