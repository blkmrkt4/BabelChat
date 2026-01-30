import UIKit
import ImageIO
import AuthenticationServices

class LandingViewController: UIViewController {

    // MARK: - Properties
    /// When true, shows only close button (for viewing from profile)
    var isViewingFromProfile = false

    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    private var separatorLine: UIView!
    private let taglineLabel2 = UILabel()
    private let buttonsStackView = UIStackView()
    private let signInWithAppleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    private let createAccountButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let dividerView = UIView()
    private let dividerLabel = UILabel()
    private var onboardingCoordinator: OnboardingCoordinator?

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

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Background image/GIF
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        // Try to load GIF first
        if let gifImage = loadGIF(named: "Language_Animation") {
            backgroundImageView.image = gifImage
        } else if let staticImage = UIImage(named: "language_background") {
            // Fallback to static image
            backgroundImageView.image = staticImage
        } else {
            // Final fallback: animated gradient
            setupAnimatedGradientBackground()
        }
        view.addSubview(backgroundImageView)

        // Dark overlay for better text visibility
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(overlayView)

        // Logo/App Name
        logoLabel.text = "Fluenca"
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
        view.addSubview(taglineLabel)

        // Thin separator line between taglines
        let separatorLine = UIView()
        separatorLine.backgroundColor = .white.withAlphaComponent(0.3)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)

        // Second tagline
        taglineLabel2.text = "tagline_2".localized
        taglineLabel2.font = .systemFont(ofSize: 15, weight: .regular)
        taglineLabel2.textColor = .white.withAlphaComponent(0.7)
        taglineLabel2.textAlignment = .center
        taglineLabel2.numberOfLines = 0
        taglineLabel2.lineBreakMode = .byWordWrapping
        view.addSubview(taglineLabel2)

        // Store separator for constraints
        self.separatorLine = separatorLine

        // Buttons stack
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 16
        buttonsStackView.distribution = .fillEqually
        view.addSubview(buttonsStackView)

        if isViewingFromProfile {
            // View-only mode: just show close button
            closeButton.setTitle("common_close".localized, for: .normal)
            closeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            closeButton.backgroundColor = .white
            closeButton.setTitleColor(.black, for: .normal)
            closeButton.layer.cornerRadius = 25
            closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            buttonsStackView.addArrangedSubview(closeButton)

            // Also add X button in top-right corner
            let xButton = UIButton(type: .system)
            xButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            xButton.tintColor = UIColor.white.withAlphaComponent(0.8)
            xButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            xButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(xButton)

            NSLayoutConstraint.activate([
                xButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                xButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                xButton.widthAnchor.constraint(equalToConstant: 32),
                xButton.heightAnchor.constraint(equalToConstant: 32)
            ])
        } else {
            // Normal sign-in mode
            // Sign in with Apple button (Apple requires this to be prominent)
            signInWithAppleButton.cornerRadius = 25
            signInWithAppleButton.addTarget(self, action: #selector(signInWithAppleTapped), for: .touchUpInside)
            buttonsStackView.addArrangedSubview(signInWithAppleButton)

            // Divider with "or" label
            dividerView.backgroundColor = .clear
            buttonsStackView.addArrangedSubview(dividerView)

            dividerLabel.text = "auth_or_divider".localized
            dividerLabel.font = .systemFont(ofSize: 14, weight: .medium)
            dividerLabel.textColor = .white.withAlphaComponent(0.8)
            dividerLabel.textAlignment = .center
            dividerView.addSubview(dividerLabel)

            // Create Account button
            createAccountButton.setTitle("auth_create_account".localized, for: .normal)
            createAccountButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            createAccountButton.backgroundColor = .white
            createAccountButton.setTitleColor(.systemIndigo, for: .normal)
            createAccountButton.layer.cornerRadius = 25
            createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
            buttonsStackView.addArrangedSubview(createAccountButton)

            // Sign In button
            signInButton.setTitle("auth_signin_button".localized, for: .normal)
            signInButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            signInButton.backgroundColor = .clear
            signInButton.setTitleColor(.white, for: .normal)
            signInButton.layer.cornerRadius = 25
            signInButton.layer.borderWidth = 2
            signInButton.layer.borderColor = UIColor.white.cgColor
            signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
            buttonsStackView.addArrangedSubview(signInButton)
        }
    }

    private func setupConstraints() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel2.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerLabel.translatesAutoresizingMaskIntoConstraints = false
        createAccountButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.translatesAutoresizingMaskIntoConstraints = false

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
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])

        if isViewingFromProfile {
            // Close button height
            NSLayoutConstraint.activate([
                closeButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        } else {
            // Sign-in button heights
            NSLayoutConstraint.activate([
                signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50),
                dividerView.heightAnchor.constraint(equalToConstant: 30),
                createAccountButton.heightAnchor.constraint(equalToConstant: 50),
                signInButton.heightAnchor.constraint(equalToConstant: 50),

                // Divider label (centered in divider view)
                dividerLabel.centerXAnchor.constraint(equalTo: dividerView.centerXAnchor),
                dividerLabel.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor)
            ])
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame if using fallback
        if let gradientLayer = backgroundImageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundImageView.bounds
        }
    }

    private func loadGIF(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            print("GIF not found: \(name)")
            return nil
        }

        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url) else {
            print("Failed to load GIF data")
            return nil
        }

        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            print("Failed to create image source")
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                // Get frame duration
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

        // If it's a single frame, return static image
        if images.count == 1 {
            return images.first
        }

        // Return animated image
        return UIImage.animatedImage(with: images, duration: duration)
    }

    private func setupAnimatedGradientBackground() {
        // Create a beautiful animated gradient as fallback
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

        // Animate the gradient
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

        // Update gradient frame
        DispatchQueue.main.async {
            gradientLayer.frame = self.backgroundImageView.bounds
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func signInWithAppleTapped() {
        print("Sign in with Apple tapped")

        // Disable button to prevent double-tap
        signInWithAppleButton.isEnabled = false

        Task {
            do {
                // Authenticate with Apple
                try await SupabaseService.shared.signInWithApple(from: self)
                print("✅ Signed in with Apple successfully!")

                // Get the authenticated user's ID from Supabase
                guard let userId = SupabaseService.shared.currentUserId else {
                    throw NSError(domain: "LandingViewController", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID after Apple sign in"])
                }

                // Save user ID and mark as signed in
                UserDefaults.standard.set(userId.uuidString, forKey: "userId")
                UserDefaults.standard.set(true, forKey: "isUserSignedIn")

                print("✅ User ID saved: \(userId.uuidString)")

                // Check if user profile exists
                do {
                    let profile = try await SupabaseService.shared.getCurrentProfile()
                    print("✅ User profile found, navigating to main app")
                    await MainActor.run { navigateToMainApp() }
                } catch {
                    // Profile doesn't exist - user needs to complete onboarding
                    print("⚠️ No profile found, starting onboarding")
                    await MainActor.run {
                        onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
                        onboardingCoordinator?.start()
                    }
                }

            } catch {
                await MainActor.run {
                    signInWithAppleButton.isEnabled = true

                    // Show error alert
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

    @objc private func createAccountTapped() {
        print("Create Account tapped")

        // Ask for email and password before starting onboarding
        let alert = UIAlertController(
            title: "auth_create_account".localized,
            message: "auth_enter_email_password".localized,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "auth_email_placeholder".localized
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        alert.addTextField { textField in
            textField.placeholder = "auth_password_placeholder".localized
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "auth_create_account".localized, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let email = alert?.textFields?[0].text, !email.isEmpty,
                  let password = alert?.textFields?[1].text, !password.isEmpty else { return }

            Task {
                do {
                    try await SupabaseService.shared.signUp(email: email, password: password)
                    print("✅ Account created for: \(email)")

                    await MainActor.run {
                        // Now start onboarding with an authenticated session
                        self.onboardingCoordinator = OnboardingCoordinator(navigationController: self.navigationController)
                        self.onboardingCoordinator?.start()
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = UIAlertController(
                            title: "auth_signup_failed".localized,
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    @objc private func signInTapped() {
        print("Sign In tapped")

        // Show email/password login dialog
        let alert = UIAlertController(
            title: "auth_sign_in".localized,
            message: "auth_enter_email_password".localized,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "auth_email_placeholder".localized
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        alert.addTextField { textField in
            textField.placeholder = "auth_password_placeholder".localized
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "auth_sign_in".localized, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let email = alert?.textFields?[0].text, !email.isEmpty,
                  let password = alert?.textFields?[1].text, !password.isEmpty else { return }

            self.signInButton.isEnabled = false
            self.signInButton.alpha = 0.6

            Task {
                do {
                    try await SupabaseService.shared.signIn(email: email, password: password)
                    print("✅ Signed in: \(email)")

                    // Check if profile is complete
                    let hasProfile = try await SupabaseService.shared.hasCompletedProfile()

                    await MainActor.run {
                        self.signInButton.isEnabled = true
                        self.signInButton.alpha = 1.0

                        if hasProfile {
                            self.navigateToMainApp()
                        } else {
                            // Profile incomplete - go through onboarding
                            self.onboardingCoordinator = OnboardingCoordinator(navigationController: self.navigationController)
                            self.onboardingCoordinator?.start()
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.signInButton.isEnabled = true
                        self.signInButton.alpha = 1.0

                        let errorAlert = UIAlertController(
                            title: "auth_signin_failed".localized,
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Helper Methods

    /// Navigate to the main app after successful sign in
    private func navigateToMainApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Could not find window for navigation")
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