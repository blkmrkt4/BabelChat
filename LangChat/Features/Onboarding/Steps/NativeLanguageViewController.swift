import UIKit

class NativeLanguageViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()

    // MARK: - Properties
    private let allLanguages = Language.allCases.sorted { $0.name < $1.name }
    private var filteredLanguages: [Language] = []
    private var selectedLanguage: Language?

    // MARK: - Lifecycle
    override func configure() {
        step = .nativeLanguage
        setTitle("What's your native language?",
                subtitle: "The language you speak fluently and can teach others")
        setupViews()
        filteredLanguages = allLanguages
    }

    // MARK: - Setup
    private func setupViews() {
        // Search bar
        searchBar.placeholder = "Search languages"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        contentView.addSubview(searchBar)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LanguageCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        contentView.addSubview(tableView)

        // Layout
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func continueButtonTapped() {
        delegate?.didCompleteStep(withData: selectedLanguage)
    }
}

// MARK: - UITableViewDataSource
extension NativeLanguageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as! LanguageCell
        let language = filteredLanguages[indexPath.row]
        cell.configure(
            with: language,
            isSelected: language == selectedLanguage
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NativeLanguageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLanguage = filteredLanguages[indexPath.row]
        tableView.reloadData()
        updateContinueButton(enabled: selectedLanguage != nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension NativeLanguageViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredLanguages = allLanguages
        } else {
            filteredLanguages = allLanguages.filter { language in
                language.name.lowercased().contains(searchText.lowercased()) ||
                language.nativeName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}

// MARK: - Language Cell
private class LanguageCell: UITableViewCell {
    private let containerView = UIView()
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let nativeNameLabel = UILabel()
    private let checkmarkImageView = UIImageView()

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

        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.isHidden = true
        containerView.addSubview(checkmarkImageView)

        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

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
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),

            nativeNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nativeNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            nativeNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            checkmarkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with language: Language, isSelected: Bool) {
        flagLabel.text = language.flag
        nameLabel.text = language.name
        nativeNameLabel.text = language.nativeName

        if isSelected {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            checkmarkImageView.isHidden = false
        } else {
            containerView.backgroundColor = .secondarySystemBackground
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            checkmarkImageView.isHidden = true
        }
    }
}