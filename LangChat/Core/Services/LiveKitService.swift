import Foundation
import AVFoundation
import HMSSDK

/// 100ms service wrapper for video/audio room management.
/// Provides the same interface as the previous LiveKit integration.
class LiveKitService: HMSUpdateListener {
    static let shared = LiveKitService()

    // MARK: - Callbacks
    var onParticipantConnected: ((String) -> Void)?
    var onParticipantDisconnected: ((String) -> Void)?
    var onTrackPublished: ((String) -> Void)?
    var onTrackUnpublished: ((String) -> Void)?

    // MARK: - State
    private(set) var isConnected = false
    private(set) var isMicEnabled = false
    private(set) var isCameraEnabled = false
    private(set) var isVideoSubscriptionEnabled = true

    private var hmsSDK: HMSSDK?

    private init() {}

    // MARK: - Permissions

    /// Request camera and microphone permissions before connecting.
    func requestMediaPermissions() async -> (audio: Bool, video: Bool) {
        let audioGranted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }

        let videoGranted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }

        return (audio: audioGranted, video: videoGranted)
    }

    // MARK: - Audio Session Management

    /// Configure audio session for live voice/video sessions.
    func configureAudioSessionForSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            #if DEBUG
            print("Audio session configured for live session")
            #endif
        } catch {
            print("Failed to configure audio session for session: \(error.localizedDescription)")
            CrashReportingService.shared.captureError(error, context: ["stage": "session_audio_setup"])
        }
    }

    /// Restore audio session to default TTS playback mode.
    func restoreAudioSessionForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            #if DEBUG
            print("Audio session restored for playback")
            #endif
        } catch {
            print("Failed to restore audio session: \(error.localizedDescription)")
            CrashReportingService.shared.captureError(error, context: ["stage": "session_audio_restore"])
        }
    }

    // MARK: - Connection

    /// Connect to a 100ms room.
    /// - Parameters:
    ///   - url: Unused (kept for API compatibility). 100ms uses the token to determine the endpoint.
    ///   - token: Auth token from the `session-token` Edge Function.
    func connect(url: String, token: String) async throws {
        #if DEBUG
        print("100ms: Connecting...")
        #endif

        let sdk = HMSSDK.build()
        self.hmsSDK = sdk

        let config = HMSConfig(userName: userName(), authToken: token)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var resumed = false
            sdk.join(config: config, delegate: self)

            // Store continuation to be resumed from on(join:) or on(error:)
            self.joinContinuation = continuation
            self.joinContinuationResumed = { resumed = true }
            // Safety timeout — if neither callback fires in 15 seconds, fail
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                guard !resumed else { return }
                self?.joinContinuation?.resume(throwing: NSError(
                    domain: "LiveKitService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "100ms join timed out"]
                ))
                self?.joinContinuation = nil
            }
        }
    }

    private var joinContinuation: CheckedContinuation<Void, Error>?
    private var joinContinuationResumed: (() -> Void)?

    private func userName() -> String {
        let first = UserDefaults.standard.string(forKey: "firstName") ?? ""
        let last = UserDefaults.standard.string(forKey: "lastName") ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "User" : name
    }

    func disconnect() {
        #if DEBUG
        print("100ms: Disconnecting...")
        #endif

        hmsSDK?.leave()
        hmsSDK = nil

        isConnected = false
        isMicEnabled = false
        isCameraEnabled = false
        isVideoSubscriptionEnabled = true

        restoreAudioSessionForPlayback()
    }

    // MARK: - Media Controls

    func enableMicrophone() {
        hmsSDK?.localPeer?.localAudioTrack()?.setMute(false)
        isMicEnabled = true
    }

    func disableMicrophone() {
        hmsSDK?.localPeer?.localAudioTrack()?.setMute(true)
        isMicEnabled = false
    }

    func enableCamera() {
        hmsSDK?.localPeer?.localVideoTrack()?.setMute(false)
        isCameraEnabled = true
    }

    func disableCamera() {
        hmsSDK?.localPeer?.localVideoTrack()?.setMute(true)
        isCameraEnabled = false
    }

    // MARK: - Host Moderation

    /// Remotely mute a specific participant's microphone (host only).
    /// Uses 100ms's first-class remote mute API (server-enforced).
    func muteParticipant(identity: String) {
        guard let peer = findPeer(byUserId: identity),
              let audioTrack = peer.audioTrack else { return }
        hmsSDK?.changeTrackState(for: audioTrack, mute: true) { success, error in
            #if DEBUG
            if let error = error {
                print("100ms: Failed to mute \(identity): \(error.localizedDescription)")
            } else {
                print("100ms: Muted \(identity)")
            }
            #endif
        }
    }

    /// Remotely disable a specific participant's camera (host only).
    func disableParticipantCamera(identity: String) {
        guard let peer = findPeer(byUserId: identity),
              let videoTrack = peer.videoTrack else { return }
        hmsSDK?.changeTrackState(for: videoTrack, mute: true) { success, error in
            #if DEBUG
            if let error = error {
                print("100ms: Failed to disable camera for \(identity): \(error.localizedDescription)")
            } else {
                print("100ms: Disabled camera for \(identity)")
            }
            #endif
        }
    }

    private func findPeer(byUserId userId: String) -> HMSPeer? {
        return hmsSDK?.room?.peers.first { peer in
            // Match by customerUserId (set via token metadata) or peer name
            peer.customerUserID == userId || peer.peerID == userId
        }
    }

    // MARK: - Selective Video Subscription

    /// Enable or disable video subscription for all remote participants.
    /// In 100ms, this is done by muting/unmuting playback on remote video tracks.
    func setVideoSubscriptionEnabled(_ enabled: Bool) {
        isVideoSubscriptionEnabled = enabled

        guard let peers = hmsSDK?.room?.peers else { return }
        for peer in peers where !peer.isLocal {
            if let videoTrack = peer.videoTrack as? HMSRemoteVideoTrack {
                videoTrack.setPlaybackAllowed(enabled)
            }
        }

        #if DEBUG
        print("100ms: Video subscription \(enabled ? "enabled" : "disabled")")
        #endif
    }

    // MARK: - Role Permissions

    func applyPermissions(for role: SessionRole) {
        #if DEBUG
        print("100ms: Applying permissions for role: \(role.rawValue)")
        #endif
        if role.canSpeak {
            enableMicrophone()
            enableCamera()
        } else {
            disableMicrophone()
            disableCamera()
        }
    }

    // MARK: - HMSUpdateListener

    func on(join room: HMSRoom) {
        isConnected = true
        #if DEBUG
        print("100ms: Joined room \(room.name ?? "")")
        #endif
        joinContinuationResumed?()
        joinContinuation?.resume()
        joinContinuation = nil
    }

    func on(room: HMSRoom, update: HMSRoomUpdate) {
        // Room-level updates (peer count changes, etc.)
    }

    func on(peer: HMSPeer, update: HMSPeerUpdate) {
        let identity = peer.customerUserID ?? peer.peerID

        switch update {
        case .peerJoined:
            // Apply video subscription state to new peer
            if !peer.isLocal && !isVideoSubscriptionEnabled {
                if let videoTrack = peer.videoTrack as? HMSRemoteVideoTrack {
                    videoTrack.setPlaybackAllowed(false)
                }
            }
            onParticipantConnected?(identity)
        case .peerLeft:
            onParticipantDisconnected?(identity)
        default:
            break
        }
    }

    func on(track: HMSTrack, update: HMSTrackUpdate, for peer: HMSPeer) {
        guard !peer.isLocal else { return }
        let identity = peer.customerUserID ?? peer.peerID

        switch update {
        case .trackAdded:
            // Apply video subscription state to newly added tracks
            if track.kind == .video && !isVideoSubscriptionEnabled,
               let remoteVideo = track as? HMSRemoteVideoTrack {
                remoteVideo.setPlaybackAllowed(false)
            }
            onTrackPublished?(identity)
        case .trackRemoved:
            onTrackUnpublished?(identity)
        default:
            break
        }
    }

    func on(error: any Error) {
        print("100ms error: \(error.localizedDescription)")
        CrashReportingService.shared.captureError(error, context: ["stage": "hms_room"])

        // If this fires during join, resume the continuation with error
        joinContinuationResumed?()
        joinContinuation?.resume(throwing: error)
        joinContinuation = nil
    }

    func on(message: HMSMessage) {
        // Handle incoming data messages (moderation commands are now handled
        // server-side by 100ms via changeTrackState, so no client parsing needed)
    }

    func on(updated speakers: [HMSSpeaker]) {
        // Active speaker updates — could be used for UI indicators
    }

    func onRemovedFromRoom(notification: HMSRemovedFromRoomNotification) {
        #if DEBUG
        print("100ms: Removed from room — \(notification.reason)")
        #endif
        isConnected = false
    }

    func on(roleChangeRequest: HMSRoleChangeRequest) {
        // Accept role changes from host automatically
        hmsSDK?.accept(changeRole: roleChangeRequest)
    }

    func on(changeTrackStateRequest: HMSChangeTrackStateRequest) {
        // Host requested track state change (mute/unmute) — auto-apply
        if changeTrackStateRequest.mute {
            if changeTrackStateRequest.track.kind == .audio {
                disableMicrophone()
            } else if changeTrackStateRequest.track.kind == .video {
                disableCamera()
            }
        }
    }

    func onPeerListUpdate(added: [HMSPeer], removed: [HMSPeer]) {
        for peer in added where !peer.isLocal {
            let identity = peer.customerUserID ?? peer.peerID
            if !isVideoSubscriptionEnabled, let videoTrack = peer.videoTrack as? HMSRemoteVideoTrack {
                videoTrack.setPlaybackAllowed(false)
            }
            onParticipantConnected?(identity)
        }
        for peer in removed where !peer.isLocal {
            let identity = peer.customerUserID ?? peer.peerID
            onParticipantDisconnected?(identity)
        }
    }

    func onReconnecting() {
        #if DEBUG
        print("100ms: Reconnecting...")
        #endif
    }

    func onReconnected() {
        #if DEBUG
        print("100ms: Reconnected")
        #endif
        isConnected = true
    }
}
