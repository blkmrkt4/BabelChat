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
    private let flipCameraButton = UIButton(type: .system)
    private let handRaiseButton = UIButton(type: .system)
    private let manageButton = UIButton(type: .system)
    private let addParticipantButton = UIButton(type: .system)

    private let chatView: SessionChatView

    // State
    private var isMicOn = false
    private var isCameraOn = false
    private var isHandRaised = false
    private var hasVideoAccess = false
    private var videoSlotsChannel: RealtimeChannel?
    /// Speakers currently shown in the 4 video slots (by index)
    private var slotSpeakers: [SessionParticipant?] = [nil, nil, nil, nil]

    // MARK: - Init
    init(session: Session) {
        self.session = session

        // Determine language context from session's language pair
        let learning = Language.from(name: session.languagePair.learning) ?? .english
        let native: Language
        if let data = UserDefaults.standard.data(forKey: "userLanguages"),
           let decoded = try? JSONDecoder().decode(UserLanguageData.self, from: data) {
            native = decoded.nativeLanguage.language
        } else {
            native = Language.from(name: session.languagePair.native) ?? .english
        }

        self.chatView = SessionChatView(
            sessionId: session.id,
            learningLanguage: learning,
            nativeLanguage: native
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        chatView.delegate = self
        determineRole()
        connectToSession()
        startTimer()
        Task { try? await SessionService.shared.incrementViewerCount(sessionId: session.id) }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            Task { try? await SessionService.shared.decrementViewerCount(sessionId: session.id) }
            leaveSession()
        }
    }

    deinit {
        sessionTimer?.invalidate()
        videoSlotsChannel?.unsubscribe()
        SessionService.shared.unsubscribeAll()
        HundredMSService.shared.disconnect()
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
            videoView.onEmptySlotTapped = { [weak self] in
                guard let self, self.myRole.canPromote else { return }
                self.addParticipantToSlot(slotIndex: i)
            }
            videoView.onOccupiedSlotTapped = { [weak self] in
                guard let self, let participant = self.slotSpeakers[i] else { return }
                self.showSlotOptions(for: participant, at: i)
            }
            videoView.onParticipantLongPressed = { [weak self] in
                guard let self, let participant = self.slotSpeakers[i] else { return }
                self.showSlotOptions(for: participant, at: i)
            }
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
        configureControlButton(flipCameraButton, systemName: "camera.rotate", action: #selector(flipCameraTapped))
        configureControlButton(handRaiseButton, systemName: "hand.raised", action: #selector(handRaiseTapped))
        configureControlButton(manageButton, systemName: "person.2.badge.gearshape", action: #selector(manageTapped))
        configureControlButton(addParticipantButton, systemName: "person.badge.plus", action: #selector(addParticipantTapped))
        manageButton.isHidden = true // Host/co-speaker only
        addParticipantButton.isHidden = true // Host only

        controlsBar.addArrangedSubview(micButton)
        controlsBar.addArrangedSubview(cameraButton)
        controlsBar.addArrangedSubview(flipCameraButton)
        controlsBar.addArrangedSubview(handRaiseButton)
        controlsBar.addArrangedSubview(manageButton)
        controlsBar.addArrangedSubview(addParticipantButton)

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
        guard let currentUserId = SupabaseService.shared.currentUserId else {
            print("[Session] determineRole: no currentUserId — defaulting to listener")
            myRole = .listener
            updateUIForRole()
            return
        }

        // Use lowercased comparison — Swift UUID.uuidString is uppercase,
        // but Supabase/PostgreSQL stores UUIDs as lowercase
        let myId = currentUserId.uuidString.lowercased()

        // Host check is authoritative — session.hostId is the source of truth
        // and does not depend on participant data being loaded yet
        if session.hostId.lowercased() == myId {
            myRole = .host
        } else if let myParticipant = participants.first(where: { $0.userId.lowercased() == myId }) {
            myRole = myParticipant.role
        } else if !participants.isEmpty {
            myRole = .listener
        }

        print("[Session] determineRole: userId=\(myId.prefix(8)), hostId=\(session.hostId.lowercased().prefix(8)), participants=\(participants.count), resolved=\(myRole)")

        updateUIForRole()
    }

    private func updateUIForRole() {
        switch myRole {
        case .host:
            endButton.isHidden = false
            manageButton.isHidden = false
            addParticipantButton.isHidden = false
            handRaiseButton.isHidden = true
            updateMediaControls(canSpeak: true)
            navigationItem.rightBarButtonItem = nil

        case .coHost:
            endButton.isHidden = true
            manageButton.isHidden = false
            addParticipantButton.isHidden = false
            handRaiseButton.isHidden = true
            updateMediaControls(canSpeak: true)
            navigationItem.rightBarButtonItem = nil

        case .rotatingSpeaker:
            endButton.isHidden = true
            manageButton.isHidden = true
            addParticipantButton.isHidden = true
            handRaiseButton.isHidden = true
            updateMediaControls(canSpeak: true)
            navigationItem.rightBarButtonItem = nil

        case .listener:
            endButton.isHidden = true
            manageButton.isHidden = true
            addParticipantButton.isHidden = true
            navigationItem.rightBarButtonItem = nil
            micButton.isHidden = true
            cameraButton.isHidden = true
            flipCameraButton.isHidden = true
            handRaiseButton.isHidden = false
        }
    }

    private func updateMediaControls(canSpeak: Bool) {
        micButton.isHidden = false
        cameraButton.isHidden = false
        flipCameraButton.isHidden = false
        micButton.isEnabled = canSpeak
        cameraButton.isEnabled = canSpeak
        flipCameraButton.isEnabled = canSpeak
        micButton.alpha = canSpeak ? 1.0 : 0.5
        cameraButton.alpha = canSpeak ? 1.0 : 0.5
        flipCameraButton.alpha = canSpeak ? 1.0 : 0.5

        if canSpeak {
            isMicOn = true
            isCameraOn = true
        }
        updateMicButtonState()
        updateCameraButtonState()
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
        connectHMS()
    }

    private func connectHMS() {
        Task {
            do {
                // Request camera/microphone permissions before connecting
                let permissions = await HundredMSService.shared.requestMediaPermissions()
                if !permissions.audio {
                    print("[Session] Microphone permission denied — audio will not work")
                }
                if !permissions.video {
                    print("[Session] Camera permission denied — video will not work")
                }

                // Configure audio session for live voice/video
                HundredMSService.shared.configureAudioSessionForSession()

                let tokenResponse = try await fetchSessionToken()
                try await HundredMSService.shared.connect(
                    url: Config.hmsEndpoint,
                    token: tokenResponse.token
                )

                // Determine video access based on slot status
                await configureVideoAccess()

                await MainActor.run {
                    // Re-apply role permissions and control state after connection completes
                    print("[Session] 100ms connected — re-applying role: \(self.myRole)")
                    HundredMSService.shared.applyPermissions(for: self.myRole)
                    self.updateUIForRole()
                    self.attachVideoTracks()
                }

                HundredMSService.shared.onParticipantConnected = { [weak self] participantId in
                    print("[Session] Participant connected: \(participantId)")
                    DispatchQueue.main.async { self?.attachVideoTracks() }
                }
                HundredMSService.shared.onParticipantDisconnected = { [weak self] participantId in
                    print("[Session] Participant disconnected: \(participantId)")
                    DispatchQueue.main.async { self?.attachVideoTracks() }
                }
                HundredMSService.shared.onTrackPublished = { [weak self] _ in
                    DispatchQueue.main.async { self?.attachVideoTracks() }
                }
                HundredMSService.shared.onTrackUnpublished = { [weak self] _ in
                    DispatchQueue.main.async { self?.attachVideoTracks() }
                }
            } catch {
                print("[Session] 100ms connection failed: \(error)")
            }
        }
    }

    /// Configure video access based on the user's video slot status
    private func configureVideoAccess() async {
        let tier = SubscriptionService.shared.currentStatus.tier

        // Speakers always get video
        if myRole.canSpeak {
            hasVideoAccess = true
            HundredMSService.shared.setVideoSubscriptionEnabled(true)
            return
        }

        // Free users: audio only
        guard tier.canViewSessionVideo else {
            hasVideoAccess = false
            HundredMSService.shared.setVideoSubscriptionEnabled(false)
            print("[Session] Free tier — audio-only mode")
            return
        }

        // Check video slot status
        do {
            // Try to activate a confirmed slot
            try await SessionService.shared.activateVideoSlot(sessionId: session.id)

            let slotInfo = try await SessionService.shared.getVideoSlotStatus(sessionId: session.id)
            let slotActive = slotInfo.myStatus == .active

            await MainActor.run {
                self.hasVideoAccess = slotActive
                HundredMSService.shared.setVideoSubscriptionEnabled(slotActive)
                if !slotActive {
                    print("[Session] No active video slot — audio-only until promoted")
                }
            }
        } catch {
            print("[Session] Video slot check failed: \(error) — defaulting to audio-only")
            hasVideoAccess = false
            HundredMSService.shared.setVideoSubscriptionEnabled(false)
        }

        // Subscribe to video slot changes for real-time promotion
        subscribeToVideoSlotChanges()
    }

    /// Listen for video slot promotions via Realtime
    private func subscribeToVideoSlotChanges() {
        let myUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""

        videoSlotsChannel = SessionService.shared.subscribeToVideoSlotUpdates(
            sessionId: session.id
        ) { [weak self] slot in
            guard let self else { return }
            // Check if this update is for us and we got promoted
            if slot.userId.lowercased() == myUserId && slot.status == .active && !self.hasVideoAccess {
                self.hasVideoAccess = true
                HundredMSService.shared.setVideoSubscriptionEnabled(true)
                self.showVideoGrantedToast()
            }
        }
    }

    /// Show a toast notification when video access is granted
    private func showVideoGrantedToast() {
        let banner = UILabel()
        banner.text = "session_video_granted".localized
        banner.font = .systemFont(ofSize: 14, weight: .semibold)
        banner.textColor = .white
        banner.backgroundColor = .systemGreen
        banner.textAlignment = .center
        banner.layer.cornerRadius = 8
        banner.clipsToBounds = true
        banner.frame = CGRect(x: 16, y: view.safeAreaInsets.top + 4, width: view.bounds.width - 32, height: 36)
        view.addSubview(banner)

        UIView.animate(withDuration: 0.3, delay: 3.0, options: [], animations: {
            banner.alpha = 0
        }) { _ in
            banner.removeFromSuperview()
        }
    }

    private func fetchSessionToken() async throws -> SessionTokenResponse {
        guard SupabaseService.shared.currentUserId != nil else {
            throw SessionError.notAuthenticated
        }

        // userId is now derived from the authenticated JWT on the server side
        let params: [String: String] = [
            "sessionId": session.id
        ]

        let tokenResponse: SessionTokenResponse = try await SupabaseService.shared.client
            .functions.invoke(
                "session-token",
                options: .init(body: params)
            )

        return tokenResponse
    }

    private func handleParticipantsUpdate(_ newParticipants: [SessionParticipant]) {
        participants = newParticipants

        // Update video grid — speakers fill the 4 quadrants
        let speakers = newParticipants.filter { $0.role.canSpeak }
        for (index, videoView) in videoViews.enumerated() {
            if index < speakers.count {
                let speaker = speakers[index]
                slotSpeakers[index] = speaker
                videoView.configure(
                    name: speaker.user?.firstName ?? "Speaker",
                    role: speaker.role,
                    isMuted: false,
                    isVideoOff: false,
                    userId: speaker.userId
                )
            } else {
                slotSpeakers[index] = nil
                videoView.configureEmpty()
            }
        }

        // Attach video tracks to the video views
        attachVideoTracks()

        // Re-evaluate my role based on current participant data
        let previousRole = myRole
        determineRole()
        if previousRole != myRole {
            handleRoleChange()
        }
    }

    private func handleRoleChange() {
        // updateUIForRole() is already called by determineRole(), but call again
        // defensively in case handleRoleChange is invoked from other paths
        updateUIForRole()

        // Update 100ms permissions for the new role without reconnecting
        // (connectHMS already happened at session join)
        print("[Session] Role changed to \(myRole) — updating 100ms permissions")
        HundredMSService.shared.applyPermissions(for: myRole)
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

    // MARK: - Video Track Rendering

    /// Attach 100ms video tracks to the video grid views.
    /// Matches speakers in `slotSpeakers` to their HMSVideoTrack via user ID.
    private func attachVideoTracks() {
        guard HundredMSService.shared.isConnected else { return }

        guard let myId = SupabaseService.shared.currentUserId?.uuidString.lowercased() else { return }

        for (index, videoView) in videoViews.enumerated() {
            guard let speaker = slotSpeakers[index] else {
                videoView.setVideoTrack(nil)
                continue
            }

            let speakerId = speaker.userId.lowercased()

            if speakerId == myId {
                // Local user — attach local video track
                videoView.setVideoTrack(HundredMSService.shared.localVideoTrack())
            } else {
                // Remote user — look up their video track
                videoView.setVideoTrack(HundredMSService.shared.videoTrack(for: speaker.userId))
            }
        }
    }

    // MARK: - Actions

    @objc private func micTapped() {
        isMicOn.toggle()
        updateMicButtonState()
        if isMicOn {
            HundredMSService.shared.enableMicrophone()
        } else {
            HundredMSService.shared.disableMicrophone()
        }
    }

    @objc private func cameraTapped() {
        isCameraOn.toggle()
        updateCameraButtonState()
        if isCameraOn {
            HundredMSService.shared.enableCamera()
        } else {
            HundredMSService.shared.disableCamera()
        }
    }

    @objc private func flipCameraTapped() {
        HundredMSService.shared.flipCamera()
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
        if myRole == .host {
            // Host gets both Leave and End Session options
            let alert = UIAlertController(
                title: "session_host_leave_title".localized,
                message: "session_host_leave_message".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "session_leave".localized, style: .default) { [weak self] _ in
                self?.leaveSession()
            })
            alert.addAction(UIAlertAction(title: "session_end".localized, style: .destructive) { [weak self] _ in
                self?.endSession()
            })
            alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
            present(alert, animated: true)
        } else {
            leaveSession()
        }
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
        HundredMSService.shared.disconnect()

        Task {
            // Release video slot to free it for next waitlisted user
            if hasVideoAccess {
                try? await SessionService.shared.releaseVideoSlot(sessionId: session.id)
            }
            try? await SessionService.shared.leaveSession(sessionId: session.id)
        }

        navigationController?.popViewController(animated: true)
    }

    private func sessionEnded() {
        sessionTimer?.invalidate()
        HundredMSService.shared.disconnect()

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

    // MARK: - Add Participant

    @objc private func addParticipantTapped() {
        // Find first empty slot
        if let emptyIndex = slotSpeakers.firstIndex(where: { $0 == nil }) {
            addParticipantToSlot(slotIndex: emptyIndex)
        } else {
            let alert = UIAlertController(
                title: "session_error_title".localized,
                message: SessionError.sessionFull.errorDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
            present(alert, animated: true)
        }
    }

    private func addParticipantToSlot(slotIndex: Int) {
        let existingSpeakerIds = slotSpeakers.compactMap { $0?.userId }
        let existingParticipantIds = participants.map { $0.userId }

        // Show options: invite from matches or promote a listener already in the session
        let listeners = participants.filter { $0.role == .listener && $0.isActive }

        let alert = UIAlertController(
            title: "session_add_participant_title".localized,
            message: nil,
            preferredStyle: .actionSheet
        )

        // Option 1: Invite from matches
        alert.addAction(UIAlertAction(title: "session_invite_from_matches".localized, style: .default) { [weak self] _ in
            guard let self else { return }
            let selectVC = SelectMatchViewController(excludedUserIds: existingParticipantIds)
            selectVC.onSelectUser = { [weak self] user in
                guard let self else { return }
                Task {
                    do {
                        try await SessionService.shared.createInvite(
                            sessionId: self.session.id,
                            inviteeId: user.id,
                            role: SessionRole.coHost.rawValue
                        )
                        await MainActor.run {
                            self.dismiss(animated: true)
                        }
                    } catch {
                        print("Failed to invite participant: \(error)")
                    }
                }
            }
            let nav = UINavigationController(rootViewController: selectVC)
            self.present(nav, animated: true)
        })

        // Option 2: Promote an existing listener to speaker
        if !listeners.isEmpty {
            alert.addAction(UIAlertAction(title: "session_promote_listener".localized, style: .default) { [weak self] _ in
                self?.showListenerPicker(listeners: listeners, slotIndex: slotIndex)
            })
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addParticipantButton
            popover.sourceRect = addParticipantButton.bounds
        }

        present(alert, animated: true)
    }

    private func showListenerPicker(listeners: [SessionParticipant], slotIndex: Int) {
        let alert = UIAlertController(
            title: "session_choose_listener".localized,
            message: nil,
            preferredStyle: .actionSheet
        )

        for listener in listeners {
            let name = listener.user?.firstName ?? listener.userId.prefix(8).description
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self else { return }
                Task {
                    try? await SessionService.shared.promoteParticipant(
                        sessionId: self.session.id,
                        userId: listener.userId,
                        to: .rotatingSpeaker
                    )
                }
            })
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addParticipantButton
            popover.sourceRect = addParticipantButton.bounds
        }

        present(alert, animated: true)
    }

    // MARK: - Slot Management

    private func showSlotOptions(for participant: SessionParticipant, at slotIndex: Int) {
        let currentUserId = SupabaseService.shared.currentUserId?.uuidString.lowercased() ?? ""
        let isSelf = participant.userId.lowercased() == currentUserId
        let participantName = participant.user?.firstName ?? "Participant"

        let alert = UIAlertController(
            title: participantName,
            message: participant.role.displayName,
            preferredStyle: .actionSheet
        )

        if isSelf {
            alert.message = String(format: "session_you_are_role".localized, myRole.displayName)

            // Self-management: toggle own mic/camera
            alert.addAction(UIAlertAction(
                title: isMicOn ? "session_mute_self".localized : "session_unmute_self".localized,
                style: .default
            ) { [weak self] _ in
                self?.micTapped()
            })
            alert.addAction(UIAlertAction(
                title: isCameraOn ? "session_camera_off".localized : "session_camera_on".localized,
                style: .default
            ) { [weak self] _ in
                self?.cameraTapped()
            })
        } else if canManageParticipant(participant) {
            // Moderation options based on role permissions
            alert.addAction(UIAlertAction(title: "session_mute_participant".localized, style: .default) { _ in
                HundredMSService.shared.muteParticipant(identity: participant.userId)
            })

            alert.addAction(UIAlertAction(title: "session_disable_camera".localized, style: .default) { _ in
                HundredMSService.shared.disableParticipantCamera(identity: participant.userId)
            })

            if participant.role.canSpeak {
                alert.addAction(UIAlertAction(title: "session_demote_to_listener".localized, style: .default) { [weak self] _ in
                    guard let self else { return }
                    Task {
                        try? await SessionService.shared.demoteParticipant(
                            sessionId: self.session.id,
                            userId: participant.userId
                        )
                    }
                })
            }

            // Replace with another participant
            let listeners = participants.filter { $0.role == .listener && $0.isActive }
            if !listeners.isEmpty {
                alert.addAction(UIAlertAction(title: "session_replace_with".localized, style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.replaceParticipant(participant, at: slotIndex, with: listeners)
                })
            }
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController,
           slotIndex < videoViews.count {
            let sourceView = videoViews[slotIndex]
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(alert, animated: true)
    }

    /// Determines if the current user can manage (mute, demote, replace) the given participant
    private func canManageParticipant(_ participant: SessionParticipant) -> Bool {
        switch myRole {
        case .host:
            // Host can manage everyone except themselves
            return true
        case .coHost:
            // Co-host can manage rotating speakers and listeners, but NOT host or other co-hosts
            switch participant.role {
            case .host, .coHost:
                return false
            case .rotatingSpeaker, .listener:
                return true
            }
        case .rotatingSpeaker, .listener:
            return false
        }
    }

    private func replaceParticipant(_ existing: SessionParticipant, at slotIndex: Int, with listeners: [SessionParticipant]) {
        let existingName = existing.user?.firstName ?? "Participant"
        let alert = UIAlertController(
            title: String(format: "session_replace_title".localized, existingName),
            message: nil,
            preferredStyle: .actionSheet
        )

        for listener in listeners {
            let name = listener.user?.firstName ?? listener.userId.prefix(8).description
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self else { return }
                Task {
                    // Demote existing speaker to listener
                    try? await SessionService.shared.demoteParticipant(
                        sessionId: self.session.id,
                        userId: existing.userId
                    )
                    // Promote the replacement to speaker
                    try? await SessionService.shared.promoteParticipant(
                        sessionId: self.session.id,
                        userId: listener.userId,
                        to: .rotatingSpeaker
                    )
                }
            })
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController,
           slotIndex < videoViews.count {
            let sourceView = videoViews[slotIndex]
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(alert, animated: true)
    }

    /// Called from chat when a user name is tapped — promotes them to speaker if permissions allow
    func promoteUserFromChat(userId: String) {
        guard myRole.canPromote else { return }

        // Find the participant
        guard let participant = participants.first(where: { $0.userId == userId && $0.isActive }) else { return }

        // Can only promote listeners
        guard participant.role == .listener else {
            // Already a speaker — show info
            if let slotIndex = slotSpeakers.firstIndex(where: { $0?.userId == userId }) {
                showSlotOptions(for: participant, at: slotIndex)
            }
            return
        }

        let name = participant.user?.firstName ?? "Participant"
        let alert = UIAlertController(
            title: name,
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "session_promote_to_speaker".localized, style: .default) { [weak self] _ in
            guard let self else { return }
            Task {
                try? await SessionService.shared.promoteParticipant(
                    sessionId: self.session.id,
                    userId: userId,
                    to: .rotatingSpeaker
                )
            }
        })

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = chatView
            popover.sourceRect = chatView.bounds
        }

        present(alert, animated: true)
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

// MARK: - SessionChatViewDelegate & Muse

extension SessionViewController: SessionChatViewDelegate {

    func sessionChatView(_ chatView: SessionChatView, didRequestMuseWithLanguage language: Language) {
        showMuseDialog(for: language)
    }

    func sessionChatView(_ chatView: SessionChatView, didTapUserWithId userId: String) {
        promoteUserFromChat(userId: userId)
    }

    func sessionChatViewParentViewController(_ chatView: SessionChatView) -> UIViewController? {
        return self
    }

    func sessionChatViewParticipants(_ chatView: SessionChatView) -> [SessionParticipant] {
        return participants
    }

    func sessionChatViewHostId(_ chatView: SessionChatView) -> String {
        return session.hostId
    }

    // MARK: - Muse Dialog

    private var museDialogVC: UIViewController? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.museDialogVC) as? UIViewController }
        set { objc_setAssociatedObject(self, &AssociatedKeys.museDialogVC, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var museDialogObserver: NSObjectProtocol? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.museDialogObserver) as? NSObjectProtocol }
        set { objc_setAssociatedObject(self, &AssociatedKeys.museDialogObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private func showMuseDialog(for language: Language) {
        let alertVC = UIViewController()
        alertVC.modalPresentationStyle = .overCurrentContext
        alertVC.modalTransitionStyle = .crossDissolve

        // Dimmed background
        let dimmedView = UIView()
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(dimmedView)

        // Card container
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        alertVC.view.addSubview(cardView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "chat_ask_muse".localized
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "What would you like to say in \(language.name)?"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        // Text view for multi-line input
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(textView)

        // Placeholder label
        let placeholderLabel = UILabel()
        placeholderLabel.text = "chat_ask_example".localized
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)

        // Button stack
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(buttonStack)

        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("common_cancel".localized, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 10
        buttonStack.addArrangedSubview(cancelButton)

        // Ask button
        let askButton = UIButton(type: .system)
        askButton.setTitle("common_ask".localized, for: .normal)
        askButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        askButton.backgroundColor = .systemBlue
        askButton.setTitleColor(.white, for: .normal)
        askButton.layer.cornerRadius = 10
        buttonStack.addArrangedSubview(askButton)

        // Constraints
        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: alertVC.view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor),

            cardView.centerYAnchor.constraint(equalTo: alertVC.view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            textView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 80),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -12),

            buttonStack.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Handle placeholder visibility
        museDialogObserver = NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: textView, queue: .main) { _ in
            placeholderLabel.isHidden = !textView.text.isEmpty
        }

        // Button actions
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.dismissMuseDialog()
        }, for: .touchUpInside)

        askButton.addAction(UIAction { [weak self] _ in
            guard let self = self, !textView.text.isEmpty else { return }
            let query = textView.text ?? ""
            self.dismissMuseDialog()
            self.askMuse(query: query, language: language)
        }, for: .touchUpInside)

        // Dismiss on background tap
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(dismissMuseDialogAction))
        dimmedView.addGestureRecognizer(tapGesture)

        self.museDialogVC = alertVC

        present(alertVC, animated: true) {
            textView.becomeFirstResponder()
        }
    }

    @objc private func dismissMuseDialogAction() {
        dismissMuseDialog()
    }

    private func dismissMuseDialog() {
        if let observer = museDialogObserver {
            NotificationCenter.default.removeObserver(observer)
            museDialogObserver = nil
        }
        museDialogVC?.dismiss(animated: true)
        museDialogVC = nil
    }

    private func askMuse(query: String, language: Language) {
        let loadingAlert = UIAlertController(
            title: "Muse is thinking...",
            message: nil,
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let config = try await AIConfigurationManager.shared.getConfiguration(for: .chatting)

                let systemPrompt = """
                You are a helpful language assistant called Muse. The user is practicing \(language.name) and needs help composing a message.

                Respond ONLY with the phrase they need in \(language.name). Do not add explanations, translations, or extra text unless specifically asked.
                Keep it natural and conversational.
                """

                let chatMessages = [
                    ChatMessage(role: "system", content: systemPrompt),
                    ChatMessage(role: "user", content: query)
                ]

                let response = try await OpenRouterService.shared.sendChatCompletion(
                    model: config.modelId,
                    messages: chatMessages,
                    temperature: Double(config.temperature),
                    maxTokens: config.maxTokens
                )

                guard let content = response.choices?.first?.content else {
                    throw NSError(domain: "MuseError", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Empty response from Muse"])
                }

                let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showMuseResponse(cleanedResponse)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showMuseError(error)
                    }
                }
            }
        }
    }

    private func showMuseResponse(_ response: String) {
        let alert = UIAlertController(
            title: "Muse suggests:",
            message: response,
            preferredStyle: .alert
        )

        let useAction = UIAlertAction(title: "common_use_this".localized, style: .default) { [weak self] _ in
            self?.chatView.insertMuseText(response)
        }

        let copyAction = UIAlertAction(title: "common_copy".localized, style: .default) { _ in
            UIPasteboard.general.string = response
        }

        alert.addAction(useAction)
        alert.addAction(copyAction)
        alert.addAction(UIAlertAction(title: "common_dismiss".localized, style: .cancel))

        present(alert, animated: true)
    }

    private func showMuseError(_ error: Error) {
        let alert = UIAlertController(
            title: "Muse couldn't help",
            message: "Please try again. Error: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
        present(alert, animated: true)
    }
}

private enum AssociatedKeys {
    static var museDialogVC = "museDialogVC"
    static var museDialogObserver = "museDialogObserver"
}

/// MARK: - Session Token Response
struct SessionTokenResponse: Codable {
    let token: String
    let roomName: String
}
