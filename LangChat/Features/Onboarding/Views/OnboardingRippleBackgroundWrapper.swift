import UIKit
import SwiftUI

/// Helper to wrap a UIKit view controller with the SwiftUI ripple background
class OnboardingRippleBackgroundWrapper {

    /// Adds ripple background to a view controller by inserting it behind all views
    /// - Parameter viewController: The view controller to add the background to
    static func addRippleBackground(to viewController: UIViewController) {
        // Create SwiftUI view
        let rippleView = OnboardingRippleBackground()

        // Wrap in hosting controller
        let hostingController = UIHostingController(rootView: rippleView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Add as child view controller
        viewController.addChild(hostingController)
        viewController.view.insertSubview(hostingController.view, at: 0)
        hostingController.didMove(toParent: viewController)

        // Pin to edges
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
    }
}

/// Extension to make it easy to add ripple background to BaseOnboardingViewController
extension BaseOnboardingViewController {

    /// Call this in viewDidLoad to add the ripple background
    func addRippleBackground() {
        OnboardingRippleBackgroundWrapper.addRippleBackground(to: self)

        // Make the view controller's background clear so ripple shows through
        view.backgroundColor = .clear
    }
}
