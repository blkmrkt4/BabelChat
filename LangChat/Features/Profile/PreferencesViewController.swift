import UIKit

class PreferencesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum PreferenceSection: Int, CaseIterable {
        case discovery
        case matching
        case communication

        var title: String {
            switch self {
            case .discovery: return "preferences_discovery_header".localized
            case .matching: return "preferences_matching_header".localized
            case .communication: return "preferences_communication_header".localized
            }
        }
    }

    private var preferences = UserPreferences()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadPreferences()
    }

    private func setupViews() {
        title = "preferences_title".localized
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PreferenceCell")
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "SliderCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadPreferences() {
        // Load from UserDefaults
        preferences = UserPreferences.load()
        tableView.reloadData()
    }

    @objc private func saveTapped() {
        preferences.save()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension PreferencesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return PreferenceSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let prefSection = PreferenceSection(rawValue: section) else { return 0 }

        switch prefSection {
        case .discovery:
            return 3 // Age range, Distance, Show me
        case .matching:
            return 2 // Auto-match similar proficiency, Prioritize active users
        case .communication:
            return 3 // Show online status, Read receipts, Typing indicators
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let prefSection = PreferenceSection(rawValue: section) else { return nil }
        return prefSection.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let prefSection = PreferenceSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch prefSection {
        case .discovery:
            switch indexPath.row {
            case 0: // Age range
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as? SliderTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_age_range".localized,
                    minValue: 18,
                    maxValue: 99,
                    currentMin: Float(preferences.minAge),
                    currentMax: Float(preferences.maxAge)
                )
                cell.valuesChanged = { [weak self] min, max in
                    self?.preferences.minAge = Int(min)
                    self?.preferences.maxAge = Int(max)
                }
                return cell

            case 1: // Distance
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as? SliderTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_max_distance".localized,
                    minValue: 1,
                    maxValue: 100,
                    currentMin: 1,
                    currentMax: Float(preferences.maxDistance),
                    isSingleValue: true
                )
                cell.valuesChanged = { [weak self] _, max in
                    self?.preferences.maxDistance = Int(max)
                }
                return cell

            case 2: // Show me
                let cell = tableView.dequeueReusableCell(withIdentifier: "PreferenceCell", for: indexPath)
                var config = cell.defaultContentConfiguration()
                config.text = "matching_show_me".localized
                config.secondaryText = preferences.showMe
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
                return cell

            default:
                return UITableViewCell()
            }

        case .matching:
            switch indexPath.row {
            case 0: // Auto-match
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_auto_match".localized,
                    icon: "sparkles",
                    isOn: preferences.autoMatchSimilarProficiency
                )
                cell.switchValueChanged = { [weak self] isOn in
                    self?.preferences.autoMatchSimilarProficiency = isOn
                }
                return cell

            case 1: // Prioritize active
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_prioritize_active".localized,
                    icon: "clock",
                    isOn: preferences.prioritizeActiveUsers
                )
                cell.switchValueChanged = { [weak self] isOn in
                    self?.preferences.prioritizeActiveUsers = isOn
                }
                return cell

            default:
                return UITableViewCell()
            }

        case .communication:
            switch indexPath.row {
            case 0: // Online status
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_show_online".localized,
                    icon: "circle.fill",
                    isOn: preferences.showOnlineStatus
                )
                cell.switchValueChanged = { [weak self] isOn in
                    self?.preferences.showOnlineStatus = isOn
                }
                return cell

            case 1: // Read receipts
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_read_receipts".localized,
                    icon: "checkmark.message",
                    isOn: preferences.readReceipts
                )
                cell.switchValueChanged = { [weak self] isOn in
                    self?.preferences.readReceipts = isOn
                }
                return cell

            case 2: // Typing indicators
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchTableViewCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "preferences_typing_indicators".localized,
                    icon: "ellipsis.bubble",
                    isOn: preferences.typingIndicators
                )
                cell.switchValueChanged = { [weak self] isOn in
                    self?.preferences.typingIndicators = isOn
                }
                return cell

            default:
                return UITableViewCell()
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension PreferencesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let prefSection = PreferenceSection(rawValue: indexPath.section) else { return }

        if prefSection == .discovery && indexPath.row == 2 {
            // Show me options
            let alert = UIAlertController(title: "preferences_show_me".localized, message: nil, preferredStyle: .actionSheet)
            let options = [
                ("Everyone", "preferences_everyone".localized),
                ("Men", "preferences_men".localized),
                ("Women", "preferences_women".localized),
                ("Non-binary", "preferences_non_binary".localized)
            ]

            for (value, displayName) in options {
                alert.addAction(UIAlertAction(title: displayName, style: .default) { [weak self] _ in
                    self?.preferences.showMe = value
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                })
            }

            alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

            if let popover = alert.popoverPresentationController,
               let cell = tableView.cellForRow(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }

            present(alert, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let prefSection = PreferenceSection(rawValue: indexPath.section) else { return 44 }

        if prefSection == .discovery && (indexPath.row == 0 || indexPath.row == 1) {
            return 80 // Taller for slider cells
        }

        return 44
    }
}

// MARK: - Slider Cell
class SliderTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var isSingleValue = false

    var valuesChanged: ((Float, Float) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 17)
        contentView.addSubview(titleLabel)

        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        contentView.addSubview(valueLabel)

        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        contentView.addSubview(slider)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(title: String, minValue: Float, maxValue: Float, currentMin: Float, currentMax: Float, isSingleValue: Bool = false) {
        titleLabel.text = title
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        self.isSingleValue = isSingleValue

        if isSingleValue {
            slider.value = currentMax
            valueLabel.text = String(format: "preferences_km_unit".localized, Int(currentMax))
        } else {
            // For range, we'll use the average for now (iOS doesn't have native range slider)
            slider.value = (currentMin + currentMax) / 2
            valueLabel.text = "\(Int(currentMin)) - \(Int(currentMax))"
        }
    }

    @objc private func sliderChanged() {
        if isSingleValue {
            valueLabel.text = String(format: "preferences_km_unit".localized, Int(slider.value))
            valuesChanged?(slider.minimumValue, slider.value)
        } else {
            // Simplified for demo - in production would use custom range slider
            let range: Float = 10
            let minValue = max(slider.minimumValue, slider.value - range)
            let maxValue = min(slider.maximumValue, slider.value + range)
            valueLabel.text = "\(Int(minValue)) - \(Int(maxValue))"
            valuesChanged?(minValue, maxValue)
        }
    }
}

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    var minAge: Int = 18
    var maxAge: Int = 99
    var maxDistance: Int = 50
    var showMe: String = "Everyone"
    var autoMatchSimilarProficiency: Bool = true
    var prioritizeActiveUsers: Bool = true
    var showOnlineStatus: Bool = true
    var readReceipts: Bool = true
    var typingIndicators: Bool = true

    static func load() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return UserPreferences()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
}