import UIKit

/// A minimal WiFi status indicator that shows connectivity state
class OfflineBannerView: UIView {

    static let height: CGFloat = 32

    private let iconView = UIImageView()
    private var isShowing = false
    private var wasOffline = false  // Track if we were offline to show "back online"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        // WiFi icon - centered
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: "wifi.slash", withConfiguration: config)
        iconView.tintColor = .systemRed
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28)
        ])

        // Start hidden
        alpha = 0
    }

    func show(animated: Bool = true) {
        guard !isShowing else { return }
        isShowing = true
        wasOffline = true

        // Show red WiFi slash icon
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: "wifi.slash", withConfiguration: config)
        iconView.tintColor = .systemRed

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
        } else {
            alpha = 1
        }
    }

    func hide(animated: Bool = true) {
        guard isShowing else { return }
        isShowing = false

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 0
            }
        } else {
            alpha = 0
        }
    }

    func showConnected() {
        // Only show green icon if we were previously offline
        guard wasOffline else {
            hide()
            return
        }

        isShowing = true

        // Show green WiFi icon
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: "wifi", withConfiguration: config)
        iconView.tintColor = .systemGreen

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.wasOffline = false
            self?.hide()
        }
    }
}

// MARK: - UIViewController Extension for Easy Banner Integration
extension UIViewController {

    private static var offlineBannerKey: UInt8 = 0

    var offlineBanner: OfflineBannerView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.offlineBannerKey) as? OfflineBannerView
        }
        set {
            objc_setAssociatedObject(self, &UIViewController.offlineBannerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Sets up offline monitoring for this view controller
    func setupOfflineMonitoring() {
        // Create banner if needed
        if offlineBanner == nil {
            let banner = OfflineBannerView()
            banner.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(banner)

            NSLayoutConstraint.activate([
                banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                banner.heightAnchor.constraint(equalToConstant: OfflineBannerView.height)
            ])

            offlineBanner = banner
        }

        // Listen for connectivity changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectivityChange),
            name: NetworkMonitor.connectivityDidChangeNotification,
            object: nil
        )

        // Check current state
        if !NetworkMonitor.shared.isConnected {
            offlineBanner?.show(animated: false)
        }
    }

    @objc private func handleConnectivityChange(_ notification: Notification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }

        if isConnected {
            offlineBanner?.showConnected()
        } else {
            offlineBanner?.show()
        }
    }

    func removeOfflineMonitoring() {
        NotificationCenter.default.removeObserver(self, name: NetworkMonitor.connectivityDidChangeNotification, object: nil)
        offlineBanner?.removeFromSuperview()
        offlineBanner = nil
    }
}
