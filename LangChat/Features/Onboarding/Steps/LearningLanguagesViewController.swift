import UIKit

class LearningLanguagesViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let selectionCountLabel = UILabel()

    // MARK: - Properties
    private let allLanguages = Language.allCases.sorted { $0.name < $1.name }
    private var filteredLanguages: [Language] = []
    private var selectedLanguages: Set<Language> = []
    private let maxLanguages = 5

    // Native language to exclude from selection
    var nativeLanguage: Language?

    // MARK: - Lifecycle
    override func configure() {
        step = .learningLanguages
        setTitle("Which languages are you learning?",
                subtitle: "Select all that interest you (up to 5)")
        setupViews()

        // Filter out native language from available options
        if let native = nativeLanguage {
            filteredLanguages = allLanguages.filter { $0 != native }
        } else {
            filteredLanguages = allLanguages
        }
    }

    // MARK: - Setup
    private func setupViews() {
        // Selection count label
        selectionCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        selectionCountLabel.textColor = .systemBlue
        selectionCountLabel.textAlignment = .center
        updateSelectionLabel()
        contentView.addSubview(selectionCountLabel)

        // Search bar
        searchBar.placeholder = "Search languages"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        contentView.addSubview(searchBar)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LanguageSelectionCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsMultipleSelection = true
        contentView.addSubview(tableView)

        // Layout
        selectionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectionCountLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionCountLabel.heightAnchor.constraint(equalToConstant: 30),

            searchBar.topAnchor.constraint(equalTo: selectionCountLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func updateSelectionLabel() {
        let count = selectedLanguages.count
        if count == 0 {
            selectionCountLabel.text = "Select up to \(maxLanguages) languages"
            selectionCountLabel.textColor = .secondaryLabel
        } else if count < maxLanguages {
            selectionCountLabel.text = "\(count) selected • Select up to \(maxLanguages - count) more"
            selectionCountLabel.textColor = .systemBlue
        } else {
            selectionCountLabel.text = "Maximum languages selected (\(maxLanguages))"
            selectionCountLabel.textColor = .systemGreen
        }
    }

    override func continueButtonTapped() {
        delegate?.didCompleteStep(withData: Array(selectedLanguages))
    }
}

// MARK: - UITableViewDataSource
extension LearningLanguagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as! LanguageSelectionCell
        let language = filteredLanguages[indexPath.row]
        let isSelected = selectedLanguages.contains(language)
        let isEnabled = isSelected || selectedLanguages.count < maxLanguages
        cell.configure(
            with: language,
            isSelected: isSelected,
            isEnabled: isEnabled
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LearningLanguagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let language = filteredLanguages[indexPath.row]

        if selectedLanguages.contains(language) {
            selectedLanguages.remove(language)
        } else if selectedLanguages.count < maxLanguages {
            selectedLanguages.insert(language)
        } else {
            // Show alert that max languages reached
            tableView.deselectRow(at: indexPath, animated: false)
            let alert = UIAlertController(
                title: "Maximum Languages Reached",
                message: "You can select up to \(maxLanguages) languages. Deselect one to choose another.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        tableView.reloadData()
        updateSelectionLabel()
        updateContinueButton(enabled: !selectedLanguages.isEmpty)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension LearningLanguagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Get available languages (excluding native language)
        let availableLanguages: [Language]
        if let native = nativeLanguage {
            availableLanguages = allLanguages.filter { $0 != native }
        } else {
            availableLanguages = allLanguages
        }

        if searchText.isEmpty {
            filteredLanguages = availableLanguages
        } else {
            filteredLanguages = availableLanguages.filter { language in
                language.name.lowercased().contains(searchText.lowercased()) ||
                language.nativeName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}

// MARK: - Language Selection Cell
private class LanguageSelectionCell: UITableViewCell {
    private let containerView = UIView()
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let nativeNameLabel = UILabel()
    private let checkboxImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear

        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        contentView.addSubview(containerView)

        flagLabel.font = .systemFont(ofSize: 32)
        flagLabel.textAlignment = .center
        containerView.addSubview(flagLabel)

        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        containerView.addSubview(nameLabel)

        nativeNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        nativeNameLabel.textColor = .secondaryLabel
        containerView.addSubview(nativeNameLabel)

        checkboxImageView.contentMode = .scaleAspectFit
        containerView.addSubview(checkboxImageView)

        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        checkboxImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            flagLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            flagLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: checkboxImageView.leadingAnchor, constant: -12),

            nativeNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nativeNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            nativeNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            checkboxImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            checkboxImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkboxImageView.widthAnchor.constraint(equalToConstant: 24),
            checkboxImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with language: Language, isSelected: Bool, isEnabled: Bool) {
        flagLabel.text = language.flag
        nameLabel.text = language.name
        nativeNameLabel.text = language.nativeName

        if isSelected {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            checkboxImageView.image = UIImage(systemName: "checkmark.square.fill")
            checkboxImageView.tintColor = .systemBlue
            nameLabel.textColor = .label
            nativeNameLabel.textColor = .secondaryLabel
        } else if isEnabled {
            containerView.backgroundColor = .secondarySystemBackground
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            checkboxImageView.image = UIImage(systemName: "square")
            checkboxImageView.tintColor = .systemGray3
            nameLabel.textColor = .label
            nativeNameLabel.textColor = .secondaryLabel
        } else {
            containerView.backgroundColor = .systemGray6
            containerView.layer.borderColor = UIColor.systemGray5.cgColor
            checkboxImageView.image = UIImage(systemName: "square")
            checkboxImageView.tintColor = .systemGray4
            nameLabel.textColor = .tertiaryLabel
            nativeNameLabel.textColor = .quaternaryLabel
        }
    }
}
