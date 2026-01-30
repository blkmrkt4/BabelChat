import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupViewControllers()
        setupAppearance()
        setupConnectivityBanner()

        // Auto-sync UserDefaults to Supabase if data is out of sync
        // This fixes cases where onboarding data wasn't synced properly
        syncLocalDataToSupabaseIfNeeded()
    }

    /// Check if UserDefaults has more complete data than Supabase and sync if needed
    private func syncLocalDataToSupabaseIfNeeded() {
        print("🔄 MainTabBarController: Starting auto-sync check...")
        print("🔄 Authenticated: \(SupabaseService.shared.isAuthenticated)")
        print("🔄 CurrentUserId: \(SupabaseService.shared.currentUserId?.uuidString ?? "nil")")

        Task {
            do {
                print("🔄 Fetching current profile from Supabase...")
                let profile = try await SupabaseService.shared.getCurrentProfile()

                // Get local data from UserDefaults
                let localFirstName = UserDefaults.standard.string(forKey: "firstName") ?? ""
                let localLastName = UserDefaults.standard.string(forKey: "lastName") ?? ""
                let localBio = UserDefaults.standard.string(forKey: "bio") ?? ""

                // Check if we have language data locally
                var localHasLanguages = false
                if let data = UserDefaults.standard.data(forKey: "userLanguages") {
                    localHasLanguages = true
                }

                // Check if local data is more complete than Supabase data
                let supabaseFirstName = profile.firstName
                let supabaseBio = profile.bio ?? ""
                let supabaseLearningLanguages = profile.learningLanguages ?? []

                print("🔄 Supabase data: firstName='\(supabaseFirstName)', bio='\(supabaseBio.prefix(20))...', languages=\(supabaseLearningLanguages)")
                print("🔄 Local data: firstName='\(localFirstName)', lastName='\(localLastName)', bio='\(localBio.prefix(20))...', hasLanguages=\(localHasLanguages)")

                var needsSync = false
                var syncReasons: [String] = []

                // If Supabase has empty/default name but UserDefaults has real name
                if (supabaseFirstName.isEmpty || supabaseFirstName.lowercased() == "user") && !localFirstName.isEmpty {
                    syncReasons.append("name mismatch")
                    needsSync = true
                }

                // If names don't match at all
                if !localFirstName.isEmpty && supabaseFirstName != localFirstName {
                    syncReasons.append("firstName differs ('\(supabaseFirstName)' vs '\(localFirstName)')")
                    needsSync = true
                }

                // If Supabase has no bio but UserDefaults has bio
                if supabaseBio.isEmpty && !localBio.isEmpty {
                    syncReasons.append("bio mismatch")
                    needsSync = true
                }

                // If Supabase has no learning languages but we have them locally
                if supabaseLearningLanguages.isEmpty && localHasLanguages {
                    syncReasons.append("languages mismatch")
                    needsSync = true
                }

                // If photos need syncing - Supabase has no photos but we completed onboarding
                if (profile.profilePhotos?.filter { !$0.isEmpty }.count ?? 0) == 0 {
                    // No photos in Supabase - might need upload
                    // But we can't recover UIImages from UserDefaults, so just sync text data
                }

                if needsSync {
                    print("📤 Auto-sync NEEDED. Reasons: \(syncReasons.joined(separator: ", "))")
                    print("📤 Auto-syncing local profile data to Supabase...")
                    try await SupabaseService.shared.syncOnboardingDataToSupabase()
                    print("✅ Auto-sync completed successfully!")

                    // Notify that profile was updated so UI refreshes
                    await MainActor.run {
                        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                    }
                } else {
                    print("✅ Auto-sync check: No sync needed, data appears in sync")
                }
            } catch {
                print("❌ Auto-sync check FAILED with error: \(error)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkSubscriptionAccess()
    }

    // MARK: - Subscription Access Check

    private func checkSubscriptionAccess() {
        let subscriptionService = SubscriptionService.shared

        // Initialize free trial for new users
        subscriptionService.initializeFreeTrialIfNeeded()

        // Check if paywall should be shown (free trial expired)
        if subscriptionService.shouldShowPaywall {
            presentPaywall()
        }
    }

    private func presentPaywall() {
        // Create pricing view controller as a forced paywall
        let pricingVC = PricingViewController()
        pricingVC.isModalPaywall = true  // Flag to prevent dismissal and show different messaging

        let navController = UINavigationController(rootViewController: pricingVC)
        navController.modalPresentationStyle = .fullScreen
        navController.isModalInPresentation = true  // Prevent swipe to dismiss

        present(navController, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupConnectivityBanner() {
        // We no longer add a global connectivity banner to the tab bar controller
        // because it overlaps with navigation bar content when views are pushed.
        //
        // Instead, we just listen for connectivity changes and could show alerts
        // or banners within individual view controllers if needed.
        //
        // The NWPathMonitor typically fires immediately on app launch before UI is ready,
        // causing false "offline" states. Better to trust the connection and only
        // show errors when actual network requests fail.

        // Listen for connectivity changes (for future use or logging)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusDidChange),
            name: NetworkMonitor.connectivityDidChangeNotification,
            object: nil
        )
    }

    @objc private func networkStatusDidChange(_ notification: Notification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }

        #if DEBUG
        print("📶 MainTabBarController: Network status changed - connected: \(isConnected)")
        #endif

        // We no longer show a banner here - individual views can handle offline state
        // if needed by showing inline messages or alerts when requests fail
    }

    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // If tapping the already selected tab, pop to root
        if let navController = viewController as? UINavigationController,
           viewController == selectedViewController {
            navController.popToRootViewController(animated: true)
        }
        return true
    }

    private func setupViewControllers() {
        let discoverVC = createDiscoverViewController()
        let languageLabVC = createLanguageLabViewController()
        let matchesVC = createMatchesViewController()
        let chatsVC = createChatsViewController()
        let profileVC = createProfileViewController()

        viewControllers = [discoverVC, languageLabVC, matchesVC, chatsVC, profileVC]

        selectedIndex = 2 // Start on Matches tab
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground

            // Ensure consistent appearance in all states
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.backgroundColor = .systemBackground
            tabBar.isTranslucent = false
        }
    }

    private func createDiscoverViewController() -> UINavigationController {
        let discoverVC = DiscoverViewController()
        discoverVC.tabBarItem = UITabBarItem(
            title: "tab_discover".localized,
            image: UIImage(systemName: "rectangle.stack.fill"),
            selectedImage: UIImage(systemName: "rectangle.stack.fill")
        )
        return UINavigationController(rootViewController: discoverVC)
    }

    private func createLanguageLabViewController() -> UINavigationController {
        let languageLabVC = LanguageLabViewController()
        languageLabVC.tabBarItem = UITabBarItem(
            title: "tab_language_lab".localized,
            image: UIImage(systemName: "brain.head.profile"),
            selectedImage: UIImage(systemName: "brain.head.profile.fill")
        )
        return UINavigationController(rootViewController: languageLabVC)
    }

    private func createMatchesViewController() -> UINavigationController {
        let matchesVC = MatchesListViewController()
        let tabItem = UITabBarItem(
            title: "tab_matches".localized,
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        matchesVC.tabBarItem = tabItem
        let navController = UINavigationController(rootViewController: matchesVC)
        navController.tabBarItem = tabItem
        return navController
    }

    private func createChatsViewController() -> UINavigationController {
        let chatsVC = ChatsListViewController()
        chatsVC.tabBarItem = UITabBarItem(
            title: "tab_chats".localized,
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        // Add badge for unread messages
        chatsVC.tabBarItem.badgeValue = "3"
        chatsVC.tabBarItem.badgeColor = .systemRed

        return UINavigationController(rootViewController: chatsVC)
    }

    private func createProfileViewController() -> UINavigationController {
        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(
            title: "tab_profile".localized,
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        return UINavigationController(rootViewController: profileVC)
    }
}