import UIKit

class LanguageBadgeView: UIView {

    private let containerView = UIView()
    private let languageLabel = UILabel()
    private let proficiencyLabel = UILabel()
    private let starImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 2

        languageLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        languageLabel.textColor = .white
        containerView.addSubview(languageLabel)
        languageLabel.translatesAutoresizingMaskIntoConstraints = false

        proficiencyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        proficiencyLabel.textColor = .white
        containerView.addSubview(proficiencyLabel)
        proficiencyLabel.translatesAutoresizingMaskIntoConstraints = false

        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .white
        starImageView.contentMode = .scaleAspectFit
        containerView.addSubview(starImageView)
        starImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            languageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            languageLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            proficiencyLabel.leadingAnchor.constraint(equalTo: languageLabel.trailingAnchor, constant: 6),
            proficiencyLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            starImageView.leadingAnchor.constraint(equalTo: proficiencyLabel.trailingAnchor, constant: 4),
            starImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),

            containerView.heightAnchor.constraint(equalToConstant: 40),
            // Ensure minimum width for content
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func configure(with userLanguage: UserLanguage, isNative: Bool, showStar: Bool = false) {
        languageLabel.text = userLanguage.displayCode
        proficiencyLabel.text = userLanguage.displayProficiency

        if isNative {
            containerView.backgroundColor = UIColor.systemBlue
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            switch userLanguage.proficiency {
            case .beginner:
                containerView.backgroundColor = UIColor.systemOrange
                containerView.layer.borderColor = UIColor.systemYellow.cgColor
            case .intermediate:
                containerView.backgroundColor = UIColor.systemBlue
                containerView.layer.borderColor = UIColor.systemYellow.cgColor
            case .advanced:
                containerView.backgroundColor = UIColor.systemGreen
                containerView.layer.borderColor = UIColor.systemGreen.cgColor
            case .native:
                containerView.backgroundColor = UIColor.systemBlue
                containerView.layer.borderColor = UIColor.systemBlue.cgColor
            }
        }

        // Only show star if explicitly requested (for languages they're seeking matches in)
        starImageView.isHidden = !showStar
    }
}