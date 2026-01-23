import UIKit

class InterfaceLanguageViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let tickerContainerView = UIView()
    private let tickerLabel = UILabel()
    private let searchBar = UISearchBar()
    private let tableView = UITableView()

    // MARK: - Ticker Messages
    private let tickerMessages = [
        "Select your Interface Language",      // English
        "Selecciona el idioma de la interfaz", // Spanish
        "Sélectionnez la langue de l'interface", // French
        "Wählen Sie Ihre Sprache",             // German
        "选择界面语言",                          // Chinese
        "インターフェース言語を選択",              // Japanese
        "인터페이스 언어 선택",                   // Korean
        "Selecione o idioma da interface",     // Portuguese
        "اختر لغة الواجهة",                     // Arabic
        "Выберите язык интерфейса"             // Russian
    ]
    private var currentTickerIndex = 0
    private var tickerTimer: Timer?

    // MARK: - Properties
    private let allLanguages = LocalizationService.availableLanguages
    private var filteredLanguages = LocalizationService.availableLanguages
    private var selectedLanguageCode: String?

    // MARK: - Lifecycle
    override func configure() {
        step = .interfaceLanguage
        setTitle("interface_language_title".localized)
        setupViews()

        // Hide back button on first step
        backButton.isHidden = true

        // Pre-select current language if set
        selectedLanguageCode = LocalizationService.shared.currentLanguage
        updateContinueButton(enabled: selectedLanguageCode != nil)
    }

    // MARK: - Setup
    private func setupViews() {
        // Ticker container
        tickerContainerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        tickerContainerView.clipsToBounds = true
        contentView.addSubview(tickerContainerView)

        // Ticker label
        tickerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        tickerLabel.textColor = .systemBlue
        tickerLabel.textAlignment = .center
        tickerLabel.text = tickerMessages[0]
        tickerContainerView.addSubview(tickerLabel)

        // Search bar
        searchBar.placeholder = "onboarding_native_search".localized
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        contentView.addSubview(searchBar)

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(InterfaceLanguageCell.self, forCellReuseIdentifier: "InterfaceLanguageCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        contentView.addSubview(tableView)

        // Layout
        tickerContainerView.translatesAutoresizingMaskIntoConstraints = false
        tickerLabel.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tickerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tickerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tickerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tickerContainerView.heightAnchor.constraint(equalToConstant: 32),

            tickerLabel.centerYAnchor.constraint(equalTo: tickerContainerView.centerYAnchor),
            tickerLabel.leadingAnchor.constraint(equalTo: tickerContainerView.leadingAnchor, constant: 16),
            tickerLabel.trailingAnchor.constraint(equalTo: tickerContainerView.trailingAnchor, constant: -16),

            searchBar.topAnchor.constraint(equalTo: tickerContainerView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Start ticker animation
        startTickerAnimation()
    }

    private func startTickerAnimation() {
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.animateToNextMessage()
        }
    }

    private func animateToNextMessage() {
        currentTickerIndex = (currentTickerIndex + 1) % tickerMessages.count

        // Slide up and fade out
        UIView.animate(withDuration: 0.3, animations: {
            self.tickerLabel.transform = CGAffineTransform(translationX: 0, y: -20)
            self.tickerLabel.alpha = 0
        }) { _ in
            // Update text and position below
            self.tickerLabel.text = self.tickerMessages[self.currentTickerIndex]
            self.tickerLabel.transform = CGAffineTransform(translationX: 0, y: 20)

            // Slide up and fade in
            UIView.animate(withDuration: 0.3) {
                self.tickerLabel.transform = .identity
                self.tickerLabel.alpha = 1
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tickerTimer?.invalidate()
        tickerTimer = nil
    }

    override func continueButtonTapped() {
        if let code = selectedLanguageCode {
            // Set the interface language immediately
            LocalizationService.shared.setLanguage(code)
        }
        delegate?.didCompleteStep(withData: selectedLanguageCode)
    }
}

// MARK: - UITableViewDataSource
extension InterfaceLanguageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InterfaceLanguageCell",
            for: indexPath
        ) as? InterfaceLanguageCell else {
            return UITableViewCell()
        }
        let language = filteredLanguages[indexPath.row]
        cell.configure(
            code: language.code,
            name: language.name,
            nativeName: language.nativeName,
            flag: language.flag,
            isSelected: language.code == selectedLanguageCode
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension InterfaceLanguageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLanguageCode = filteredLanguages[indexPath.row].code
        tableView.reloadData()
        updateContinueButton(enabled: selectedLanguageCode != nil)

        // Update Continue button text in the selected language
        if let code = selectedLanguageCode {
            LocalizationService.shared.setLanguage(code)
            continueButton.setTitle("common_continue".localized, for: .normal)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UISearchBarDelegate
extension InterfaceLanguageViewController: UISearchBarDelegate {
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

// MARK: - Interface Language Cell
private class InterfaceLanguageCell: UITableViewCell {
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

    func configure(code: String, name: String, nativeName: String, flag: String, isSelected: Bool) {
        flagLabel.text = flag
        nameLabel.text = name
        nativeNameLabel.text = nativeName

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
