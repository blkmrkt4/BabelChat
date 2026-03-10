//
//  VideoSlot.swift
//  LangChat
//
//  Created by Claude Code on 2026-03-10.
//

import Foundation

// MARK: - Video Slot Status
enum VideoSlotStatus: String, Codable {
    case confirmed = "confirmed"   // RSVP'd pre-session, slot reserved
    case waitlisted = "waitlisted" // In queue, ordered by position
    case active = "active"         // In session, receiving video
    case expired = "expired"       // No-show after grace period, slot reclaimed
}

// MARK: - Video Slot
struct VideoSlot: Codable {
    let id: String
    let sessionId: String
    let userId: String
    let status: VideoSlotStatus
    let position: Int?
    let reservedAt: Date
    let activatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case status
        case position
        case reservedAt = "reserved_at"
        case activatedAt = "activated_at"
    }
}

// MARK: - Video Slot Info
struct VideoSlotInfo: Codable {
    let totalActive: Int
    let maxSlots: Int
    let myStatus: VideoSlotStatus?
    let myPosition: Int?

    var availableSlots: Int {
        max(0, maxSlots - totalActive)
    }

    var hasAvailableSlots: Bool {
        availableSlots > 0
    }

    enum CodingKeys: String, CodingKey {
        case totalActive = "total_active"
        case maxSlots = "max_slots"
        case myStatus = "my_status"
        case myPosition = "my_position"
    }
}

// MARK: - Reserve Video Slot Response
struct ReserveVideoSlotResponse: Codable {
    let status: VideoSlotStatus
    let position: Int?
}
