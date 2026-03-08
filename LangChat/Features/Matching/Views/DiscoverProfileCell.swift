import UIKit

class DiscoverProfileCell: UICollectionViewCell {

    static let reuseIdentifier = "DiscoverProfileCell"

    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let scorePill = UILabel()
    private let onlineDot = UIView()
    private let badgeStack = UIStackView()
    private let blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        // Photo
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 12
        photoImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        photoImageView.backgroundColor = .tertiarySystemBackground
        contentView.addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Blur overlay
        blurOverlay.isHidden = true
        blurOverlay.layer.cornerRadius = 12
        blurOverlay.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurOverlay.clipsToBounds = true
        photoImageView.addSubview(blurOverlay)
        blurOverlay.translatesAutoresizingMaskIntoConstraints = false

        // Score pill (top-right)
        scorePill.font = .systemFont(ofSize: 11, weight: .bold)
        scorePill.textColor = .white
        scorePill.textAlignment = .center
        scorePill.layer.cornerRadius = 10
        scorePill.clipsToBounds = true
        contentView.addSubview(scorePill)
        scorePill.translatesAutoresizingMaskIntoConstraints = false

        // Online dot (top-left)
        onlineDot.backgroundColor = .systemGreen
        onlineDot.layer.cornerRadius = 4
        onlineDot.layer.borderWidth = 1.5
        onlineDot.layer.borderColor = UIColor.white.cgColor
        onlineDot.isHidden = true
        contentView.addSubview(onlineDot)
        onlineDot.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Info (age, location)
        infoLabel.font = .systemFont(ofSize: 12, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 1
        contentView.addSubview(infoLabel)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        // Language badge stack
        badgeStack.axis = .horizontal
        badgeStack.spacing = 4
        badgeStack.alignment = .center
        contentView.addSubview(badgeStack)
        badgeStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoImageView.heightAnchor.constraint(equalToConstant: 140),

            blurOverlay.topAnchor.constraint(equalTo: photoImageView.topAnchor),
            blurOverlay.leadingAnchor.constraint(equalTo: photoImageView.leadingAnchor),
            blurOverlay.trailingAnchor.constraint(equalTo: photoImageView.trailingAnchor),
            blurOverlay.bottomAnchor.constraint(equalTo: photoImageView.bottomAnchor),

            scorePill.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            scorePill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            scorePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            scorePill.heightAnchor.constraint(equalToConstant: 20),

            onlineDot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            onlineDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            onlineDot.widthAnchor.constraint(equalToConstant: 8),
            onlineDot.heightAnchor.constraint(equalToConstant: 8),

            nameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            badgeStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 4),
            badgeStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            badgeStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),
        ])
    }

    func configure(with user: User, score: Int) {
        nameLabel.text = user.firstName

        // Build info string
        var infoParts: [String] = []
        if let age = user.age { infoParts.append("\(age)") }
        if let location = user.displayLocation {
            // Extract city or country
            let components = location.components(separatedBy: ",")
            if let first = components.first?.trimmingCharacters(in: .whitespaces) {
                infoParts.append(first)
            }
        }
        infoLabel.text = infoParts.joined(separator: ", ")

        // Score pill
        scorePill.text = " \(score) "
        if score >= 80 {
            scorePill.backgroundColor = .systemGreen
        } else if score >= 60 {
            scorePill.backgroundColor = .systemYellow
        } else {
            scorePill.backgroundColor = .systemOrange
        }

        // Online dot
        onlineDot.isHidden = !user.isOnline

        // Photo
        if let urlString = user.profileImageURL {
            ImageService.shared.loadImage(from: urlString, into: photoImageView)
        } else if !user.photoURLs.isEmpty {
            ImageService.shared.loadImage(from: user.photoURLs[0], into: photoImageView)
        } else {
            photoImageView.image = UIImage(systemName: "person.circle.fill")
            photoImageView.tintColor = .tertiaryLabel
        }

        // Blur overlay
        blurOverlay.isHidden = !user.shouldBlurPhoto(at: 0)

        // Language badges (show up to 2)
        badgeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let languages = [user.nativeLanguage] + Array(user.learningLanguages.prefix(1))
        for lang in languages.prefix(2) {
            let badge = createMicroBadge(flag: lang.language.flag, code: lang.language.code)
            badgeStack.addArrangedSubview(badge)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        nameLabel.text = nil
        infoLabel.text = nil
        scorePill.text = nil
        onlineDot.isHidden = true
        blurOverlay.isHidden = true
        badgeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func createMicroBadge(flag: String, code: String) -> UIView {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.text = "\(flag)\(code)"
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }
}
