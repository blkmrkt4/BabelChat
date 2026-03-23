import Foundation
import Supabase

class SessionService {
    static let shared = SessionService()

    private let supabase = SupabaseService.shared
    private var sessionChannel: RealtimeChannel?
    private var messagesChannel: RealtimeChannel?
    private var videoSlotsChannel: RealtimeChannel?

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
        let roomName: String
        let hmsRoomId: String
        let maxParticipants: Int
        let maxVideoViewers: Int

        enum CodingKeys: String, CodingKey {
            case hostId = "host_id"
            case title
            case goal
            case languagePair = "language_pair"
            case status
            case isOpen = "is_open"
            case scheduledAt = "scheduled_at"
            case startedAt = "started_at"
            case roomName = "livekit_room_name"
            case hmsRoomId = "hms_room_id"
            case maxParticipants = "max_participants"
            case maxVideoViewers = "max_video_viewers"
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

    // MARK: - Host Enrichment

    /// Batch-fetch host profiles and co-host participants, then assign to sessions
    private func enrichWithHosts(_ sessions: inout [Session]) async {
        let hostIds = Array(Set(sessions.map { $0.hostId }))
        guard !hostIds.isEmpty else { return }

        do {
            // Fetch host profiles
            let profiles: [ProfileResponse] = try await supabase.client
                .from("profiles")
                .select()
                .in("id", values: hostIds)
                .execute()
                .value

            var userMap: [String: User] = [:]
            for profile in profiles {
                if let user = profile.toUser() {
                    userMap[profile.id] = user
                }
            }

            for i in sessions.indices {
                sessions[i].host = userMap[sessions[i].hostId]
            }

            // Fetch co-host participants for all sessions
            let sessionIds = sessions.map { $0.id }
            let coHostParticipants: [SessionParticipant] = try await supabase.client
                .from("session_participants")
                .select()
                .in("session_id", values: sessionIds)
                .eq("role", value: SessionRole.coHost.rawValue)
                .eq("is_active", value: true)
                .execute()
                .value

            // Track which sessions already have co-host participants
            let sessionsWithCoHosts = Set(coHostParticipants.map { $0.sessionId })

            if !coHostParticipants.isEmpty {
                // Fetch co-host profiles
                let coHostUserIds = Array(Set(coHostParticipants.map { $0.userId }))
                let coHostProfiles: [ProfileResponse] = try await supabase.client
                    .from("profiles")
                    .select()
                    .in("id", values: coHostUserIds)
                    .execute()
                    .value

                for profile in coHostProfiles {
                    if let user = profile.toUser() {
                        userMap[profile.id] = user
                    }
                }

                // Assign co-host participants (with user data) to each session
                for i in sessions.indices {
                    var sessionCoHosts = coHostParticipants.filter { $0.sessionId == sessions[i].id }
                    for j in sessionCoHosts.indices {
                        sessionCoHosts[j].user = userMap[sessionCoHosts[j].userId]
                    }
                    if !sessionCoHosts.isEmpty {
                        sessions[i].participants = sessionCoHosts
                    }
                }
            }

            // Fallback: for sessions without co-host participants, check session_invites
            let sessionsNeedingInviteCheck = sessionIds.filter { !sessionsWithCoHosts.contains($0) }
            if !sessionsNeedingInviteCheck.isEmpty {
                let coHostInvites: [SessionInvite] = try await supabase.client
                    .from("session_invites")
                    .select()
                    .in("session_id", values: sessionsNeedingInviteCheck)
                    .eq("role", value: SessionRole.coHost.rawValue)
                    .in("status", values: ["pending", "accepted"])
                    .execute()
                    .value

                if !coHostInvites.isEmpty {
                    // Fetch invitee profiles
                    let inviteeIds = Array(Set(coHostInvites.map { $0.inviteeId }))
                    let inviteeProfiles: [ProfileResponse] = try await supabase.client
                        .from("profiles")
                        .select()
                        .in("id", values: inviteeIds)
                        .execute()
                        .value

                    for profile in inviteeProfiles {
                        if let user = profile.toUser() {
                            userMap[profile.id] = user
                        }
                    }

                    // Create synthetic co-host participant entries from invites
                    for i in sessions.indices {
                        guard sessions[i].participants == nil else { continue }
                        let invitesForSession = coHostInvites.filter { $0.sessionId == sessions[i].id }
                        if let invite = invitesForSession.first, let user = userMap[invite.inviteeId] {
                            var syntheticParticipant = SessionParticipant(
                                id: invite.id,
                                sessionId: invite.sessionId,
                                userId: invite.inviteeId,
                                role: .coHost,
                                isHandRaised: false,
                                handRaisedAt: nil,
                                joinedAt: invite.createdAt,
                                leftAt: nil,
                                isActive: true
                            )
                            syntheticParticipant.user = user
                            sessions[i].participants = [syntheticParticipant]
                        }
                    }
                }
            }
        } catch {
            print("Failed to enrich sessions with host data: \(error)")
        }
    }

