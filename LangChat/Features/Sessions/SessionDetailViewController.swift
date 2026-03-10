import UIKit
import UserNotifications

class SessionDetailViewController: UIViewController {

    // MARK: - Properties
    private let session: Session
    private var participants: [SessionParticipant] = []
    private var isTrackingViewer = false

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let hostAvatarView = UIImageView()
    private let hostNameLabel = UILabel()
    private let titleLabel = UILabel()
    private let languagePairLabel = UILabel()
    private let statusLabel = UILabel()
    private let participantsLabel = UILabel()
    private let viewerCountLabel = UILabel()
    private let videoSlotsLabel = UILabel()
    private let speakersLabel = UILabel()
    private let joinButton = UIButton(type: .system)
    private let reserveVideoButton = UIButton(type: .system)
    private let notifyButton = UIButton(type: .system)
    private let countdownLabel = UILabel()

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
        loadVideoSlotStatus()
        trackViewerCount(increment: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        trackViewerCount(increment: false)
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

        // Viewer count
        viewerCountLabel.font = .systemFont(ofSize: 14, weight: .regular)
        viewerCountLabel.textColor = .tertiaryLabel
        viewerCountLabel.textAlignment = .center
        viewerCountLabel.isHidden = true
        contentStack.addArrangedSubview(viewerCountLabel)

        // Video slots availability
        videoSlotsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        videoSlotsLabel.textColor = .systemGreen
        videoSlotsLabel.textAlignment = .center
        videoSlotsLabel.isHidden = true
        contentStack.addArrangedSubview(videoSlotsLabel)

        // Speakers
        speakersLabel.font = .systemFont(ofSize: 14, weight: .regular)
        speakersLabel.textColor = .tertiaryLabel
        speakersLabel.textAlignment = .center
        speakersLabel.numberOfLines = 0
        contentStack.addArrangedSubview(speakersLabel)

        // Countdown label (shown for future sessions)
        countdownLabel.font = .systemFont(ofSize: 14, weight: .medium)
        countdownLabel.textColor = .secondaryLabel
        countdownLabel.textAlignment = .center
        countdownLabel.numberOfLines = 0
        countdownLabel.isHidden = true
        contentStack.addArrangedSubview(countdownLabel)

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
        contentStack.addArrangedSubview(joinButton)
        // Constrain after adding to stack so they share a common ancestor
        joinButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        joinButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        // Reserve Video Spot button (shown for premium+ users)
        reserveVideoButton.setTitle("session_reserve_video".localized, for: .normal)
        reserveVideoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        reserveVideoButton.setTitleColor(.white, for: .normal)
        reserveVideoButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        reserveVideoButton.tintColor = .white
        reserveVideoButton.backgroundColor = .systemPurple
        reserveVideoButton.layer.cornerRadius = 12
        reserveVideoButton.addTarget(self, action: #selector(reserveVideoTapped), for: .touchUpInside)
        reserveVideoButton.translatesAutoresizingMaskIntoConstraints = false
        reserveVideoButton.isHidden = true
        contentStack.addArrangedSubview(reserveVideoButton)
        reserveVideoButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        reserveVideoButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        // Notify Me button (shown for future sessions that can't be joined yet)
        notifyButton.setTitle("session_notify_me".localized, for: .normal)
        notifyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        notifyButton.setTitleColor(.systemBlue, for: .normal)
        notifyButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
        notifyButton.tintColor = .systemBlue
        notifyButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        notifyButton.layer.cornerRadius = 12
        notifyButton.addTarget(self, action: #selector(notifyMeTapped), for: .touchUpInside)
        notifyButton.translatesAutoresizingMaskIntoConstraints = false
        notifyButton.isHidden = true
        contentStack.addArrangedSubview(notifyButton)
        notifyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        notifyButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    private func configureContent() {
        titleLabel.text = session.displayTitle
        languagePairLabel.text = "\(session.languagePair.displayString) · \(session.maxDurationMinutes) min"
        participantsLabel.text = "\(session.participantCount)/\(session.maxParticipants) \("session_participants".localized)"
        hostNameLabel.text = session.host?.firstName ?? "session_role_host".localized

        // Load host profile picture
        if let host = session.host, let urlString = host.profileImageURL {
            ImageService.shared.loadImage(from: urlString, into: hostAvatarView)
        }

        // Show viewer count for live sessions
        if session.isLive && session.viewerCount > 0 {
            viewerCountLabel.text = "\(session.viewerCount) \("session_users_watching".localized)"
            viewerCountLabel.isHidden = false
        }

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

            // Show relative time and handle join gating for future sessions
            let timeUntilStart = scheduledAt.timeIntervalSince(Date())
            let fiveMinutes: TimeInterval = 5 * 60

            if timeUntilStart > fiveMinutes {
                // Session is too far in the future to join
                let relativeTime = SessionCell.relativeTimeString(for: scheduledAt)
                countdownLabel.text = "\(relativeTime)\n\("session_join_available_soon".localized)"
                countdownLabel.isHidden = false
                notifyButton.isHidden = false

                // Check if notification is already scheduled
                checkExistingNotification()
            }
        }

        // Check if current user is the host (lowercased: Swift UUID is uppercase, DB is lowercase)
        let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""
        let isHost = session.hostId.lowercased() == currentUserId
        if isHost {
            joinButton.setTitle(session.isLive ? "session_resume".localized : "session_start".localized, for: .normal)
            // Host can always join/start — hide gating UI
            countdownLabel.isHidden = true
            notifyButton.isHidden = true
        } else if let scheduledAt = session.scheduledAt {
            let timeUntilStart = scheduledAt.timeIntervalSince(Date())
            let fiveMinutes: TimeInterval = 5 * 60
            if timeUntilStart > fiveMinutes {
                joinButton.isEnabled = false
                joinButton.backgroundColor = .systemGray4
                joinButton.setTitle("session_join".localized, for: .normal)
            }
        }
    }

    private func checkExistingNotification() {
        let notificationId = "session_reminder_\(session.id)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let isScheduled = requests.contains { $0.identifier == notificationId }
            DispatchQueue.main.async {
                if isScheduled {
                    self?.notifyButton.setTitle("session_notification_scheduled".localized, for: .normal)
                    self?.notifyButton.setImage(UIImage(systemName: "bell.badge.fill"), for: .normal)
                    self?.notifyButton.isEnabled = false
                }
            }
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

    private func loadVideoSlotStatus() {
        let tier = SubscriptionService.shared.currentStatus.tier

        Task {
            do {
                let slotInfo = try await SessionService.shared.getVideoSlotStatus(sessionId: session.id)
                await MainActor.run {
                    let available = slotInfo.availableSlots
                    let total = slotInfo.maxSlots

                    // Show video slot availability
                    if available > 0 {
                        videoSlotsLabel.text = "\(available)/\(total) \("session_video_spots_available".localized)"
                        videoSlotsLabel.textColor = .systemGreen
                    } else {
                        videoSlotsLabel.text = "\("session_video_spots_full".localized)"
                        videoSlotsLabel.textColor = .systemOrange
                    }
                    videoSlotsLabel.isHidden = false

                    // Show reserve button for premium+ users who don't have a slot yet
                    if tier.canViewSessionVideo && slotInfo.myStatus == nil {
                        reserveVideoButton.isHidden = false
                    } else if let myStatus = slotInfo.myStatus {
                        switch myStatus {
                        case .confirmed, .active:
                            reserveVideoButton.setTitle("session_video_spot_confirmed".localized, for: .normal)
                            reserveVideoButton.backgroundColor = .systemGreen
                            reserveVideoButton.isEnabled = false
                            reserveVideoButton.isHidden = false
                        case .waitlisted:
                            let posText = slotInfo.myPosition.map { " (#\($0))" } ?? ""
                            reserveVideoButton.setTitle("\("session_video_waitlisted".localized)\(posText)", for: .normal)
                            reserveVideoButton.backgroundColor = .systemOrange
                            reserveVideoButton.isEnabled = false
                            reserveVideoButton.isHidden = false
                        case .expired:
                            break
                        }
                    }
                }
            } catch {
                print("Failed to load video slot status: \(error)")
            }
        }
    }

    @objc private func reserveVideoTapped() {
        reserveVideoButton.isEnabled = false
        reserveVideoButton.setTitle("common_loading".localized, for: .normal)

        Task {
            do {
                let result = try await SessionService.shared.reserveVideoSlot(sessionId: session.id)
                await MainActor.run {
                    switch result.status {
                    case .confirmed:
                        reserveVideoButton.setTitle("session_video_spot_confirmed".localized, for: .normal)
                        reserveVideoButton.backgroundColor = .systemGreen
                    case .waitlisted:
                        let posText = result.position.map { " (#\($0))" } ?? ""
                        reserveVideoButton.setTitle("\("session_video_waitlisted".localized)\(posText)", for: .normal)
                        reserveVideoButton.backgroundColor = .systemOrange
                    default:
                        break
                    }
                    // Reload slot status to update availability display
                    loadVideoSlotStatus()
                }
            } catch {
                await MainActor.run {
                    reserveVideoButton.isEnabled = true
                    reserveVideoButton.setTitle("session_reserve_video".localized, for: .normal)
                    let alert = UIAlertController(title: "session_error_title".localized, message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func notifyMeTapped() {
        guard let scheduledAt = session.scheduledAt else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard let self = self, granted else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "session_notification_denied_title".localized,
                        message: "session_notification_denied_message".localized,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    self?.present(alert, animated: true)
                }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "session_reminder_title".localized
            content.body = String(format: "session_reminder_body".localized, self.session.displayTitle)
            content.sound = .default

            // Schedule 5 minutes before start
            let triggerDate = scheduledAt.addingTimeInterval(-5 * 60)
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let notificationId = "session_reminder_\(self.session.id)"
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.notifyButton.setTitle("session_notification_scheduled".localized, for: .normal)
                        self.notifyButton.setImage(UIImage(systemName: "bell.badge.fill"), for: .normal)
                        self.notifyButton.isEnabled = false
                    }
                }
            }
        }
    }

    private func trackViewerCount(increment: Bool) {
        guard session.isLive || session.isScheduled else { return }
        if increment {
            guard !isTrackingViewer else { return }
            isTrackingViewer = true
            Task { try? await SessionService.shared.incrementViewerCount(sessionId: session.id) }
        } else {
            guard isTrackingViewer else { return }
            isTrackingViewer = false
            Task { try? await SessionService.shared.decrementViewerCount(sessionId: session.id) }
        }
    }

    @objc private func joinTapped() {
        let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""
        let isHost = session.hostId.lowercased() == currentUserId

        // Time-gate: non-host users can only join within 5 minutes of start
        if !isHost, let scheduledAt = session.scheduledAt {
            let timeUntilStart = scheduledAt.timeIntervalSince(Date())
            if timeUntilStart > 5 * 60 {
                let relativeTime = SessionCell.relativeTimeString(for: scheduledAt)
                let alert = UIAlertController(
                    title: "session_not_yet_title".localized,
                    message: String(format: "session_not_yet_message".localized, relativeTime),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                present(alert, animated: true)
                return
            }
        }

        // Host path: start the session if scheduled, then go straight to the room
        if isHost {
            joinButton.isEnabled = false
            joinButton.setTitle("common_loading".localized, for: .normal)

            Task {
                do {
                    // If session is scheduled (not yet live), start it now
                    if session.status == .scheduled {
                        try await SessionService.shared.startSession(id: session.id)
                    }

                    await MainActor.run {
                        self.trackViewerCount(increment: false)
                        let sessionVC = SessionViewController(session: self.session)
                        self.navigationController?.pushViewController(sessionVC, animated: true)
                    }
                } catch {
                    await MainActor.run {
                        self.joinButton.isEnabled = true
                        self.joinButton.setTitle(self.session.isLive ? "session_resume".localized : "session_start".localized, for: .normal)
                        let alert = UIAlertController(title: "session_error_title".localized, message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
            return
        }

        // Non-host path: check limits and capacity, then join
        let tier = SubscriptionService.shared.currentStatus.tier
        let limitResult = UsageLimitService.shared.checkLimit(for: .sessionJoins, tier: tier)

        if case .limitReached(_, _, let resetDate) = limitResult {
            UpgradePromptViewController.present(for: .sessionJoins, resetDate: resetDate, from: self)
            return
        }

        if session.participantCount >= session.maxParticipants {
            let alert = UIAlertController(
                title: "session_error_title".localized,
                message: SessionError.sessionFull.errorDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
            present(alert, animated: true)
            return
        }

        joinButton.isEnabled = false
        joinButton.setTitle("common_loading".localized, for: .normal)

        Task {
            do {
                // Join as listener (upsert handles re-joining)
                try await SessionService.shared.joinSession(sessionId: session.id, role: .listener)
                UsageLimitService.shared.incrementUsage(for: .sessionJoins)

                await MainActor.run {
                    self.trackViewerCount(increment: false)
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
