import UIKit
import MapKit

protocol LocationPickerDelegate: AnyObject {
    func locationPicker(_ picker: LocationPickerViewController, didSelect location: LocationPickerViewController.LocationData)
    func locationPickerDidCancel(_ picker: LocationPickerViewController)
}

class LocationPickerViewController: UIViewController {

    // MARK: - Location Data Model
    struct LocationData {
        let displayName: String   // e.g., "Toronto, ON, Canada"
        let city: String          // e.g., "Toronto"
        let country: String       // e.g., "Canada"
        let latitude: Double
        let longitude: Double
    }

    // MARK: - Properties
    weak var delegate: LocationPickerDelegate?
    private var selectedLocation: LocationData?

    // MARK: - UI Components
    private let searchTextField = UITextField()
    private let suggestionsTableView = UITableView()
    private let selectedLocationView = UIView()
    private let selectedLocationLabel = UILabel()
    private let clearButton = UIButton(type: .system)

    // MARK: - MapKit
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSearchCompleter()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }

    // MARK: - Setup
    private func setupViews() {
        title = "Select Location"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false

        // Search text field
        searchTextField.placeholder = "Search for your city..."
        searchTextField.font = .systemFont(ofSize: 18, weight: .regular)
        searchTextField.textColor = .label
        searchTextField.autocapitalizationType = .words
        searchTextField.autocorrectionType = .no
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
        searchTextField.layer.cornerRadius = 12
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        // Add search icon
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.frame = CGRect(x: 12, y: 0, width: 20, height: 20)
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 20))
        leftContainer.addSubview(searchIcon)
        searchTextField.leftView = leftContainer
        searchTextField.leftViewMode = .always

        view.addSubview(searchTextField)

        // Suggestions table view
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        suggestionsTableView.layer.cornerRadius = 12
        suggestionsTableView.layer.borderWidth = 1
        suggestionsTableView.layer.borderColor = UIColor.systemGray4.cgColor
        suggestionsTableView.isHidden = true
        suggestionsTableView.backgroundColor = .secondarySystemBackground
        view.addSubview(suggestionsTableView)

        // Selected location view
        selectedLocationView.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        selectedLocationView.layer.cornerRadius = 12
        selectedLocationView.layer.borderWidth = 1
        selectedLocationView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        selectedLocationView.isHidden = true
        view.addSubview(selectedLocationView)

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

        // Layout
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 50),

            suggestionsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            suggestionsTableView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),

            selectedLocationView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 16),
            selectedLocationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectedLocationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            selectedLocationView.heightAnchor.constraint(equalToConstant: 60),

            selectedLocationLabel.leadingAnchor.constraint(equalTo: selectedLocationView.leadingAnchor, constant: 16),
            selectedLocationLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
            selectedLocationLabel.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: selectedLocationView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: selectedLocationView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 24),
            clearButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - Actions
    @objc private func searchTextChanged() {
        guard let text = searchTextField.text, !text.isEmpty else {
            searchResults = []
            suggestionsTableView.isHidden = true
            return
        }

        searchCompleter.queryFragment = text
    }

    @objc private func clearSelection() {
        selectedLocation = nil
        selectedLocationView.isHidden = true
        searchTextField.isHidden = false
        searchTextField.text = ""
        navigationItem.rightBarButtonItem?.isEnabled = false
        searchTextField.becomeFirstResponder()
    }

    @objc private func cancelTapped() {
        delegate?.locationPickerDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        guard let location = selectedLocation else { return }
        delegate?.locationPicker(self, didSelect: location)
        dismiss(animated: true)
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        search.start { [weak self] response, error in
            guard let self = self,
                  let mapItem = response?.mapItems.first,
                  let placemark = mapItem.placemark as? MKPlacemark else {
                return
            }

            let city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
            let country = placemark.country ?? ""
            let displayName = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")

            let locationData = LocationData(
                displayName: displayName,
                city: city,
                country: country,
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            )

            DispatchQueue.main.async {
                self.selectedLocation = locationData
                self.selectedLocationLabel.text = displayName
                self.selectedLocationView.isHidden = false
                self.suggestionsTableView.isHidden = true
                self.searchTextField.isHidden = true
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension LocationPickerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationPickerViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to only show city/region results
        searchResults = completer.results.filter { result in
            // Exclude specific addresses (they usually have numbers)
            !result.title.contains(where: { $0.isNumber })
        }

        suggestionsTableView.reloadData()
        suggestionsTableView.isHidden = searchResults.isEmpty
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

// MARK: - UITableViewDataSource
extension LocationPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        let result = searchResults[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = result.title
        config.secondaryText = result.subtitle
        config.image = UIImage(systemName: "mappin.circle.fill")
        config.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = config

        return cell
    }
}

// MARK: - UITableViewDelegate
extension LocationPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        selectLocation(result)
    }
}