    /// Enrich a single session with host data
    private func enrichWithHost(_ session: inout Session) async {
        var sessions = [session]
        await enrichWithHosts(&sessions)
        session = sessions[0]
    }

    // MARK: - CRUD

    func createSession(
        title: String?,
        goal: String? = nil,
        languagePair: SessionLanguagePair,
        isOpen: Bool,
        scheduledAt: Date?,
        invitees: [(userId: String, role: SessionRole)] = [],
        hostTier: SubscriptionTier = .pro
    ) async throws -> Session {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let isStartingNow = scheduledAt == nil
        let roomName = "session_\(UUID().uuidString.lowercased())"

        // Create room on 100ms via Edge Function (region based on host location)
        let hostLocation = UserDefaults.standard.string(forKey: "location") ?? ""
        let hmsRoomId = try await createHMSRoom(roomName: roomName, hostLocation: hostLocation)

        let insert = SessionInsert(
            hostId: userId.uuidString,
            title: title,
            goal: goal,
            languagePair: languagePair,
            status: isStartingNow ? "live" : "scheduled",
            isOpen: isOpen,
            scheduledAt: scheduledAt?.ISO8601Format(),
            startedAt: isStartingNow ? Date().ISO8601Format() : nil,
            roomName: roomName,
            hmsRoomId: hmsRoomId,
            maxParticipants: hostTier.maxVideoSlots,
            maxVideoViewers: 5
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

        var response: [Session] = try await supabase.client
            .from("sessions")
            .select()
            .eq("host_id", value: userId.uuidString)
            .in("status", values: ["scheduled", "live"])
            .order("scheduled_at", ascending: true)
            .execute()
            .value

        await enrichWithHosts(&response)
        return response
    }

    func getDiscoverableSessions() async throws -> [Session] {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        var response: [Session] = try await supabase.client
            .rpc("get_discoverable_sessions", params: ["p_user_id": userId.uuidString])
            .execute()
            .value

        await enrichWithHosts(&response)
        return response
    }

    func getSession(id: String) async throws -> Session {
        var response: Session = try await supabase.client
            .from("sessions")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        await enrichWithHost(&response)
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

    /// Fetch participants with their profile data (names, avatars)
    func getSessionParticipantsWithProfiles(sessionId: String) async throws -> [SessionParticipant] {
        var participants = try await getSessionParticipants(sessionId: sessionId)

        let userIds = participants.map { $0.userId }
        guard !userIds.isEmpty else { return participants }

        let profiles: [ProfileResponse] = try await supabase.client
            .from("profiles")
            .select()
            .in("id", values: userIds)
            .execute()
            .value

        var userMap: [String: User] = [:]
        for profile in profiles {
            if let user = profile.toUser() {
                userMap[profile.id] = user
            }
        }

        for i in participants.indices {
            participants[i].user = userMap[participants[i].userId]
        }

        return participants
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
            .upsert(insert, onConflict: "session_id,user_id")
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

    // MARK: - 100ms Room Creation

    private struct CreateRoomResponse: Decodable {
        let roomId: String
        let roomName: String
    }

    /// Creates a room on 100ms via the create-room Edge Function.
    /// The host's location is used to select the nearest 100ms media region.
    private func createHMSRoom(roomName: String, hostLocation: String) async throws -> String {
        let response: CreateRoomResponse = try await supabase.client.functions
            .invoke(
                "create-room",
                options: .init(body: ["roomName": roomName, "hostLocation": hostLocation])
            )

        return response.roomId
    }

    // MARK: - Invites

    func createInvite(sessionId: String, inviteeId: String, role: String = "co_host") async throws {
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

            let role = SessionRole(rawValue: invite.role) ?? .coHost
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
        videoSlotsChannel?.unsubscribe()
        sessionChannel = nil
        messagesChannel = nil
        videoSlotsChannel = nil
    }

    // MARK: - Past Sessions

    func getMyPastSessions() async throws -> [Session] {
        guard let userId = supabase.currentUserId else {
            throw SessionError.notAuthenticated
        }

        // Get session IDs where user was a participant
        let participantRecords: [SessionParticipant] = try await supabase.client
            .from("session_participants")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let participatedIds = participantRecords.map { $0.sessionId }
        guard !participatedIds.isEmpty else { return [] }

        // Fetch ended sessions from the last 30 days that the user participated in
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600).ISO8601Format()

        var sessions: [Session] = try await supabase.client
            .from("sessions")
            .select()
            .in("id", values: participatedIds)
            .eq("status", value: "ended")
            .gte("ended_at", value: thirtyDaysAgo)
            .order("ended_at", ascending: false)
            .execute()
            .value

        await enrichWithHosts(&sessions)
        return sessions
    }

    // MARK: - Viewer Count

    func incrementViewerCount(sessionId: String) async throws {
        try await supabase.client
            .rpc("increment_viewer_count", params: ["p_session_id": sessionId])
            .execute()
    }

    func decrementViewerCount(sessionId: String) async throws {
        try await supabase.client
            .rpc("decrement_viewer_count", params: ["p_session_id": sessionId])
            .execute()
    }

    // MARK: - Video Slots

    /// Reserve a video slot for the current user in a session
    func reserveVideoSlot(sessionId: String) async throws -> ReserveVideoSlotResponse {
        let response: ReserveVideoSlotResponse = try await supabase.client
            .rpc("reserve_video_slot", params: ["p_session_id": sessionId])
            .execute()
            .value

        return response
    }

    /// Activate a confirmed video slot when joining a live session
    func activateVideoSlot(sessionId: String) async throws {
        try await supabase.client
            .rpc("activate_video_slot", params: ["p_session_id": sessionId])
            .execute()
    }

    /// Release a video slot (when leaving a session)
    @discardableResult
    func releaseVideoSlot(sessionId: String) async throws -> String? {
        let response: String? = try await supabase.client
            .rpc("release_video_slot", params: ["p_session_id": sessionId])
            .execute()
            .value

        return response
    }

    /// Get video slot status for a session
    func getVideoSlotStatus(sessionId: String) async throws -> VideoSlotInfo {
        let response: VideoSlotInfo = try await supabase.client
            .rpc("get_video_slot_status", params: ["p_session_id": sessionId])
            .execute()
            .value

        return response
    }

    /// Subscribe to video slot changes for real-time UI updates
    func subscribeToVideoSlotUpdates(
        sessionId: String,
        onChange: @escaping (VideoSlot) -> Void
    ) -> RealtimeChannel {
        let channel = supabase.client.realtime.channel("video_slots:\(sessionId)")

        channel.on("postgres_changes", filter: ChannelFilter(
            event: "*",
            schema: "public",
            table: "session_video_slots",
            filter: "session_id=eq.\(sessionId)"
        )) { message in
            if let payload = message.payload["record"] as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: payload)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let slot = try decoder.decode(VideoSlot.self, from: jsonData)
                    Task { @MainActor in onChange(slot) }
                } catch {
                    print("Error parsing video slot update: \(error)")
                }
            }
        }

        channel.subscribe()
        self.videoSlotsChannel = channel
        return channel
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
