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
    let broadcasterPriceUsd: Double
    let broadcasterBanner: String
    let broadcasterFeatures: [PricingFeature]
    let freeFeatures: [PricingFeature]
    let weeklyPricingCountries: [String]  // Country codes that show weekly pricing (e.g., ["IN", "BR", "MX"])
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case premiumPriceUsd = "premium_price_usd"
        case premiumBanner = "premium_banner"
        case premiumFeatures = "premium_features"
        case proPriceUsd = "pro_price_usd"
        case proBanner = "pro_banner"
        case proFeatures = "pro_features"
        case broadcasterPriceUsd = "broadcaster_price_usd"
        case broadcasterBanner = "broadcaster_banner"
        case broadcasterFeatures = "broadcaster_features"
        case freeFeatures = "free_features"
        case weeklyPricingCountries = "weekly_pricing_countries"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        premiumPriceUsd = try container.decode(Double.self, forKey: .premiumPriceUsd)
        premiumBanner = try container.decode(String.self, forKey: .premiumBanner)
        premiumFeatures = try container.decode([PricingFeature].self, forKey: .premiumFeatures)
        proPriceUsd = try container.decode(Double.self, forKey: .proPriceUsd)
        proBanner = try container.decode(String.self, forKey: .proBanner)
        proFeatures = try container.decode([PricingFeature].self, forKey: .proFeatures)
        broadcasterPriceUsd = try container.decodeIfPresent(Double.self, forKey: .broadcasterPriceUsd) ?? 49.99
        broadcasterBanner = try container.decodeIfPresent(String.self, forKey: .broadcasterBanner) ?? "For Power Hosts"
        broadcasterFeatures = try container.decodeIfPresent([PricingFeature].self, forKey: .broadcasterFeatures) ?? PricingConfig.defaultBroadcasterFeatures
        freeFeatures = try container.decode([PricingFeature].self, forKey: .freeFeatures)
        weeklyPricingCountries = try container.decode([String].self, forKey: .weeklyPricingCountries)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    init(premiumPriceUsd: Double, premiumBanner: String, premiumFeatures: [PricingFeature],
         proPriceUsd: Double, proBanner: String, proFeatures: [PricingFeature],
         broadcasterPriceUsd: Double, broadcasterBanner: String, broadcasterFeatures: [PricingFeature],
         freeFeatures: [PricingFeature], weeklyPricingCountries: [String], updatedAt: String?) {
        self.premiumPriceUsd = premiumPriceUsd
        self.premiumBanner = premiumBanner
        self.premiumFeatures = premiumFeatures
        self.proPriceUsd = proPriceUsd
        self.proBanner = proBanner
        self.proFeatures = proFeatures
        self.broadcasterPriceUsd = broadcasterPriceUsd
        self.broadcasterBanner = broadcasterBanner
        self.broadcasterFeatures = broadcasterFeatures
        self.freeFeatures = freeFeatures
        self.weeklyPricingCountries = weeklyPricingCountries
        self.updatedAt = updatedAt
    }

    static let defaultBroadcasterFeatures: [PricingFeature] = [
        PricingFeature(title: "Everything in Pro", subtitle: "", included: true),
        PricingFeature(title: "15 hosted sessions/month", subtitle: "", included: true),
        PricingFeature(title: "4 video speaker slots/session", subtitle: "", included: true),
        PricingFeature(title: "Priority matching & support", subtitle: "", included: true)
    ]

    // MARK: - Default fallback config (matches SubscriptionTier.swift)
    static var defaultConfig: PricingConfig {
        return PricingConfig(
            premiumPriceUsd: 9.99,
            premiumBanner: "7-Day Free Trial • Cancel Anytime",
            premiumFeatures: [
                PricingFeature(title: "Match with real people worldwide", subtitle: "", included: true),
                PricingFeature(title: "Unlimited messages*", subtitle: "", included: true),
                PricingFeature(title: "Full translation & grammar insights", subtitle: "", included: true),
                PricingFeature(title: "200 Text-to-Speech plays/month with natural voices", subtitle: "", included: true),
                PricingFeature(title: "Watch sessions with audio + video", subtitle: "", included: true),
                PricingFeature(title: "Up to 5 video viewer slots/session", subtitle: "", included: true)
            ],
            proPriceUsd: 19.99,
            proBanner: "Best Value for Serious Learners",
            proFeatures: [
                PricingFeature(title: "Everything in Premium", subtitle: "", included: true),
                PricingFeature(title: "5 hosted sessions/month", subtitle: "", included: true),
                PricingFeature(title: "2 video speaker slots/session", subtitle: "", included: true),
                PricingFeature(title: "Unlimited Text-to-Speech plays*", subtitle: "", included: true),
                PricingFeature(title: "Priority matching", subtitle: "", included: true)
            ],
            broadcasterPriceUsd: 49.99,
            broadcasterBanner: "For Power Hosts",
            broadcasterFeatures: defaultBroadcasterFeatures,
            freeFeatures: [
                PricingFeature(title: "7 days to explore all features", subtitle: "", included: true),
                PricingFeature(title: "10 messages/day", subtitle: "", included: true),
                PricingFeature(title: "AI Muse conversations (5/day)", subtitle: "", included: true),
                PricingFeature(title: "Full translation & grammar insights", subtitle: "", included: true),
                PricingFeature(title: "Listen to sessions (audio only)", subtitle: "", included: true)
            ],
            weeklyPricingCountries: ["IN", "BR", "MX", "ID", "PH", "VN", "TH", "MY"],  // Default emerging markets
            updatedAt: nil
        )
    }

    /// Check if a country should show weekly pricing
    func shouldShowWeeklyPricing(for countryCode: String) -> Bool {
        return weeklyPricingCountries.contains(countryCode.uppercased())
    }

    // MARK: - Helper computed properties
    var premiumPriceFormatted: String {
        return String(format: "$%.2f/mo", premiumPriceUsd)
    }

    var proPriceFormatted: String {
        return String(format: "$%.2f/mo", proPriceUsd)
    }

    var broadcasterPriceFormatted: String {
        return String(format: "$%.2f/mo", broadcasterPriceUsd)
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

    var broadcasterFeaturesText: [String] {
        return broadcasterFeatures.map { $0.title }
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
