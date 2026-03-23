import UIKit

class SessionCell: UITableViewCell {

    static let reuseIdentifier = "SessionCell"

    private let hostAvatarView = UIImageView()
    private let titleLabel = UILabel()
    private let hostInfoLabel = UILabel()
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
        titleLabel.numberOfLines = 2

        // Host info (e.g. "Hosted by Hannah & Aviella")
        hostInfoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        hostInfoLabel.textColor = .secondaryLabel

        // Language pair
        languagePairLabel.font = .systemFont(ofSize: 13, weight: .regular)
        languagePairLabel.textColor = .tertiaryLabel

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
        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right
        timeLabel.numberOfLines = 2

        // Info stack
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, hostInfoLabel, languagePairLabel, participantCountLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 3
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
            rightStack.widthAnchor.constraint(lessThanOrEqualToConstant: 100),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 104),

            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            statusBadge.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    private func setupConstraints() {
        // Handled in setupViews
    }

    func configure(with session: Session) {
        titleLabel.text = session.displayTitle

        // Host info line: "Hosted by Hannah" or "Hosted by Hannah & Aviella"
        if let hostName = session.host?.firstName {
            var hostText = "\("session_hosted_by".localized) \(hostName)"
            if let coHost = session.participants?.first(where: { $0.role == .coHost }),
               let coHostName = coHost.user?.firstName {
                hostText += " & \(coHostName)"
            }
            hostInfoLabel.text = hostText
            hostInfoLabel.isHidden = false
        } else {
            hostInfoLabel.isHidden = true
        }

        languagePairLabel.text = "\(session.languagePair.displayString) · \(session.maxDurationMinutes) min"

        let maxP = session.maxParticipants
        switch session.status {
        case .live:
            var participantText = "\(session.participantCount)/\(maxP) \("session_participants".localized)"
            if session.viewerCount > 0 {
                participantText += " · \(session.viewerCount) \("session_users_watching".localized)"
            }
            participantCountLabel.text = participantText
            statusBadge.text = " LIVE "
            statusBadge.backgroundColor = .systemRed
            statusBadge.isHidden = false
            timeLabel.isHidden = true
        case .scheduled:
            participantCountLabel.text = "\(session.participantCount)/\(maxP) \("session_participants".localized)"
            statusBadge.isHidden = true
            timeLabel.isHidden = false
            if let scheduledAt = session.scheduledAt {
                timeLabel.text = Self.relativeTimeString(for: scheduledAt)
            }
        case .ended:
            participantCountLabel.text = "\(session.participantCount)/\(maxP) \("session_participants".localized)"
            statusBadge.text = " \("session_ended_badge".localized) "
            statusBadge.backgroundColor = .systemGray
            statusBadge.isHidden = false
            if let endedAt = session.endedAt {
                let elapsed = Date().timeIntervalSince(endedAt)
                let hours = Int(elapsed / 3600)
                let minutes = Int(elapsed / 60) % 60
                let relativeTime: String
                if hours > 0 {
                    relativeTime = "\(hours)h"
                } else {
                    relativeTime = "\(minutes)m"
                }
                timeLabel.text = String(format: "session_ended_ago".localized, relativeTime)
                timeLabel.isHidden = false
            } else {
                timeLabel.isHidden = true
            }
        default:
            participantCountLabel.text = "\(session.participantCount)/\(maxP) \("session_participants".localized)"
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

    /// Returns a human-readable relative time string, e.g. "Starts in 27 hours" or "Today at 2:00 PM"
    static func relativeTimeString(for date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            // Already past — show absolute time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        if minutes < 60 {
            return String(format: "session_starts_in_minutes".localized, minutes)
        } else if hours < 24 {
            return "In \(hours)h\n\(timeFormatter.string(from: date))"
        } else if days == 1 {
            return String(format: "session_starts_tomorrow".localized, timeFormatter.string(from: date))
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: date))\n\(timeFormatter.string(from: date))"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostAvatarView.image = UIImage(systemName: "person.circle.fill")
        hostInfoLabel.isHidden = true
        statusBadge.isHidden = true
        timeLabel.isHidden = true
    }
}
