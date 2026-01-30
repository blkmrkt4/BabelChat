import UIKit

/// Displayed when the app cannot connect to the server
class OfflineViewController: UIViewController {

    // MARK: - Properties
    var onConnected: (() -> Void)?
    private var retryTimer: Timer?
    private var retryCount = 0
    private let maxRetryInterval: TimeInterval = 30.0
    private var currentRetryInterval: TimeInterval = 3.0

    // MARK: - UI Components
    private let containerView = UIView()
    private let networkIconView = NetworkAnimationView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryingLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let countdownLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        startListeningForConnectivity()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        networkIconView.startAnimating()
        startRetrying()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRetrying()
        networkIconView.stopAnimating()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopRetrying()
    }

    // MARK: - Setup
    private func setupViews() {
        // Dark gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).cgColor,
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Network animation
        networkIconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(networkIconView)

        // Title
        titleLabel.text = "offline_title".localized
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Message
        messageLabel.text = "offline_message".localized
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        // Retrying label with animated dots
        retryingLabel.text = "offline_retrying".localized
        retryingLabel.font = .systemFont(ofSize: 15, weight: .medium)
        retryingLabel.textColor = UIColor.systemBlue.withAlphaComponent(0.9)
        retryingLabel.textAlignment = .center
        retryingLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(retryingLabel)

        // Countdown label
        countdownLabel.font = .systemFont(ofSize: 13, weight: .regular)
        countdownLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        countdownLabel.textAlignment = .center
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(countdownLabel)

        // Manual retry button
        retryButton.setTitle("offline_retry_button".localized, for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 12
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(retryButton)

        // Start dots animation
        animateRetryingDots()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            networkIconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            networkIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            networkIconView.widthAnchor.constraint(equalToConstant: 120),
            networkIconView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: networkIconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            retryingLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            retryingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            countdownLabel.topAnchor.constraint(equalTo: retryingLabel.bottomAnchor, constant: 8),
            countdownLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            retryButton.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 24),
            retryButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 140),
            retryButton.heightAnchor.constraint(equalToConstant: 48),
            retryButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }

    // MARK: - Connectivity Listening
    private func startListeningForConnectivity() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectivityChanged),
            name: NetworkMonitor.connectivityDidChangeNotification,
            object: nil
        )
    }

    @objc private func connectivityChanged(_ notification: Notification) {
        if let isConnected = notification.userInfo?["isConnected"] as? Bool, isConnected {
            checkAndProceed()
        }
    }

    // MARK: - Retry Logic
    private func startRetrying() {
        scheduleNextRetry()
    }

    private func stopRetrying() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    private func scheduleNextRetry() {
        retryTimer?.invalidate()

        // Exponential backoff with cap
        let interval = min(currentRetryInterval, maxRetryInterval)
        var countdown = Int(interval)

        // Update countdown every second
        retryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            countdown -= 1

            if countdown <= 0 {
                timer.invalidate()
                self.performRetry()
            } else {
                self.countdownLabel.text = String(format: "offline_next_retry".localized, countdown)
            }
        }

        countdownLabel.text = String(format: "offline_next_retry".localized, Int(interval))
    }

    private func performRetry() {
        retryCount += 1
        retryingLabel.text = "offline_retrying".localized
        countdownLabel.text = "offline_checking".localized

        // Increase next interval (exponential backoff)
        currentRetryInterval = min(currentRetryInterval * 1.5, maxRetryInterval)

        checkAndProceed()
    }

    private func checkAndProceed() {
        Task {
            let isReachable = await NetworkMonitor.shared.checkSupabaseConnectivity()

            await MainActor.run {
                if isReachable {
                    // Success - notify and dismiss
                    self.stopRetrying()
                    self.networkIconView.showSuccess()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.onConnected?()
                    }
                } else {
                    // Still offline - schedule next retry
                    self.retryingLabel.text = "offline_still_offline".localized
                    self.scheduleNextRetry()
                }
            }
        }
    }

    @objc private func retryButtonTapped() {
        stopRetrying()
        currentRetryInterval = 3.0 // Reset backoff
        performRetry()
    }

    // MARK: - Animations
    private var dotsTimer: Timer?

    private func animateRetryingDots() {
        dotsTimer?.invalidate()
        var dotCount = 0
        dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.retryingLabel.text?.hasPrefix("Retrying") == true {
                dotCount = (dotCount + 1) % 4
                let dots = String(repeating: ".", count: dotCount)
                self.retryingLabel.text = "Retrying\(dots)"
            }
        }
    }

    private func stopAnimatingDots() {
        dotsTimer?.invalidate()
        dotsTimer = nil
    }
}

// MARK: - Network Animation View
/// Custom animated view showing network connectivity status
class NetworkAnimationView: UIView {

    private let wifiIcon = UIImageView()
    private let signalBars: [UIView] = (0..<3).map { _ in UIView() }
    private let pulseLayer = CAShapeLayer()
    private var isAnimating = false

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

        // Pulse circle behind icon
        let circleSize: CGFloat = 100
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: 60, y: 60),
            radius: circleSize / 2,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        pulseLayer.path = circlePath.cgPath
        pulseLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        pulseLayer.opacity = 0
        layer.addSublayer(pulseLayer)

        // WiFi icon
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .medium)
        wifiIcon.image = UIImage(systemName: "wifi.slash", withConfiguration: config)
        wifiIcon.tintColor = .systemRed
        wifiIcon.contentMode = .scaleAspectFit
        wifiIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(wifiIcon)

        NSLayoutConstraint.activate([
            wifiIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            wifiIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            wifiIcon.widthAnchor.constraint(equalToConstant: 60),
            wifiIcon.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        // Pulse animation
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 0.8
        pulseAnimation.toValue = 1.3
        pulseAnimation.duration = 1.5
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.4
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1.5
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity

        pulseLayer.add(pulseAnimation, forKey: "pulse")
        pulseLayer.add(opacityAnimation, forKey: "opacity")

        // Icon color cycling animation
        animateIconColor()
    }

    private func animateIconColor() {
        guard isAnimating else { return }

        UIView.animate(withDuration: 1.0, animations: {
            self.wifiIcon.tintColor = .systemOrange
        }) { _ in
            guard self.isAnimating else { return }
            UIView.animate(withDuration: 1.0, animations: {
                self.wifiIcon.tintColor = .systemRed
            }) { _ in
                self.animateIconColor()
            }
        }
    }

    func stopAnimating() {
        isAnimating = false
        pulseLayer.removeAllAnimations()
        wifiIcon.layer.removeAllAnimations()
    }

    func showSuccess() {
        stopAnimating()

        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .medium)
        wifiIcon.image = UIImage(systemName: "wifi", withConfiguration: config)
        wifiIcon.tintColor = .systemGreen

        // Success pulse
        UIView.animate(withDuration: 0.3, animations: {
            self.wifiIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.wifiIcon.transform = .identity
            }
        }
    }
}
