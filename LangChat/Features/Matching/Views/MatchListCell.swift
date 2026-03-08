import UIKit

class MatchListCell: UICollectionViewCell {

    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let locationLabel = UILabel()
    private let categoryLabel = UILabel()
    private let onlineDot = UIView()
    private let newMessageDot = UIView()
    private let separatorLine = UIView()

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

        // Photo
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 8
        photoImageView.backgroundColor = .systemGray5
        contentView.addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Location
        locationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        locationLabel.textColor = .secondaryLabel
        contentView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        // Category tags
        categoryLabel.font = .systemFont(ofSize: 13, weight: .regular)
        categoryLabel.textColor = .systemBlue
        contentView.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        // Online dot
        onlineDot.backgroundColor = .systemGreen
        onlineDot.layer.cornerRadius = 5
        onlineDot.isHidden = true
        contentView.addSubview(onlineDot)
        onlineDot.translatesAutoresizingMaskIntoConstraints = false

        // New message dot
        newMessageDot.backgroundColor = .systemRed
        newMessageDot.layer.cornerRadius = 4
        newMessageDot.isHidden = true
        contentView.addSubview(newMessageDot)
        newMessageDot.translatesAutoresizingMaskIntoConstraints = false

        // Separator
        separatorLine.backgroundColor = .separator
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Photo: 56x56, leading 16, vertically centered
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 56),
            photoImageView.heightAnchor.constraint(equalToConstant: 56),

            // Name: 12pt from photo
            nameLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: onlineDot.leadingAnchor, constant: -8),

            // Location
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            locationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            // Category
            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 2),
            categoryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            // Online dot: trailing 16, vertically centered
            onlineDot.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            onlineDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -6),
            onlineDot.widthAnchor.constraint(equalToConstant: 10),
            onlineDot.heightAnchor.constraint(equalToConstant: 10),

            // New message dot: below online dot
            newMessageDot.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
            newMessageDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8),
            newMessageDot.widthAnchor.constraint(equalToConstant: 8),
            newMessageDot.heightAnchor.constraint(equalToConstant: 8),

            // Separator: 0.5pt, inset 84pt from leading
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 84),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with match: Match, categoryLabel categoryText: String) {
        // Name, age
        let user = match.user
        if let age = user.age {
            nameLabel.text = "\(user.firstName), \(age)"
        } else {
            nameLabel.text = user.firstName
        }

        // Location
        locationLabel.text = user.displayLocation ?? ""

        // Category tags
        categoryLabel.text = categoryText

        // Indicators
        onlineDot.isHidden = !user.isOnline
        newMessageDot.isHidden = !match.hasNewMessage

        // Load photo
        if let profileImageURL = user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileImageURL,
                into: photoImageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        } else {
            photoImageView.image = UIImage(systemName: "person.fill")
            photoImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        onlineDot.isHidden = true
        newMessageDot.isHidden = true
    }
}
