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
    var isDevelopmentMode: Bool = true // Development mode enabled for testing
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
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)

        // Set delegate to listen for purchase updates
        Purchases.shared.delegate = self

        // Check current subscription status
        checkSubscriptionStatus()

        print("✅ RevenueCat configured successfully")
    }

    // MARK: - Fetch Offerings
    /// Fetch available subscription offerings from RevenueCat
    func fetchOfferings(completion: @escaping (Result<[SubscriptionOffering], Error>) -> Void) {
        // In development mode, return empty offerings
        if isDevelopmentMode {
            print("⚠️ Development Mode: Skipping RevenueCat offerings fetch")
            completion(.success([]))
            return
        }

        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let offerings = offerings, let current = offerings.current else {
                completion(.success([]))
                return
            }

            // Convert RevenueCat packages to our model
            let subscriptionOfferings = current.availablePackages.compactMap { package -> SubscriptionOffering? in
                guard let tier = SubscriptionTier(rawValue: package.identifier) else { return nil }
                return SubscriptionOffering(
                    tier: tier,
                    package: package,
                    price: package.storeProduct.localizedPriceString,
                    trialDays: package.storeProduct.introductoryDiscount?.subscriptionPeriod.value ?? 0
                )
            }

            completion(.success(subscriptionOfferings))
        }
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
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let error = error {
                print("❌ Failed to get customer info: \(error.localizedDescription)")
                return
            }

            self?.updateStatus(from: customerInfo)
        }
    }

    // MARK: - Private Helpers
    private func updateStatus(from customerInfo: Any?) {
        guard let customerInfo = customerInfo as? CustomerInfo else { return }

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
    let package: Any // Will be RevenueCat.Package when SDK is added
    let price: String
    let trialDays: Int
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
}

// MARK: - RevenueCat Delegate
extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateStatus(from: customerInfo)
    }
}
