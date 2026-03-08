import UIKit

class SessionCell: UITableViewCell {

    static let reuseIdentifier = "SessionCell"

    private let hostAvatarView = UIImageView()
    private let titleLabel = UILabel()
    private let languagePairLabel = UILabel()
    private let participantCountLabel = UILabel()
    private let statusBadge = UILabel()
    private let timeLabel = UILabel()
    private let containerStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator

        // Host avatar
        hostAvatarView.contentMode = .scaleAspectFill
        hostAvatarView.clipsToBounds = true
        hostAvatarView.layer.cornerRadius = 24
        hostAvatarView.backgroundColor = .systemGray5
        hostAvatarView.image = UIImage(systemName: "person.circle.fill")
        hostAvatarView.tintColor = .systemGray3
        contentView.addSubview(hostAvatarView)

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 1

        // Language pair
        languagePairLabel.font = .systemFont(ofSize: 14, weight: .regular)
        languagePairLabel.textColor = .secondaryLabel

        // Participant count
        participantCountLabel.font = .systemFont(ofSize: 13, weight: .regular)
        participantCountLabel.textColor = .tertiaryLabel

        // Status badge
        statusBadge.font = .systemFont(ofSize: 11, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 4
        statusBadge.clipsToBounds = true
        statusBadge.textColor = .white

        // Time label
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right

        // Info stack
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, languagePairLabel, participantCountLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        contentView.addSubview(infoStack)

        // Right side stack
        let rightStack = UIStackView(arrangedSubviews: [statusBadge, timeLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing
        contentView.addSubview(rightStack)

        // Store references for constraints
        hostAvatarView.translatesAutoresizingMaskIntoConstraints = false
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostAvatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hostAvatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            hostAvatarView.widthAnchor.constraint(equalToConstant: 48),
            hostAvatarView.heightAnchor.constraint(equalToConstant: 48),

            infoStack.leadingAnchor.constraint(equalTo: hostAvatarView.trailingAnchor, constant: 12),
            infoStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoStack.trailingAnchor.constraint(lessThanOrEqualTo: rightStack.leadingAnchor, constant: -8),

            rightStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            rightStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            statusBadge.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    private func setupConstraints() {
        // Handled in setupViews
    }

    func configure(with session: Session) {
        titleLabel.text = session.displayTitle
        languagePairLabel.text = session.languagePair.displayString
        participantCountLabel.text = "\(session.participantCount)/4 \("session_participants".localized)"

        switch session.status {
        case .live:
            statusBadge.text = " LIVE "
            statusBadge.backgroundColor = .systemRed
            statusBadge.isHidden = false
            timeLabel.isHidden = true
        case .scheduled:
            statusBadge.isHidden = true
            timeLabel.isHidden = false
            if let scheduledAt = session.scheduledAt {
                let formatter = DateFormatter()
                if Calendar.current.isDateInToday(scheduledAt) {
                    formatter.dateFormat = "h:mm a"
                } else {
                    formatter.dateFormat = "MMM d, h:mm a"
                }
                timeLabel.text = formatter.string(from: scheduledAt)
            }
        default:
            statusBadge.isHidden = true
            timeLabel.isHidden = true
        }

        // Load host avatar if available
        if let host = session.host, let urlString = host.profileImageURL {
            ImageService.shared.loadImage(from: urlString, into: hostAvatarView)
        }
    }

    func configureForInvite(with invite: SessionInvite) {
        if let session = invite.session {
            titleLabel.text = session.displayTitle
            languagePairLabel.text = session.languagePair.displayString
        } else {
            titleLabel.text = "session_invite".localized
            languagePairLabel.text = ""
        }
        participantCountLabel.text = "session_invite_pending".localized
        statusBadge.text = " \("session_invite".localized) "
        statusBadge.backgroundColor = .systemBlue
        statusBadge.isHidden = false
        timeLabel.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostAvatarView.image = UIImage(systemName: "person.circle.fill")
        statusBadge.isHidden = true
        timeLabel.isHidden = true
    }
}
