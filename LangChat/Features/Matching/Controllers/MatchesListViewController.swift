import UIKit

class MatchesListViewController: UIViewController {

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var matches: [Match] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadMatches()
    }

    private func setupNavigationBar() {
        title = "Your Matches"
        navigationController?.navigationBar.prefersLargeTitles = true

        let notificationButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(notificationsTapped)
        )
        navigationItem.rightBarButtonItem = notificationButton
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MatchCollectionViewCell.self, forCellWithReuseIdentifier: "MatchCell")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadMatches() {
        let sampleUser1 = User(
            id: "1",
            username: "jihyun_kim",
            firstName: "Ji-hyun",
            lastName: "Kim",
            bio: "Seoul native learning English and Spanish. Love K-dramas and coffee culture!",
            profileImageURL: "https://picsum.photos/seed/jihyun_profile/400/400",
            photoURLs: [
                "https://picsum.photos/seed/jihyun1/400/600",
                "https://picsum.photos/seed/jihyun2/400/600",
                "https://picsum.photos/seed/jihyun3/400/600",
                "https://picsum.photos/seed/jihyun4/400/600",
                "https://picsum.photos/seed/jihyun5/400/600",
                "https://picsum.photos/seed/jihyun6/400/600"
            ],
            nativeLanguage: UserLanguage(language: .korean, proficiency: .native, isNative: true),
            learningLanguages: [
                UserLanguage(language: .english, proficiency: .intermediate, isNative: false),
                UserLanguage(language: .spanish, proficiency: .beginner, isNative: false)
            ],
            openToLanguages: [.english, .japanese],
            practiceLanguages: nil,
            location: "Seoul, South Korea",
            showCityInProfile: true,  // Shows "Seoul, South Korea"
            matchedDate: Date(timeIntervalSince1970: 1726358400),
            isOnline: true
        )

        let sampleUser2 = User(
            id: "2",
            username: "alex_smith",
            firstName: "Alex",
            lastName: "Smith",
            bio: "Language enthusiast from London. Fluent in 3 languages!",
            profileImageURL: "https://picsum.photos/seed/alex_profile/400/400",
            photoURLs: ImageService.shared.generatePhotoURLs(for: "alex", count: 6),
            nativeLanguage: UserLanguage(language: .english, proficiency: .native, isNative: true),
            learningLanguages: [
                UserLanguage(language: .spanish, proficiency: .advanced, isNative: false),
                UserLanguage(language: .french, proficiency: .intermediate, isNative: false)
            ],
            openToLanguages: [.spanish, .french],
            practiceLanguages: nil,
            location: "London, UK",
            showCityInProfile: false,  // Shows only "UK"
            matchedDate: Date(timeIntervalSince1970: 1726272000),
            isOnline: false
        )

        let sampleUser3 = User(
            id: "3",
            username: "sofia_martinez",
            firstName: "Sofia",
            lastName: "Martinez",
            bio: "Mexican teacher passionate about cultural exchange!",
            profileImageURL: "https://picsum.photos/seed/sofia_profile/400/400",
            photoURLs: ImageService.shared.generatePhotoURLs(for: "sofia", count: 6),
            nativeLanguage: UserLanguage(language: .spanish, proficiency: .native, isNative: true),
            learningLanguages: [
                UserLanguage(language: .english, proficiency: .advanced, isNative: false),
                UserLanguage(language: .german, proficiency: .beginner, isNative: false)
            ],
            openToLanguages: [.english, .german],
            practiceLanguages: nil,
            location: "Mexico City, Mexico",
            showCityInProfile: true,  // Shows "Mexico City, Mexico"
            matchedDate: Date(timeIntervalSince1970: 1726185600),
            isOnline: true
        )

        let sampleUser4 = User(
            id: "4",
            username: "pooja_sharma",
            firstName: "Pooja",
            lastName: "Sharma",
            bio: "Mumbai native, love Bollywood and chai! Practicing English for my job in tech.",
            profileImageURL: "https://picsum.photos/seed/pooja_profile/400/400",
            photoURLs: ImageService.shared.generatePhotoURLs(for: "pooja", count: 6),
            nativeLanguage: UserLanguage(language: .hindi, proficiency: .native, isNative: true),
            learningLanguages: [
                UserLanguage(language: .english, proficiency: .intermediate, isNative: false)
            ],
            openToLanguages: [.english],
            practiceLanguages: nil,
            location: "Mumbai, India",
            showCityInProfile: true,  // Shows "Mumbai, India"
            matchedDate: Date(timeIntervalSince1970: 1726099200),
            isOnline: true
        )

        matches = [
            Match(id: "1", user: sampleUser1, matchedAt: Date(), hasNewMessage: true, lastMessage: "안녕하세요! How are you?", lastMessageTime: Date()),
            Match(id: "2", user: sampleUser2, matchedAt: Date(), hasNewMessage: false, lastMessage: "That sounds great!", lastMessageTime: Date(timeIntervalSinceNow: -3600)),
            Match(id: "3", user: sampleUser3, matchedAt: Date(), hasNewMessage: true, lastMessage: "¡Hola! Nice to meet you", lastMessageTime: Date(timeIntervalSinceNow: -7200)),
            Match(id: "4", user: sampleUser4, matchedAt: Date(), hasNewMessage: true, lastMessage: "नमस्ते! Let's practice together!", lastMessageTime: Date(timeIntervalSinceNow: -1800))
        ]

        collectionView.reloadData()
    }

    @objc private func notificationsTapped() {
        print("Notifications tapped")
    }
}

