import Foundation
import UIKit

// Import Sentry when available
#if canImport(Sentry)
import Sentry
#endif

/// Centralized crash reporting service
/// Uses Sentry when available, falls back to console logging
final class CrashReportingService {
    static let shared = CrashReportingService()

    private var isInitialized = false

    private init() {}

    // MARK: - Initialization

    /// Configure crash reporting - call from AppDelegate
    func configure() {
        #if canImport(Sentry)
        guard let dsn = getSentryDSN() else {
            print("⚠️ Sentry DSN not found in Info.plist")
            print("   Add SENTRY_DSN to Secrets.xcconfig to enable crash reporting")
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = false // Set to true for debugging Sentry itself

            // Set environment
            #if DEBUG
            options.environment = "development"
            #else
            options.environment = "production"
            #endif

            // Performance monitoring (optional - uses more data)
            options.tracesSampleRate = 0.2 // 20% of transactions

            // Session tracking
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30000

            // Attach screenshots on crash (helpful for debugging)
            options.attachScreenshot = true

            // Enable app hang detection (UI freezes > 2 seconds)
            options.enableAppHangTracking = true
            options.appHangTimeoutInterval = 2

            // Enable HTTP tracking
            options.enableNetworkTracking = true

            // Automatically track breadcrumbs for debugging
            options.enableAutoBreadcrumbTracking = true

            // Set max breadcrumbs
            options.maxBreadcrumbs = 100

            // Add app info
            options.releaseName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            options.dist = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        }

        isInitialized = true
        print("✅ Sentry crash reporting initialized")
        #else
        print("⚠️ Sentry SDK not installed - crash reporting disabled")
        print("   Add Sentry via Swift Package Manager to enable")
        #endif
    }

    private func getSentryDSN() -> String? {
        guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String,
              !dsn.isEmpty,
              !dsn.hasPrefix("$(") else {
            return nil
        }
        return dsn
    }

    // MARK: - User Identification

    /// Set the current user for crash reports
    func setUser(id: String, email: String? = nil, username: String? = nil) {
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            let user = Sentry.User()
            user.userId = id
            user.email = email
            user.username = username
            scope.setUser(user)
        }
        #endif
    }

    /// Clear user on logout
    func clearUser() {
        #if canImport(Sentry)
        SentrySDK.setUser(nil)
        #endif
    }

    // MARK: - Error Capturing

    /// Capture a non-fatal error
    func captureError(_ error: Error, context: [String: Any]? = nil) {
        #if canImport(Sentry)
        if let context = context {
            SentrySDK.capture(error: error) { scope in
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        } else {
            SentrySDK.capture(error: error)
        }
        #endif

        // Always log to console in debug
        #if DEBUG
        print("🔴 Error captured: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
        #endif
    }

    /// Capture a message (for non-error issues)
    func captureMessage(_ message: String, level: SentryLevel = .info) {
        #if canImport(Sentry)
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
        #endif

        #if DEBUG
        print("📝 Sentry message: [\(level.rawValue)] \(message)")
        #endif
    }

    // MARK: - Breadcrumbs (for debugging crashes)

    /// Add a breadcrumb for debugging crash context
    func addBreadcrumb(category: String, message: String, level: SentryLevel = .info, data: [String: Any]? = nil) {
        #if canImport(Sentry)
        let crumb = Breadcrumb(level: level.sentryLevel, category: category)
        crumb.message = message
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
        #endif
    }

    /// Add navigation breadcrumb
    func trackScreen(_ screenName: String) {
        addBreadcrumb(category: "navigation", message: "Viewed \(screenName)")
    }

    /// Add user action breadcrumb
    func trackAction(_ action: String, data: [String: Any]? = nil) {
        addBreadcrumb(category: "user_action", message: action, data: data)
    }

    // MARK: - Context

    /// Set a tag that will be included in all future events
    func setTag(_ key: String, value: String) {
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            scope.setTag(value: value, key: key)
        }
        #endif
    }

    /// Set extra context data
    func setExtra(_ key: String, value: Any) {
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            scope.setExtra(value: value, key: key)
        }
        #endif
    }
}

// MARK: - Sentry Level Wrapper

enum SentryLevel: String {
    case debug
    case info
    case warning
    case error
    case fatal

    #if canImport(Sentry)
    var sentryLevel: Sentry.SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
    #endif
}

// MARK: - Convenience for Common Scenarios

extension CrashReportingService {

    /// Track API error with full context
    func captureAPIError(_ error: Error, endpoint: String, statusCode: Int? = nil) {
        var context: [String: Any] = ["endpoint": endpoint]
        if let code = statusCode {
            context["status_code"] = code
        }
        captureError(error, context: context)
    }

    /// Track subscription-related errors
    func captureSubscriptionError(_ error: Error, productId: String? = nil) {
        var context: [String: Any] = ["category": "subscription"]
        if let id = productId {
            context["product_id"] = id
        }
        captureError(error, context: context)
    }

    /// Track AI/translation errors
    func captureAIError(_ error: Error, model: String, category: String) {
        captureError(error, context: [
            "ai_model": model,
            "ai_category": category
        ])
    }
}
