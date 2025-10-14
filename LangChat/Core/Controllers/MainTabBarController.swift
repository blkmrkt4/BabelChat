import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupAppearance()
    }

    private func setupViewControllers() {
        let discoverVC = createDiscoverViewController()
        let matchesVC = createMatchesViewController()
        let chatsVC = createChatsViewController()
        let profileVC = createProfileViewController()

        viewControllers = [discoverVC, matchesVC, chatsVC, profileVC]

        selectedIndex = 1 // Start on Matches tab
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .systemBackground
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
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

    private func createMatchesViewController() -> UINavigationController {
        let matchesVC = MatchesListViewController()
        matchesVC.tabBarItem = UITabBarItem(
            title: "Matches",
            image: UIImage(systemName: "heart.circle"),
            selectedImage: UIImage(systemName: "heart.circle.fill")
        )
        return UINavigationController(rootViewController: matchesVC)
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