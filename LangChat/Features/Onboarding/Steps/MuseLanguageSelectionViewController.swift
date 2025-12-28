import UIKit

class MuseLanguageSelectionViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let infoLabel = UILabel()
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let selectionCountLabel = UILabel()

    // MARK: - Properties
    private var availableLanguages: [Language] = []
    private var filteredLanguages: [Language] = []
    private var selectedLanguages: Set<Language> = []

    // Languages already selected for matching (will be excluded from selection but shown as already included)
    var learningLanguages: [Language] = []
    var nativeLanguage: Language?

    // MARK: - Lifecycle
    override func configure() {
        step = .museLanguages
        setTitle("Choose Muse Languages",
                subtitle: "Select languages that will appear when you message your AI Muse. You can change this anytime in Profile → Settings → Muse Languages.")
        setupViews()
        loadAvailableLanguages()
    }

    private func loadAvailableLanguages() {
        // Get all Muse languages except English (always included) and learning languages (already included)
        let excludedLanguages = Set(learningLanguages + [nativeLanguage].compactMap { $0 } + [.english])
        availableLanguages = Language.museLanguages.filter { !excludedLanguages.contains($0) }
        filteredLanguages = availableLanguages

        tableView.reloadData()
    }

    // MARK: - Setup
    private func setupViews() {
        // Info label explaining what this is for
        infoLabel.text = "Your Muse already speaks your native and learning languages. Select additional languages you'd like to explore with your AI companion."
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        contentView.addSubview(infoLabel)

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
        tableView.register(MuseLanguageCell.self, forCellReuseIdentifier: "MuseLanguageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsMultipleSelection = true
        contentView.addSubview(tableView)

        // Layout
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            selectionCountLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            selectionCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionCountLabel.heightAnchor.constraint(equalToConstant: 24),

            searchBar.topAnchor.constraint(equalTo: selectionCountLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Enable continue button by default (selection is optional)
        updateContinueButton(enabled: true)
    }

    private func updateSelectionLabel() {
        let count = selectedLanguages.count
        if count == 0 {
            selectionCountLabel.text = "Optional - Skip if you're happy with your current selection"
            selectionCountLabel.textColor = .secondaryLabel
        } else {
            selectionCountLabel.text = "\(count) additional language\(count == 1 ? "" : "s") selected"
            selectionCountLabel.textColor = .systemBlue
        }
    }

    override func continueButtonTapped() {
        delegate?.didCompleteStep(withData: Array(selectedLanguages))
    }
}

// MARK: - UITableViewDataSource
extension MuseLanguageSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MuseLanguageCell", for: indexPath) as! MuseLanguageCell
        let language = filteredLanguages[indexPath.row]
        let isSelected = selectedLanguages.contains(language)
        cell.configure(with: language, isSelected: isSelected)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MuseLanguageSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let language = filteredLanguages[indexPath.row]

        if selectedLanguages.contains(language) {
            selectedLanguages.remove(language)
        } else {
            selectedLanguages.insert(language)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateSelectionLabel()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension MuseLanguageSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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

// MARK: - Muse Language Cell
private class MuseLanguageCell: UITableViewCell {
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

    func configure(with language: Language, isSelected: Bool) {
        flagLabel.text = language.flag
        nameLabel.text = language.name
        nativeNameLabel.text = language.nativeName

        if isSelected {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            checkboxImageView.image = UIImage(systemName: "checkmark.square.fill")
            checkboxImageView.tintColor = .systemBlue
        } else {
            containerView.backgroundColor = .secondarySystemBackground
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            checkboxImageView.image = UIImage(systemName: "square")
            checkboxImageView.tintColor = .systemGray3
        }

        nameLabel.textColor = .label
        nativeNameLabel.textColor = .secondaryLabel
    }
}
