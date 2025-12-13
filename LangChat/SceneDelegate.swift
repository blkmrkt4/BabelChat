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

        // Show loading screen while checking connectivity
        showLoadingScreen()
        window?.makeKeyAndVisible()

        // Check connectivity before proceeding
        checkConnectivityAndProceed()
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
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

