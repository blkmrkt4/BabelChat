//
//  SubscriptionService.swift
//  LangChat
//
//  Created by Claude Code on 2025-11-03.
//

import Foundation
import UIKit
import RevenueCat

class SubscriptionService: NSObject {
    static let shared = SubscriptionService()

    // MARK: - Properties
    /// Set to true during development when RevenueCat is not yet configured
    /// This allows the app to work without requiring RevenueCat dashboard setup
    /// ⚠️ Set to FALSE to test real App Store pricing from RevenueCat
    var isDevelopmentMode: Bool = false // Uses real RevenueCat for actual App Store prices

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

    /// Indicates whether RevenueCat has been properly configured
    /// If false, purchases will fail with a configuration error
    private(set) var isConfigured: Bool = false

    /// Check if current locale should show weekly pricing (uses remote config)
    var shouldShowWeeklyPricing: Bool {
        guard let regionCode = Locale.current.region?.identifier else { return false }
        let config = cachedPricingConfig ?? PricingConfig.defaultConfig
        return config.shouldShowWeeklyPricing(for: regionCode)
    }

    /// Returns the currency code from cached offerings (e.g., "USD", "EUR", "INR")
    var currentCurrencyCode: String {
        cachedOfferings.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
    }

    /// Maps currency codes to their primary country names
    /// Used to show accurate country based on App Store pricing region
    private func countryName(forCurrencyCode currencyCode: String) -> String? {
        let currencyToCountry: [String: String] = [
            "GBP": "United Kingdom",
            "USD": "United States",
            "EUR": "Eurozone",
            "CAD": "Canada",
            "AUD": "Australia",
            "INR": "India",
            "JPY": "Japan",
            "CNY": "China",
            "KRW": "South Korea",
            "BRL": "Brazil",
            "MXN": "Mexico",
            "SGD": "Singapore",
            "HKD": "Hong Kong",
            "NZD": "New Zealand",
            "CHF": "Switzerland",
            "SEK": "Sweden",
            "NOK": "Norway",
            "DKK": "Denmark",
            "PLN": "Poland",
            "THB": "Thailand",
            "MYR": "Malaysia",
            "PHP": "Philippines",
            "IDR": "Indonesia",
            "VND": "Vietnam",
            "ZAR": "South Africa",
            "AED": "United Arab Emirates",
            "SAR": "Saudi Arabia",
            "ILS": "Israel",
            "TRY": "Turkey",
            "RUB": "Russia",
            "TWD": "Taiwan",
            "CLP": "Chile",
            "COP": "Colombia",
            "PEN": "Peru",
            "ARS": "Argentina"
        ]
        return currencyToCountry[currencyCode.uppercased()]
    }

    /// Returns a user-friendly string describing the pricing region
    /// e.g., "Prices in USD" or "Prices for United Kingdom (GBP)"
    var pricingRegionDescription: String {
        let currencyCode = currentCurrencyCode

        // Derive country name from currency code (from App Store/RevenueCat)
        if let countryName = countryName(forCurrencyCode: currencyCode) {
            return "Prices for \(countryName) (\(currencyCode))"
        }

        return "Prices in \(currencyCode)"
    }

