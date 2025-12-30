import UIKit
import PhotosUI

// Notification for profile updates
extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    static let userWantsToChangePhoto = Notification.Name("userWantsToChangePhoto")
    static let userWantsToRemovePhoto = Notification.Name("userWantsToRemovePhoto")
}

class EditProfileViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Profile Image
    private let profileImageView = UIImageView()
    private let changePhotoButton = UIButton(type: .system)

    // Basic Info
    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()
    private let bioTextView = UITextView()

    // Location Section
    private let locationTextField = UITextField()
    private let showCitySwitch = UISwitch()
    private let privacyLabel = UILabel()

    // Languages Section
    private let nativeLanguageLabel = UILabel()
    private let nativeLanguageButton = UIButton(type: .system)
    private var selectedNativeLanguage: Language = .english

    private let learningLanguagesLabel = UILabel()
    private let learningLanguagesStack = UIStackView()
    private var learningLanguages: [UserLanguage] = []

    private let openToMatchLabel = UILabel()
    private let openToMatchStack = UIStackView()
    private var openToLanguages: [Language] = []

    // Practice Languages (what you want to chat in)
    private let practiceLanguagesLabel = UILabel()
    private let practiceLanguagesStack = UIStackView()
    private let addPracticeLanguageButton = UIButton(type: .system)
    private var practiceLanguages: [UserLanguage] = []

    // Photo Gallery
    private let photosLabel = UILabel()
    private let photosCollectionView: UICollectionView
    private var photoURLs: [String] = []

    // Current user data
    var currentUser: User? {
        didSet {
            if isViewLoaded {
                populateUserData()
            }
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        self.photosCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        self.photosCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        setupConstraints()

        if currentUser != nil {
            populateUserData()
        } else {
            loadMockUserData()
        }
    }

    private func setupNavigationBar() {
        title = "Edit Profile"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .plain,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.fill")
        profileImageView.tintColor = .systemGray3
        contentView.addSubview(profileImageView)

        changePhotoButton.setTitle("Change Photo", for: .normal)
        changePhotoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        contentView.addSubview(changePhotoButton)

        // First Name
        firstNameTextField.placeholder = "First Name"
        firstNameTextField.borderStyle = .roundedRect
        firstNameTextField.font = .systemFont(ofSize: 16)
        contentView.addSubview(firstNameTextField)

        // Last Name
        lastNameTextField.placeholder = "Last Name"
        lastNameTextField.borderStyle = .roundedRect
        lastNameTextField.font = .systemFont(ofSize: 16)
        contentView.addSubview(lastNameTextField)

        // Bio
        let bioLabel = UILabel()
        bioLabel.text = "About Me"
        bioLabel.font = .systemFont(ofSize: 14, weight: .medium)
        bioLabel.textColor = .secondaryLabel
        contentView.addSubview(bioLabel)

        bioTextView.font = .systemFont(ofSize: 16)
        bioTextView.layer.borderColor = UIColor.systemGray4.cgColor
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.cornerRadius = 8
        bioTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        contentView.addSubview(bioTextView)

        // Bio tips label
        let bioTipsLabel = UILabel()
        bioTipsLabel.text = "💡 Tip: Share your interests, hobbies, and mention if you're learning other languages!"
        bioTipsLabel.font = .systemFont(ofSize: 13)
        bioTipsLabel.textColor = .secondaryLabel
        bioTipsLabel.numberOfLines = 0
        contentView.addSubview(bioTipsLabel)
        bioTipsLabel.translatesAutoresizingMaskIntoConstraints = false

        // Location
        let locationLabel = UILabel()
        locationLabel.text = "Location"
        locationLabel.font = .systemFont(ofSize: 14, weight: .medium)
        locationLabel.textColor = .secondaryLabel
        contentView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        locationTextField.placeholder = "City, Country"
        locationTextField.borderStyle = .roundedRect
        locationTextField.font = .systemFont(ofSize: 16)
        contentView.addSubview(locationTextField)
        locationTextField.translatesAutoresizingMaskIntoConstraints = false

        // Privacy setting
        let privacyContainer = UIView()
        privacyContainer.backgroundColor = .secondarySystemBackground
        privacyContainer.layer.cornerRadius = 8
        contentView.addSubview(privacyContainer)
        privacyContainer.translatesAutoresizingMaskIntoConstraints = false

        privacyLabel.text = "Show city in profile"
        privacyLabel.font = .systemFont(ofSize: 16)
        privacyContainer.addSubview(privacyLabel)
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false

        showCitySwitch.isOn = true
        privacyContainer.addSubview(showCitySwitch)
        showCitySwitch.translatesAutoresizingMaskIntoConstraints = false

        let privacyHelpLabel = UILabel()
        privacyHelpLabel.text = "When off, only your country will be shown"
        privacyHelpLabel.font = .systemFont(ofSize: 12)
        privacyHelpLabel.textColor = .secondaryLabel
        contentView.addSubview(privacyHelpLabel)
        privacyHelpLabel.translatesAutoresizingMaskIntoConstraints = false

        // Native Language
        nativeLanguageLabel.text = "Native Language"
        nativeLanguageLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentView.addSubview(nativeLanguageLabel)

        nativeLanguageButton.setTitle("Select Native Language", for: .normal)
        nativeLanguageButton.contentHorizontalAlignment = .left
        nativeLanguageButton.titleLabel?.font = .systemFont(ofSize: 16)
        nativeLanguageButton.addTarget(self, action: #selector(selectNativeLanguageTapped), for: .touchUpInside)
        contentView.addSubview(nativeLanguageButton)

        // Learning Languages
        learningLanguagesLabel.text = "Languages I'm Learning"
        learningLanguagesLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentView.addSubview(learningLanguagesLabel)

        learningLanguagesStack.axis = .vertical
        learningLanguagesStack.spacing = 10
        contentView.addSubview(learningLanguagesStack)

        let addLearningButton = UIButton(type: .system)
        addLearningButton.setTitle("+ Add Language", for: .normal)
        addLearningButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addLearningButton.addTarget(self, action: #selector(addLearningLanguageTapped), for: .touchUpInside)
        contentView.addSubview(addLearningButton)

        // Practice Languages (Languages you want to practice/chat in)
        practiceLanguagesLabel.text = "Languages I Want to Match In"
        practiceLanguagesLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentView.addSubview(practiceLanguagesLabel)

        practiceLanguagesStack.axis = .vertical
        practiceLanguagesStack.spacing = 10
        contentView.addSubview(practiceLanguagesStack)

        addPracticeLanguageButton.setTitle("+ Add Language to Match In", for: .normal)
        addPracticeLanguageButton.titleLabel?.font = .systemFont(ofSize: 16)
        addPracticeLanguageButton.contentHorizontalAlignment = .left
        addPracticeLanguageButton.addTarget(self, action: #selector(addPracticeLanguageTapped), for: .touchUpInside)
        contentView.addSubview(addPracticeLanguageButton)

        // Open to Match (hidden - we now use practice languages)
        openToMatchLabel.text = "Open to Match In"
        openToMatchLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        openToMatchLabel.isHidden = true
        contentView.addSubview(openToMatchLabel)

        openToMatchStack.axis = .vertical
        openToMatchStack.spacing = 10
        openToMatchStack.isHidden = true
        contentView.addSubview(openToMatchStack)

        // Photos
        photosLabel.text = "My Photos"
        photosLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentView.addSubview(photosLabel)

        photosCollectionView.backgroundColor = .clear
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        photosCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        photosCollectionView.register(AddPhotoCell.self, forCellWithReuseIdentifier: "AddPhotoCell")
        photosCollectionView.showsHorizontalScrollIndicator = false
        contentView.addSubview(photosCollectionView)

        // Layout all subviews
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        let locationLabelView = contentView.subviews.first { ($0 as? UILabel)?.text == "Location" } as? UILabel
        locationLabelView?.translatesAutoresizingMaskIntoConstraints = false
        let privacyContainerView = contentView.subviews.first { $0.backgroundColor == .secondarySystemBackground && $0.layer.cornerRadius == 8 }
        privacyContainerView?.translatesAutoresizingMaskIntoConstraints = false
        let privacyHelpLabelView = contentView.subviews.first { ($0 as? UILabel)?.text == "When off, only your country will be shown" } as? UILabel
        privacyHelpLabelView?.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bioLabel.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 24),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Bio tips
            bioTipsLabel.topAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 6),
            bioTipsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioTipsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Location fields
            locationLabelView!.topAnchor.constraint(equalTo: bioTipsLabel.bottomAnchor, constant: 20),
            locationLabelView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            locationTextField.topAnchor.constraint(equalTo: locationLabelView!.bottomAnchor, constant: 8),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),

            privacyContainerView!.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 12),
            privacyContainerView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            privacyContainerView!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            privacyContainerView!.heightAnchor.constraint(equalToConstant: 56),

            privacyLabel.leadingAnchor.constraint(equalTo: privacyContainerView!.leadingAnchor, constant: 16),
            privacyLabel.centerYAnchor.constraint(equalTo: privacyContainerView!.centerYAnchor),

            showCitySwitch.trailingAnchor.constraint(equalTo: privacyContainerView!.trailingAnchor, constant: -16),
            showCitySwitch.centerYAnchor.constraint(equalTo: privacyContainerView!.centerYAnchor),

            privacyHelpLabelView!.topAnchor.constraint(equalTo: privacyContainerView!.bottomAnchor, constant: 4),
            privacyHelpLabelView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            privacyHelpLabelView!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        changePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageButton.translatesAutoresizingMaskIntoConstraints = false
        learningLanguagesLabel.translatesAutoresizingMaskIntoConstraints = false
        learningLanguagesStack.translatesAutoresizingMaskIntoConstraints = false
        practiceLanguagesLabel.translatesAutoresizingMaskIntoConstraints = false
        practiceLanguagesStack.translatesAutoresizingMaskIntoConstraints = false
        addPracticeLanguageButton.translatesAutoresizingMaskIntoConstraints = false
        openToMatchLabel.translatesAutoresizingMaskIntoConstraints = false
        openToMatchStack.translatesAutoresizingMaskIntoConstraints = false
        photosLabel.translatesAutoresizingMaskIntoConstraints = false
        photosCollectionView.translatesAutoresizingMaskIntoConstraints = false

        // Find the add learning button
        let addLearningButton = contentView.subviews.first { ($0 as? UIButton)?.titleLabel?.text == "+ Add Language" }
        addLearningButton?.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            changePhotoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            firstNameTextField.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 24),
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 44),

            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 12),
            lastNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lastNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 44),

            bioTextView.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 44),
            bioTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            bioTextView.heightAnchor.constraint(equalToConstant: 100),

            nativeLanguageLabel.topAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 200),
            nativeLanguageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            nativeLanguageButton.topAnchor.constraint(equalTo: nativeLanguageLabel.bottomAnchor, constant: 12),
            nativeLanguageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nativeLanguageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nativeLanguageButton.heightAnchor.constraint(equalToConstant: 44),

            learningLanguagesLabel.topAnchor.constraint(equalTo: nativeLanguageButton.bottomAnchor, constant: 32),
            learningLanguagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            learningLanguagesStack.topAnchor.constraint(equalTo: learningLanguagesLabel.bottomAnchor, constant: 12),
            learningLanguagesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            learningLanguagesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])

        if let addButton = addLearningButton {
            NSLayoutConstraint.activate([
                addButton.topAnchor.constraint(equalTo: learningLanguagesStack.bottomAnchor, constant: 12),
                addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

                // Practice Languages
                practiceLanguagesLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 32),
                practiceLanguagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

                practiceLanguagesStack.topAnchor.constraint(equalTo: practiceLanguagesLabel.bottomAnchor, constant: 12),
                practiceLanguagesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                practiceLanguagesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

                addPracticeLanguageButton.topAnchor.constraint(equalTo: practiceLanguagesStack.bottomAnchor, constant: 12),
                addPracticeLanguageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                addPracticeLanguageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                addPracticeLanguageButton.heightAnchor.constraint(equalToConstant: 44),

                openToMatchLabel.topAnchor.constraint(equalTo: addPracticeLanguageButton.bottomAnchor, constant: 32),
                openToMatchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ])
        }

        NSLayoutConstraint.activate([
            openToMatchStack.topAnchor.constraint(equalTo: openToMatchLabel.bottomAnchor, constant: 12),
            openToMatchStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            openToMatchStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            photosLabel.topAnchor.constraint(equalTo: openToMatchStack.bottomAnchor, constant: 32),
            photosLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            photosCollectionView.topAnchor.constraint(equalTo: photosLabel.bottomAnchor, constant: 12),
            photosCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photosCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photosCollectionView.heightAnchor.constraint(equalToConstant: 110),
            photosCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func populateUserData() {
        guard let user = currentUser else { return }

        firstNameTextField.text = user.firstName
        lastNameTextField.text = user.lastName
        bioTextView.text = user.bio
        locationTextField.text = user.location
        showCitySwitch.isOn = user.showCityInProfile

        selectedNativeLanguage = user.nativeLanguage.language
        nativeLanguageButton.setTitle("\(user.nativeLanguage.language.name) (\(user.nativeLanguage.language.nativeName ?? ""))", for: .normal)

        learningLanguages = user.aspiringLanguages
        openToLanguages = user.openToLanguages
        practiceLanguages = user.practiceLanguages ?? []
        photoURLs = user.photoURLs

        updateLearningLanguagesDisplay()
        updateOpenToMatchDisplay()
        updatePracticeLanguagesDisplay()
        photosCollectionView.reloadData()

        if let profileImageURL = user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: profileImageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        }
    }

    private func loadMockUserData() {
        // Load location from UserDefaults
        locationTextField.text = UserDefaults.standard.string(forKey: "location") ?? ""
        showCitySwitch.isOn = UserDefaults.standard.object(forKey: "showCityInProfile") as? Bool ?? true

        // Load from UserDefaults if available
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            selectedNativeLanguage = decoded.nativeLanguage.language
            nativeLanguageButton.setTitle("\(decoded.nativeLanguage.language.name) (\(decoded.nativeLanguage.language.nativeName ?? ""))", for: .normal)
            learningLanguages = decoded.learningLanguages
            openToLanguages = decoded.openToLanguages
            practiceLanguages = decoded.practiceLanguages ?? []
        } else {
            // Create mock user for testing
            firstNameTextField.text = "John"
            lastNameTextField.text = "Doe"
            bioTextView.text = "Language enthusiast and world traveler. Love meeting new people!"
            locationTextField.text = "San Francisco, USA"
            showCitySwitch.isOn = true

            selectedNativeLanguage = .english
            nativeLanguageButton.setTitle("English", for: .normal)

            learningLanguages = [
                UserLanguage(language: .spanish, proficiency: .intermediate, isNative: false),
                UserLanguage(language: .japanese, proficiency: .beginner, isNative: false)
            ]

            openToLanguages = [.spanish, .japanese]
            practiceLanguages = []
        }

        updateLearningLanguagesDisplay()
        updateOpenToMatchDisplay()
        updatePracticeLanguagesDisplay()
    }

    private func updateLearningLanguagesDisplay() {
        learningLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for language in learningLanguages {
            let row = createLanguageRow(language: language, isLearning: true)
            learningLanguagesStack.addArrangedSubview(row)
        }
    }

    private func updateOpenToMatchDisplay() {
        openToMatchStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for language in learningLanguages {
            let row = createOpenToMatchRow(language: language)
            openToMatchStack.addArrangedSubview(row)
        }
    }

    private func updatePracticeLanguagesDisplay() {
        practiceLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for language in practiceLanguages {
            let row = createPracticeLanguageRow(language: language)
            practiceLanguagesStack.addArrangedSubview(row)
        }
    }

    private func createLanguageRow(language: UserLanguage, isLearning: Bool) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let label = UILabel()
        label.text = "\(language.language.name) - \(language.proficiency.displayName)"
        label.font = .systemFont(ofSize: 16)
        row.addSubview(label)

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Remove", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 14)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.tag = learningLanguages.firstIndex(where: { $0.language.code == language.language.code }) ?? 0
        deleteButton.addTarget(self, action: #selector(removeLearningLanguage(_:)), for: .touchUpInside)
        row.addSubview(deleteButton)

        label.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            deleteButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func createOpenToMatchRow(language: UserLanguage) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let checkbox = UISwitch()
        checkbox.isOn = openToLanguages.contains { $0.code == language.language.code }
        checkbox.tag = learningLanguages.firstIndex(where: { $0.language.code == language.language.code }) ?? 0
        checkbox.addTarget(self, action: #selector(toggleOpenToMatch(_:)), for: .valueChanged)
        row.addSubview(checkbox)

        let label = UILabel()
        label.text = language.language.name
        label.font = .systemFont(ofSize: 16)
        row.addSubview(label)

        checkbox.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            checkbox.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func createPracticeLanguageRow(language: UserLanguage) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let label = UILabel()
        label.text = "\(language.language.name) - \(language.proficiency.displayName)"
        label.font = .systemFont(ofSize: 16)
        row.addSubview(label)

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Remove", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 14)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.tag = practiceLanguages.firstIndex(where: { $0.language.code == language.language.code }) ?? 0
        deleteButton.addTarget(self, action: #selector(removePracticeLanguage(_:)), for: .touchUpInside)
        row.addSubview(deleteButton)

        label.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            deleteButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    @objc private func changePhotoTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func selectNativeLanguageTapped() {
        showLanguagePicker(isNative: true)
    }

    @objc private func addLearningLanguageTapped() {
        showLanguagePicker(isNative: false)
    }

    @objc private func addPracticeLanguageTapped() {
        showPracticeLanguagePicker()
    }

    @objc private func removeLearningLanguage(_ sender: UIButton) {
        guard sender.tag < learningLanguages.count else { return }

        let language = learningLanguages[sender.tag]
        learningLanguages.remove(at: sender.tag)
        openToLanguages.removeAll { $0.code == language.language.code }

        updateLearningLanguagesDisplay()
        updateOpenToMatchDisplay()
    }

    @objc private func removePracticeLanguage(_ sender: UIButton) {
        guard sender.tag < practiceLanguages.count else { return }

        practiceLanguages.remove(at: sender.tag)
        updatePracticeLanguagesDisplay()
    }

    @objc private func toggleOpenToMatch(_ sender: UISwitch) {
        guard sender.tag < learningLanguages.count else { return }

        let language = learningLanguages[sender.tag].language

        if sender.isOn {
            if !openToLanguages.contains(where: { $0.code == language.code }) {
                openToLanguages.append(language)
            }
        } else {
            openToLanguages.removeAll { $0.code == language.code }
        }
    }

    private func showLanguagePicker(isNative: Bool) {
        let alertController = UIAlertController(
            title: isNative ? "Select Native Language" : "Add Learning Language",
            message: nil,
            preferredStyle: .actionSheet
        )

        let languages: [Language] = [.english, .spanish, .french, .german, .japanese, .korean, .chinese, .portuguese, .italian, .russian]

        for language in languages {
            // Skip if already selected as native or learning
            if isNative && language.code == selectedNativeLanguage.code { continue }
            if !isNative && learningLanguages.contains(where: { $0.language.code == language.code }) { continue }

            alertController.addAction(UIAlertAction(title: "\(language.name) (\(language.nativeName ?? ""))", style: .default) { _ in
                if isNative {
                    self.selectedNativeLanguage = language
                    self.nativeLanguageButton.setTitle("\(language.name) (\(language.nativeName ?? ""))", for: .normal)
                } else {
                    self.showProficiencyPicker(for: language)
                }
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = isNative ? nativeLanguageButton : view
            popover.sourceRect = isNative ? nativeLanguageButton.bounds : CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true)
    }

    private func showProficiencyPicker(for language: Language) {
        let alertController = UIAlertController(
            title: "Select Proficiency Level",
            message: "How well do you speak \(language.name)?",
            preferredStyle: .actionSheet
        )

        for proficiency in LanguageProficiency.allCases {
            if proficiency == .native { continue } // Skip native for learning languages

            alertController.addAction(UIAlertAction(title: proficiency.displayName, style: .default) { _ in
                let userLanguage = UserLanguage(language: language, proficiency: proficiency, isNative: false)
                self.learningLanguages.append(userLanguage)
                self.updateLearningLanguagesDisplay()
                self.updateOpenToMatchDisplay()
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true)
    }

    private func showPracticeLanguagePicker() {
        let alertController = UIAlertController(
            title: "Add Language to Match In",
            message: "Select a language you want to match and chat in",
            preferredStyle: .actionSheet
        )

        let languages: [Language] = [.english, .spanish, .french, .german, .japanese, .korean, .chinese, .portuguese, .italian, .russian]

        for language in languages {
            // Skip if already added to practice languages
            if practiceLanguages.contains(where: { $0.language.code == language.code }) { continue }

            alertController.addAction(UIAlertAction(title: "\(language.name) (\(language.nativeName ?? ""))", style: .default) { _ in
                self.showPracticeProficiencyPicker(for: language)
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = addPracticeLanguageButton
            popover.sourceRect = addPracticeLanguageButton.bounds
        }

        present(alertController, animated: true)
    }

    private func showPracticeProficiencyPicker(for language: Language) {
        let alertController = UIAlertController(
            title: "Proficiency Level",
            message: "How well can you communicate in \(language.name)?",
            preferredStyle: .actionSheet
        )

        for proficiency in LanguageProficiency.allCases {
            alertController.addAction(UIAlertAction(title: proficiency.displayName, style: .default) { _ in
                let userLanguage = UserLanguage(language: language, proficiency: proficiency, isNative: proficiency == .native)
                self.practiceLanguages.append(userLanguage)
                self.updatePracticeLanguagesDisplay()
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alertController, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter your first and last name.")
            return
        }

        // Save to UserDefaults
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(bioTextView.text, forKey: "bio")

        // Save location and privacy setting
        if let location = locationTextField.text, !location.isEmpty {
            UserDefaults.standard.set(location, forKey: "location")
        }
        UserDefaults.standard.set(showCitySwitch.isOn, forKey: "showCityInProfile")

        // Save language data including practice languages
        let languageData = UserLanguageData(
            nativeLanguage: UserLanguage(language: selectedNativeLanguage, proficiency: .native, isNative: true),
            learningLanguages: learningLanguages,
            openToLanguages: openToLanguages,
            practiceLanguages: practiceLanguages
        )

        if let encoded = try? JSONEncoder().encode(languageData) {
            UserDefaults.standard.set(encoded, forKey: "userLanguages")
        }

        // Create updated user object
        let updatedUser = User(
            id: currentUser?.id ?? UUID().uuidString,
            username: currentUser?.username ?? "\(firstName.lowercased())_\(lastName.lowercased())",
            firstName: firstName,
            lastName: lastName,
            bio: bioTextView.text,
            profileImageURL: currentUser?.profileImageURL,
            photoURLs: photoURLs,
            nativeLanguage: UserLanguage(language: selectedNativeLanguage, proficiency: .native, isNative: true),
            learningLanguages: learningLanguages,
            openToLanguages: openToLanguages,
            practiceLanguages: practiceLanguages,
            location: currentUser?.location ?? "Unknown",
            matchedDate: currentUser?.matchedDate,
            isOnline: currentUser?.isOnline ?? false
        )

        // TODO: Save to backend (Supabase/CloudKit)
        print("User saved: \(updatedUser.firstName)")

        // Post notification to update profile
        NotificationCenter.default.post(name: .userProfileUpdated, object: updatedUser)

        dismiss(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension EditProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoURLs.count + 1 // +1 for add button
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < photoURLs.count {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: photoURLs[indexPath.item])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCell", for: indexPath) as? AddPhotoCell else {
                return UICollectionViewCell()
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < photoURLs.count {
            // Show option to delete
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { _ in
                self.photoURLs.remove(at: indexPath.item)
                collectionView.reloadData()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    popover.sourceView = cell
                    popover.sourceRect = cell.bounds
                }
            }

            present(alert, animated: true)
        } else {
            // Add new photo
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 6 - photoURLs.count
            configuration.filter = .images

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard !results.isEmpty else { return }

        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Uploading Photos", message: "Please wait...", preferredStyle: .alert)
        present(loadingAlert, animated: true)

        Task {
            var uploadedCount = 0
            var failedCount = 0

            for result in results {
                do {
                    // Load the image from picker result
                    let image = try await loadImage(from: result)

                    // Compress image to JPEG
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        failedCount += 1
                        continue
                    }

                    // Get current user ID
                    guard let userId = SupabaseService.shared.currentUserId?.uuidString else {
                        failedCount += 1
                        continue
                    }

                    // Determine photo index
                    let photoIndex = self.photoURLs.count

                    // Upload to Supabase storage
                    let storagePath = try await SupabaseService.shared.uploadPhoto(
                        imageData,
                        userId: userId,
                        photoIndex: photoIndex
                    )

                    // Add the storage path to our array
                    await MainActor.run {
                        if picker.configuration.selectionLimit == 1 {
                            // Profile photo - update the profile image view
                            self.profileImageView.image = image
                            // Store path at index 6 (profile photo slot)
                            while self.photoURLs.count < 7 {
                                self.photoURLs.append("")
                            }
                            self.photoURLs[6] = storagePath
                        } else {
                            // Gallery photo
                            self.photoURLs.append(storagePath)
                            self.photosCollectionView.reloadData()
                        }
                    }

                    uploadedCount += 1
                    print("✅ Photo uploaded: \(storagePath)")

                } catch {
                    print("❌ Failed to upload photo: \(error)")
                    failedCount += 1
                }
            }

            // Dismiss loading and show result
            await MainActor.run {
                loadingAlert.dismiss(animated: true) {
                    if failedCount > 0 {
                        let alert = UIAlertController(
                            title: "Upload Complete",
                            message: "\(uploadedCount) photo(s) uploaded. \(failedCount) failed.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    // Reload to show the new photos
                    self.photosCollectionView.reloadData()
                }
            }
        }
    }

    /// Helper to load UIImage from PHPickerResult asynchronously
    private func loadImage(from result: PHPickerResult) async throws -> UIImage {
        let originalImage: UIImage = try await withCheckedThrowingContinuation { continuation in
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = object as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "PhotoPicker", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not load image"]))
                }
            }
        }

        // Resize image to max 1200px to reduce memory usage and prevent crashes
        return resizeImage(originalImage, maxDimension: 1200)
    }

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already small enough, return it
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use UIGraphicsImageRenderer for efficient memory handling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }
}

// MARK: - Collection View Cells
class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with pathOrUrl: String) {
        // Check if it's a storage path (not a URL) - needs signed URL
        if !pathOrUrl.isEmpty && !pathOrUrl.hasPrefix("http") {
            // It's a storage path, get signed URL
            Task {
                do {
                    let signedURL = try await SupabaseService.shared.getSignedPhotoURL(path: pathOrUrl)
                    await MainActor.run {
                        ImageService.shared.loadImage(
                            from: signedURL,
                            into: self.imageView,
                            placeholder: UIImage(systemName: "photo")
                        )
                    }
                } catch {
                    print("❌ Failed to get signed URL for photo: \(error)")
                    await MainActor.run {
                        self.imageView.image = UIImage(systemName: "photo")
                        self.imageView.tintColor = .systemGray3
                    }
                }
            }
        } else if pathOrUrl.hasPrefix("http") {
            // It's already a URL
            ImageService.shared.loadImage(
                from: pathOrUrl,
                into: imageView,
                placeholder: UIImage(systemName: "photo")
            )
        } else {
            // Empty or invalid
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
        }
    }
}

class AddPhotoCell: UICollectionViewCell {
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        contentView.backgroundColor = .systemGray5
        contentView.layer.cornerRadius = 8

        iconView.image = UIImage(systemName: "plus")
        iconView.tintColor = .systemGray2
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}