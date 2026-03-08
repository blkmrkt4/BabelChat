import UIKit

class VideoParticipantView: UIView {

    // MARK: - UI
    private let videoContainer = UIView()
    private let placeholderIcon = UIImageView()
    private let nameLabel = UILabel()
    private let roleBadge = UILabel()
    private let muteIndicator = UIImageView()
    private let videoOffIndicator = UIImageView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        clipsToBounds = true

        // Video container (for LiveKit VideoView)
        videoContainer.backgroundColor = .systemGray6
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(videoContainer)

        // Placeholder
        placeholderIcon.image = UIImage(systemName: "person.fill")
        placeholderIcon.tintColor = .systemGray3
        placeholderIcon.contentMode = .scaleAspectFit
        placeholderIcon.translatesAutoresizingMaskIntoConstraints = false
        videoContainer.addSubview(placeholderIcon)

        // Name label
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        nameLabel.textAlignment = .center
        nameLabel.layer.cornerRadius = 4
        nameLabel.clipsToBounds = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Role badge
        roleBadge.font = .systemFont(ofSize: 10, weight: .bold)
        roleBadge.textColor = .white
        roleBadge.backgroundColor = .systemBlue
        roleBadge.textAlignment = .center
        roleBadge.layer.cornerRadius = 4
        roleBadge.clipsToBounds = true
        roleBadge.translatesAutoresizingMaskIntoConstraints = false
        roleBadge.isHidden = true
        addSubview(roleBadge)

        // Mute indicator
        muteIndicator.image = UIImage(systemName: "mic.slash.fill")
        muteIndicator.tintColor = .systemRed
        muteIndicator.translatesAutoresizingMaskIntoConstraints = false
        muteIndicator.isHidden = true
        addSubview(muteIndicator)

        // Video off indicator
        videoOffIndicator.image = UIImage(systemName: "video.slash.fill")
        videoOffIndicator.tintColor = .systemRed
        videoOffIndicator.translatesAutoresizingMaskIntoConstraints = false
        videoOffIndicator.isHidden = true
        addSubview(videoOffIndicator)

        NSLayoutConstraint.activate([
            videoContainer.topAnchor.constraint(equalTo: topAnchor),
            videoContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            placeholderIcon.centerXAnchor.constraint(equalTo: videoContainer.centerXAnchor),
            placeholderIcon.centerYAnchor.constraint(equalTo: videoContainer.centerYAnchor),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 40),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            roleBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            roleBadge.topAnchor.constraint(equalTo: topAnchor, constant: 4),

            muteIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            muteIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            muteIndicator.widthAnchor.constraint(equalToConstant: 16),
            muteIndicator.heightAnchor.constraint(equalToConstant: 16),

            videoOffIndicator.leadingAnchor.constraint(equalTo: muteIndicator.trailingAnchor, constant: 4),
            videoOffIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            videoOffIndicator.widthAnchor.constraint(equalToConstant: 16),
            videoOffIndicator.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    // MARK: - Configuration

    func configure(name: String, role: SessionRole, isMuted: Bool, isVideoOff: Bool) {
        nameLabel.text = " \(name) "
        nameLabel.isHidden = false
        placeholderIcon.isHidden = !isVideoOff

        muteIndicator.isHidden = !isMuted
        videoOffIndicator.isHidden = !isVideoOff

        if role == .host {
            roleBadge.text = " HOST "
            roleBadge.backgroundColor = .systemOrange
            roleBadge.isHidden = false
        } else if role == .coSpeaker || role == .rotatingSpeaker {
            roleBadge.text = " SPEAKER "
            roleBadge.backgroundColor = .systemBlue
            roleBadge.isHidden = false
        } else {
            roleBadge.isHidden = true
        }

        videoContainer.backgroundColor = isVideoOff ? .systemGray6 : .black
    }

    func configureEmpty() {
        nameLabel.isHidden = true
        roleBadge.isHidden = true
        muteIndicator.isHidden = true
        videoOffIndicator.isHidden = true
        placeholderIcon.isHidden = false
        videoContainer.backgroundColor = .systemGray6
        placeholderIcon.image = UIImage(systemName: "plus")
        placeholderIcon.tintColor = .systemGray4
    }
}
