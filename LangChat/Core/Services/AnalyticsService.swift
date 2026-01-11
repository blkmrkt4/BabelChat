import Foundation
import UIKit

/// Centralized analytics service for tracking user events
/// Currently logs to console, but designed to easily integrate with
/// Mixpanel, Amplitude, PostHog, or Firebase Analytics
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var userId: String?
    private var userProperties: [String: Any] = [:]

    private init() {
        // Collect device info once
        userProperties["device_model"] = UIDevice.current.model
        userProperties["os_version"] = UIDevice.current.systemVersion
        userProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        userProperties["build_number"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    // MARK: - User Identification

    /// Set the current user ID for analytics
    func identify(userId: String) {
        self.userId = userId
        logEvent(.identify, properties: ["user_id": userId])
    }

    /// Clear user ID on logout
    func reset() {
        userId = nil
        userProperties = [:]
        logEvent(.reset)
    }

    /// Set a user property (e.g., subscription tier, language)
    func setUserProperty(_ key: String, value: Any) {
        userProperties[key] = value
    }

    // MARK: - Event Tracking

    /// Track an analytics event
    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        logEvent(event, properties: properties)

        // TODO: Send to analytics backend
        // When you add Mixpanel/Amplitude/PostHog, add the call here:
        // Mixpanel.mainInstance().track(event: event.rawValue, properties: properties)
        // Analytics.track(event.rawValue, properties: properties)
    }

    private func logEvent(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        #if DEBUG
        var logMessage = "📊 Analytics: \(event.rawValue)"
        if let props = properties, !props.isEmpty {
            logMessage += " | \(props)"
        }
        print(logMessage)
        #endif
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    // System
    case identify = "identify"
    case reset = "reset"
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"

    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"

    // Authentication
    case signUpStarted = "signup_started"
    case signUpCompleted = "signup_completed"
    case signUpFailed = "signup_failed"
    case loginStarted = "login_started"
    case loginCompleted = "login_completed"
    case loginFailed = "login_failed"
    case logoutCompleted = "logout_completed"

    // Profile
    case profileViewed = "profile_viewed"
    case profileEdited = "profile_edited"
    case profilePhotoUploaded = "profile_photo_uploaded"
    case languageAdded = "language_added"
    case languageRemoved = "language_removed"

    // Matching
    case discoverViewed = "discover_viewed"
    case profileSwipedRight = "profile_swiped_right"
    case profileSwipedLeft = "profile_swiped_left"
    case matchCreated = "match_created"
    case matchesListViewed = "matches_list_viewed"

    // Chat
    case chatOpened = "chat_opened"
    case messageSent = "message_sent"
    case messageReceived = "message_received"
    case translationRequested = "translation_requested"
    case ttsPlayed = "tts_played"

    // Muse (AI Practice Partner)
    case museSessionStarted = "muse_session_started"
    case museMessageSent = "muse_message_sent"
    case museSessionEnded = "muse_session_ended"

    // Subscription
    case paywallViewed = "paywall_viewed"
    case paywallDismissed = "paywall_dismissed"
    case upgradeButtonTapped = "upgrade_button_tapped"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseRestored = "purchase_restored"
    case trialStarted = "trial_started"
    case subscriptionCancelled = "subscription_cancelled"

    // Usage Limits
    case usageLimitReached = "usage_limit_reached"
    case upgradePromptShown = "upgrade_prompt_shown"

    // Errors
    case errorOccurred = "error_occurred"
    case networkError = "network_error"
    case apiError = "api_error"
}

// MARK: - Convenience Extensions

extension AnalyticsService {

    /// Track onboarding step
    func trackOnboardingStep(_ step: Int, stepName: String) {
        track(.onboardingStepViewed, properties: [
            "step_number": step,
            "step_name": stepName
        ])
    }

    /// Track a match action
    func trackSwipe(direction: String, profileId: String) {
        let event: AnalyticsEvent = direction == "right" ? .profileSwipedRight : .profileSwipedLeft
        track(event, properties: ["profile_id": profileId])
    }

    /// Track message sent with metadata
    func trackMessageSent(conversationId: String, isAI: Bool, characterCount: Int) {
        track(.messageSent, properties: [
            "conversation_id": conversationId,
            "is_ai_conversation": isAI,
            "character_count": characterCount
        ])
    }

    /// Track paywall view with context
    func trackPaywallViewed(source: String, currentTier: String) {
        track(.paywallViewed, properties: [
            "source": source,
            "current_tier": currentTier
        ])
    }

    /// Track purchase with revenue
    func trackPurchaseCompleted(productId: String, price: Double, currency: String) {
        track(.purchaseCompleted, properties: [
            "product_id": productId,
            "price": price,
            "currency": currency
        ])
    }

    /// Track usage limit reached
    func trackUsageLimitReached(limitType: String, currentCount: Int) {
        track(.usageLimitReached, properties: [
            "limit_type": limitType,
            "current_count": currentCount
        ])
    }

    /// Track error with context
    func trackError(_ error: Error, context: String) {
        track(.errorOccurred, properties: [
            "error_message": error.localizedDescription,
            "context": context
        ])
    }
}
