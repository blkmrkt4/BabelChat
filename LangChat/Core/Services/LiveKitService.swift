import Foundation

/// LiveKit service wrapper for video/audio room management.
/// Requires LiveKit Swift SDK (`livekit-client-sdk-swift`) to be added via SPM.
/// Until the SDK is added, this provides the interface and stubs.
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

    private init() {}

    // MARK: - Connection

    func connect(url: String, token: String) async throws {
        print("LiveKit: Connecting to \(url)...")
        // TODO: Integrate LiveKit SDK
        // let room = Room()
        // try await room.connect(url, token)
        isConnected = true
        print("LiveKit: Connected (stub)")
    }

    func disconnect() {
        print("LiveKit: Disconnecting...")
        // TODO: room.disconnect()
        isConnected = false
        isMicEnabled = false
        isCameraEnabled = false
    }

    // MARK: - Media Controls

    func enableMicrophone() {
        print("LiveKit: Enabling microphone")
        // TODO: room.localParticipant.setMicrophone(enabled: true)
        isMicEnabled = true
    }

    func disableMicrophone() {
        print("LiveKit: Disabling microphone")
        // TODO: room.localParticipant.setMicrophone(enabled: false)
        isMicEnabled = false
    }

    func enableCamera() {
        print("LiveKit: Enabling camera")
        // TODO: room.localParticipant.setCamera(enabled: true)
        isCameraEnabled = true
    }

    func disableCamera() {
        print("LiveKit: Disabling camera")
        // TODO: room.localParticipant.setCamera(enabled: false)
        isCameraEnabled = false
    }

    // MARK: - Permissions

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
