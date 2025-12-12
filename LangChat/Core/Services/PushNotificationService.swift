import UIKit
import UserNotifications
import Supabase

/// Device token data model for Supabase
private struct DeviceTokenData: Codable {
    let user_id: String
    let device_token: String
    let device_type: String
    let environment: String
    let device_name: String
    let device_model: String
    let os_version: String
    let app_version: String
    let is_active: Bool
}

/// Manages push notification registration, permissions, and device token management
class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private override init() {
        super.init()
    }

    // MARK: - Permission Request

    /// Request push notification permissions from the user
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Push notification authorization error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            if granted {
                print("✅ Push notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                completion(true, nil)
            } else {
                print("⚠️ Push notification permission denied by user")
                completion(false, nil)
            }
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }

    // MARK: - Device Token Management

    /// Handle successful device token registration
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNs Device Token: \(tokenString)")

        // Save token to Supabase
        Task {
            await saveDeviceToken(tokenString)
        }
    }

    /// Handle device token registration failure
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    /// Save device token to Supabase database
    private func saveDeviceToken(_ token: String) async {
        guard let userId = SupabaseService.shared.currentUserId else {
            print("⚠️ Cannot save device token: user not authenticated")
            return
        }

        do {
            // Get device information
            let device = UIDevice.current
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

            // Determine environment (production vs development)
            #if DEBUG
            let environment = "development"
            #else
            let environment = "production"
            #endif

            let deviceTokenData = DeviceTokenData(
                user_id: userId.uuidString,
                device_token: token,
                device_type: "ios",
                environment: environment,
                device_name: device.name,
                device_model: device.model,
                os_version: device.systemVersion,
                app_version: appVersion,
                is_active: true
            )

            // Upsert device token (insert or update if exists)
            try await SupabaseService.shared.client
                .from("device_tokens")
                .upsert(deviceTokenData)
                .execute()

            print("✅ Device token saved to Supabase")
        } catch {
            print("❌ Failed to save device token: \(error.localizedDescription)")
        }
    }

    /// Remove device token from Supabase (call on logout)
    func removeDeviceToken() async {
        guard let userId = SupabaseService.shared.currentUserId else {
            return
        }

        do {
            try await SupabaseService.shared.client
                .from("device_tokens")
                .update(["is_active": false])
                .eq("user_id", value: userId)
                .execute()

            print("✅ Device token marked as inactive")
        } catch {
            print("❌ Failed to deactivate device token: \(error.localizedDescription)")
        }
    }

    // MARK: - Badge Management

    /// Update app badge count
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    /// Clear app badge
    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - Notification Handling

    /// Handle notification when app is in foreground
    func handleForegroundNotification(_ notification: UNNotification, completion: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📬 Received notification in foreground: \(userInfo)")

        // Parse notification data
        if let type = userInfo["type"] as? String {
            switch type {
            case "new_message":
                // Show alert, sound, and badge for new messages
                completion([.banner, .sound, .badge])
            case "new_match":
                // Show alert and sound for new matches
                completion([.banner, .sound])
            case "like_received":
                // Show badge only for likes
                completion([.badge])
            default:
                completion([.banner, .sound, .badge])
            }
        } else {
            // Default: show all
            completion([.banner, .sound, .badge])
        }
    }

    /// Handle notification tap (user opened the app from notification)
    func handleNotificationTap(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 User tapped notification: \(userInfo)")

        guard let type = userInfo["type"] as? String else {
            return
        }

        switch type {
        case "new_message":
            if let conversationId = userInfo["conversation_id"] as? String {
                navigateToConversation(conversationId: conversationId)
            }
        case "new_match":
            if let matchId = userInfo["match_id"] as? String {
                navigateToMatch(matchId: matchId)
            }
        case "like_received":
            navigateToMatches()
        default:
            break
        }
    }

    // MARK: - Navigation Helpers

    private func navigateToConversation(conversationId: String) {
        // Post notification to navigate to chat
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToConversation"),
            object: nil,
            userInfo: ["conversationId": conversationId]
        )
    }

    private func navigateToMatch(matchId: String) {
        // Post notification to navigate to match detail
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToMatch"),
            object: nil,
            userInfo: ["matchId": matchId]
        )
    }

    private func navigateToMatches() {
        // Post notification to navigate to matches tab
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToMatches"),
            object: nil
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleForegroundNotification(notification, completion: completionHandler)
    }

    /// Handle notification response (user tapped notification)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationTap(response)
        completionHandler()
    }
}
