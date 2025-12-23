//
//  SceneDelegate.swift
//  LangChat
//
//  Created by Robin Hutchinson on 2025-09-26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()

        // Handle any incoming URLs (app launched via deep link)
        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingURL(urlContext.url)
        }

        // Show loading screen while checking connectivity
        showLoadingScreen()
        window?.makeKeyAndVisible()

        // Check connectivity before proceeding
        checkConnectivityAndProceed()
    }

    // MARK: - Deep Link Handling

    /// Handle URLs when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleIncomingURL(url)
    }

    /// Parse and handle incoming URLs (invite links)
    private func handleIncomingURL(_ url: URL) {
        print("🔗 Received URL: \(url)")

        // Parse invite code from URL
        // Supports: fluenca://invite?code=FLU-ABC123
        // Or: fluenca://invite/FLU-ABC123

        guard url.scheme == "fluenca" else {
            print("⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }

        var inviteCode: String?

        if url.host == "invite" {
            // Check path component: fluenca://invite/FLU-ABC123
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let code = pathComponents.first {
                inviteCode = code
            }

            // Check query parameter: fluenca://invite?code=FLU-ABC123
            if inviteCode == nil, let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                inviteCode = queryItems.first(where: { $0.name == "code" })?.value
            }
        }

        if let code = inviteCode {
            print("📨 Found invite code: \(code)")
            // Store the code for processing after authentication/onboarding
            UserDefaults.standard.set(code, forKey: "pendingInviteCode")

            // If user is already logged in and on main screen, show confirmation
            if SupabaseService.shared.isAuthenticated,
               let rootVC = window?.rootViewController as? MainTabBarController {
                showInviteReceivedAlert(code: code, on: rootVC)
            }
        }
    }

    /// Show alert when invite received while app is active
    private func showInviteReceivedAlert(code: String, on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Invite Link Received",
            message: "You've received an invite code: \(code). Would you like to connect with this person?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
            self.processInviteCode(code)
        })

        alert.addAction(UIAlertAction(title: "Ignore", style: .cancel) { _ in
            UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
        })

        viewController.present(alert, animated: true)
    }

    /// Process an invite code and create the match
    private func processInviteCode(_ code: String) {
        Task {
            do {
                let result = try await SupabaseService.shared.acceptInvite(code: code)
                await MainActor.run {
                    UserDefaults.standard.removeObject(forKey: "pendingInviteCode")

                    if result.success, let inviterName = result.inviterName {
                        // Show success and navigate to chat
                        self.showMatchSuccessAlert(inviterName: inviterName, matchId: result.matchId)
                    } else {
                        self.showInviteErrorAlert(error: result.error ?? "Unknown error")
                    }
                }
            } catch {
                await MainActor.run {
                    self.showInviteErrorAlert(error: error.localizedDescription)
                }
            }
        }
    }

    private func showMatchSuccessAlert(inviterName: String, matchId: String?) {
        guard let rootVC = window?.rootViewController else { return }

        let alert = UIAlertController(
            title: "You're Connected!",
            message: "You're now matched with \(inviterName). Start chatting!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // TODO: Navigate to the chat with this match
            // For now, just refresh the matches tab
            if let tabBar = rootVC as? MainTabBarController {
                tabBar.selectedIndex = 1 // Switch to Matches tab
            }
        })

        rootVC.present(alert, animated: true)
    }

    private func showInviteErrorAlert(error: String) {
        guard let rootVC = window?.rootViewController else { return }

        let alert = UIAlertController(
            title: "Invite Error",
            message: error,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootVC.present(alert, animated: true)
    }

    /// Process any pending invite code (from deep link during signup)
    private func processPendingInviteCode() {
        guard let inviteCode = UserDefaults.standard.string(forKey: "pendingInviteCode") else {
            return
        }

        print("📨 Processing pending invite code: \(inviteCode)")

        Task {
            do {
                let result = try await SupabaseService.shared.acceptInvite(code: inviteCode)

                await MainActor.run {
                    // Clear the pending code regardless of result
                    UserDefaults.standard.removeObject(forKey: "pendingInviteCode")

                    if result.success, let inviterName = result.inviterName {
                        print("✅ Invite accepted - matched with \(inviterName)")

                        // Show success alert after a short delay to let the UI settle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.showMatchSuccessAlert(inviterName: inviterName, matchId: result.matchId)
                        }
                    } else if let error = result.error {
                        print("⚠️ Invite processing failed: \(error)")
                        // Don't show error for expired/invalid codes during app launch
                        // Just silently clear it
                    }
                }
            } catch {
                await MainActor.run {
                    UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
                    print("❌ Error processing invite: \(error)")
                }
            }
        }
    }

    private func showLoadingScreen() {
        let loadingVC = UIViewController()
        loadingVC.view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingVC.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingVC.view.centerYAnchor)
        ])
        activityIndicator.startAnimating()

        window?.rootViewController = loadingVC
    }

    private func checkConnectivityAndProceed() {
        Task {
            // Give network monitor a moment to initialize
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            let isConnected = await NetworkMonitor.shared.checkSupabaseConnectivity()

            await MainActor.run {
                if isConnected {
                    self.proceedWithAppFlow()
                } else {
                    self.showOfflineScreen()
                }
            }
        }
    }

    private func showOfflineScreen() {
        let offlineVC = OfflineViewController()
        offlineVC.onConnected = { [weak self] in
            self?.proceedWithAppFlow()
        }
        window?.rootViewController = offlineVC
    }

    private func proceedWithAppFlow() {
        // Check if user has an active Supabase session
        let hasActiveSession = SupabaseService.shared.isAuthenticated

        print("🔍 Session check - Authenticated: \(hasActiveSession)")

        if hasActiveSession {
            // User has active session - check if they have completed profile in Supabase
            showLoadingScreen()

            Task {
                do {
                    let hasCompletedProfile = try await SupabaseService.shared.hasCompletedProfile()

                    if hasCompletedProfile {
                        // Sync profile from Supabase to UserDefaults
                        try await SupabaseService.shared.syncProfileToUserDefaults()
                    }

                    await MainActor.run {
                        if hasCompletedProfile {
                            // User has completed profile - go to main app
                            print("✅ Profile complete - going to main app")

                            // Check for pending invite code and process it
                            self.processPendingInviteCode()

                            self.window?.rootViewController = MainTabBarController()
                        } else {
                            // User is logged in but hasn't completed profile - show onboarding
                            print("⚠️ Profile incomplete - showing onboarding")
                            let navController = UINavigationController()
                            self.window?.rootViewController = navController

                            let coordinator = OnboardingCoordinator(navigationController: navController)
                            coordinator.start()
                        }
                    }
                } catch {
                    // Error checking profile - likely network issue
                    print("❌ Error checking profile: \(error)")
                    await MainActor.run {
                        // User has a valid session but we can't reach the server
                        // Show offline screen instead of kicking them to onboarding
                        self.showOfflineScreen()
                    }
                }
            }
        } else {
            // No active session - show authentication flow
            showAuthenticationFlow()
        }
    }

    private func showAuthenticationFlow() {
        let shouldShowWelcome = UserEngagementTracker.shared.shouldShowWelcomeScreen

        let rootVC: UIViewController
        if shouldShowWelcome {
            // Show the carousel for first-time users
            rootVC = OnboardingCarouselViewController()
            print("📱 Showing Onboarding Carousel (first time experience)")
        } else {
            rootVC = AuthenticationViewController()
            print("📱 Showing Authentication screen (returning user)")
        }

        let navController = UINavigationController(rootViewController: rootVC)
        window?.rootViewController = navController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Update user's last_active timestamp to mark them as online
        Task {
            await SupabaseService.shared.updateLastActive()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Clear TTS voice cache so any web-admin changes take effect immediately
        TTSService.shared.clearVoiceCache()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

