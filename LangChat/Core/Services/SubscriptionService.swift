//
//  SubscriptionService.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation
import RevenueCat

class SubscriptionService: NSObject {
    static let shared = SubscriptionService()

    // MARK: - Properties
    /// Set to true during development when RevenueCat is not yet configured
    /// This allows the app to work without requiring RevenueCat dashboard setup
    /// ⚠️ WARNING: Must be set to FALSE before production release
    #if DEBUG
    var isDevelopmentMode: Bool = true // Development mode enabled for testing - RevenueCat disabled
    #else
    var isDevelopmentMode: Bool = false // Production mode - uses real RevenueCat
    #endif

    private let userDefaultsKey = "user_subscription_status"
    private(set) var currentStatus: SubscriptionStatus {
        didSet {
            saveStatus()
            NotificationCenter.default.post(name: .subscriptionStatusChanged, object: currentStatus)
        }
    }

    // MARK: - Cached Offerings for Localized Pricing
    private(set) var cachedOfferings: [SubscriptionOffering] = []
    private(set) var isLoadingOfferings: Bool = false
    private var cachedPricingConfig: PricingConfig?

    /// Check if current locale should show weekly pricing (uses remote config)
    var shouldShowWeeklyPricing: Bool {
        guard let regionCode = Locale.current.region?.identifier else { return false }
        let config = cachedPricingConfig ?? PricingConfig.defaultConfig
        return config.shouldShowWeeklyPricing(for: regionCode)
    }

    /// Update the cached pricing config (called when config is fetched)
    func updatePricingConfig(_ config: PricingConfig) {
        cachedPricingConfig = config
    }

    // MARK: - Initialization
    private override init() {
        // Load saved status or default to free
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) {
            self.currentStatus = status
        } else {
            self.currentStatus = .free
        }

