import UIKit

class WelcomeViewController: UIViewController {

    // MARK: - Properties
    var isViewingFromProfile = false

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let closeButton = UIButton(type: .system)

    private let logoLabel = UILabel()
    private let headlineLabel = UILabel()
    private let subheadlineLabel = UILabel()

    private let featuresStackView = UIStackView()
    private let premiumNoteLabel = UILabel()

    private let continueButton = UIButton(type: .system)

    #if DEBUG
    private let resetButton = UIButton(type: .system)
    #endif

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRippleBackground()
        setupViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup
    private func setupRippleBackground() {
        OnboardingRippleBackgroundWrapper.addRippleBackground(to: self)
        view.backgroundColor = .clear
    }

    private func setupViews() {
        // Scroll view for smaller screens
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        // Main content stack
        contentStackView.axis = .vertical
        contentStackView.spacing = 32
        contentStackView.alignment = .center
        scrollView.addSubview(contentStackView)

        // Logo
        logoLabel.text = "Fluenca"
        logoLabel.font = .systemFont(ofSize: 48, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        contentStackView.addArrangedSubview(logoLabel)

        // Headline
        headlineLabel.text = "Learn Languages\nThrough Real Connections"
        headlineLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headlineLabel.textColor = .white
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(headlineLabel)

        // Subheadline
        subheadlineLabel.text = "The best way to learn is through genuine conversations with people who inspire you."
        subheadlineLabel.font = .systemFont(ofSize: 17, weight: .regular)
        subheadlineLabel.textColor = .white.withAlphaComponent(0.9)
        subheadlineLabel.textAlignment = .center
        subheadlineLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(subheadlineLabel)

        // Spacer
        let spacerTop = UIView()
        spacerTop.translatesAutoresizingMaskIntoConstraints = false
        spacerTop.heightAnchor.constraint(equalToConstant: 16).isActive = true
        contentStackView.addArrangedSubview(spacerTop)

        // Features
        setupFeatures()
        contentStackView.addArrangedSubview(featuresStackView)

        // Spacer
        let spacerBottom = UIView()
        spacerBottom.translatesAutoresizingMaskIntoConstraints = false
        spacerBottom.heightAnchor.constraint(equalToConstant: 16).isActive = true
        contentStackView.addArrangedSubview(spacerBottom)

        // Premium note
        let premiumContainer = UIView()
        premiumContainer.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        premiumContainer.layer.cornerRadius = 16
        premiumContainer.translatesAutoresizingMaskIntoConstraints = false

        premiumNoteLabel.text = "Free to start, Premium to thrive"
        premiumNoteLabel.font = .systemFont(ofSize: 15, weight: .medium)
        premiumNoteLabel.textColor = Color(hex: "FFD700").uiColor
        premiumNoteLabel.textAlignment = .center
        premiumNoteLabel.numberOfLines = 0
        premiumContainer.addSubview(premiumNoteLabel)

        premiumNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            premiumNoteLabel.topAnchor.constraint(equalTo: premiumContainer.topAnchor, constant: 12),
            premiumNoteLabel.leadingAnchor.constraint(equalTo: premiumContainer.leadingAnchor, constant: 20),
            premiumNoteLabel.trailingAnchor.constraint(equalTo: premiumContainer.trailingAnchor, constant: -20),
            premiumNoteLabel.bottomAnchor.constraint(equalTo: premiumContainer.bottomAnchor, constant: -12)
        ])

        contentStackView.addArrangedSubview(premiumContainer)

        // Continue button
        if isViewingFromProfile {
            continueButton.setTitle("Close", for: .normal)
        } else {
            continueButton.setTitle("Get Started", for: .normal)
        }
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .white
        continueButton.setTitleColor(.black, for: .normal)
        continueButton.layer.cornerRadius = 25
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        view.addSubview(continueButton)

        // Close button (X) in top-right when viewing from profile
        if isViewingFromProfile {
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .white.withAlphaComponent(0.8)
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            view.addSubview(closeButton)
        }

        #if DEBUG
        // Reset button (development only)
        resetButton.setTitle("🔄 Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        resetButton.backgroundColor = .systemRed.withAlphaComponent(0.8)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 20
        resetButton.addTarget(self, action: #selector(resetAllDataTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        #endif
    }

    private func setupFeatures() {
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 20
        featuresStackView.alignment = .leading
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false

        let features = [
            (icon: "person.2.fill", title: "Match with Real People", description: "Connect with native speakers and learners who share your interests"),
            (icon: "hand.point.right.fill", title: "Swipe Right for Translation", description: "Instantly see what any message means in your language"),
            (icon: "hand.point.left.fill", title: "Swipe Left for Grammar Help", description: "Get AI-powered insights to improve your language skills"),
            (icon: "message.fill", title: "Chat with Confidence", description: "Practice with real people or AI bots anytime")
        ]

        for feature in features {
            let featureView = createFeatureView(icon: feature.icon, title: feature.title, description: feature.description)
            featuresStackView.addArrangedSubview(featureView)
        }
    }

    private func createFeatureView(icon: String, title: String, description: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = Color(hex: "FFD700").uiColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(descLabel)
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            // Content stack
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),

            // Features stack width
            featuresStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),

            // Continue button
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Close button constraints (when viewing from profile)
        if isViewingFromProfile {
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 32),
                closeButton.heightAnchor.constraint(equalToConstant: 32)
            ])
        }

        #if DEBUG
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        #endif
    }

    // MARK: - Actions
    @objc private func continueTapped() {
        if isViewingFromProfile {
            // Just dismiss when viewing from profile
            dismiss(animated: true)
        } else {
            // Mark welcome screen as seen
            UserEngagementTracker.shared.markWelcomeScreenSeen()

            // Navigate to authentication page (Apple Sign In + Email)
            let authVC = AuthenticationViewController()
            navigationController?.pushViewController(authVC, animated: true)
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    #if DEBUG
    @objc private func resetAllDataTapped() {
        print("🔄 DEBUG: Reset all data tapped from Welcome screen")

        let alert = UIAlertController(
            title: "Reset All Data?",
            message: "This will clear all app data and you'll see this welcome screen again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            Task {
                do {
                    // Sign out from Supabase
                    try await SupabaseService.shared.signOut()
                    print("✅ Signed out from Supabase")
                } catch {
                    print("⚠️ Sign out error (may not be logged in): \(error)")
                }

                await MainActor.run {
                    // Clear all user data
                    DebugConfig.resetAllUserData()
                    print("✅ All data reset - you'll see the welcome screen on next launch")

                    // Show confirmation
                    let confirmAlert = UIAlertController(
                        title: "Reset Complete",
                        message: "All data has been cleared. Close and reopen the app to see the welcome screen.",
                        preferredStyle: .alert
                    )
                    confirmAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(confirmAlert, animated: true)
                }
            }
        })

        present(alert, animated: true)
    }
    #endif
}

// MARK: - Color Helper
private struct Color {
    let uiColor: UIColor

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.uiColor = UIColor(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}
