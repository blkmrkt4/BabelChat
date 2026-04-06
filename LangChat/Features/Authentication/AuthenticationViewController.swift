import UIKit
import AuthenticationServices

class AuthenticationViewController: UIViewController {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    private var separatorLine: UIView!
    private let taglineLabel2 = UILabel()
    private let buttonsStackView = UIStackView()
    private let appleSignInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    private let emailButton = UIButton(type: .system)
    private let dividerView = UIView()
    private let dividerLabel = UILabel()

    #if DEBUG
    private let devLoginButton = UIButton(type: .system)
    private let freshStartButton = UIButton(type: .system)
    private let debugStackView = UIStackView()
    #endif

    private var onboardingCoordinator: OnboardingCoordinator?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Background image/GIF (same as LandingViewController)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        // Try to load GIF first
        if let gifImage = loadGIF(named: "Language_Animation") {
            backgroundImageView.image = gifImage
        } else if let staticImage = UIImage(named: "language_background") {
            backgroundImageView.image = staticImage
        } else {
            setupAnimatedGradientBackground()
        }
        view.addSubview(backgroundImageView)

        // Dark overlay for better text visibility
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(overlayView)

        // Logo/App Name
        logoLabel.text = "Language Match"
        logoLabel.font = .systemFont(ofSize: 48, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        view.addSubview(logoLabel)

        // Tagline
        taglineLabel.text = "tagline_1".localized
        taglineLabel.font = .systemFont(ofSize: 18, weight: .medium)
        taglineLabel.textColor = .white.withAlphaComponent(0.9)
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 0
        taglineLabel.lineBreakMode = .byWordWrapping
        taglineLabel.adjustsFontSizeToFitWidth = false
        view.addSubview(taglineLabel)

        // Thin separator line between taglines
        let separatorLine = UIView()
        separatorLine.backgroundColor = .white.withAlphaComponent(0.3)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        self.separatorLine = separatorLine

        // Second tagline
        taglineLabel2.text = "tagline_2".localized
        taglineLabel2.font = .systemFont(ofSize: 18, weight: .medium)
        taglineLabel2.textColor = .white.withAlphaComponent(0.7)
        taglineLabel2.textAlignment = .center
        taglineLabel2.numberOfLines = 0
        taglineLabel2.lineBreakMode = .byWordWrapping
        taglineLabel2.adjustsFontSizeToFitWidth = false
        view.addSubview(taglineLabel2)

        // Buttons stack
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 16
        buttonsStackView.distribution = .fill
        view.addSubview(buttonsStackView)

        // Apple Sign In button
        appleSignInButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        appleSignInButton.cornerRadius = 25
        buttonsStackView.addArrangedSubview(appleSignInButton)

        // Divider
        let dividerContainer = UIView()
        dividerContainer.translatesAutoresizingMaskIntoConstraints = false

        dividerView.backgroundColor = .white.withAlphaComponent(0.3)
        dividerContainer.addSubview(dividerView)

        dividerLabel.text = "auth_or_divider".localized
        dividerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dividerLabel.textColor = .white.withAlphaComponent(0.7)
        dividerLabel.textAlignment = .center
        dividerLabel.backgroundColor = UIColor.clear
        dividerContainer.addSubview(dividerLabel)

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dividerContainer.heightAnchor.constraint(equalToConstant: 30),

            dividerView.centerYAnchor.constraint(equalTo: dividerContainer.centerYAnchor),
            dividerView.leadingAnchor.constraint(equalTo: dividerContainer.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: dividerContainer.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            dividerLabel.centerXAnchor.constraint(equalTo: dividerContainer.centerXAnchor),
            dividerLabel.centerYAnchor.constraint(equalTo: dividerContainer.centerYAnchor),
            dividerLabel.widthAnchor.constraint(equalToConstant: 40)
        ])

        buttonsStackView.addArrangedSubview(dividerContainer)

        // Email Sign In button
        emailButton.setTitle("auth_continue_email".localized, for: .normal)
        emailButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        emailButton.backgroundColor = .clear
        emailButton.setTitleColor(.white, for: .normal)
        emailButton.layer.cornerRadius = 25
        emailButton.layer.borderWidth = 2
        emailButton.layer.borderColor = UIColor.white.cgColor
        emailButton.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(emailButton)

