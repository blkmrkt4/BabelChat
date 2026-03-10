import Foundation

// MARK: - Session Role
enum SessionRole: String, Codable {
    case host = "host"
    case coSpeaker = "co_speaker"
    case rotatingSpeaker = "rotating_speaker"
    case listener = "listener"

    var canSpeak: Bool {
        switch self {
        case .host, .coSpeaker, .rotatingSpeaker:
            return true
        case .listener:
            return false
        }
    }

    var canVideo: Bool {
        return canSpeak
    }

    var canPromote: Bool {
        switch self {
        case .host, .coSpeaker:
            return true
        case .rotatingSpeaker, .listener:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .host: return "session_role_host".localized
        case .coSpeaker: return "session_role_co_speaker".localized
        case .rotatingSpeaker: return "session_role_speaker".localized
        case .listener: return "session_role_listener".localized
        }
    }
}

// MARK: - Session Status
enum SessionStatus: String, Codable {
    case scheduled = "scheduled"
    case live = "live"
    case ended = "ended"
    case cancelled = "cancelled"
}

// MARK: - Language Pair
struct SessionLanguagePair: Codable, Equatable {
    let native: String
    let learning: String

    var displayString: String {
        return "\(native) \u{2194} \(learning)"
    }
}

// MARK: - Session
struct Session: Codable {
    let id: String
    let hostId: String
    let title: String?
    var goal: String?
    let languagePair: SessionLanguagePair
    let status: SessionStatus
    let isOpen: Bool
    let scheduledAt: Date?
    let startedAt: Date?
    let endedAt: Date?
    let maxDurationMinutes: Int
    let participantCount: Int
    let maxParticipants: Int
    let maxVideoViewers: Int
    let livekitRoomName: String?
    let createdAt: Date

    // Viewer count (for live sessions)
    var viewerCount: Int

    // Joined data (optional, populated when fetched with joins)
    var host: User?
    var participants: [SessionParticipant]?

    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title
        case goal
        case languagePair = "language_pair"
        case status
        case isOpen = "is_open"
        case scheduledAt = "scheduled_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case maxDurationMinutes = "max_duration_minutes"
        case participantCount = "participant_count"
        case maxParticipants = "max_participants"
        case maxVideoViewers = "max_video_viewers"
        case livekitRoomName = "livekit_room_name"
        case createdAt = "created_at"
        case viewerCount = "viewer_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        hostId = try container.decode(String.self, forKey: .hostId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        goal = try container.decodeIfPresent(String.self, forKey: .goal)
        languagePair = try container.decode(SessionLanguagePair.self, forKey: .languagePair)
        status = try container.decode(SessionStatus.self, forKey: .status)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        scheduledAt = try container.decodeIfPresent(Date.self, forKey: .scheduledAt)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        maxDurationMinutes = try container.decode(Int.self, forKey: .maxDurationMinutes)
        participantCount = try container.decode(Int.self, forKey: .participantCount)
        maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants) ?? 4
        maxVideoViewers = try container.decodeIfPresent(Int.self, forKey: .maxVideoViewers) ?? 5
        livekitRoomName = try container.decodeIfPresent(String.self, forKey: .livekitRoomName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        viewerCount = try container.decodeIfPresent(Int.self, forKey: .viewerCount) ?? 0
        // host and participants are set via post-fetch enrichment, not from JSON
        host = nil
        participants = nil
    }

    var isLive: Bool {
        return status == .live
    }

    /// Whether the session's max duration has been exceeded (host may have crashed)
    var isExpired: Bool {
        guard status == .live, let startedAt = startedAt else { return false }
        return Date().timeIntervalSince(startedAt) > TimeInterval(maxDurationMinutes * 60)
    }

    var isScheduled: Bool {
        return status == .scheduled
    }

    var displayTitle: String {
        return title ?? languagePair.displayString
    }
}

// MARK: - Session Participant
struct SessionParticipant: Codable {
    let id: String
    let sessionId: String
    let userId: String
    var role: SessionRole
    var isHandRaised: Bool
    let handRaisedAt: Date?
    let joinedAt: Date
    let leftAt: Date?
    let isActive: Bool

    // Joined data
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case role
        case isHandRaised = "is_hand_raised"
        case handRaisedAt = "hand_raised_at"
        case joinedAt = "joined_at"
        case leftAt = "left_at"
        case isActive = "is_active"
    }
}

// MARK: - Session Message
struct SessionMessage: Codable {
    let id: String
    let sessionId: String
    let senderId: String
    let originalText: String
    let originalLanguage: String
    let translatedText: [String: String]
    let aiInsights: [String: String]
    let createdAt: Date

    // Runtime (not persisted)
    var senderName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case senderId = "sender_id"
        case originalText = "original_text"
        case originalLanguage = "original_language"
        case translatedText = "translated_text"
        case aiInsights = "ai_insights"
        case createdAt = "created_at"
    }

    /// Convert to Message for SwipeableMessageCell compatibility
    func toMessage(currentUserId: String) -> Message {
        return Message(
            id: id,
            senderId: senderId,
            recipientId: sessionId,
            text: originalText,
            timestamp: createdAt,
            isRead: true,
            originalLanguage: Language.from(name: originalLanguage),
            translatedText: translatedText.values.first,
            grammarSuggestions: nil,
            alternatives: nil,
            culturalNotes: nil
        )
    }
}

// MARK: - Session Invite
struct SessionInvite: Codable {
    let id: String
    let sessionId: String
    let inviterId: String
    let inviteeId: String
    let role: String
    let status: String
    let createdAt: Date

    // Joined data
    var session: Session?
    var inviter: User?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case role
        case status
        case createdAt = "created_at"
    }

    var isPending: Bool {
        return status == "pending"
    }
}
