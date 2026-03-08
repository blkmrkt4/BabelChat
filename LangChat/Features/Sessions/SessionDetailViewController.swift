import UIKit

class SessionDetailViewController: UIViewController {

    // MARK: - Properties
    private let session: Session
    private var participants: [SessionParticipant] = []

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let hostAvatarView = UIImageView()
    private let hostNameLabel = UILabel()
    private let titleLabel = UILabel()
    private let languagePairLabel = UILabel()
    private let statusLabel = UILabel()
    private let participantsLabel = UILabel()
    private let speakersLabel = UILabel()
    private let joinButton = UIButton(type: .system)

    // MARK: - Init
    init(session: Session) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureContent()
        loadParticipants()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = session.displayTitle

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
        ])

        // Host avatar
        hostAvatarView.contentMode = .scaleAspectFill
        hostAvatarView.clipsToBounds = true
        hostAvatarView.layer.cornerRadius = 40
        hostAvatarView.backgroundColor = .systemGray5
        hostAvatarView.image = UIImage(systemName: "person.circle.fill")
        hostAvatarView.tintColor = .systemGray3
        hostAvatarView.translatesAutoresizingMaskIntoConstraints = false
        hostAvatarView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        hostAvatarView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        contentStack.addArrangedSubview(hostAvatarView)

        // Host name
        hostNameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        hostNameLabel.textAlignment = .center
        contentStack.addArrangedSubview(hostNameLabel)

        // Title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Language pair
        languagePairLabel.font = .systemFont(ofSize: 16, weight: .medium)
        languagePairLabel.textColor = .systemBlue
        contentStack.addArrangedSubview(languagePairLabel)

        // Status
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 6
        statusLabel.clipsToBounds = true
        statusLabel.textColor = .white
        contentStack.addArrangedSubview(statusLabel)

        // Participants
        participantsLabel.font = .systemFont(ofSize: 15, weight: .regular)
        participantsLabel.textColor = .secondaryLabel
        participantsLabel.textAlignment = .center
        contentStack.addArrangedSubview(participantsLabel)

        // Speakers
        speakersLabel.font = .systemFont(ofSize: 14, weight: .regular)
        speakersLabel.textColor = .tertiaryLabel
        speakersLabel.textAlignment = .center
        speakersLabel.numberOfLines = 0
        contentStack.addArrangedSubview(speakersLabel)

        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(spacer)

        // Join button
        joinButton.setTitle("session_join".localized, for: .normal)
        joinButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.backgroundColor = .systemBlue
        joinButton.layer.cornerRadius = 12
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        joinButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        contentStack.addArrangedSubview(joinButton)
    }

    private func configureContent() {
        titleLabel.text = session.displayTitle
        languagePairLabel.text = session.languagePair.displayString
        participantsLabel.text = "\(session.participantCount)/4 \("session_participants".localized)"
        hostNameLabel.text = session.host?.firstName ?? "session_role_host".localized

        if let goal = session.goal, !goal.isEmpty {
            let goalDetailLabel = UILabel()
            goalDetailLabel.font = .systemFont(ofSize: 14)
            goalDetailLabel.textColor = .secondaryLabel
            goalDetailLabel.textAlignment = .center
            goalDetailLabel.numberOfLines = 0
            goalDetailLabel.text = "\("session_goal_label".localized): \(goal)"
            contentStack.insertArrangedSubview(goalDetailLabel, at: contentStack.arrangedSubviews.firstIndex(of: languagePairLabel)! + 1)
        }

        if session.isLive {
            statusLabel.text = "  LIVE  "
            statusLabel.backgroundColor = .systemRed
        } else if let scheduledAt = session.scheduledAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            statusLabel.text = "  \(formatter.string(from: scheduledAt))  "
            statusLabel.backgroundColor = .systemOrange
        }

        // Check if current user is the host
        if let currentUserId = SupabaseService.shared.currentUserId,
           session.hostId == currentUserId.uuidString {
            joinButton.setTitle(session.isLive ? "session_resume".localized : "session_start".localized, for: .normal)
        }
    }

    private func loadParticipants() {
        Task {
            do {
                let fetched = try await SessionService.shared.getSessionParticipants(sessionId: session.id)
                await MainActor.run {
                    self.participants = fetched
                    let speakers = fetched.filter { $0.role.canSpeak }
                    if !speakers.isEmpty {
                        self.speakersLabel.text = "Speakers: \(speakers.count) | Listeners: \(fetched.count - speakers.count)"
                    }
                }
            } catch {
                print("Failed to load participants: \(error)")
            }
        }
    }

    // MARK: - Actions

    @objc private func joinTapped() {
        // Check free tier limit
        let tier = SubscriptionService.shared.currentStatus.tier
        let limitResult = UsageLimitService.shared.checkLimit(for: .sessionJoins, tier: tier)

        if case .limitReached(_, let limit, let resetDate) = limitResult {
            UpgradePromptViewController.present(for: .sessionJoins, resetDate: resetDate, from: self)
            return
        }

        joinButton.isEnabled = false
        joinButton.setTitle("common_loading".localized, for: .normal)

        Task {
            do {
                // Determine role
                var role: SessionRole = .listener
                if let currentUserId = SupabaseService.shared.currentUserId,
                   session.hostId == currentUserId.uuidString {
                    role = .host
                } else if tier.canSpeakInSession {
                    role = .listener // Start as listener, can be promoted
                }

                if role != .host {
                    try await SessionService.shared.joinSession(sessionId: session.id, role: role)
                    UsageLimitService.shared.incrementUsage(for: .sessionJoins)
                }

                await MainActor.run {
                    let sessionVC = SessionViewController(session: self.session)
                    self.navigationController?.pushViewController(sessionVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.joinButton.isEnabled = true
                    self.joinButton.setTitle("session_join".localized, for: .normal)
                    let alert = UIAlertController(title: "session_error_title".localized, message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
