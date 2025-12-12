//
//  UsageLimit.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation

// MARK: - Usage Limit Types
enum UsageLimitType: String, Codable {
    case aiMessages = "ai_messages"
    case profileViews = "profile_views"

    var displayName: String {
        switch self {
        case .aiMessages:
            return "AI Messages"
        case .profileViews:
            return "Profile Views"
        }
    }

    var limitForFreeTier: Int {
        switch self {
        case .aiMessages:
            return 5
        case .profileViews:
            return 10
        }
    }
}

// MARK: - Daily Usage
struct DailyUsage: Codable {
    let type: UsageLimitType
    let date: Date
    var count: Int

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    init(type: UsageLimitType, date: Date = Date(), count: Int = 0) {
        self.type = type
        self.date = date
        self.count = count
    }

    func hasReachedLimit(for tier: SubscriptionTier) -> Bool {
        switch tier {
        case .free:
            return count >= type.limitForFreeTier
        case .premium:
            return false // Premium has no limits
        }
    }

    func remainingCount(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:
            return max(0, type.limitForFreeTier - count)
        case .premium:
            return nil // Unlimited
        }
    }
}

// MARK: - Usage Limit Result
enum UsageLimitResult {
    case allowed(remaining: Int?)
    case limitReached(type: UsageLimitType, limit: Int, resetDate: Date)

    var isAllowed: Bool {
        if case .allowed = self {
            return true
        }
        return false
    }

    var message: String {
        switch self {
        case .allowed(let remaining):
            if let remaining = remaining {
                return "\(remaining) remaining today"
            } else {
                return "Unlimited"
            }
        case .limitReached(let type, let limit, _):
            return "You've reached your daily limit of \(limit) \(type.displayName.lowercased())"
        }
    }
}
