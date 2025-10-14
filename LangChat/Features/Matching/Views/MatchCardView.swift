import UIKit

class MatchCardView: UIView {

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let nativeLanguageBadge = LanguageBadgeView()
    private let aspiringLabel = UILabel()
    private let aspiringLanguagesStack = UIStackView()
    private let photoGridView = PhotoGridView()
    private let openToMatchLabel = UILabel()
    private let aboutLabel = UILabel()
    private let bioLabel = UILabel()
    private let matchDateLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    var user: User? {
        didSet {
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10

        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        contentView.addSubview(profileImageView)

        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        contentView.addSubview(nameLabel)

        contentView.addSubview(nativeLanguageBadge)

        aspiringLabel.text = "Aspiring:"
        aspiringLabel.font = .systemFont(ofSize: 16, weight: .regular)
        aspiringLabel.textColor = .secondaryLabel
        contentView.addSubview(aspiringLabel)

        aspiringLanguagesStack.axis = .horizontal
        aspiringLanguagesStack.spacing = 8
        aspiringLanguagesStack.distribution = .fill
        aspiringLanguagesStack.alignment = .center
        contentView.addSubview(aspiringLanguagesStack)

        photoGridView.layer.cornerRadius = 12
        photoGridView.clipsToBounds = true
        contentView.addSubview(photoGridView)

        openToMatchLabel.font = .systemFont(ofSize: 16, weight: .medium)
        openToMatchLabel.textColor = .systemBlue
        contentView.addSubview(openToMatchLabel)

        aboutLabel.text = "About"
        aboutLabel.font = .systemFont(ofSize: 20, weight: .bold)
        aboutLabel.textColor = .label
        contentView.addSubview(aboutLabel)

        bioLabel.font = .systemFont(ofSize: 16, weight: .regular)
        bioLabel.textColor = .secondaryLabel
        bioLabel.numberOfLines = 0
        contentView.addSubview(bioLabel)

        matchDateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        matchDateLabel.textColor = .tertiaryLabel
        contentView.addSubview(matchDateLabel)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageBadge.translatesAutoresizingMaskIntoConstraints = false
        aspiringLabel.translatesAutoresizingMaskIntoConstraints = false
        aspiringLanguagesStack.translatesAutoresizingMaskIntoConstraints = false
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        openToMatchLabel.translatesAutoresizingMaskIntoConstraints = false
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        matchDateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            nativeLanguageBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nativeLanguageBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            aspiringLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            aspiringLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            aspiringLanguagesStack.topAnchor.constraint(equalTo: aspiringLabel.bottomAnchor, constant: 8),
            aspiringLanguagesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            aspiringLanguagesStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

            photoGridView.topAnchor.constraint(equalTo: aspiringLanguagesStack.bottomAnchor, constant: 20),
            photoGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            photoGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            photoGridView.heightAnchor.constraint(equalTo: photoGridView.widthAnchor, multiplier: 2.0/3.0),

            openToMatchLabel.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 20),
            openToMatchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            openToMatchLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            aboutLabel.topAnchor.constraint(equalTo: openToMatchLabel.bottomAnchor, constant: 24),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            bioLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            matchDateLabel.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 20),
            matchDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            matchDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func updateUI() {
        guard let user = user else { return }

        nameLabel.text = user.displayName

        if let imageURL = user.profileImageURL {
            loadImage(from: imageURL, into: profileImageView)
        }

        // Native language - no star
        nativeLanguageBadge.configure(with: user.nativeLanguage, isNative: true, showStar: false)

        aspiringLanguagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for language in user.aspiringLanguages {
            let badge = LanguageBadgeView()
            // Show star only if this language is in their openToLanguages list
            let isOpenToMatch = user.openToLanguages.contains { $0.code == language.language.code }
            badge.configure(with: language, isNative: false, showStar: isOpenToMatch)
            aspiringLanguagesStack.addArrangedSubview(badge)
        }

        photoGridView.configure(with: user.photoURLs)

        let languageNames = user.openToLanguages.map { $0.name }.joined(separator: ", ")
        openToMatchLabel.text = "Open to match in: \(languageNames)"

        bioLabel.text = user.bio ?? ""
        matchDateLabel.text = user.formattedMatchDate

        aboutLabel.text = "About \(user.firstName)"
    }

    private func loadImage(from urlString: String, into imageView: UIImageView) {
        ImageService.shared.loadImage(
            from: urlString,
            into: imageView,
            placeholder: UIImage(systemName: "person.circle.fill")
        )
    }
}