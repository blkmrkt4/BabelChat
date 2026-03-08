import UIKit
import Supabase

class SessionViewController: UIViewController {

    // MARK: - Properties
    private var session: Session
    private var participants: [SessionParticipant] = []
    private var myRole: SessionRole = .listener
    private var sessionTimer: Timer?
    private var remainingSeconds: Int = 0
    private var sessionChannel: RealtimeChannel?
    private var messagesChannel: RealtimeChannel?

    // MARK: - UI
    private let timerBar = UIView()
    private let timerLabel = UILabel()
    private let sessionTitleLabel = UILabel()
    private let goalLabel = UILabel()
    private let endButton = UIButton(type: .system)

    private let videoGrid = UIStackView()
    private var videoViews: [VideoParticipantView] = []

    private let controlsBar = UIStackView()
    private let micButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private let handRaiseButton = UIButton(type: .system)
    private let manageButton = UIButton(type: .system)

    private let chatView: SessionChatView

    // State
    private var isMicOn = false
    private var isCameraOn = false
    private var isHandRaised = false

    // MARK: - Init
    init(session: Session) {
        self.session = session
        self.chatView = SessionChatView(sessionId: session.id)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        determineRole()
        connectToSession()
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            leaveSession()
        }
    }

    deinit {
        sessionTimer?.invalidate()
        SessionService.shared.unsubscribeAll()
        LiveKitService.shared.disconnect()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = "session_room_title".localized
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "session_leave".localized,
            style: .plain,
            target: self,
            action: #selector(leaveTapped)
        )

        // Timer bar
        timerBar.backgroundColor = .secondarySystemBackground
        timerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerBar)

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        timerLabel.textColor = .label
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerBar.addSubview(timerLabel)

        sessionTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sessionTitleLabel.textColor = .secondaryLabel
        sessionTitleLabel.text = session.displayTitle
        sessionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        timerBar.addSubview(sessionTitleLabel)

        // Goal label below title
        goalLabel.font = .systemFont(ofSize: 12)
        goalLabel.textColor = .tertiaryLabel
        goalLabel.text = session.goal
        goalLabel.numberOfLines = 1
        goalLabel.isHidden = session.goal == nil
        goalLabel.translatesAutoresizingMaskIntoConstraints = false
        timerBar.addSubview(goalLabel)

        // Tap goal to edit (host only)
        let goalTap = UITapGestureRecognizer(target: self, action: #selector(goalTapped))
        goalLabel.isUserInteractionEnabled = true
        goalLabel.addGestureRecognizer(goalTap)

        endButton.setTitle("session_end".localized, for: .normal)
        endButton.setTitleColor(.systemRed, for: .normal)
        endButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        endButton.addTarget(self, action: #selector(endSessionTapped), for: .touchUpInside)
        endButton.isHidden = true // Shown only for host
        endButton.translatesAutoresizingMaskIntoConstraints = false
        timerBar.addSubview(endButton)

        // Video grid (2x2)
        videoGrid.axis = .vertical
        videoGrid.spacing = 4
        videoGrid.distribution = .fillEqually
        videoGrid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoGrid)

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 4
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 4
        bottomRow.distribution = .fillEqually

        for i in 0..<4 {
            let videoView = VideoParticipantView()
            videoViews.append(videoView)
            if i < 2 {
                topRow.addArrangedSubview(videoView)
            } else {
                bottomRow.addArrangedSubview(videoView)
            }
        }

        videoGrid.addArrangedSubview(topRow)
        videoGrid.addArrangedSubview(bottomRow)

        // Controls bar
        controlsBar.axis = .horizontal
        controlsBar.spacing = 20
        controlsBar.alignment = .center
        controlsBar.distribution = .equalCentering
        controlsBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsBar)

        configureControlButton(micButton, systemName: "mic.slash.fill", action: #selector(micTapped))
        configureControlButton(cameraButton, systemName: "video.slash.fill", action: #selector(cameraTapped))
        configureControlButton(handRaiseButton, systemName: "hand.raised", action: #selector(handRaiseTapped))
        configureControlButton(manageButton, systemName: "person.2.badge.gearshape", action: #selector(manageTapped))
        manageButton.isHidden = true // Host only

        controlsBar.addArrangedSubview(micButton)
        controlsBar.addArrangedSubview(cameraButton)
        controlsBar.addArrangedSubview(handRaiseButton)
        controlsBar.addArrangedSubview(manageButton)

        // Chat view
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)

        // Constraints
        let timerBarHeight: CGFloat = session.goal != nil ? 60 : 44
        NSLayoutConstraint.activate([
            timerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            timerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerBar.heightAnchor.constraint(equalToConstant: timerBarHeight),

            timerLabel.leadingAnchor.constraint(equalTo: timerBar.leadingAnchor, constant: 16),
            timerLabel.topAnchor.constraint(equalTo: timerBar.topAnchor, constant: 12),

            sessionTitleLabel.centerXAnchor.constraint(equalTo: timerBar.centerXAnchor),
            sessionTitleLabel.topAnchor.constraint(equalTo: timerBar.topAnchor, constant: 6),

            goalLabel.centerXAnchor.constraint(equalTo: timerBar.centerXAnchor),
            goalLabel.topAnchor.constraint(equalTo: sessionTitleLabel.bottomAnchor, constant: 2),
            goalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: timerLabel.trailingAnchor, constant: 8),
            goalLabel.trailingAnchor.constraint(lessThanOrEqualTo: endButton.leadingAnchor, constant: -8),

            endButton.trailingAnchor.constraint(equalTo: timerBar.trailingAnchor, constant: -16),
            endButton.topAnchor.constraint(equalTo: timerBar.topAnchor, constant: 12),

            videoGrid.topAnchor.constraint(equalTo: timerBar.bottomAnchor, constant: 4),
            videoGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            videoGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            videoGrid.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.56),

            controlsBar.topAnchor.constraint(equalTo: videoGrid.bottomAnchor, constant: 8),
            controlsBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            controlsBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            controlsBar.heightAnchor.constraint(equalToConstant: 50),

            chatView.topAnchor.constraint(equalTo: controlsBar.bottomAnchor, constant: 8),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureControlButton(_ button: UIButton, systemName: String, action: Selector) {
        button.setImage(UIImage(systemName: systemName)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        ), for: .normal)
        button.tintColor = .label
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    // MARK: - Session Logic

    private func determineRole() {
        guard let currentUserId = SupabaseService.shared.currentUserId else { return }

        if session.hostId == currentUserId.uuidString {
            myRole = .host
            endButton.isHidden = false
            manageButton.isHidden = false
            handRaiseButton.isHidden = true
            updateMediaControls(canSpeak: true)
        } else if let myParticipant = participants.first(where: { $0.userId == currentUserId.uuidString }),
                  myParticipant.role == .coSpeaker {
            myRole = .coSpeaker
            manageButton.isHidden = false
            handRaiseButton.isHidden = true
            updateMediaControls(canSpeak: true)
        } else {
            let tier = SubscriptionService.shared.currentStatus.tier
            if tier.canSpeakInSession {
                // Start as listener, can be promoted
                updateMediaControls(canSpeak: false)
            } else {
                // Free tier: no media controls
                micButton.isHidden = true
                cameraButton.isHidden = true
                handRaiseButton.isHidden = true
            }
        }
    }

    private func updateMediaControls(canSpeak: Bool) {
        micButton.isEnabled = canSpeak
        cameraButton.isEnabled = canSpeak
        micButton.alpha = canSpeak ? 1.0 : 0.5
        cameraButton.alpha = canSpeak ? 1.0 : 0.5

        if canSpeak {
            isMicOn = true
            isCameraOn = true
            updateMicButtonState()
            updateCameraButtonState()
        }
    }

    private func connectToSession() {
        // Subscribe to realtime updates
        sessionChannel = SessionService.shared.subscribeToSessionUpdates(
            sessionId: session.id,
            onParticipantChange: { [weak self] participants in
                self?.handleParticipantsUpdate(participants)
            },
            onSessionStatusChange: { [weak self] updatedSession in
                self?.handleSessionStatusChange(updatedSession)
            }
        )

        messagesChannel = SessionService.shared.subscribeToSessionMessages(
            sessionId: session.id,
            onMessage: { [weak self] message in
                self?.chatView.addMessage(message)
            }
        )

        // Load initial participants
        Task {
            if let participants = try? await SessionService.shared.getSessionParticipants(sessionId: session.id) {
                await MainActor.run { self.handleParticipantsUpdate(participants) }
            }
        }

        // Connect LiveKit
        connectLiveKit()
    }

    private func connectLiveKit() {
        Task {
            do {
                let tokenResponse = try await fetchLiveKitToken()
                try await LiveKitService.shared.connect(
                    url: Config.livekitURL,
                    token: tokenResponse.token
                )
                LiveKitService.shared.applyPermissions(for: myRole)

                LiveKitService.shared.onParticipantConnected = { [weak self] participantId in
                    print("Participant connected: \(participantId)")
                }
                LiveKitService.shared.onParticipantDisconnected = { [weak self] participantId in
                    print("Participant disconnected: \(participantId)")
                }
            } catch {
                print("LiveKit connection failed: \(error)")
            }
        }
    }

    private func fetchLiveKitToken() async throws -> LiveKitTokenResponse {
        guard let userId = SupabaseService.shared.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let params: [String: String] = [
            "sessionId": session.id,
            "userId": userId.uuidString
        ]

        let tokenResponse: LiveKitTokenResponse = try await SupabaseService.shared.client
            .functions.invoke(
                "livekit-token",
                options: .init(body: params)
            )

        return tokenResponse
    }

    private func handleParticipantsUpdate(_ newParticipants: [SessionParticipant]) {
        participants = newParticipants

        // Update video grid
        let speakers = newParticipants.filter { $0.role.canSpeak }
        for (index, videoView) in videoViews.enumerated() {
            if index < speakers.count {
                let speaker = speakers[index]
                videoView.configure(
                    name: speaker.user?.firstName ?? "Speaker",
                    role: speaker.role,
                    isMuted: false,
                    isVideoOff: false
                )
            } else {
                videoView.configureEmpty()
            }
        }

        // Check if my role changed
        if let currentUserId = SupabaseService.shared.currentUserId,
           let myParticipant = newParticipants.first(where: { $0.userId == currentUserId.uuidString }) {
            if myParticipant.role != myRole {
                myRole = myParticipant.role
                handleRoleChange()
            }
        }
    }

    private func handleRoleChange() {
        let canSpeak = myRole.canSpeak
        updateMediaControls(canSpeak: canSpeak)
        handRaiseButton.isHidden = canSpeak || myRole == .host
        manageButton.isHidden = !myRole.canPromote

        if canSpeak {
            LiveKitService.shared.applyPermissions(for: myRole)
            // Reconnect with new token for publish permissions
            connectLiveKit()
        }
    }

    private func handleSessionStatusChange(_ updatedSession: Session) {
        session = updatedSession

        // Update goal display if changed
        if let newGoal = updatedSession.goal {
            goalLabel.text = newGoal
            goalLabel.isHidden = false
        }

        if updatedSession.status == .ended || updatedSession.status == .cancelled {
            sessionEnded()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        remainingSeconds = session.maxDurationMinutes * 60

        // If session already started, subtract elapsed time
        if let startedAt = session.startedAt {
            let elapsed = Int(Date().timeIntervalSince(startedAt))
            remainingSeconds = max(0, remainingSeconds - elapsed)
        }

        updateTimerDisplay()

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingSeconds -= 1

            if self.remainingSeconds <= 0 {
                self.sessionTimer?.invalidate()
                if self.myRole == .host {
                    self.endSession()
                } else {
                    self.sessionEnded()
                }
                return
            }

            if self.remainingSeconds == 300 {
                self.showWarningBanner()
            }

            self.updateTimerDisplay()
        }
    }

    private func updateTimerDisplay() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)

        if remainingSeconds <= 300 {
            timerLabel.textColor = .systemRed
        }
    }

    private func showWarningBanner() {
        let banner = UILabel()
        banner.text = "session_ending_soon".localized
        banner.font = .systemFont(ofSize: 14, weight: .semibold)
        banner.textColor = .white
        banner.backgroundColor = .systemOrange
        banner.textAlignment = .center
        banner.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: view.bounds.width, height: 30)
        view.addSubview(banner)

        UIView.animate(withDuration: 0.3, delay: 3.0, options: [], animations: {
            banner.alpha = 0
        }) { _ in
            banner.removeFromSuperview()
        }
    }

    // MARK: - Actions

    @objc private func micTapped() {
        isMicOn.toggle()
        updateMicButtonState()
        if isMicOn {
            LiveKitService.shared.enableMicrophone()
        } else {
            LiveKitService.shared.disableMicrophone()
        }
    }

    @objc private func cameraTapped() {
        isCameraOn.toggle()
        updateCameraButtonState()
        if isCameraOn {
            LiveKitService.shared.enableCamera()
        } else {
            LiveKitService.shared.disableCamera()
        }
    }

    @objc private func handRaiseTapped() {
        isHandRaised.toggle()
        handRaiseButton.tintColor = isHandRaised ? .systemYellow : .label
        handRaiseButton.setImage(UIImage(systemName: isHandRaised ? "hand.raised.fill" : "hand.raised")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        ), for: .normal)

        Task {
            if isHandRaised {
                try? await SessionService.shared.raiseHand(sessionId: session.id)
            } else {
                try? await SessionService.shared.lowerHand(sessionId: session.id)
            }
        }
    }

    @objc private func manageTapped() {
        let queueView = HandRaiseQueueView(sessionId: session.id)
        queueView.delegate = self
        let nav = UINavigationController(rootViewController: queueView)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(nav, animated: true)
    }

    @objc private func goalTapped() {
        guard myRole == .host else { return }

        let alert = UIAlertController(
            title: "session_edit_goal_title".localized,
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { [weak self] textField in
            textField.text = self?.session.goal
            textField.placeholder = "session_goal_placeholder".localized
        }
        alert.addAction(UIAlertAction(title: "common_save".localized, style: .default) { [weak self] _ in
            guard let self, let newGoal = alert.textFields?.first?.text, !newGoal.isEmpty else { return }
            self.session.goal = newGoal
            self.goalLabel.text = newGoal
            self.goalLabel.isHidden = false
            Task {
                try? await SessionService.shared.updateGoal(sessionId: self.session.id, goal: newGoal)
            }
        })
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        present(alert, animated: true)
    }

    @objc private func endSessionTapped() {
        let alert = UIAlertController(
            title: "session_end_confirm_title".localized,
            message: "session_end_confirm_message".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "session_end".localized, style: .destructive) { [weak self] _ in
            self?.endSession()
        })
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        present(alert, animated: true)
    }

    @objc private func leaveTapped() {
        leaveSession()
    }

    private func endSession() {
        Task {
            try? await SessionService.shared.endSession(id: session.id)
            await MainActor.run { sessionEnded() }
        }
    }

    private func leaveSession() {
        sessionTimer?.invalidate()
        SessionService.shared.unsubscribeAll()
        LiveKitService.shared.disconnect()

        Task {
            try? await SessionService.shared.leaveSession(sessionId: session.id)
        }

        navigationController?.popViewController(animated: true)
    }

    private func sessionEnded() {
        sessionTimer?.invalidate()
        LiveKitService.shared.disconnect()

        let alert = UIAlertController(
            title: "session_ended_title".localized,
            message: "session_ended_message".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func updateMicButtonState() {
        let imageName = isMicOn ? "mic.fill" : "mic.slash.fill"
        micButton.setImage(UIImage(systemName: imageName)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        ), for: .normal)
        micButton.tintColor = isMicOn ? .systemGreen : .systemRed
    }

    private func updateCameraButtonState() {
        let imageName = isCameraOn ? "video.fill" : "video.slash.fill"
        cameraButton.setImage(UIImage(systemName: imageName)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        ), for: .normal)
        cameraButton.tintColor = isCameraOn ? .systemGreen : .systemRed
    }
}

// MARK: - HandRaiseQueueDelegate
extension SessionViewController: HandRaiseQueueDelegate {
    func didPromoteUser(userId: String) {
        Task {
            try? await SessionService.shared.promoteParticipant(
                sessionId: session.id,
                userId: userId,
                to: .rotatingSpeaker
            )
        }
    }
}

// MARK: - LiveKit Token Response
struct LiveKitTokenResponse: Codable {
    let token: String
    let roomName: String
    let url: String
}