    /// Returns just the country name for shorter displays
    var currentCountryName: String {
        let currencyCode = currentCurrencyCode
        return countryName(forCurrencyCode: currencyCode) ?? currencyCode
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

        print("🔧 [RevenueCat] Configuring with API key: \(apiKey.prefix(10))...")
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        isConfigured = true

        // Log device and environment info
        print("📱 [RevenueCat] Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        print("🌍 [RevenueCat] Locale: \(Locale.current.identifier), Currency: \(Locale.current.currency?.identifier ?? "unknown")")

        checkSubscriptionStatus()

        // Prefetch offerings on configuration
        fetchOfferings { result in
            switch result {
            case .success(let offerings):
                print("✅ [RevenueCat] Prefetched \(offerings.count) offerings")
            case .failure(let error):
                print("⚠️ [RevenueCat] Prefetch offerings failed: \(error.localizedDescription)")
            }
        }

        print("✅ [RevenueCat] Configuration complete")
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

        // Check if RevenueCat is configured
        if !isConfigured {
            print("❌ [RevenueCat] Not configured - cannot fetch offerings")
            completion(.failure(SubscriptionError.revenueCatNotConfigured))
            return
        }

        isLoadingOfferings = true
        print("📦 [RevenueCat] Fetching offerings...")

        Purchases.shared.getOfferings { [weak self] offerings, error in
            self?.isLoadingOfferings = false

            if let error = error {
                // Convert to user-friendly error
                let userFriendlyError = SubscriptionError.from(error)
                print("❌ [RevenueCat] Offerings fetch FAILED")
                print("   Raw error: \(error)")
                print("   Error code: \((error as NSError).code)")
                print("   Error domain: \((error as NSError).domain)")
                print("   User info: \((error as NSError).userInfo)")

                // Log to crash reporting
                CrashReportingService.shared.captureError(error, context: [
                    "stage": "fetch_offerings",
                    "error_code": "\((error as NSError).code)",
                    "error_domain": (error as NSError).domain
                ])

                completion(.failure(userFriendlyError))
                return
            }

            print("📦 [RevenueCat] Offerings response received")

            guard let offerings = offerings else {
                print("⚠️ [RevenueCat] Offerings object is nil")
                completion(.failure(SubscriptionError.productNotFound))
                return
            }

            print("📦 [RevenueCat] All offering identifiers: \(offerings.all.keys.joined(separator: ", "))")

            guard let current = offerings.current else {
                print("⚠️ [RevenueCat] No current offering set!")
                print("   This usually means:")
                print("   1. No 'current' offering is set in RevenueCat dashboard")
                print("   2. Products are not created in App Store Connect")
                print("   3. Products are not linked to RevenueCat")
                completion(.failure(SubscriptionError.productNotFound))
                return
            }

            print("📦 [RevenueCat] Current offering: \(current.identifier)")
            print("📦 [RevenueCat] Available packages: \(current.availablePackages.count)")

            // Log all available packages for debugging
            for (index, package) in current.availablePackages.enumerated() {
                let product = package.storeProduct
                print("   Package \(index + 1):")
                print("     - Package ID: \(package.identifier)")
                print("     - Product ID: \(product.productIdentifier)")
                print("     - Price: \(product.localizedPriceString)")
                print("     - Currency: \(product.currencyCode ?? "unknown")")
                print("     - Subscription period: \(product.subscriptionPeriod?.unit.rawValue ?? -1)")
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
                    print("⚠️ [RevenueCat] Unknown product ID '\(productId)' - skipping")
                    return nil
                }

                let product = package.storeProduct
                print("✅ [RevenueCat] Mapped '\(productId)' -> \(tier.displayName)")

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

            if subscriptionOfferings.isEmpty {
                print("⚠️ [RevenueCat] No matching offerings found!")
                print("   Expected product IDs: 'premium_monthly', 'pro_monthly'")
                print("   Make sure these products exist in App Store Connect")
            } else {
                print("✅ [RevenueCat] Successfully mapped \(subscriptionOfferings.count) offerings")
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
        print("💳 [Purchase] Starting purchase for tier: \(tier.displayName)")

        // Check if RevenueCat is configured (unless in development mode)
        if !isDevelopmentMode && !isConfigured {
            print("❌ [Purchase] RevenueCat is not configured!")
            print("   Make sure REVENUECAT_API_KEY is set in Secrets.xcconfig")
            completion(.failure(SubscriptionError.revenueCatNotConfigured))
            return
        }

        // In development mode, simulate a successful premium purchase
        if isDevelopmentMode {
            print("⚠️ [Purchase] Development Mode: Simulating premium purchase")
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
            print("❌ [Purchase] No product identifier for tier: \(tier.displayName)")
            completion(.failure(SubscriptionError.noProductForFreeTier))
            return
        }

        print("💳 [Purchase] Looking for product ID: \(productId)")

        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                print("❌ [Purchase] Failed to get offerings: \(error)")
                print("   Error code: \((error as NSError).code)")
                print("   Error domain: \((error as NSError).domain)")

                CrashReportingService.shared.captureError(error, context: [
                    "stage": "purchase_get_offerings",
                    "tier": tier.displayName,
                    "product_id": productId
                ])

                completion(.failure(SubscriptionError.from(error)))
                return
            }

            // Log offerings state
            if let current = offerings?.current {
                print("📦 [Purchase] Current offering: \(current.identifier)")
                print("📦 [Purchase] Available packages: \(current.availablePackages.map { $0.storeProduct.productIdentifier })")
            } else {
                print("⚠️ [Purchase] No current offering available!")
                print("   This is likely because:")
                print("   1. In-App Purchases not created in App Store Connect")
                print("   2. Products not synced to RevenueCat")
                print("   3. No 'current' offering set in RevenueCat dashboard")

                CrashReportingService.shared.captureMessage("No current offering available for purchase - tier: \(tier.displayName), product_id: \(productId)")

                completion(.failure(SubscriptionError.productNotFound))
                return
            }

            guard let package = offerings?.current?.availablePackages.first(where: { $0.storeProduct.productIdentifier == productId }) else {
                print("❌ [Purchase] Product '\(productId)' not found in available packages!")
                print("   Available product IDs: \(offerings?.current?.availablePackages.map { $0.storeProduct.productIdentifier } ?? [])")
                print("   This means the product ID '\(productId)' doesn't exist in App Store Connect")
                print("   or is not linked to the current RevenueCat offering")

                CrashReportingService.shared.captureMessage("Product not found in offerings - requested: \(productId)")

                completion(.failure(SubscriptionError.productNotFound))
                return
            }

            print("✅ [Purchase] Found package for '\(productId)'")
            print("   Price: \(package.storeProduct.localizedPriceString)")
            print("   Currency: \(package.storeProduct.currencyCode ?? "unknown")")
            print("💳 [Purchase] Initiating App Store purchase...")

            Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                if userCancelled {
                    print("ℹ️ [Purchase] User cancelled the purchase")
                    completion(.failure(SubscriptionError.userCancelled))
                    return
                }

                if let error = error {
                    // Convert to user-friendly error
                    let userFriendlyError = SubscriptionError.from(error)
                    print("❌ [Purchase] Purchase FAILED!")
                    print("   Raw error: \(error)")
                    print("   Error code: \((error as NSError).code)")
                    print("   Error domain: \((error as NSError).domain)")
                    print("   User info: \((error as NSError).userInfo)")
                    print("   Friendly message: \(userFriendlyError.localizedDescription ?? "Unknown")")

                    CrashReportingService.shared.captureError(error, context: [
                        "stage": "purchase_transaction",
                        "tier": tier.displayName,
                        "product_id": productId,
                        "error_code": "\((error as NSError).code)",
                        "error_domain": (error as NSError).domain
                    ])

                    completion(.failure(userFriendlyError))
                    return
                }

                print("✅ [Purchase] Purchase successful!")

                // Log transaction details if available
                if let transaction = transaction {
                    print("   Transaction ID: \(transaction.transactionIdentifier ?? "unknown")")
                }

                // Log customer info
                if let customerInfo = customerInfo {
                    print("   Active entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
                    print("   All purchased products: \(customerInfo.allPurchasedProductIdentifiers.joined(separator: ", "))")
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
        print("🔄 [Restore] Starting restore purchases...")

        if isDevelopmentMode {
            print("⚠️ [Restore] Development Mode: Restore not available")
            completion(.success(currentStatus))
            return
        }

        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error = error {
                // Convert to user-friendly error
                let userFriendlyError = SubscriptionError.from(error)
                print("❌ [Restore] Restore FAILED!")
                print("   Raw error: \(error)")
                print("   Error code: \((error as NSError).code)")

                CrashReportingService.shared.captureError(error, context: [
                    "stage": "restore_purchases",
                    "error_code": "\((error as NSError).code)"
                ])

                completion(.failure(userFriendlyError))
                return
            }

            print("✅ [Restore] Restore completed")
            if let customerInfo = customerInfo {
                print("   Active entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
                print("   All purchases: \(customerInfo.allPurchasedProductIdentifiers.joined(separator: ", "))")
            }

            self?.updateStatus(from: customerInfo)
            completion(.success(self?.currentStatus ?? .free))
        }
    }

    // MARK: - Check Status
    /// Check current subscription status from RevenueCat
    func checkSubscriptionStatus() {
        print("🔍 [Status] Checking subscription status...")

        if isDevelopmentMode {
            print("⚠️ [Status] Development Mode: Using local subscription status")
            return
        }

        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let error = error {
                print("❌ [Status] Failed to get customer info: \(error.localizedDescription)")
                print("   Error code: \((error as NSError).code)")
                return
            }

            print("✅ [Status] Customer info received")
            self?.updateStatus(from: customerInfo)
        }
    }

    // MARK: - Private Helpers
    private func updateStatus(from customerInfo: CustomerInfo?) {
        guard let customerInfo = customerInfo else {
            print("⚠️ [Status] CustomerInfo is nil")
            return
        }

        // Log all entitlements for debugging
        print("📋 [Status] All entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
        print("📋 [Status] Active entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
        print("📋 [Status] All purchased products: \(customerInfo.allPurchasedProductIdentifiers.joined(separator: ", "))")

        // Check for Pro tier first (higher tier)
        // Try both "pro" and "Pro" for compatibility
        let proEntitlement = customerInfo.entitlements["pro"] ?? customerInfo.entitlements["Pro"]
        if let entitlement = proEntitlement, entitlement.isActive {
            print("✅ [Status] Pro entitlement is ACTIVE")
            print("   Expires: \(entitlement.expirationDate?.description ?? "never")")
            print("   Is trialing: \(entitlement.periodType == .trial)")

            let status = SubscriptionStatus(
                tier: .pro,
                isActive: true,
                expiresAt: entitlement.expirationDate,
                isTrialing: entitlement.periodType == .trial,
                trialStartDate: entitlement.originalPurchaseDate,
                trialEndDate: entitlement.periodType == .trial ? entitlement.expirationDate : nil
            )
            self.currentStatus = status
        }
        // Check for Premium tier
        // Try both "premium" and "Premium" for compatibility
        else if let entitlement = customerInfo.entitlements["premium"] ?? customerInfo.entitlements["Premium"],
           entitlement.isActive {
            print("✅ [Status] Premium entitlement is ACTIVE")
            print("   Expires: \(entitlement.expirationDate?.description ?? "never")")
            print("   Is trialing: \(entitlement.periodType == .trial)")

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
            print("ℹ️ [Status] No active entitlements - setting to FREE tier")
            self.currentStatus = .free
        }

        print("📊 [Status] Current status: \(currentStatus.tier.displayName), Active: \(currentStatus.isActive)")
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

    // MARK: - Free Tier App Trial (7-day limited access)

    private let freeTrialStartKey = "free_trial_start_date"

    /// Initialize the free trial if user is on free tier and hasn't started yet
    func initializeFreeTrialIfNeeded() {
        // Only for free tier users who haven't started trial
        guard currentStatus.tier == .free else { return }

        // Check if trial already started
        if let existingStartDate = UserDefaults.standard.object(forKey: freeTrialStartKey) as? Date {
            // Trial already exists, make sure status reflects it
            if currentStatus.freeTrialStartDate == nil {
                var updatedStatus = SubscriptionStatus.freeWithTrial(startDate: existingStartDate)
                currentStatus = updatedStatus
            }
            return
        }

        // Start the 7-day free trial
        let startDate = Date()
        UserDefaults.standard.set(startDate, forKey: freeTrialStartKey)

        // Update status with trial info
        let updatedStatus = SubscriptionStatus.freeWithTrial(startDate: startDate)
        currentStatus = updatedStatus

        print("🎉 Free trial started: \(startDate)")
    }

    /// Load free trial start date from UserDefaults
    func loadFreeTrialStartDate() -> Date? {
        return UserDefaults.standard.object(forKey: freeTrialStartKey) as? Date
    }

    /// Whether the paywall should be shown (free trial expired and not subscribed)
    var shouldShowPaywall: Bool {
        // If user has an active paid subscription, no paywall needed
        if currentStatus.tier != .free && currentStatus.isActive {
            return false
        }

        // If user is on free tier, check if trial expired
        if currentStatus.tier == .free {
            // Load trial start from UserDefaults if not in status
            if let startDate = loadFreeTrialStartDate() {
                let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
                return Date() > endDate
            }
            // No trial started yet - don't show paywall (will start trial)
            return false
        }

        return false
    }

    /// Days remaining in free trial (0 if expired or not on free tier)
    var daysRemainingInFreeTrial: Int {
        guard currentStatus.tier == .free else { return 0 }

        if let startDate = loadFreeTrialStartDate() {
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
            let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return max(0, days)
        }

        return 7 // Trial not started yet, full 7 days available
    }

    /// Whether user is currently in free trial period (not expired)
    var isInFreeTrial: Bool {
        guard currentStatus.tier == .free else { return false }

        if let startDate = loadFreeTrialStartDate() {
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
            return Date() <= endDate
        }

        return true // Trial not started = will have full trial available
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
    case networkError
    case storeUnavailable
    case paymentNotAllowed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noProductForFreeTier:
            return "Free tier does not require a purchase"
        case .productNotFound:
            return "Unable to load subscription. Please try again later."
        case .userCancelled:
            return "Purchase cancelled"
        case .revenueCatNotConfigured:
            return "Subscriptions are temporarily unavailable. Please try again later."
        case .networkError:
            return "Please check your internet connection and try again."
        case .storeUnavailable:
            return "The App Store is temporarily unavailable. Please try again later."
        case .paymentNotAllowed:
            return "Purchases are not allowed on this device. Please check your parental controls or device restrictions."
        case .unknown(let message):
            return message
        }
    }

    /// Convert RevenueCat errors to user-friendly errors
    static func from(_ error: Error) -> SubscriptionError {
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("cancel") || errorMessage.contains("cancelled") {
            return .userCancelled
        } else if errorMessage.contains("network") || errorMessage.contains("connection") || errorMessage.contains("internet") {
            return .networkError
        } else if errorMessage.contains("not allowed") || errorMessage.contains("restricted") || errorMessage.contains("parental") {
            return .paymentNotAllowed
        } else if errorMessage.contains("store") || errorMessage.contains("unavailable") {
            return .storeUnavailable
        } else if errorMessage.contains("product") || errorMessage.contains("configuration") {
            return .productNotFound
        } else {
            return .unknown("Something went wrong. Please try again.")
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
