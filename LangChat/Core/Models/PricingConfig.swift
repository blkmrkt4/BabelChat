//
//  PricingConfig.swift
//  LangChat
//
//  Created by Claude Code on 2025-12-13.
//

import Foundation

// MARK: - Pricing Feature
struct PricingFeature: Codable {
    let title: String
    let subtitle: String
    let included: Bool
}

// MARK: - Pricing Config (from Supabase)
struct PricingConfig: Codable {
    let premiumPriceUsd: Double
    let premiumBanner: String
    let premiumFeatures: [PricingFeature]
    let proPriceUsd: Double
    let proBanner: String
    let proFeatures: [PricingFeature]
    let freeFeatures: [PricingFeature]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case premiumPriceUsd = "premium_price_usd"
        case premiumBanner = "premium_banner"
        case premiumFeatures = "premium_features"
        case proPriceUsd = "pro_price_usd"
        case proBanner = "pro_banner"
        case proFeatures = "pro_features"
        case freeFeatures = "free_features"
        case updatedAt = "updated_at"
    }

    // MARK: - Default fallback config (matches SubscriptionTier.swift)
    static var defaultConfig: PricingConfig {
        return PricingConfig(
            premiumPriceUsd: 9.99,
            premiumBanner: "7-Day Free Trial • Cancel Anytime",
            premiumFeatures: [
                PricingFeature(title: "Match with real people worldwide", subtitle: "", included: true),
                PricingFeature(title: "Unlimited messages", subtitle: "", included: true),
                PricingFeature(title: "Full translation & grammar insights", subtitle: "", included: true),
                PricingFeature(title: "200 Text-to-Speech plays/month with natural voices", subtitle: "", included: true)
            ],
            proPriceUsd: 19.99,
            proBanner: "Best Value for Serious Learners",
            proFeatures: [
                PricingFeature(title: "Everything in Premium", subtitle: "", included: true),
                PricingFeature(title: "Unlimited Text-to-Speech plays", subtitle: "", included: true),
                PricingFeature(title: "Natural voices (Google Neural2)", subtitle: "", included: true),
                PricingFeature(title: "Higher word limit per play - 150 vs 100 for Premium", subtitle: "", included: true)
            ],
            freeFeatures: [
                PricingFeature(title: "No matching with real people - AI Muse chats only", subtitle: "", included: true),
                PricingFeature(title: "50 messages per month", subtitle: "", included: true),
                PricingFeature(title: "Full translation & grammar insights", subtitle: "", included: true),
                PricingFeature(title: "Basic text to speech", subtitle: "", included: true)
            ],
            updatedAt: nil
        )
    }

    // MARK: - Helper computed properties
    var premiumPriceFormatted: String {
        return String(format: "$%.2f/mo", premiumPriceUsd)
    }

    var proPriceFormatted: String {
        return String(format: "$%.2f/mo", proPriceUsd)
    }

    var freeFeaturesText: [String] {
        return freeFeatures.map { $0.title }
    }

    var premiumFeaturesText: [String] {
        return premiumFeatures.map { $0.title }
    }

    var proFeaturesText: [String] {
        return proFeatures.map { $0.title }
    }
}

// MARK: - Pricing Config Manager (caches config)
class PricingConfigManager {
    static let shared = PricingConfigManager()

    private var cachedConfig: PricingConfig?
    private var lastFetchTime: Date?
    private let cacheValiditySeconds: TimeInterval = 300 // 5 minutes

    private init() {}

    /// Get pricing config (cached or fetch fresh)
    func getConfig() async -> PricingConfig {
        // Return cached if still valid
        if let cached = cachedConfig,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValiditySeconds {
            return cached
        }

        // Fetch fresh config
        do {
            let config = try await SupabaseService.shared.fetchPricingConfig()
            cachedConfig = config
            lastFetchTime = Date()
            return config
        } catch {
            print("Failed to fetch pricing config: \(error)")
            // Return cached if available, otherwise default
            return cachedConfig ?? PricingConfig.defaultConfig
        }
    }

    /// Force refresh the config
    func refreshConfig() async -> PricingConfig {
        cachedConfig = nil
        lastFetchTime = nil
        return await getConfig()
    }

    /// Clear cache (e.g., on logout)
    func clearCache() {
        cachedConfig = nil
        lastFetchTime = nil
    }
}
