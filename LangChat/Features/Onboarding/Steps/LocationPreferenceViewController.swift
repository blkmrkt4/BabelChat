import UIKit

class LocationPreferenceViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let locationScrollView = UIScrollView()
    private let stackView = UIStackView()
    private var selectedPreference: LocationPreference = .anywhere
    private var preferenceButtons: [LocationPreference: UIButton] = [:]

    // Distance slider components (for localRegional)
    private let distanceContainer = UIView()
    private let distanceSlider = UISlider()
    private let distanceLabel = UILabel()
    private var selectedDistance: Int = 50 // Default 50km
    private var distanceHeightConstraint: NSLayoutConstraint!

    // Country selection components
    private let countryContainer = UIView()
    private let selectedCountriesLabel = UILabel()
    private let selectCountriesButton = UIButton(type: .system)
    private var selectedCountries: [String] = [] // ISO country codes
    private var isExcludeMode: Bool = false // Track if we're excluding or including
    private var countryHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func configure() {
        step = .locationPreference
        setTitle("Location range?")
        setupScrollView()
        setupPreferenceButtons()
        setupDistanceSlider()
        setupCountrySelection()
    }

    // MARK: - Setup
    private func setupScrollView() {
        locationScrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(locationScrollView)
        locationScrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            locationScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            locationScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            locationScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        locationScrollView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: locationScrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: locationScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: locationScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: locationScrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: locationScrollView.widthAnchor)
        ])
    }

    private func setupPreferenceButtons() {
        // Create buttons for each location preference
        for preference in LocationPreference.allCases {
            let button = createPreferenceButton(for: preference)
            preferenceButtons[preference] = button
            stackView.addArrangedSubview(button)

            // Add distance container right after localRegional button
            if preference == .localRegional {
                stackView.addArrangedSubview(distanceContainer)
            }

            // Add country container after specificCountries
            if preference == .specificCountries {
                stackView.addArrangedSubview(countryContainer)
            }
        }

        // Auto-select "Anywhere" as default
        selectedPreference = .anywhere
        updateButtonAppearance()
        updateContinueButton(enabled: true)
    }

    private func setupDistanceSlider() {
        distanceContainer.backgroundColor = .white.withAlphaComponent(0.05)
        distanceContainer.layer.cornerRadius = 12
        distanceContainer.clipsToBounds = true
        distanceContainer.alpha = 0

        // Distance label
        distanceLabel.text = "Maximum distance: 50 km"
        distanceLabel.font = .systemFont(ofSize: 15, weight: .medium)
        distanceLabel.textColor = .white
        distanceLabel.textAlignment = .center
        distanceContainer.addSubview(distanceLabel)

        // Slider
        distanceSlider.minimumValue = 10
        distanceSlider.maximumValue = 200
        distanceSlider.value = 50
        distanceSlider.tintColor = .systemBlue
        distanceSlider.addTarget(self, action: #selector(distanceSliderChanged(_:)), for: .valueChanged)
        distanceContainer.addSubview(distanceSlider)

        // Range labels
        let minLabel = UILabel()
        minLabel.text = "10 km"
        minLabel.font = .systemFont(ofSize: 12, weight: .regular)
        minLabel.textColor = .white.withAlphaComponent(0.6)
        distanceContainer.addSubview(minLabel)

        let maxLabel = UILabel()
        maxLabel.text = "200 km"
        maxLabel.font = .systemFont(ofSize: 12, weight: .regular)
        maxLabel.textColor = .white.withAlphaComponent(0.6)
        maxLabel.textAlignment = .right
        distanceContainer.addSubview(maxLabel)

        // Layout
        distanceContainer.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceSlider.translatesAutoresizingMaskIntoConstraints = false
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        maxLabel.translatesAutoresizingMaskIntoConstraints = false

        // Height constraint for animation (starts collapsed)
        distanceHeightConstraint = distanceContainer.heightAnchor.constraint(equalToConstant: 0)
        distanceHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            distanceLabel.topAnchor.constraint(equalTo: distanceContainer.topAnchor, constant: 16),
            distanceLabel.leadingAnchor.constraint(equalTo: distanceContainer.leadingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: distanceContainer.trailingAnchor, constant: -16),

            distanceSlider.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 12),
            distanceSlider.leadingAnchor.constraint(equalTo: distanceContainer.leadingAnchor, constant: 16),
            distanceSlider.trailingAnchor.constraint(equalTo: distanceContainer.trailingAnchor, constant: -16),

            minLabel.topAnchor.constraint(equalTo: distanceSlider.bottomAnchor, constant: 4),
            minLabel.leadingAnchor.constraint(equalTo: distanceSlider.leadingAnchor),

            maxLabel.topAnchor.constraint(equalTo: distanceSlider.bottomAnchor, constant: 4),
            maxLabel.trailingAnchor.constraint(equalTo: distanceSlider.trailingAnchor)
        ])
    }

    private func setupCountrySelection() {
        countryContainer.backgroundColor = .white.withAlphaComponent(0.05)
        countryContainer.layer.cornerRadius = 12
        countryContainer.clipsToBounds = true
        countryContainer.alpha = 0
        countryContainer.translatesAutoresizingMaskIntoConstraints = false

        // Height constraint for animation (starts collapsed)
        countryHeightConstraint = countryContainer.heightAnchor.constraint(equalToConstant: 0)
        countryHeightConstraint.isActive = true

        // Selected countries label
        selectedCountriesLabel.text = "No countries selected"
        selectedCountriesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        selectedCountriesLabel.textColor = .white.withAlphaComponent(0.7)
        selectedCountriesLabel.numberOfLines = 0
        countryContainer.addSubview(selectedCountriesLabel)

        // Select button
        selectCountriesButton.setTitle("Select Countries", for: .normal)
        selectCountriesButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        selectCountriesButton.backgroundColor = .systemBlue
        selectCountriesButton.setTitleColor(.white, for: .normal)
        selectCountriesButton.layer.cornerRadius = 8
        selectCountriesButton.addTarget(self, action: #selector(selectCountriesTapped), for: .touchUpInside)
        countryContainer.addSubview(selectCountriesButton)

        // Layout
        selectedCountriesLabel.translatesAutoresizingMaskIntoConstraints = false
        selectCountriesButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectedCountriesLabel.topAnchor.constraint(equalTo: countryContainer.topAnchor, constant: 16),
            selectedCountriesLabel.leadingAnchor.constraint(equalTo: countryContainer.leadingAnchor, constant: 16),
            selectedCountriesLabel.trailingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: -16),

            selectCountriesButton.topAnchor.constraint(equalTo: selectedCountriesLabel.bottomAnchor, constant: 12),
            selectCountriesButton.leadingAnchor.constraint(equalTo: countryContainer.leadingAnchor, constant: 16),
            selectCountriesButton.trailingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: -16),
            selectCountriesButton.heightAnchor.constraint(equalToConstant: 44),
            selectCountriesButton.bottomAnchor.constraint(equalTo: countryContainer.bottomAnchor, constant: -16)
        ])
    }

    private func createPreferenceButton(for preference: LocationPreference) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: preference.icon))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        button.addSubview(iconView)

        // Create container for content
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 4
        containerStack.alignment = .leading
        containerStack.isUserInteractionEnabled = false
        button.addSubview(containerStack)

        let titleLabel = UILabel()
        titleLabel.text = preference.displayName
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        containerStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = preference.subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.7)
        subtitleLabel.numberOfLines = 0
        containerStack.addArrangedSubview(subtitleLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            containerStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            containerStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])

        button.tag = LocationPreference.allCases.firstIndex(of: preference) ?? 0
        button.addTarget(self, action: #selector(preferenceButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Actions
    @objc private func preferenceButtonTapped(_ sender: UIButton) {
        selectedPreference = LocationPreference.allCases[sender.tag]
        updateButtonAppearance()
        updateExpandableContainers()
        validateContinueButton()

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    @objc private func distanceSliderChanged(_ sender: UISlider) {
        // Snap to nearest 5km increments
        let snappedValue = round(sender.value / 5) * 5
        sender.value = snappedValue
        selectedDistance = Int(snappedValue)
        distanceLabel.text = "Maximum distance: \(selectedDistance) km"
    }

    @objc private func selectCountriesTapped() {
        let countryPicker = CountryPickerViewController()
        countryPicker.selectedCountries = Set(selectedCountries)
        countryPicker.isExcludeMode = isExcludeMode
        countryPicker.delegate = self

        let nav = UINavigationController(rootViewController: countryPicker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func updateButtonAppearance() {
        for (preference, button) in preferenceButtons {
            if preference == selectedPreference {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
                button.backgroundColor = .white.withAlphaComponent(0.08)
            }
        }
    }

    private func updateExpandableContainers() {
        let showDistance = selectedPreference == .localRegional
        let showCountries = selectedPreference == .specificCountries || selectedPreference == .excludeCountries

        // Update exclude mode and button text before animation
        isExcludeMode = selectedPreference == .excludeCountries
        if selectedPreference == .excludeCountries {
            selectCountriesButton.setTitle("Select Countries to Exclude", for: .normal)
        } else {
            selectCountriesButton.setTitle("Select Countries", for: .normal)
        }

        // Reset countries label when switching modes
        if showCountries && selectedCountries.isEmpty {
            selectedCountriesLabel.text = isExcludeMode ? "No countries excluded" : "No countries selected"
        }

        // Move country container to correct position before animation
        repositionCountryContainer()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Animate distance slider height
            self.distanceHeightConstraint.constant = showDistance ? 100 : 0
            self.distanceContainer.alpha = showDistance ? 1 : 0

            // Animate country picker height
            self.countryHeightConstraint.constant = showCountries ? 120 : 0
            self.countryContainer.alpha = showCountries ? 1 : 0

            self.view.layoutIfNeeded()
        }
    }

    private func repositionCountryContainer() {
        // Remove from current position
        stackView.removeArrangedSubview(countryContainer)

        // Find correct insertion index
        if let excludeButton = preferenceButtons[.excludeCountries],
           let excludeIndex = stackView.arrangedSubviews.firstIndex(of: excludeButton),
           selectedPreference == .excludeCountries {
            // Insert after excludeCountries button
            stackView.insertArrangedSubview(countryContainer, at: excludeIndex + 1)
        } else if let specificButton = preferenceButtons[.specificCountries],
                  let specificIndex = stackView.arrangedSubviews.firstIndex(of: specificButton),
                  selectedPreference == .specificCountries {
            // Insert after specificCountries button
            stackView.insertArrangedSubview(countryContainer, at: specificIndex + 1)
        }
    }

    private func validateContinueButton() {
        switch selectedPreference {
        case .specificCountries, .excludeCountries:
            // Require at least one country selected
            updateContinueButton(enabled: !selectedCountries.isEmpty)
        default:
            updateContinueButton(enabled: true)
        }
    }

    private func updateSelectedCountriesLabel() {
        if selectedCountries.isEmpty {
            selectedCountriesLabel.text = isExcludeMode ? "No countries excluded" : "No countries selected"
        } else {
            let countryNames = selectedCountries.compactMap { code in
                Locale.current.localizedString(forRegionCode: code)
            }
            if countryNames.count <= 3 {
                selectedCountriesLabel.text = countryNames.joined(separator: ", ")
            } else {
                let first3 = countryNames.prefix(3).joined(separator: ", ")
                selectedCountriesLabel.text = "\(first3) +\(countryNames.count - 3) more"
            }
        }
        validateContinueButton()
    }

    override func continueButtonTapped() {
        // Return all the location preference data
        var customDistance: Int? = nil
        var preferredCountries: [String]? = nil
        var excludedCountries: [String]? = nil

        switch selectedPreference {
        case .localRegional:
            customDistance = selectedDistance
        case .specificCountries:
            preferredCountries = selectedCountries
        case .excludeCountries:
            excludedCountries = selectedCountries
        default:
            break
        }

        let data: [String: Any] = [
            "preference": selectedPreference,
            "customDistanceKm": customDistance as Any,
            "preferredCountries": preferredCountries as Any,
            "excludedCountries": excludedCountries as Any
        ]

        delegate?.didCompleteStep(withData: data)
    }
}

// MARK: - CountryPickerDelegate
extension LocationPreferenceViewController: CountryPickerDelegate {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountries countries: Set<String>) {
        selectedCountries = Array(countries).sorted()
        updateSelectedCountriesLabel()
    }
}

// MARK: - Country Picker Protocol
protocol CountryPickerDelegate: AnyObject {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountries countries: Set<String>)
}

