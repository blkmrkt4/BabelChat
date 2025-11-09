import UIKit
import AuthenticationServices

class AuthenticationViewController: UIViewController {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let appleSignInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    private let emailButton = UIButton(type: .system)
    private let dividerView = UIView()
    private let dividerLabel = UILabel()

    #if DEBUG
    private let debugLoginButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
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
        logoLabel.text = "LangChat"
        logoLabel.font = .systemFont(ofSize: 48, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        view.addSubview(logoLabel)

        // Tagline
        taglineLabel.text = "Connect Through Language"
        taglineLabel.font = .systemFont(ofSize: 20, weight: .medium)
        taglineLabel.textColor = .white.withAlphaComponent(0.9)
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 0
        view.addSubview(taglineLabel)

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

        dividerLabel.text = "or"
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
        emailButton.setTitle("Continue with Email", for: .normal)
        emailButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        emailButton.backgroundColor = .clear
        emailButton.setTitleColor(.white, for: .normal)
        emailButton.layer.cornerRadius = 25
        emailButton.layer.borderWidth = 2
        emailButton.layer.borderColor = UIColor.white.cgColor
        emailButton.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(emailButton)

        #if DEBUG
        // Reset button (development only) - appears at top
        resetButton.setTitle("🔄 Reset All Data", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        resetButton.backgroundColor = .systemRed.withAlphaComponent(0.8)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 25
        resetButton.addTarget(self, action: #selector(resetAllDataTapped), for: .touchUpInside)
        view.addSubview(resetButton)

        // Debug login button (development only)
        // Uses credentials from DebugConfig.swift - change them there if needed
        debugLoginButton.setTitle("🔧 DEV: Quick Login", for: .normal)
        debugLoginButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        debugLoginButton.backgroundColor = .systemOrange.withAlphaComponent(0.8)
        debugLoginButton.setTitleColor(.white, for: .normal)
        debugLoginButton.layer.cornerRadius = 25
        debugLoginButton.addTarget(self, action: #selector(debugLoginTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(debugLoginButton)
        #endif
    }

    private func setupConstraints() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
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

            // Logo - centered, upper third
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),

            // Tagline
            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            taglineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            taglineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Buttons at bottom
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),

            // Button heights
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            emailButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        #if DEBUG
        debugLoginButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugLoginButton.heightAnchor.constraint(equalToConstant: 50),

            // Reset button in top-right corner
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 180),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
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

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
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
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }

        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { [weak self, weak alert] _ in
            guard let email = alert?.textFields?[0].text,
                  let password = alert?.textFields?[1].text,
                  !email.isEmpty, !password.isEmpty else {
                let errorAlert = UIAlertController(title: "Error", message: "Please enter both email and password", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
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
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }

            self?.signUpWithEmail(email: email, password: password)
        })

        present(alert, animated: true)
    }

    private func signInWithEmail(email: String, password: String) {
        Task {
            do {
                try await SupabaseService.shared.signIn(email: email, password: password)
                print("✅ Email sign in successful!")

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
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Sign In Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    private func signUpWithEmail(email: String, password: String) {
        Task {
            do {
                try await SupabaseService.shared.signUp(email: email, password: password)
                print("✅ Email sign up successful!")

                await MainActor.run {
                    // Always start onboarding for new users
                    startOnboarding()
                }
            } catch {
                print("❌ Email sign up failed: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Sign Up Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    #if DEBUG
    @objc private func resetAllDataTapped() {
        print("🔄 DEBUG: Reset all data tapped")

        let alert = UIAlertController(
            title: "Reset All Data?",
            message: "This will sign you out and clear all app data. You'll see the full onboarding flow again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
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

                    // Reload the app to see welcome screen
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {

                        let welcomeVC = WelcomeViewController()
                        let navController = UINavigationController(rootViewController: welcomeVC)
                        window.rootViewController = navController

                        UIView.transition(with: window,
                                        duration: 0.3,
                                        options: .transitionCrossDissolve,
                                        animations: nil,
                                        completion: nil)

                        print("✅ App reset complete - showing welcome screen")
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    @objc private func debugLoginTapped() {
        print("🔧 DEBUG: Quick login tapped")

        Task {
            do {
                try await SupabaseService.shared.signIn(email: DebugConfig.testEmail, password: DebugConfig.testPassword)
                print("✅ DEBUG: Auto-login successful!")

                // Check if user has completed profile in Supabase
                let hasCompletedProfile = try await SupabaseService.shared.hasCompletedProfile()

                await MainActor.run {
                    if hasCompletedProfile {
                        print("✅ DEBUG: Profile found - going to main app")
                        transitionToMainApp()
                    } else {
                        print("⚠️ DEBUG: No profile found - starting onboarding")
                        startOnboarding()
                    }
                }
            } catch {
                print("❌ DEBUG: Auto-login failed: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Debug Login Failed",
                        message: "Could not sign in with test credentials: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    #endif

    private func startOnboarding() {
        onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator?.start()
    }

    private func transitionToMainApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let tabBarController = MainTabBarController()
            window.rootViewController = tabBarController
            UIView.transition(with: window,
                            duration: 0.5,
                            options: .transitionCrossDissolve,
                            animations: nil,
                            completion: nil)
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName

            print("✅ Apple Sign In successful!")
            print("User ID: \(userIdentifier)")
            print("Email: \(email ?? "not provided")")
            print("Name: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")

            // Save Apple user credentials
            UserDefaults.standard.set(userIdentifier, forKey: "userId")
            if let email = email {
                UserDefaults.standard.set(email, forKey: "email")
            }

            // TODO: Create Supabase user with Apple credentials
            // For now, just start onboarding
            UserDefaults.standard.set(true, forKey: "isUserSignedIn")
            startOnboarding()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign In failed: \(error.localizedDescription)")

        let alert = UIAlertController(
            title: "Sign In Failed",
            message: "Could not sign in with Apple. Please try again or use email sign in.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