        #if DEBUG
        // Dev Login — triggers Apple Sign In for real account access
        devLoginButton.setTitle("Dev Login", for: .normal)
        devLoginButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        devLoginButton.setTitleColor(.systemBlue.withAlphaComponent(0.6), for: .normal)
        devLoginButton.addTarget(self, action: #selector(devLoginTapped), for: .touchUpInside)

        // Fresh Start — resets everything and creates a temp account for onboarding
        freshStartButton.setTitle("Fresh Start", for: .normal)
        freshStartButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        freshStartButton.setTitleColor(.systemOrange.withAlphaComponent(0.6), for: .normal)
        freshStartButton.addTarget(self, action: #selector(freshStartTapped), for: .touchUpInside)

        debugStackView.axis = .horizontal
        debugStackView.spacing = 24
        debugStackView.distribution = .fillEqually
        debugStackView.addArrangedSubview(devLoginButton)
        debugStackView.addArrangedSubview(freshStartButton)
        view.addSubview(debugStackView)
        #endif
    }

    private func setupConstraints() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel2.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        appleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        emailButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Background image - full screen
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Overlay - full screen
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Logo - centered, moved up (halfway between original and top)
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),

            // Tagline - underneath logo
            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 16),
            taglineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            taglineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Separator line between taglines
            separatorLine.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            // Second tagline - underneath separator
            taglineLabel2.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 12),
            taglineLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            taglineLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Buttons at bottom
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),

            // Button heights
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            emailButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        #if DEBUG
        debugStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugStackView.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 16),
            debugStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            debugStackView.widthAnchor.constraint(equalToConstant: 200)
        ])
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame if using fallback
        if let gradientLayer = backgroundImageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundImageView.bounds
        }
    }

    // MARK: - Background Helper Methods (copied from LandingViewController)
    private func loadGIF(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += frameDuration
                }
            }
        }

        if images.isEmpty {
            return nil
        }

        if images.count == 1 {
            return images.first
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    private func setupAnimatedGradientBackground() {
        backgroundImageView.backgroundColor = .systemIndigo

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1).cgColor,
            UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1).cgColor,
            UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1).cgColor,
            UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.25, 0.75, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundImageView.layer.insertSublayer(gradientLayer, at: 0)

        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [
            UIColor(red: 0.4, green: 0.3, blue: 0.6, alpha: 1).cgColor,
            UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1).cgColor,
            UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 1).cgColor,
            UIColor(red: 0.5, green: 0.4, blue: 0.6, alpha: 1).cgColor
        ]
        animation.duration = 5.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")

        DispatchQueue.main.async {
            gradientLayer.frame = self.backgroundImageView.bounds
        }
    }

    // MARK: - Actions
    @objc private func appleSignInTapped() {
        print("🍎 Apple Sign In tapped")

        // Track Apple Sign In started
        AnalyticsService.shared.track(.loginStarted, properties: ["method": "apple"])

        Task {
            do {
                // Use SupabaseService to handle Apple Sign In with proper Supabase Auth integration
                try await SupabaseService.shared.signInWithApple(from: self)
                print("✅ Apple Sign In with Supabase successful!")

                // Register user in RevenueCat so they appear in the dashboard
                if let userId = SupabaseService.shared.currentUserId?.uuidString {
                    SubscriptionService.shared.logIn(userId: userId)
                }

                // Track successful login
                AnalyticsService.shared.track(.loginCompleted, properties: ["method": "apple"])

                // Check if user has completed profile in Supabase
                let hasCompletedProfile = try await SupabaseService.shared.hasCompletedProfile()

                await MainActor.run {
                    if hasCompletedProfile {
                        // User already has profile, go to main app
                        print("✅ Profile found - going to main app")
                        transitionToMainApp()
                    } else {
                        // Start onboarding
                        print("⚠️ No profile found - starting onboarding")
                        startOnboarding()
                    }
                }
            } catch SignInWithAppleError.userCancelled {
                // User cancelled - don't show error
                print("ℹ️ Apple Sign In cancelled by user")
            } catch let signInError as SignInWithAppleError {
                // Handle specific Sign in with Apple errors
                print("❌ Apple Sign In error: \(signInError)")

                // Track login failure
                AnalyticsService.shared.track(.loginFailed, properties: [
                    "method": "apple",
                    "error": signInError.errorDescription ?? "Unknown"
                ])

                await MainActor.run {
                    let message: String
                    switch signInError {
                    case .invalidCredential, .invalidIdentityToken, .missingIdentityToken:
                        message = "Unable to verify your Apple ID. Please try again."
                    case .missingNonce:
                        message = "A security error occurred. Please try again."
                    case .authorizationFailed(let underlying):
                        message = "Authorization failed: \(underlying.localizedDescription)"
                    case .invalidResponse:
                        message = "Received an invalid response from Apple. Please try again."
                    case .notHandled:
                        message = "Sign in was not handled. Please try again."
                    case .unknown(let underlying):
                        message = "An unexpected error occurred: \(underlying.localizedDescription)"
                    case .userCancelled:
                        return // Should not reach here
                    }

                    let alert = UIAlertController(
                        title: "Sign In Failed",
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                // Handle other errors (likely Supabase auth errors)
                print("❌ Sign In failed: \(error)")

                // Track login failure
                AnalyticsService.shared.track(.loginFailed, properties: [
                    "method": "apple",
                    "error": error.localizedDescription
                ])

                await MainActor.run {
                    // Check if it's a network error
                    let nsError = error as NSError
                    let message: String
                    if nsError.domain == NSURLErrorDomain {
                        message = "Unable to connect to the server. Please check your internet connection and try again."
                    } else {
                        message = "Could not complete sign in: \(error.localizedDescription)"
                    }

                    let alert = UIAlertController(
                        title: "Sign In Failed",
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func emailSignInTapped() {
        print("📧 Email Sign In tapped")

        // Show email/password input dialog
        let alert = UIAlertController(
            title: "Sign In with Email",
            message: "Enter your email and password",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "contact_email".localized
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }

        alert.addTextField { textField in
            textField.placeholder = "auth_password_placeholder".localized
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { [weak self, weak alert] _ in
            guard let email = alert?.textFields?[0].text,
                  let password = alert?.textFields?[1].text,
                  !email.isEmpty, !password.isEmpty else {
                let errorAlert = UIAlertController(title: "Error", message: "Please enter both email and password", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                self?.present(errorAlert, animated: true)
                return
            }

            self?.signInWithEmail(email: email, password: password)
        })

        alert.addAction(UIAlertAction(title: "Create Account", style: .default) { [weak self, weak alert] _ in
            guard let email = alert?.textFields?[0].text,
                  let password = alert?.textFields?[1].text,
                  !email.isEmpty, !password.isEmpty else {
                let errorAlert = UIAlertController(title: "Error", message: "Please enter both email and password", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                self?.present(errorAlert, animated: true)
                return
            }

            self?.signUpWithEmail(email: email, password: password)
        })

        present(alert, animated: true)
    }

    private func signInWithEmail(email: String, password: String) {
        // Track login attempt
        AnalyticsService.shared.track(.loginStarted, properties: ["method": "email"])

        Task {
            do {
                try await SupabaseService.shared.signIn(email: email, password: password)
                print("✅ Email sign in successful!")

                // Register user in RevenueCat so they appear in the dashboard
                if let userId = SupabaseService.shared.currentUserId?.uuidString {
                    SubscriptionService.shared.logIn(userId: userId)
                }

                // Track successful login
                AnalyticsService.shared.track(.loginCompleted, properties: ["method": "email"])

                // Check if user has completed profile in Supabase
                let hasCompletedProfile = try await SupabaseService.shared.hasCompletedProfile()

                await MainActor.run {
                    if hasCompletedProfile {
                        // User already has profile, go to main app
                        print("✅ Profile found - going to main app")
                        transitionToMainApp()
                    } else {
                        // Start onboarding
                        print("⚠️ No profile found - starting onboarding")
                        startOnboarding()
                    }
                }
            } catch {
                print("❌ Email sign in failed: \(error)")

                // Track login failure
                AnalyticsService.shared.track(.loginFailed, properties: [
                    "method": "email",
                    "error": error.localizedDescription
                ])

                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Sign In Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    private func signUpWithEmail(email: String, password: String) {
        // Track signup attempt
        AnalyticsService.shared.track(.signUpStarted, properties: ["method": "email"])
        Task {
            do {
                try await SupabaseService.shared.signUp(email: email, password: password)
                print("✅ Email sign up successful!")

                // Register user in RevenueCat so they appear in the dashboard
                if let userId = SupabaseService.shared.currentUserId?.uuidString {
                    SubscriptionService.shared.logIn(userId: userId)
                }

                // Track successful signup
                AnalyticsService.shared.track(.signUpCompleted, properties: ["method": "email"])

                await MainActor.run {
                    // Always start onboarding for new users
                    startOnboarding()
                }
            } catch {
                print("❌ Email sign up failed: \(error)")

                // Track signup failure
                AnalyticsService.shared.track(.signUpFailed, properties: [
                    "method": "email",
                    "error": error.localizedDescription
                ])

                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Sign Up Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    #if DEBUG
    @objc private func devLoginTapped() {
        print("🔧 DEBUG: Dev Login tapped — launching Apple Sign In")
        appleSignInTapped()
    }

    @objc private func freshStartTapped() {
        print("🔧 DEBUG: Fresh Start tapped")

        Task {
            // 1. Sign out of any current session
            do {
                try await SupabaseService.shared.signOut()
                print("✅ DEBUG: Signed out from Supabase")
            } catch {
                print("⚠️ DEBUG: Sign out error (may not be logged in): \(error)")
            }

            await MainActor.run {
                // 2. Clear all local state
                DebugConfig.resetAllUserData()
            }

            // 3. Create a fresh temp account
            let shortUUID = UUID().uuidString.prefix(8).lowercased()
            let tempEmail = "test-\(shortUUID)@byzyb.ai"
            let tempPassword = DebugConfig.devFreshStartPassword

            do {
                try await SupabaseService.shared.signUp(email: tempEmail, password: tempPassword)
                print("✅ DEBUG: Fresh account created — \(tempEmail)")

                // Sign in immediately — signUp may not establish a session
                // if email confirmations are enabled
                if SupabaseService.shared.currentUserId == nil {
                    print("⚠️ DEBUG: No session after signUp, signing in explicitly...")
                    try await SupabaseService.shared.signIn(email: tempEmail, password: tempPassword)
                    print("✅ DEBUG: Signed in as \(tempEmail), userId: \(SupabaseService.shared.currentUserId?.uuidString ?? "nil")")
                }

                await MainActor.run {
                    // 4. Route to onboarding
                    startOnboarding()
                }
            } catch {
                print("❌ DEBUG: Fresh Start signup failed: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Fresh Start Failed",
                        message: "Could not create temp account: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    #endif

    private func startOnboarding() {
        // Ensure we have a navigation controller for onboarding
        guard let navController = navigationController else {
            print("❌ No navigation controller for onboarding - creating one")
            // Create a new navigation controller if none exists
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
                print("❌ Could not find window for onboarding")
                return
            }

            let newNavController = UINavigationController(rootViewController: self)
            window.rootViewController = newNavController
            onboardingCoordinator = OnboardingCoordinator(navigationController: newNavController)
            onboardingCoordinator?.start()
            return
        }

        onboardingCoordinator = OnboardingCoordinator(navigationController: navController)
        onboardingCoordinator?.start()
    }

    private func transitionToMainApp() {
        // Find the key window - important for iPad with multiple windows
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            print("❌ Could not find window for transition")
            return
        }

        let tabBarController = MainTabBarController()
        window.rootViewController = tabBarController
        UIView.transition(with: window,
                        duration: 0.5,
                        options: .transitionCrossDissolve,
                        animations: nil,
                        completion: nil)
    }
}

// Note: ASAuthorizationControllerDelegate is now handled by SignInWithAppleService
// which is called via SupabaseService.shared.signInWithApple(from:)
// This ensures proper Supabase Auth integration with Apple Sign In