// MARK: - Country Picker View Controller
class CountryPickerViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: CountryPickerDelegate?
    var selectedCountries: Set<String> = []
    var isExcludeMode: Bool = false

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var allCountries: [(code: String, name: String)] = []
    private var filteredCountries: [(code: String, name: String)] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadCountries()
    }

    // MARK: - Setup
    private func setupViews() {
        title = isExcludeMode ? "Exclude Countries" : "Select Countries"
        view.backgroundColor = .systemBackground

        // Done button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        // Search bar
        searchBar.placeholder = "Search countries"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.allowsMultipleSelection = true
        view.addSubview(tableView)

        // Layout
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadCountries() {
        // Get all countries from ISO region codes
        allCountries = Locale.isoRegionCodes.compactMap { code in
            guard let name = Locale.current.localizedString(forRegionCode: code) else { return nil }
            return (code: code, name: name)
        }.sorted { $0.name < $1.name }

        filteredCountries = allCountries
        tableView.reloadData()

        // Pre-select already selected countries
        for (index, country) in filteredCountries.enumerated() {
            if selectedCountries.contains(country.code) {
                tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }

    // MARK: - Actions
    @objc private func doneTapped() {
        delegate?.countryPicker(self, didSelectCountries: selectedCountries)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CountryPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCountries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let country = filteredCountries[indexPath.row]

        // Get flag emoji
        let flag = country.code.unicodeScalars.map { String(UnicodeScalar(127397 + $0.value)!) }.joined()

        cell.textLabel?.text = "\(flag)  \(country.name)"
        cell.accessoryType = selectedCountries.contains(country.code) ? .checkmark : .none
        cell.tintColor = .systemBlue

        return cell
    }
}

// MARK: - UITableViewDelegate
extension CountryPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = filteredCountries[indexPath.row]
        selectedCountries.insert(country.code)
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let country = filteredCountries[indexPath.row]
        selectedCountries.remove(country.code)
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}

// MARK: - UISearchBarDelegate
extension CountryPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredCountries = allCountries
        } else {
            filteredCountries = allCountries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        tableView.reloadData()

        // Re-select previously selected countries
        for (index, country) in filteredCountries.enumerated() {
            if selectedCountries.contains(country.code) {
                tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