extension MatchesListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matches.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as! MatchCollectionViewCell
        cell.configure(with: matches[indexPath.row])
        return cell
    }
}

extension MatchesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = matches[indexPath.row]
        let detailVC = UserDetailViewController()
        detailVC.user = match.user
        detailVC.isMatched = true // Already matched

        // Pass the full list of matched users and current index for navigation
        detailVC.allUsers = matches.map { $0.user }
        detailVC.currentUserIndex = indexPath.row

        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MatchesListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 48) / 2
        return CGSize(width: width, height: width * 1.3)
    }
}

class MatchCollectionViewCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let languagesLabel = UILabel()
    private let locationLabel = UILabel()
    private let onlineIndicator = UIView()
    private let newMessageBadge = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        languagesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        languagesLabel.textColor = .white.withAlphaComponent(0.9)
        contentView.addSubview(languagesLabel)
        languagesLabel.translatesAutoresizingMaskIntoConstraints = false

        locationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        locationLabel.textColor = .white.withAlphaComponent(0.8)
        contentView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        onlineIndicator.backgroundColor = .systemGreen
        onlineIndicator.layer.cornerRadius = 6
        onlineIndicator.layer.borderWidth = 2
        onlineIndicator.layer.borderColor = UIColor.white.cgColor
        contentView.addSubview(onlineIndicator)
        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false

        newMessageBadge.backgroundColor = .systemRed
        newMessageBadge.layer.cornerRadius = 4
        contentView.addSubview(newMessageBadge)
        newMessageBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: languagesLabel.topAnchor, constant: -2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            languagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            languagesLabel.bottomAnchor.constraint(equalTo: locationLabel.topAnchor, constant: -2),
            languagesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            onlineIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            onlineIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 12),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 12),

            newMessageBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            newMessageBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            newMessageBadge.widthAnchor.constraint(equalToConstant: 8),
            newMessageBadge.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = imageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = imageView.bounds
        }
    }

    func configure(with match: Match) {
        nameLabel.text = match.user.firstName

        let languages = [match.user.nativeLanguage.displayCode] +
            match.user.learningLanguages.map { $0.displayCode }
        languagesLabel.text = languages.joined(separator: " • ")

        // Display location based on user's privacy setting
        locationLabel.text = match.user.displayLocation ?? ""

        onlineIndicator.isHidden = !match.user.isOnline
        newMessageBadge.isHidden = !match.hasNewMessage

        // Add gradient overlay for text readability
        if imageView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) == nil {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.6).cgColor
            ]
            gradientLayer.locations = [0.5, 1.0]
            imageView.layer.addSublayer(gradientLayer)
        }

        // Load profile image
        if let profileImageURL = match.user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: imageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        } else {
            imageView.image = UIImage(systemName: "person.fill")
            imageView.tintColor = .systemGray3
        }
    }
}