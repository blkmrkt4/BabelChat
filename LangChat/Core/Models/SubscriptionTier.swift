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
    case broadcaster = "broadcaster"

    var displayName: String {
        switch self {
        case .free:
            return "tier_free_display_name".localized
        case .premium:
            return "tier_premium_display_name".localized
        case .pro:
            return "tier_pro_display_name".localized
        case .broadcaster:
            return "tier_broadcaster_display_name".localized
        }
    }

    var price: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "$9.99/month"
        case .pro:
            return "$19.99/month"
        case .broadcaster:
            return "$49.99/month"
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
        case .broadcaster:
            return [
                "tier_broadcaster_feature_1".localized,
                "tier_broadcaster_feature_2".localized,
                "tier_broadcaster_feature_3".localized,
                "tier_broadcaster_feature_4".localized
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
        case .broadcaster:
            return "tier_broadcaster_short_desc".localized
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
        case .broadcaster:
            return "broadcaster_monthly" // Must match RevenueCat dashboard
        }
    }

    // MARK: - Message Limits

    var monthlyMessageLimit: Int? {
        switch self {
        case .free, .premium, .pro, .broadcaster:
            return nil // No monthly cap; free tier is gated by daily limits only
        }
    }

    var dailyProfileViewLimit: Int? {
        switch self {
        case .free:
            return 10
        case .premium, .pro, .broadcaster:
            return nil // Unlimited
        }
    }

    var allowsDirectMessaging: Bool {
        return true // All tiers allow messaging with daily limits
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
        case .pro, .broadcaster:
            return nil // Unlimited
        }
    }

    /// Maximum words per TTS play
    var maxWordsPerTTSPlay: Int {
        switch self {
        case .free, .premium:
            return 100
        case .pro, .broadcaster:
            return 150
        }
    }

    /// Voice quality for this tier
    var ttsVoiceQuality: TTSVoiceQuality {
        switch self {
        case .free:
            return .appleNative
        case .premium, .pro, .broadcaster:
            return .googleNeural2
        }
    }

    /// Whether this tier uses premium (Google) TTS
    var hasPremiumTTS: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro, .broadcaster:
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
        case .pro, .broadcaster:
            return "Unlimited"
        }
    }

    /// Voice quality display text for UI
    var ttsVoiceDisplayText: String {
        switch self {
        case .free:
            return "Standard voice"
        case .premium, .pro, .broadcaster:
            return "Natural voices (Google Neural2)"
        }
    }

    // MARK: - Session Properties

    var canHostSession: Bool {
        switch self {
        case .free, .premium:
            return false
        case .pro, .broadcaster:
            return true
        }
    }

    var canSpeakInSession: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro, .broadcaster:
            return true
        }
    }

    /// Whether this tier can view video in sessions (vs audio-only)
    var canViewSessionVideo: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro, .broadcaster:
            return true
        }
    }

    /// Monthly session hosting limit (nil = cannot host)
    var monthlySessionHostLimit: Int? {
        switch self {
        case .free, .premium:
            return nil
        case .pro:
            return 5
        case .broadcaster:
            return 15
        }
    }

    /// Max video participant slots when hosting (speakers with video)
    var maxVideoSlots: Int {
        switch self {
        case .free, .premium:
            return 0
        case .pro:
            return 2
        case .broadcaster:
            return 4
        }
    }

    /// Max session duration in minutes
    var maxSessionDuration: Int {
        switch self {
        case .free, .premium:
            return 15
        case .pro, .broadcaster:
            return 15
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
