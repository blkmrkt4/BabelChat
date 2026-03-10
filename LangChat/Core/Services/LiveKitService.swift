import Foundation
import AVFoundation
#if canImport(LiveKit)
import LiveKit
#endif

/// LiveKit service wrapper for video/audio room management.
/// Requires LiveKit Swift SDK (`livekit-client-sdk-swift`) to be added via SPM.
class LiveKitService {
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

    #if canImport(LiveKit)
    private var room: Room?
    #endif

    private init() {}

    // MARK: - Permissions

    /// Request camera and microphone permissions before connecting.
    /// Returns true if both permissions were granted.
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
    /// Must be called before connecting to a LiveKit room.
    func configureAudioSessionForSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured for live session")
        } catch {
            print("Failed to configure audio session for session: \(error.localizedDescription)")
            CrashReportingService.shared.captureError(error, context: ["stage": "session_audio_setup"])
        }
    }

    /// Restore audio session to default TTS playback mode.
    /// Call this when leaving a session.
    func restoreAudioSessionForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session restored for playback")
        } catch {
            print("Failed to restore audio session: \(error.localizedDescription)")
            CrashReportingService.shared.captureError(error, context: ["stage": "session_audio_restore"])
        }
    }

    // MARK: - Connection

    func connect(url: String, token: String) async throws {
        print("LiveKit: Connecting to \(url)...")

        #if canImport(LiveKit)
        let room = Room()
        room.add(delegate: self)
        try await room.connect(url, token)
        self.room = room
        isConnected = true
        print("LiveKit: Connected")
        #else
        // Stub: LiveKit SDK not yet added
        isConnected = true
        print("LiveKit: Connected (stub — add livekit-client-sdk-swift via SPM)")
        #endif
    }

    func disconnect() {
        print("LiveKit: Disconnecting...")

        #if canImport(LiveKit)
        Task {
            await room?.disconnect()
            room = nil
        }
        #endif

        isConnected = false
        isMicEnabled = false
        isCameraEnabled = false
        isVideoSubscriptionEnabled = true

        // Restore audio session when leaving
        restoreAudioSessionForPlayback()
    }

    // MARK: - Media Controls

    func enableMicrophone() {
        #if canImport(LiveKit)
        Task {
            try? await room?.localParticipant.setMicrophone(enabled: true)
        }
        #endif
        isMicEnabled = true
    }

    func disableMicrophone() {
        #if canImport(LiveKit)
        Task {
            try? await room?.localParticipant.setMicrophone(enabled: false)
        }
        #endif
        isMicEnabled = false
    }

    func enableCamera() {
        #if canImport(LiveKit)
        Task {
            try? await room?.localParticipant.setCamera(enabled: true)
        }
        #endif
        isCameraEnabled = true
    }

    func disableCamera() {
        #if canImport(LiveKit)
        Task {
            try? await room?.localParticipant.setCamera(enabled: false)
        }
        #endif
        isCameraEnabled = false
    }

    // MARK: - Host Moderation

    /// Remotely mute a specific participant's microphone (host only).
    func muteParticipant(identity: String) {
        #if canImport(LiveKit)
        guard let participant = room?.remoteParticipants[Participant.Identity(identity)] else { return }
        // LiveKit server-side API is needed for force-muting.
        // For now, send a data message requesting the participant mute themselves.
        Task {
            let data = try JSONEncoder().encode(["action": "mute_audio", "target": identity])
            try await room?.localParticipant.publish(data: data, options: DataPublishOptions(reliable: true))
        }
        #else
        print("LiveKit: muteParticipant (stub) — \(identity)")
        #endif
    }

    /// Remotely disable a specific participant's camera (host only).
    func disableParticipantCamera(identity: String) {
        #if canImport(LiveKit)
        Task {
            let data = try JSONEncoder().encode(["action": "disable_camera", "target": identity])
            try await room?.localParticipant.publish(data: data, options: DataPublishOptions(reliable: true))
        }
        #else
        print("LiveKit: disableParticipantCamera (stub) — \(identity)")
        #endif
    }

    // MARK: - Selective Video Subscription

    /// Enable or disable video track subscription for all remote participants.
    /// Used to implement audio-only mode for free users or waitlisted viewers.
    /// When disabled, the client only receives audio tracks, saving video bandwidth.
    func setVideoSubscriptionEnabled(_ enabled: Bool) {
        #if canImport(LiveKit)
        guard let room = room else {
            isVideoSubscriptionEnabled = enabled
            return
        }
        for participant in room.remoteParticipants.values {
            for publication in participant.trackPublications.values {
                if publication.kind == .video {
                    Task {
                        try? await publication.set(subscribed: enabled)
                    }
                }
            }
        }
        #endif
        isVideoSubscriptionEnabled = enabled
        print("LiveKit: Video subscription \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Role Permissions

    func applyPermissions(for role: SessionRole) {
        print("LiveKit: Applying permissions for role: \(role.rawValue)")
        if role.canSpeak {
            enableMicrophone()
            enableCamera()
        } else {
            disableMicrophone()
            disableCamera()
        }
    }
}

// MARK: - LiveKit Room Delegate
#if canImport(LiveKit)
extension LiveKitService: RoomDelegate {
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        // Apply video subscription state to newly subscribed tracks
        if publication.kind == .video && !isVideoSubscriptionEnabled {
            Task {
                try? await publication.set(subscribed: false)
            }
        }
        onTrackPublished?(participant.identity?.stringValue ?? "")
    }

    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        onTrackUnpublished?(participant.identity?.stringValue ?? "")
    }

    func room(_ room: Room, participantDidJoin participant: RemoteParticipant) {
        onParticipantConnected?(participant.identity?.stringValue ?? "")
    }

    func room(_ room: Room, participantDidLeave participant: RemoteParticipant) {
        onParticipantDisconnected?(participant.identity?.stringValue ?? "")
    }

    func room(_ room: Room, participant: RemoteParticipant, didReceiveData data: Data, forTopic topic: String) {
        // Handle moderation commands from host
        guard let command = try? JSONDecoder().decode([String: String].self, from: data),
              let action = command["action"],
              let target = command["target"],
              target == room.localParticipant.identity?.stringValue else { return }

        Task { @MainActor in
            switch action {
            case "mute_audio":
                self.disableMicrophone()
                self.isMicEnabled = false
            case "disable_camera":
                self.disableCamera()
                self.isCameraEnabled = false
            default:
                break
            }
        }
    }
}
#endif
