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
            return "Free"
        case .premium:
            return "Premium"
        case .pro:
            return "Pro"
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
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "No matching with real people - AI Muse chats only",
                "50 messages per month",
                "Full translation & grammar insights",
                "Basic text to speech"
            ]
        case .premium:
            return [
                "Match with real people worldwide",
                "Unlimited messages",
                "Full translation & grammar insights",
                "200 Text-to-Speech plays/month with natural voices"
            ]
        case .pro:
            return [
                "Everything in Premium",
                "Unlimited Text-to-Speech plays",
                "Natural voices (Google Neural2)",
                "Higher word limit per play - 150 vs 100 for Premium"
            ]
        }
    }

    var shortDescription: String {
        switch self {
        case .free:
            return "Practice with AI Muse"
        case .premium:
            return "Match with real people + natural voices"
        case .pro:
            return "Unlimited learning, zero limits"
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
