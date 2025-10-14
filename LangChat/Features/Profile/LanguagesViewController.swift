import UIKit

class LanguagesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var nativeLanguage: UserLanguage?
    private var learningLanguages: [UserLanguage] = []
    private var openToLanguages: [Language] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadUserLanguages()
    }

    private func setupViews() {
        title = "Languages"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editTapped)
        )

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadUserLanguages() {
        // Load from UserDefaults for now
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            nativeLanguage = decoded.nativeLanguage
            learningLanguages = decoded.learningLanguages
            openToLanguages = decoded.openToLanguages
        } else {
            // Default data
            nativeLanguage = UserLanguage(language: .english, proficiency: .native, isNative: true)
            learningLanguages = [
                UserLanguage(language: .spanish, proficiency: .intermediate, isNative: false),
                UserLanguage(language: .japanese, proficiency: .beginner, isNative: false)
            ]
            openToLanguages = [.spanish]
        }

        tableView.reloadData()
    }

    @objc private func editTapped() {
        let editVC = EditProfileViewController()
        editVC.currentUser = createCurrentUser()
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func createCurrentUser() -> User {
        return User(
            id: "current",
            username: "current_user",
            firstName: UserDefaults.standard.string(forKey: "firstName") ?? "User",
            lastName: UserDefaults.standard.string(forKey: "lastName") ?? "",
            bio: UserDefaults.standard.string(forKey: "bio"),
            profileImageURL: nil,
            photoURLs: [],
            nativeLanguage: nativeLanguage ?? UserLanguage(language: .english, proficiency: .native, isNative: true),
            learningLanguages: learningLanguages,
            openToLanguages: openToLanguages,
            practiceLanguages: [],
            location: "Current Location",
            matchedDate: nil,
            isOnline: true
        )
    }
}

// MARK: - UITableViewDataSource
extension LanguagesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Native language
        case 1: return learningLanguages.count
        case 2: return openToLanguages.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Native Language"
        case 1: return "Languages I'm Learning"
        case 2: return "Open to Match In"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)

        var config = cell.defaultContentConfiguration()

        switch indexPath.section {
        case 0:
            if let native = nativeLanguage {
                config.text = native.language.name
                config.secondaryText = native.language.nativeName
                config.image = UIImage(systemName: "star.fill")
                config.imageProperties.tintColor = .systemYellow
            }

        case 1:
            let language = learningLanguages[indexPath.row]
            config.text = language.language.name
            config.secondaryText = "\(language.proficiency.displayName) • \(language.language.nativeName ?? "")"
            config.image = UIImage(systemName: "book.fill")
            config.imageProperties.tintColor = .systemBlue

        case 2:
            let language = openToLanguages[indexPath.row]
            config.text = language.name
            config.secondaryText = language.nativeName
            config.image = UIImage(systemName: "message.fill")
            config.imageProperties.tintColor = .systemGreen

        default:
            break
        }

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate
extension LanguagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Open edit screen focused on selected language
        editTapped()
    }
}

// Helper struct for UserDefaults encoding
struct UserLanguageData: Codable {
    let nativeLanguage: UserLanguage
    let learningLanguages: [UserLanguage]
    let openToLanguages: [Language]
    let practiceLanguages: [UserLanguage]?
}