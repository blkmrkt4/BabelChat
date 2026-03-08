import Foundation
import Supabase

class SessionService {
    static let shared = SessionService()

    private let supabase = SupabaseService.shared
    private var sessionChannel: RealtimeChannel?
    private var messagesChannel: RealtimeChannel?

    private init() {}

    // MARK: - Insert DTOs

    private struct SessionInsert: Encodable {
        let hostId: String
        let title: String?
        let goal: String?
        let languagePair: SessionLanguagePair
        let status: String
        let isOpen: Bool
        let scheduledAt: String?
        let startedAt: String?
        let livekitRoomName: String

        enum CodingKeys: String, CodingKey {
            case hostId = "host_id"
            case title
            case goal
            case languagePair = "language_pair"
            case status
            case isOpen = "is_open"
            case scheduledAt = "scheduled_at"
            case startedAt = "started_at"
            case livekitRoomName = "livekit_room_name"
        }
    }

    private struct ParticipantInsert: Encodable {
        let sessionId: String
        let userId: String
        let role: String
        let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case userId = "user_id"
            case role
            case isActive = "is_active"
        }
    }

    private struct MessageInsert: Encodable {
        let sessionId: String
        let senderId: String
        let originalText: String
        let originalLanguage: String

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case senderId = "sender_id"
            case originalText = "original_text"
            case originalLanguage = "original_language"
        }
    }

    private struct InviteInsert: Encodable {
        let sessionId: String
        let inviterId: String
        let inviteeId: String
        let role: String

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case inviterId = "inviter_id"
            case inviteeId = "invitee_id"
            case role
        }
    }

    // MARK: - CRUD

    func createSession(
        title: String?,
        goal: String? = nil,
        languagePair: SessionLanguagePair,
        isOpen: Bool,
        scheduledAt: Date?,
        invitees: [(userId: String, role: SessionRole)] = []
    ) async throws -> Session {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let isStartingNow = scheduledAt == nil
        let roomName = "session_\(UUID().uuidString.lowercased())"

        let insert = SessionInsert(
            hostId: userId.uuidString,
            title: title,
            goal: goal,
            languagePair: languagePair,
            status: isStartingNow ? "live" : "scheduled",
            isOpen: isOpen,
            scheduledAt: scheduledAt?.ISO8601Format(),
            startedAt: isStartingNow ? Date().ISO8601Format() : nil,
            livekitRoomName: roomName
        )

        let response: Session = try await supabase.client
            .from("sessions")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        // Add host as participant
        try await joinSession(sessionId: response.id, role: .host)

        // Create invites for selected participants
        for invitee in invitees {
            try await createInvite(sessionId: response.id, inviteeId: invitee.userId, role: invitee.role.rawValue)
        }

        AnalyticsService.shared.track(.sessionCreated, properties: [
            "session_id": response.id,
            "is_open": isOpen,
            "invitee_count": invitees.count
        ])

        return response
    }

    func getMySessions() async throws -> [Session] {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let response: [Session] = try await supabase.client
            .from("sessions")
            .select()
            .eq("host_id", value: userId.uuidString)
            .in("status", values: ["scheduled", "live"])
            .order("scheduled_at", ascending: true)
            .execute()
            .value

        return response
    }

    func getDiscoverableSessions() async throws -> [Session] {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let response: [Session] = try await supabase.client
            .rpc("get_discoverable_sessions", params: ["p_user_id": userId.uuidString])
            .execute()
            .value

        return response
    }

    func getSession(id: String) async throws -> Session {
        let response: Session = try await supabase.client
            .from("sessions")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return response
    }

    func getSessionParticipants(sessionId: String) async throws -> [SessionParticipant] {
        let response: [SessionParticipant] = try await supabase.client
            .from("session_participants")
            .select()
            .eq("session_id", value: sessionId)
            .eq("is_active", value: true)
            .execute()
            .value

        return response
    }

    func startSession(id: String) async throws {
        try await supabase.client
            .from("sessions")
            .update(["status": "live", "started_at": Date().ISO8601Format()])
            .eq("id", value: id)
            .execute()
    }

    func endSession(id: String) async throws {
        try await supabase.client
            .from("sessions")
            .update(["status": "ended", "ended_at": Date().ISO8601Format()])
            .eq("id", value: id)
            .execute()

        AnalyticsService.shared.track(.sessionEnded, properties: ["session_id": id])
    }

    func updateGoal(sessionId: String, goal: String) async throws {
        try await supabase.client
            .from("sessions")
            .update(["goal": goal])
            .eq("id", value: sessionId)
            .execute()
    }

    func cancelSession(id: String) async throws {
        try await supabase.client
            .from("sessions")
            .update(["status": "cancelled", "ended_at": Date().ISO8601Format()])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Participants

    @discardableResult
    func joinSession(sessionId: String, role: SessionRole = .listener) async throws -> SessionParticipant {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let insert = ParticipantInsert(
            sessionId: sessionId,
            userId: userId.uuidString,
            role: role.rawValue,
            isActive: true
        )

        let response: SessionParticipant = try await supabase.client
            .from("session_participants")
            .upsert(insert)
            .select()
            .single()
            .execute()
            .value

        AnalyticsService.shared.track(.sessionJoined, properties: [
            "session_id": sessionId,
            "role": role.rawValue
        ])

        return response
    }

    func leaveSession(sessionId: String) async throws {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        try await supabase.client
            .from("session_participants")
            .update(["is_active": "false", "left_at": Date().ISO8601Format()])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func promoteParticipant(sessionId: String, userId: String, to role: SessionRole) async throws {
        // If promoting to rotating_speaker, demote current rotating speaker first
        if role == .rotatingSpeaker {
            try await supabase.client
                .from("session_participants")
                .update(["role": SessionRole.listener.rawValue])
                .eq("session_id", value: sessionId)
                .eq("role", value: SessionRole.rotatingSpeaker.rawValue)
                .eq("is_active", value: true)
                .execute()
        }

        try await supabase.client
            .from("session_participants")
            .update(["role": role.rawValue, "is_hand_raised": "false"])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()

        AnalyticsService.shared.track(.speakerPromoted, properties: [
            "session_id": sessionId,
            "promoted_user_id": userId,
            "new_role": role.rawValue
        ])
    }

    func demoteParticipant(sessionId: String, userId: String) async throws {
        try await supabase.client
            .from("session_participants")
            .update(["role": SessionRole.listener.rawValue])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId)
            .execute()
    }

    func raiseHand(sessionId: String) async throws {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        try await supabase.client
            .from("session_participants")
            .update(["is_hand_raised": "true", "hand_raised_at": Date().ISO8601Format()])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId.uuidString)
            .execute()

        AnalyticsService.shared.track(.handRaised, properties: ["session_id": sessionId])
    }

    func lowerHand(sessionId: String) async throws {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        try await supabase.client
            .from("session_participants")
            .update(["is_hand_raised": "false"])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func getHandRaiseQueue(sessionId: String) async throws -> [SessionParticipant] {
        let response: [SessionParticipant] = try await supabase.client
            .from("session_participants")
            .select()
            .eq("session_id", value: sessionId)
            .eq("is_hand_raised", value: true)
            .eq("is_active", value: true)
            .order("hand_raised_at", ascending: true)
            .execute()
            .value

        return response
    }

    // MARK: - Messages

    func sendMessage(sessionId: String, text: String, language: String) async throws -> SessionMessage {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let insert = MessageInsert(
            sessionId: sessionId,
            senderId: userId.uuidString,
            originalText: text,
            originalLanguage: language
        )

        let response: SessionMessage = try await supabase.client
            .from("session_messages")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func getSessionMessages(sessionId: String, limit: Int = 50) async throws -> [SessionMessage] {
        let response: [SessionMessage] = try await supabase.client
            .from("session_messages")
            .select()
            .eq("session_id", value: sessionId)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value

        return response
    }

    // MARK: - Invites

    func createInvite(sessionId: String, inviteeId: String, role: String = "co_speaker") async throws {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let insert = InviteInsert(
            sessionId: sessionId,
            inviterId: userId.uuidString,
            inviteeId: inviteeId,
            role: role
        )

        try await supabase.client
            .from("session_invites")
            .insert(insert)
            .execute()
    }

    func getMyInvites() async throws -> [SessionInvite] {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let response: [SessionInvite] = try await supabase.client
            .from("session_invites")
            .select()
            .eq("invitee_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func respondToInvite(inviteId: String, accept: Bool) async throws {
        let newStatus = accept ? "accepted" : "declined"

        try await supabase.client
            .from("session_invites")
            .update(["status": newStatus])
            .eq("id", value: inviteId)
            .execute()

        // If accepted, join the session with the invited role
        if accept {
            let invite: SessionInvite = try await supabase.client
                .from("session_invites")
                .select()
                .eq("id", value: inviteId)
                .single()
                .execute()
                .value

            let role = SessionRole(rawValue: invite.role) ?? .coSpeaker
            try await joinSession(sessionId: invite.sessionId, role: role)
        }
    }

    // MARK: - Realtime

    func subscribeToSessionUpdates(
        sessionId: String,
        onParticipantChange: @escaping ([SessionParticipant]) -> Void,
        onSessionStatusChange: @escaping (Session) -> Void
    ) -> RealtimeChannel {
        let channel = supabase.client.realtime.channel("session:\(sessionId)")

        // Listen for participant changes
        channel.on("postgres_changes", filter: ChannelFilter(
            event: "*",
            schema: "public",
            table: "session_participants",
            filter: "session_id=eq.\(sessionId)"
        )) { _ in
            Task {
                if let participants = try? await self.getSessionParticipants(sessionId: sessionId) {
                    await MainActor.run { onParticipantChange(participants) }
                }
            }
        }

        // Listen for session status changes
        channel.on("postgres_changes", filter: ChannelFilter(
            event: "UPDATE",
            schema: "public",
            table: "sessions",
            filter: "id=eq.\(sessionId)"
        )) { message in
            if let payload = message.payload["record"] as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: payload)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let session = try decoder.decode(Session.self, from: jsonData)
                    Task { @MainActor in onSessionStatusChange(session) }
                } catch {
                    print("Error parsing session update: \(error)")
                }
            }
        }

        channel.subscribe()
        self.sessionChannel = channel
        return channel
    }

    func subscribeToSessionMessages(
        sessionId: String,
        onMessage: @escaping (SessionMessage) -> Void
    ) -> RealtimeChannel {
        let channel = supabase.client.realtime.channel("session_messages:\(sessionId)")

        channel.on("postgres_changes", filter: ChannelFilter(
            event: "INSERT",
            schema: "public",
            table: "session_messages",
            filter: "session_id=eq.\(sessionId)"
        )) { message in
            if let payload = message.payload["record"] as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: payload)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let sessionMessage = try decoder.decode(SessionMessage.self, from: jsonData)
                    Task { @MainActor in onMessage(sessionMessage) }
                } catch {
                    print("Error parsing session message: \(error)")
                }
            }
        }

        channel.subscribe()
        self.messagesChannel = channel
        return channel
    }

    func unsubscribeAll() {
        sessionChannel?.unsubscribe()
        messagesChannel?.unsubscribe()
        sessionChannel = nil
        messagesChannel = nil
    }
}

// MARK: - Session Error
enum SessionError: LocalizedError {
    case notAuthenticated
    case sessionFull
    case sessionEnded
    case notHost

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to use sessions."
        case .sessionFull: return "This session is full."
        case .sessionEnded: return "This session has ended."
        case .notHost: return "Only the host can perform this action."
        }
    }
}
