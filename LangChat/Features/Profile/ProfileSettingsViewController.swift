import UIKit

class ProfileSettingsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum ProfileField: Int, CaseIterable {
        case name
        case email
        case phoneNumber
        case location
        case age

        var title: String {
            switch self {
            case .name: return "Name"
            case .email: return "Email"
            case .phoneNumber: return "Phone Number"
            case .location: return "Location"
            case .age: return "Age"
            }
        }

        var icon: String {
            switch self {
            case .name: return "person"
            case .email: return "envelope"
            case .phoneNumber: return "phone"
            case .location: return "location"
            case .age: return "calendar"
            }
        }

        var placeholder: String {
            switch self {
            case .name: return "Tap to set name"
            case .email: return "Tap to set email"
            case .phoneNumber: return "Tap to set phone number"
            case .location: return "Tap to set location"
            case .age: return "Tap to set age"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupViews() {
        title = "Profile Settings"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func getCurrentValue(for field: ProfileField) -> String {
        switch field {
        case .name:
            let firstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
            let lastName = UserDefaults.standard.string(forKey: "lastName") ?? ""
            if !firstName.isEmpty && !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return ""
        case .email:
            return UserDefaults.standard.string(forKey: "email") ?? ""
        case .phoneNumber:
            return UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
        case .location:
            return UserDefaults.standard.string(forKey: "location") ?? ""
        case .age:
            let birthYear = UserDefaults.standard.integer(forKey: "birthYear")
            if birthYear > 0 {
                let age = Calendar.current.component(.year, from: Date()) - birthYear
                return "\(age) years old"
            }
            return ""
        }
    }

    private func handleFieldSelection(_ field: ProfileField) {
        switch field {
        case .name: showNameEditor()
        case .email: showEmailEditor()
        case .phoneNumber: showPhoneEditor()
        case .location: showLocationEditor()
        case .age: showAgeEditor()
        }
    }

    // MARK: - Editors

    private func showNameEditor() {
        let currentFirstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
        let currentLastName = UserDefaults.standard.string(forKey: "lastName") ?? ""

        let alert = UIAlertController(
            title: "Update Name",
            message: "Enter your first and last name",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "First Name"
            textField.text = currentFirstName
            textField.autocapitalizationType = .words
        }

        alert.addTextField { textField in
            textField.placeholder = "Last Name"
            textField.text = currentLastName
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let firstName = alert?.textFields?[0].text, !firstName.isEmpty,
                  let lastName = alert?.textFields?[1].text, !lastName.isEmpty else {
                return
            }

            UserDefaults.standard.set(firstName, forKey: "firstName")
            UserDefaults.standard.set(lastName, forKey: "lastName")

            NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func showEmailEditor() {
        let currentEmail = UserDefaults.standard.string(forKey: "email") ?? ""

        let alert = UIAlertController(
            title: "Email Address",
            message: "Enter your email address",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "email@example.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.text = currentEmail
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let newEmail = alert?.textFields?.first?.text, !newEmail.isEmpty else {
                return
            }

            // Basic email validation
            if newEmail.contains("@") && newEmail.contains(".") {
                UserDefaults.standard.set(newEmail, forKey: "email")
                self?.tableView.reloadData()
            } else {
                let errorAlert = UIAlertController(
                    title: "Invalid Email",
                    message: "Please enter a valid email address.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
            }
        })

        present(alert, animated: true)
    }

    private func showPhoneEditor() {
        let currentPhone = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""

        let alert = UIAlertController(
            title: "Phone Number",
            message: "Enter your phone number",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "+1 (555) 123-4567"
            textField.keyboardType = .phonePad
            textField.text = currentPhone
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let newPhone = alert?.textFields?.first?.text, !newPhone.isEmpty else {
                return
            }

            UserDefaults.standard.set(newPhone, forKey: "phoneNumber")
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func showLocationEditor() {
        let currentLocation = UserDefaults.standard.string(forKey: "location") ?? ""

        let alert = UIAlertController(
            title: "Location",
            message: "Enter your city and country",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "City, Country"
            textField.text = currentLocation
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let location = alert?.textFields?.first?.text, !location.isEmpty else {
                return
            }

            UserDefaults.standard.set(location, forKey: "location")
            NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    private func showAgeEditor() {
        let currentBirthYear = UserDefaults.standard.integer(forKey: "birthYear")

        let alert = UIAlertController(
            title: "Update Age",
            message: "Enter your birth year",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Birth year (e.g. 1990)"
            textField.keyboardType = .numberPad
            if currentBirthYear > 0 {
                textField.text = "\(currentBirthYear)"
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let yearText = alert?.textFields?.first?.text,
                  let birthYear = Int(yearText),
                  birthYear > 1900 && birthYear <= Calendar.current.component(.year, from: Date()) else {
                let errorAlert = UIAlertController(
                    title: "Invalid Year",
                    message: "Please enter a valid birth year.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }

            UserDefaults.standard.set(birthYear, forKey: "birthYear")
            self?.tableView.reloadData()
        })

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ProfileSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProfileField.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        guard let field = ProfileField(rawValue: indexPath.row) else { return cell }

        var config = cell.defaultContentConfiguration()
        config.text = field.title
        config.image = UIImage(systemName: field.icon)

        let currentValue = getCurrentValue(for: field)
        config.secondaryText = currentValue.isEmpty ? field.placeholder : currentValue
        config.secondaryTextProperties.color = currentValue.isEmpty ? .secondaryLabel : .label

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProfileSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let field = ProfileField(rawValue: indexPath.row) else { return }
        handleFieldSelection(field)
    }
}
