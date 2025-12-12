//
//  SubscriptionTier.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation

enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free:
            return "Discovery"
        case .premium:
            return "Premium"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "5 AI chat messages per day",
                "View up to 10 profiles per day",
                "Unlimited matches",
                "AI chat only (subject to message limit)"
            ]
        case .premium:
            return [
                "Unlimited AI chat messages",
                "Unlimited profile views",
                "Direct messaging with matches",
                "Full conversation history",
                "All language pairs",
                "Grammar tips & insights",
                "Cultural context",
                "Voice pronunciation"
            ]
        }
    }

    // RevenueCat product identifiers
    var productIdentifier: String? {
        switch self {
        case .free:
            return nil // Free tier has no product
        case .premium:
            return "premium_monthly" // Must match RevenueCat dashboard
        }
    }

    // Daily limits for free tier
    var dailyAIMessageLimit: Int? {
        switch self {
        case .free:
            return 5
        case .premium:
            return nil // Unlimited
        }
    }

    var dailyProfileViewLimit: Int? {
        switch self {
        case .free:
            return 10
        case .premium:
            return nil // Unlimited
        }
    }

    var allowsDirectMessaging: Bool {
        switch self {
        case .free:
            return false
        case .premium:
            return true
        }
    }

    var allowsUnlimitedMatches: Bool {
        return true // Both tiers allow unlimited matches
    }
}

// MARK: - Subscription Status
struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let expiresAt: Date?
    let isTrialing: Bool
    let trialStartDate: Date?
    let trialEndDate: Date?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    var daysRemainingInTrial: Int? {
        guard isTrialing, let trialEndDate = trialEndDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: trialEndDate).day
        return max(0, days ?? 0)
    }

    static var free: SubscriptionStatus {
        return SubscriptionStatus(
            tier: .free,
            isActive: true,
            expiresAt: nil,
            isTrialing: false,
            trialStartDate: nil,
            trialEndDate: nil
        )
    }
}
