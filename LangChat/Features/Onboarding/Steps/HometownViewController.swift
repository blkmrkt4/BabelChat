import UIKit
import MapKit

class HometownViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let searchTextField = UITextField()
    private let suggestionsTableView = UITableView()
    private let selectedLocationView = UIView()
    private let selectedLocationLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let timezoneLabel = UILabel()
    private let privacyToggle = UISwitch()
    private let privacyLabel = UILabel()
    private let privacyDescriptionLabel = UILabel()

    // MARK: - MapKit
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []

    // MARK: - Selected Location Data
    private var selectedLocation: LocationData?

    struct LocationData {
        let name: String          // e.g., "Toronto, ON, Canada"
        let city: String          // e.g., "Toronto"
        let country: String       // e.g., "Canada"
        let latitude: Double
        let longitude: Double
    }

    // MARK: - Lifecycle
    override func configure() {
        step = .hometown
        setTitle("Your location?")
        setupSearchCompleter()
        setupLocationInputs()
    }

    // MARK: - Setup
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    private func setupLocationInputs() {
        // Search text field
        searchTextField.placeholder = "Search for your city..."
        searchTextField.font = .systemFont(ofSize: 18, weight: .regular)
        searchTextField.textColor = .label
        searchTextField.autocapitalizationType = .words
        searchTextField.autocorrectionType = .no
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
        searchTextField.layer.cornerRadius = 12
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        searchTextField.leftViewMode = .always
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        // Add search icon
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.frame = CGRect(x: 12, y: 0, width: 20, height: 20)
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        leftContainer.addSubview(searchIcon)
        searchTextField.leftView = leftContainer
        searchTextField.leftViewMode = .always

        contentView.addSubview(searchTextField)

        // Suggestions table view
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(LocationSuggestionCell.self, forCellReuseIdentifier: "SuggestionCell")
        suggestionsTableView.layer.cornerRadius = 12
        suggestionsTableView.layer.borderWidth = 1
        suggestionsTableView.layer.borderColor = UIColor.systemGray4.cgColor
        suggestionsTableView.isHidden = true
        suggestionsTableView.backgroundColor = .secondarySystemBackground
        suggestionsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        contentView.addSubview(suggestionsTableView)

        // Selected location view (shown after selection)
        selectedLocationView.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        selectedLocationView.layer.cornerRadius = 12
        selectedLocationView.layer.borderWidth = 1
        selectedLocationView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        selectedLocationView.isHidden = true
        contentView.addSubview(selectedLocationView)

        // Selected location label
        selectedLocationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        selectedLocationLabel.textColor = .label
        selectedLocationLabel.numberOfLines = 2
        selectedLocationView.addSubview(selectedLocationLabel)

        // Clear button
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .secondaryLabel
        clearButton.addTarget(self, action: #selector(clearSelection), for: .touchUpInside)
        selectedLocationView.addSubview(clearButton)

        // Location pin icon
        let pinIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        pinIcon.tintColor = .systemGreen
        pinIcon.tag = 100
        selectedLocationView.addSubview(pinIcon)

        // Timezone label
        timezoneLabel.text = "🌍 Your timezone will be detected automatically"
        timezoneLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timezoneLabel.textColor = .secondaryLabel
        timezoneLabel.numberOfLines = 0
        contentView.addSubview(timezoneLabel)

        // Privacy toggle container
        let privacyContainer = UIView()
        privacyContainer.layer.cornerRadius = 12
        privacyContainer.backgroundColor = .secondarySystemBackground
        privacyContainer.tag = 200
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
        setupConstraints(privacyContainer: privacyContainer, pinIcon: pinIcon)

        // Auto-focus
        searchTextField.becomeFirstResponder()
    }

    private func setupConstraints(privacyContainer: UIView, pinIcon: UIImageView) {
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        timezoneLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyContainer.translatesAutoresizingMaskIntoConstraints = false
        privacyToggle.translatesAutoresizingMaskIntoConstraints = false
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Search text field
            searchTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 56),

            // Suggestions table view
            suggestionsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 200),

            // Selected location view
            selectedLocationView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 16),
            selectedLocationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedLocationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Pin icon
            pinIcon.leadingAnchor.constraint(equalTo: selectedLocationView.leadingAnchor, constant: 16),
            pinIcon.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 24),
            pinIcon.heightAnchor.constraint(equalToConstant: 24),

            // Selected location label
            selectedLocationLabel.topAnchor.constraint(equalTo: selectedLocationView.topAnchor, constant: 16),
            selectedLocationLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 12),
            selectedLocationLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
            selectedLocationLabel.bottomAnchor.constraint(equalTo: selectedLocationView.bottomAnchor, constant: -16),

            // Clear button
            clearButton.trailingAnchor.constraint(equalTo: selectedLocationView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 24),
            clearButton.heightAnchor.constraint(equalToConstant: 24),

            // Timezone label
            timezoneLabel.topAnchor.constraint(equalTo: selectedLocationView.bottomAnchor, constant: 16),
            timezoneLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timezoneLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Privacy container
            privacyContainer.topAnchor.constraint(equalTo: timezoneLabel.bottomAnchor, constant: 24),
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
            privacyDescriptionLabel.bottomAnchor.constraint(equalTo: privacyContainer.bottomAnchor, constant: -16),

            // Ensure content view has proper height
            privacyContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Actions
    @objc private func searchTextChanged() {
        guard let query = searchTextField.text, !query.isEmpty else {
            searchResults = []
            suggestionsTableView.reloadData()
            suggestionsTableView.isHidden = true
            return
        }

        searchCompleter.queryFragment = query
    }

    @objc private func clearSelection() {
        selectedLocation = nil
        selectedLocationView.isHidden = true
        searchTextField.isHidden = false
        searchTextField.text = ""
        searchTextField.becomeFirstResponder()
        updateContinueButton(enabled: false)
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        // Dismiss keyboard
        searchTextField.resignFirstResponder()

        // Show loading state
        selectedLocationLabel.text = "Finding location..."
        selectedLocationView.isHidden = false
        searchTextField.isHidden = true
        suggestionsTableView.isHidden = true

        // Geocode the selected location to get coordinates
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        search.start { [weak self] response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    self.showGeocodeError()
                    return
                }

                guard let mapItem = response?.mapItems.first,
                      let location = mapItem.placemark.location else {
                    self.showGeocodeError()
                    return
                }

                // Extract location components
                let placemark = mapItem.placemark
                let city = placemark.locality ?? placemark.subAdministrativeArea ?? completion.title
                let country = placemark.country ?? ""

                // Build display name
                var displayComponents: [String] = []
                if let locality = placemark.locality {
                    displayComponents.append(locality)
                }
                if let adminArea = placemark.administrativeArea {
                    displayComponents.append(adminArea)
                }
                if let country = placemark.country {
                    displayComponents.append(country)
                }
                let displayName = displayComponents.isEmpty ? completion.title : displayComponents.joined(separator: ", ")

                // Store selected location
                self.selectedLocation = LocationData(
                    name: displayName,
                    city: city,
                    country: country,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )

                // Update UI
                self.selectedLocationLabel.text = "📍 \(displayName)"
                self.updateContinueButton(enabled: true)

                print("✅ Location selected: \(displayName)")
                print("   Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }

    private func showGeocodeError() {
        selectedLocationView.isHidden = true
        searchTextField.isHidden = false

        let alert = UIAlertController(
            title: "Location Not Found",
            message: "We couldn't find that location. Please try a different search.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func continueButtonTapped() {
        guard let location = selectedLocation else { return }

        // Dismiss keyboard
        view.endEditing(true)

        // Save privacy preference
        UserDefaults.standard.set(privacyToggle.isOn, forKey: "showCityInProfile")

        // Pass location data to coordinator
        let locationData: [String: Any] = [
            "name": location.name,
            "city": location.city,
            "country": location.country,
            "latitude": location.latitude,
            "longitude": location.longitude
        ]

        // Small delay for keyboard dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.delegate?.didCompleteStep(withData: locationData)
        }
    }
}

// MARK: - UITextFieldDelegate
extension HometownViewController: UITextFieldDelegate {
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
            suggestionsTableView.isHidden = false
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension HometownViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to show only city/region results (not businesses)
        searchResults = completer.results.filter { result in
            // Exclude results that look like businesses (usually have subtitle with category)
            let subtitle = result.subtitle.lowercased()
            return !subtitle.contains("search nearby") &&
                   !subtitle.contains("restaurant") &&
                   !subtitle.contains("store") &&
                   !subtitle.contains("shop")
        }

        suggestionsTableView.reloadData()
        suggestionsTableView.isHidden = searchResults.isEmpty
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Search completer error: \(error.localizedDescription)")
        searchResults = []
        suggestionsTableView.reloadData()
        suggestionsTableView.isHidden = true
    }
}

// MARK: - UITableViewDelegate & DataSource
extension HometownViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(searchResults.count, 5) // Limit to 5 suggestions
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath) as? LocationSuggestionCell else {
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
        return 56
    }
}

// MARK: - Location Suggestion Cell
class LocationSuggestionCell: UITableViewCell {
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

        // Icon
        iconView.image = UIImage(systemName: "mappin.circle")
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        contentView.addSubview(subtitleLabel)

        // Layout
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            subtitleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(with result: MKLocalSearchCompletion) {
        titleLabel.text = result.title
        subtitleLabel.text = result.subtitle.isEmpty ? "Location" : result.subtitle
    }
}
