import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupViewControllers()
        setupAppearance()
        setupConnectivityBanner()
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
            title: "Discover",
            image: UIImage(systemName: "rectangle.stack.fill"),
            selectedImage: UIImage(systemName: "rectangle.stack.fill")
        )
        return UINavigationController(rootViewController: discoverVC)
    }

    private func createLanguageLabViewController() -> UINavigationController {
        let languageLabVC = LanguageLabViewController()
        languageLabVC.tabBarItem = UITabBarItem(
            title: "Language Lab",
            image: UIImage(systemName: "brain.head.profile"),
            selectedImage: UIImage(systemName: "brain.head.profile.fill")
        )
        return UINavigationController(rootViewController: languageLabVC)
    }

    private func createMatchesViewController() -> UINavigationController {
        let matchesVC = MatchesListViewController()
        let tabItem = UITabBarItem(
            title: "Matches",
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
            title: "Chats",
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
            title: "Profile",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
        return UINavigationController(rootViewController: profileVC)
    }
}