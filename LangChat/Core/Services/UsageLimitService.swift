//
//  UsageLimitService.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation

class UsageLimitService {
    static let shared = UsageLimitService()

    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let usageKeyPrefix = "daily_usage_"

    // MARK: - Initialization
    private init() {
        // Clean up old usage data on init
        cleanupOldUsageData()
    }

    // MARK: - Check Usage Limit
    /// Check if user can perform an action based on their subscription tier
    /// - Parameters:
    ///   - type: The type of action (AI message or profile view)
    ///   - tier: The user's subscription tier
    /// - Returns: UsageLimitResult indicating if action is allowed
    func checkLimit(for type: UsageLimitType, tier: SubscriptionTier) -> UsageLimitResult {
        // Premium users have no limits
        if tier == .premium {
            return .allowed(remaining: nil)
        }

        // Get today's usage
        let usage = getTodayUsage(for: type)

        // Check if limit reached
        if usage.hasReachedLimit(for: tier) {
            let resetDate = getNextResetDate()
            return .limitReached(type: type, limit: type.limitForFreeTier, resetDate: resetDate)
        }

        // Calculate remaining
        let remaining = usage.remainingCount(for: tier)
        return .allowed(remaining: remaining)
    }

    // MARK: - Increment Usage
    /// Increment usage count for a specific type
    /// - Parameter type: The type of action being performed
    /// - Returns: Updated usage count
    @discardableResult
    func incrementUsage(for type: UsageLimitType) -> Int {
        var usage = getTodayUsage(for: type)
        usage.count += 1
        saveUsage(usage)

        print("📊 Usage incremented: \(type.displayName) = \(usage.count)/\(type.limitForFreeTier)")

        return usage.count
    }

    // MARK: - Get Usage
    /// Get today's usage for a specific type
    func getTodayUsage(for type: UsageLimitType) -> DailyUsage {
        let today = getTodayDateString()
        let key = usageKey(for: type, date: today)

        if let data = userDefaults.data(forKey: key),
           let usage = try? JSONDecoder().decode(DailyUsage.self, from: data),
           usage.dateString == today {
            return usage
        }

        // Return new usage for today
        return DailyUsage(type: type, date: Date(), count: 0)
    }

    /// Get remaining count for a specific type
    func getRemainingCount(for type: UsageLimitType, tier: SubscriptionTier) -> Int? {
        if tier == .premium {
            return nil // Unlimited
        }

        let usage = getTodayUsage(for: type)
        return usage.remainingCount(for: tier)
    }

    // MARK: - Reset Usage
    /// Reset usage for a specific type (mainly for testing)
    func resetUsage(for type: UsageLimitType) {
        let today = getTodayDateString()
        let key = usageKey(for: type, date: today)
        userDefaults.removeObject(forKey: key)
        print("🔄 Usage reset: \(type.displayName)")
    }

    /// Reset all usage (mainly for testing)
    func resetAllUsage() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let usageKeys = allKeys.filter { $0.hasPrefix(usageKeyPrefix) }
        usageKeys.forEach { userDefaults.removeObject(forKey: $0) }
        print("🔄 All usage reset")
    }

    // MARK: - Private Helpers
    private func saveUsage(_ usage: DailyUsage) {
        let key = usageKey(for: usage.type, date: usage.dateString)
        if let encoded = try? JSONEncoder().encode(usage) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    private func usageKey(for type: UsageLimitType, date: String) -> String {
        return "\(usageKeyPrefix)\(type.rawValue)_\(date)"
    }

    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func getNextResetDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        return startOfTomorrow
    }

    /// Clean up usage data older than 7 days
    private func cleanupOldUsageData() {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffDateString = formatter.string(from: sevenDaysAgo)

        let allKeys = userDefaults.dictionaryRepresentation().keys
        let usageKeys = allKeys.filter { $0.hasPrefix(usageKeyPrefix) }

        for key in usageKeys {
            // Extract date from key (format: daily_usage_type_YYYY-MM-DD)
            let components = key.split(separator: "_")
            if let dateString = components.last, dateString < cutoffDateString {
                userDefaults.removeObject(forKey: key)
                print("🗑️ Cleaned up old usage data: \(key)")
            }
        }
    }

    // MARK: - Convenience Methods
    /// Check if user can send AI message
    func canSendAIMessage(tier: SubscriptionTier) -> UsageLimitResult {
        return checkLimit(for: .aiMessages, tier: tier)
    }

    /// Check if user can view profile
    func canViewProfile(tier: SubscriptionTier) -> UsageLimitResult {
        return checkLimit(for: .profileViews, tier: tier)
    }

    /// Increment AI message count
    @discardableResult
    func incrementAIMessage() -> Int {
        return incrementUsage(for: .aiMessages)
    }

    /// Increment profile view count
    @discardableResult
    func incrementProfileView() -> Int {
        return incrementUsage(for: .profileViews)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let usageLimitReached = Notification.Name("usageLimitReached")
}

// MARK: - Usage Limit Reached Notification
extension UsageLimitService {
    /// Post notification when limit is reached
    func postLimitReachedNotification(for type: UsageLimitType) {
        NotificationCenter.default.post(
            name: .usageLimitReached,
            object: nil,
            userInfo: ["limitType": type]
        )
    }
}
