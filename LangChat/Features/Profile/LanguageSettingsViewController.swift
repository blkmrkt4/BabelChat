import UIKit

class LanguageSettingsViewController: UIViewController {

    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Properties
    private let allLanguages = LocalizationService.availableLanguages
    private var filteredLanguages = LocalizationService.availableLanguages
    private var selectedLanguageCode: String

    // MARK: - Initialization
    init() {
        self.selectedLanguageCode = LocalizationService.shared.currentLanguage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        title = "App Language"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        // Search bar
        searchBar.placeholder = "onboarding_native_search".localized
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        view.addSubview(searchBar)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LanguageSelectionCell.self, forCellReuseIdentifier: "LanguageSelectionCell")
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        // Layout
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func selectLanguage(_ code: String) {
        let previousCode = selectedLanguageCode
        selectedLanguageCode = code
        tableView.reloadData()

        // Set the language
        LocalizationService.shared.setLanguage(code)

        // Show confirmation alert
        let languageName = LocalizationService.shared.nativeName(for: code)
        let alert = UIAlertController(
            title: "Language Changed",
            message: "The app language has been changed to \(languageName). Some screens may need to be reopened to see the change.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension LanguageSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "LanguageSelectionCell",
            for: indexPath
        ) as? LanguageSelectionCell else {
            return UITableViewCell()
        }
        let language = filteredLanguages[indexPath.row]
        cell.configure(
            flag: language.flag,
            name: language.name,
            nativeName: language.nativeName,
            isSelected: language.code == selectedLanguageCode
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LanguageSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let language = filteredLanguages[indexPath.row]
        if language.code != selectedLanguageCode {
            selectLanguage(language.code)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension LanguageSettingsViewController: UISearchBarDelegate {
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

// MARK: - Language Selection Cell
private class LanguageSelectionCell: UITableViewCell {
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
        flagLabel.font = .systemFont(ofSize: 28)
        flagLabel.textAlignment = .center
        contentView.addSubview(flagLabel)

        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)

        nativeNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        nativeNameLabel.textColor = .secondaryLabel
        contentView.addSubview(nativeNameLabel)

        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.isHidden = true
        contentView.addSubview(checkmarkImageView)

        // Layout
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            flagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 36),

            nameLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),

            nativeNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            nativeNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            nativeNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(flag: String, name: String, nativeName: String, isSelected: Bool) {
        flagLabel.text = flag
        nameLabel.text = name
        nativeNameLabel.text = nativeName
        checkmarkImageView.isHidden = !isSelected
        accessoryType = .none
    }
}
