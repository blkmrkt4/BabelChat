//
//  SubscriptionTier.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation

// MARK: - TTS Voice Quality
enum TTSVoiceQuality: String, Codable {
    case appleNative = "apple"
    case googleNeural2 = "google_neural2"
    case googleChirp = "google_chirp"

    var displayName: String {
        switch self {
        case .appleNative:
            return "Standard"
        case .googleNeural2:
            return "Natural (Neural2)"
        case .googleChirp:
            return "Premium (Chirp)"
        }
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free:
            return "tier_free_display_name".localized
        case .premium:
            return "tier_premium_display_name".localized
        case .pro:
            return "tier_pro_display_name".localized
        }
    }

    var price: String {
        switch self {
        case .free:
            return "7-Day Trial"
        case .premium:
            return "$9.99/month"
        case .pro:
            return "$19.99/month"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "tier_free_feature_1".localized,
                "tier_free_feature_2".localized,
                "tier_free_feature_3".localized,
                "tier_free_feature_4".localized
            ]
        case .premium:
            return [
                "tier_premium_feature_1".localized,
                "tier_premium_feature_2".localized,
                "tier_premium_feature_3".localized,
                "tier_premium_feature_4".localized
            ]
        case .pro:
            return [
                "tier_pro_feature_1".localized,
                "tier_pro_feature_2".localized,
                "tier_pro_feature_3".localized,
                "tier_pro_feature_4".localized
            ]
        }
    }

    var shortDescription: String {
        switch self {
        case .free:
            return "tier_free_short_desc".localized
        case .premium:
            return "tier_premium_short_desc".localized
        case .pro:
            return "tier_pro_short_desc".localized
        }
    }

    // RevenueCat product identifiers
    var productIdentifier: String? {
        switch self {
        case .free:
            return nil // Free tier has no product
        case .premium:
            return "premium_monthly" // Must match RevenueCat dashboard
        case .pro:
            return "pro_monthly" // Must match RevenueCat dashboard
        }
    }

    // MARK: - Message Limits

    var monthlyMessageLimit: Int? {
        switch self {
        case .free:
            return 50
        case .premium, .pro:
            return nil // Unlimited
        }
    }

    var dailyProfileViewLimit: Int? {
        switch self {
        case .free:
            return 10
        case .premium, .pro:
            return nil // Unlimited
        }
    }

    var allowsDirectMessaging: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro:
            return true
        }
    }

    var allowsUnlimitedMatches: Bool {
        return true // All tiers allow unlimited matches
    }

    // MARK: - TTS Properties

    /// Monthly TTS play limit (nil = unlimited)
    var monthlyTTSLimit: Int? {
        switch self {
        case .free:
            return 10
        case .premium:
            return 200
        case .pro:
            return nil // Unlimited
        }
    }

    /// Maximum words per TTS play
    var maxWordsPerTTSPlay: Int {
        switch self {
        case .free, .premium:
            return 100
        case .pro:
            return 150
        }
    }

    /// Voice quality for this tier
    var ttsVoiceQuality: TTSVoiceQuality {
        switch self {
        case .free:
            return .appleNative
        case .premium, .pro:
            return .googleNeural2
        }
    }

    /// Whether this tier uses premium (Google) TTS
    var hasPremiumTTS: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro:
            return true
        }
    }

    /// TTS limit display text for UI
    var ttsLimitDisplayText: String {
        switch self {
        case .free:
            return "10 plays/month"
        case .premium:
            return "200 plays/month"
        case .pro:
            return "Unlimited"
        }
    }

    /// Voice quality display text for UI
    var ttsVoiceDisplayText: String {
        switch self {
        case .free:
            return "Standard voice"
        case .premium, .pro:
            return "Natural voices (Google Neural2)"
        }
    }
}

// MARK: - Subscription Status
struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let expiresAt: Date?
    let isTrialing: Bool  // For Premium subscription trial
    let trialStartDate: Date?  // For Premium subscription trial
    let trialEndDate: Date?  // For Premium subscription trial

    // Free tier app trial (7 days to try the app before requiring subscription)
    var freeTrialStartDate: Date?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    /// Days remaining in Premium subscription trial
    var daysRemainingInTrial: Int? {
        guard isTrialing, let trialEndDate = trialEndDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: trialEndDate).day
        return max(0, days ?? 0)
    }

    // MARK: - Free Tier App Trial (7-day limited access)

    /// End date for free tier app trial (7 days after start)
    var freeTrialEndDate: Date? {
        guard let start = freeTrialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 7, to: start)
    }

    /// Whether the free tier app trial has expired
    var isFreeTrialExpired: Bool {
        guard tier == .free, let endDate = freeTrialEndDate else { return false }
        return Date() > endDate
    }

    /// Days remaining in free tier app trial
    var daysRemainingInFreeTrial: Int {
        guard let endDate = freeTrialEndDate else { return 7 }  // Default to 7 if not started
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }

    static var free: SubscriptionStatus {
        return SubscriptionStatus(
            tier: .free,
            isActive: true,
            expiresAt: nil,
            isTrialing: false,
            trialStartDate: nil,
            trialEndDate: nil,
            freeTrialStartDate: nil
        )
    }

    /// Create a free status with trial started
    static func freeWithTrial(startDate: Date) -> SubscriptionStatus {
        return SubscriptionStatus(
            tier: .free,
            isActive: true,
            expiresAt: nil,
            isTrialing: false,
            trialStartDate: nil,
            trialEndDate: nil,
            freeTrialStartDate: startDate
        )
    }
}
