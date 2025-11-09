import Foundation

/// Tracks user engagement to determine if the welcome screen should be shown
class UserEngagementTracker {

    // MARK: - Singleton
    static let shared = UserEngagementTracker()
    private init() {}

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let hasSeenWelcomeScreen = "hasSeenWelcomeScreen"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasFirstMatch = "hasFirstMatch"
        static let hasFirstMessage = "hasFirstMessage"
        static let hasFilledProfile = "hasFilledProfile"
    }

    // MARK: - Tracking Methods

    /// Check if user has engaged with the app enough to skip the welcome screen
    /// Returns true if user has: first match OR first message OR filled in profile
    var hasUserEngaged: Bool {
        return hasFirstMatch || hasFirstMessage || hasFilledProfile || hasCompletedOnboarding
    }

    /// Check if user should see the welcome screen
    /// Returns true if user hasn't seen it yet AND hasn't engaged with the app
    var shouldShowWelcomeScreen: Bool {
        return !hasSeenWelcomeScreen && !hasUserEngaged
    }

    /// Mark that user has seen the welcome screen
    func markWelcomeScreenSeen() {
        UserDefaults.standard.set(true, forKey: Keys.hasSeenWelcomeScreen)
    }

    /// Mark that user completed onboarding (filling in profile)
    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    /// Mark that user has their first match
    func markFirstMatch() {
        UserDefaults.standard.set(true, forKey: Keys.hasFirstMatch)
    }

    /// Mark that user sent/received their first message
    func markFirstMessage() {
        UserDefaults.standard.set(true, forKey: Keys.hasFirstMessage)
    }

    /// Mark that user has filled in any part of their profile
    func markProfileFilled() {
        UserDefaults.standard.set(true, forKey: Keys.hasFilledProfile)
    }

    // MARK: - Private Properties

    private var hasSeenWelcomeScreen: Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasSeenWelcomeScreen)
    }

    private var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
    }

    private var hasFirstMatch: Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasFirstMatch)
    }

    private var hasFirstMessage: Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasFirstMessage)
    }

    private var hasFilledProfile: Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasFilledProfile)
    }

    // MARK: - Reset (for testing)

    /// Reset all engagement tracking (useful for testing)
    func reset() {
        UserDefaults.standard.removeObject(forKey: Keys.hasSeenWelcomeScreen)
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.hasFirstMatch)
        UserDefaults.standard.removeObject(forKey: Keys.hasFirstMessage)
        UserDefaults.standard.removeObject(forKey: Keys.hasFilledProfile)
    }
}