        super.init()
    }

    // MARK: - RevenueCat Configuration
    /// Call this from AppDelegate to configure RevenueCat
    /// - Parameter apiKey: Your RevenueCat public API key
    func configure(apiKey: String) {
        if isDevelopmentMode {
            print("⚠️ Development Mode: RevenueCat disabled, using mock subscriptions")
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        checkSubscriptionStatus()
        print("✅ RevenueCat configured successfully")
    }

    // MARK: - Fetch Offerings
    /// Fetch available subscription offerings from RevenueCat
    func fetchOfferings(completion: @escaping (Result<[SubscriptionOffering], Error>) -> Void) {
        // In development mode, return mock offerings with default prices
        if isDevelopmentMode {
            print("⚠️ Development Mode: Using mock offerings")
            let mockOfferings = [
                SubscriptionOffering(
                    tier: .premium,
                    package: nil,
                    localizedPrice: "$9.99",
                    localizedPricePerPeriod: "$9.99/mo",
                    priceValue: 9.99,
                    currencyCode: "USD",
                    trialDays: 7
                ),
                SubscriptionOffering(
                    tier: .pro,
                    package: nil,
                    localizedPrice: "$19.99",
                    localizedPricePerPeriod: "$19.99/mo",
                    priceValue: 19.99,
                    currencyCode: "USD",
                    trialDays: 0
                )
            ]
            self.cachedOfferings = mockOfferings
            completion(.success(mockOfferings))
            return
        }

        isLoadingOfferings = true

        Purchases.shared.getOfferings { [weak self] offerings, error in
            self?.isLoadingOfferings = false

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let offerings = offerings, let current = offerings.current else {
                completion(.success([]))
                return
            }

            // Convert RevenueCat packages to our model with full pricing info
            let subscriptionOfferings = current.availablePackages.compactMap { package -> SubscriptionOffering? in
                // Match by product identifier instead of package identifier
                let productId = package.storeProduct.productIdentifier
                let tier: SubscriptionTier
                if productId == "premium_monthly" {
                    tier = .premium
                } else if productId == "pro_monthly" {
                    tier = .pro
                } else {
                    return nil
                }

                let product = package.storeProduct
                return SubscriptionOffering(
                    tier: tier,
                    package: package,
                    localizedPrice: product.localizedPriceString,
                    localizedPricePerPeriod: "\(product.localizedPriceString)/mo",
                    priceValue: NSDecimalNumber(decimal: product.price).doubleValue,
                    currencyCode: product.currencyCode ?? "USD",
                    trialDays: product.introductoryDiscount?.subscriptionPeriod.value ?? 0
                )
            }

            self?.cachedOfferings = subscriptionOfferings
            NotificationCenter.default.post(name: .offeringsLoaded, object: subscriptionOfferings)
            completion(.success(subscriptionOfferings))
        }
    }

    // MARK: - Localized Price Helpers

    /// Get the localized price for a subscription tier
    func localizedPrice(for tier: SubscriptionTier) -> String? {
        return cachedOfferings.first(where: { $0.tier == tier })?.localizedPrice
    }

    /// Get the localized price with period (e.g., "$9.99/mo" or "$2.50/wk")
    func localizedPricePerPeriod(for tier: SubscriptionTier) -> String {
        guard let offering = cachedOfferings.first(where: { $0.tier == tier }) else {
            return tier.price // Fallback to hardcoded
        }

        if shouldShowWeeklyPricing {
            return offering.weeklyPriceString
        } else {
            return offering.localizedPricePerPeriod
        }
    }

    /// Get trial info text for a tier
    func trialInfoText(for tier: SubscriptionTier) -> String? {
        guard let offering = cachedOfferings.first(where: { $0.tier == tier }),
              offering.trialDays > 0 else {
            return nil
        }
        return "\(offering.trialDays)-day free trial"
    }

    /// Check if offerings have been loaded
    var hasLoadedOfferings: Bool {
        return !cachedOfferings.isEmpty
    }

    // MARK: - Purchase
    /// Purchase a subscription tier
    func purchase(tier: SubscriptionTier, completion: @escaping (Result<SubscriptionStatus, Error>) -> Void) {
        // In development mode, simulate a successful premium purchase
        if isDevelopmentMode {
            print("⚠️ Development Mode: Simulating premium purchase")
            let status = SubscriptionStatus(
                tier: .premium,
                isActive: true,
                expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
                isTrialing: true,
                trialStartDate: Date(),
                trialEndDate: Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 day trial
            )
            self.currentStatus = status
            completion(.success(status))
            return
        }

        guard let productId = tier.productIdentifier else {
            completion(.failure(SubscriptionError.noProductForFreeTier))
            return
        }

        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let package = offerings?.current?.availablePackages.first(where: { $0.identifier == productId }) else {
                completion(.failure(SubscriptionError.productNotFound))
                return
            }

            Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                if userCancelled {
                    completion(.failure(SubscriptionError.userCancelled))
                    return
                }

                if let error = error {
                    completion(.failure(error))
                    return
                }

                // Update subscription status
                self?.updateStatus(from: customerInfo)
                completion(.success(self?.currentStatus ?? .free))
            }
        }
    }

    // MARK: - Restore Purchases
    /// Restore previous purchases
    func restorePurchases(completion: @escaping (Result<SubscriptionStatus, Error>) -> Void) {
        if isDevelopmentMode {
            print("⚠️ Development Mode: Restore not available")
            completion(.success(currentStatus))
            return
        }

        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self?.updateStatus(from: customerInfo)
            completion(.success(self?.currentStatus ?? .free))
        }
    }

    // MARK: - Check Status
    /// Check current subscription status from RevenueCat
    func checkSubscriptionStatus() {
        if isDevelopmentMode {
            print("⚠️ Development Mode: Using local subscription status")
            return
        }

        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let error = error {
                print("❌ Failed to get customer info: \(error.localizedDescription)")
                return
            }

            self?.updateStatus(from: customerInfo)
        }
    }

    // MARK: - Private Helpers
    private func updateStatus(from customerInfo: CustomerInfo?) {
        guard let customerInfo = customerInfo else { return }

        // Check if user has active premium subscription
        if let entitlement = customerInfo.entitlements["premium"],
           entitlement.isActive {
            let status = SubscriptionStatus(
                tier: .premium,
                isActive: true,
                expiresAt: entitlement.expirationDate,
                isTrialing: entitlement.periodType == .trial,
                trialStartDate: entitlement.originalPurchaseDate,
                trialEndDate: entitlement.periodType == .trial ? entitlement.expirationDate : nil
            )
            self.currentStatus = status
        } else {
            self.currentStatus = .free
        }
    }

    private func saveStatus() {
        if let encoded = try? JSONEncoder().encode(currentStatus) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    // MARK: - Convenience Methods
    var isFreeTier: Bool {
        return currentStatus.tier == .free
    }

    var isPremium: Bool {
        return currentStatus.tier == .premium && currentStatus.isActive
    }

    var isTrialing: Bool {
        return currentStatus.isTrialing
    }
}

// MARK: - Subscription Offering Model
struct SubscriptionOffering {
    let tier: SubscriptionTier
    let package: Package?
    let localizedPrice: String          // e.g., "$9.99" or "₹799"
    let localizedPricePerPeriod: String // e.g., "$9.99/mo" or "₹799/mo"
    let priceValue: Double              // Numeric value for calculations
    let currencyCode: String            // e.g., "USD", "INR"
    let trialDays: Int

    /// Calculate weekly equivalent price (monthly / 4.33)
    var weeklyPriceValue: Double {
        return priceValue / 4.33
    }

    /// Formatted weekly price string
    var weeklyPriceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2

        if let formatted = formatter.string(from: NSNumber(value: weeklyPriceValue)) {
            return "\(formatted)/wk"
        }
        return localizedPricePerPeriod
    }

    // Legacy compatibility
    var price: String { localizedPrice }
}

// MARK: - Errors
enum SubscriptionError: LocalizedError {
    case noProductForFreeTier
    case productNotFound
    case userCancelled
    case revenueCatNotConfigured

    var errorDescription: String? {
        switch self {
        case .noProductForFreeTier:
            return "Free tier does not require a purchase"
        case .productNotFound:
            return "Subscription product not found"
        case .userCancelled:
            return "Purchase cancelled by user"
        case .revenueCatNotConfigured:
            return "RevenueCat SDK not configured"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let offeringsLoaded = Notification.Name("offeringsLoaded")
}

// MARK: - RevenueCat Delegate
extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateStatus(from: customerInfo)
    }
}
