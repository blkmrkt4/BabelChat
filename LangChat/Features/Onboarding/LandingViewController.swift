import UIKit
import ImageIO

class LandingViewController: UIViewController {

    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let createAccountButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
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
        buttonsStackView.distribution = .fillEqually
        view.addSubview(buttonsStackView)

        // Create Account button
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        createAccountButton.backgroundColor = .white
        createAccountButton.setTitleColor(.systemIndigo, for: .normal)
        createAccountButton.layer.cornerRadius = 25
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(createAccountButton)

        // Sign In button
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        signInButton.backgroundColor = .clear
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.cornerRadius = 25
        signInButton.layer.borderWidth = 2
        signInButton.layer.borderColor = UIColor.white.cgColor
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(signInButton)
    }

    private func setupConstraints() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
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
            createAccountButton.heightAnchor.constraint(equalToConstant: 50),
            signInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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

    @objc private func createAccountTapped() {
        print("Create Account tapped")
        // Start onboarding flow
        onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator?.start()
    }

    @objc private func signInTapped() {
        print("Sign In tapped")

        // Disable button to prevent double-tap
        signInButton.isEnabled = false
        signInButton.alpha = 0.6

        // Authenticate first, then navigate
        Task {
            do {
                #if DEBUG
                // DEVELOPMENT ONLY: Auto-login with test credentials
                // TODO: Remove this before production release
                let testEmail = "test@langchat.com"
                let testPassword = "testpassword123"

                print("🔐 [DEBUG] Attempting to sign in with: \(testEmail)")

                // Just try to sign in - don't attempt sign up
                try await SupabaseService.shared.signIn(email: testEmail, password: testPassword)
                print("✅ [DEBUG] Signed in successfully!")
                #else
                // PRODUCTION: User must sign in manually
                print("⚠️ Auto-login disabled in production build")
                return
                #endif

                // Get the authenticated user's ID from Supabase
                guard let userId = SupabaseService.shared.currentUserId else {
                    throw NSError(domain: "LandingViewController", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID after sign in"])
                }

                // Save user ID and mark as signed in
                UserDefaults.standard.set(userId.uuidString, forKey: "userId")
                UserDefaults.standard.set(true, forKey: "isUserSignedIn")

                print("✅ User ID saved: \(userId.uuidString)")

                // Navigate to main app on main thread
                await MainActor.run {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {

                        // Create Language Lab in navigation controller
                        let languageLabVC = LanguageLabViewController()
                        let navController = UINavigationController(rootViewController: languageLabVC)

                        // Create tab bar with Language Lab as first tab
                        let tabBarController = MainTabBarController()

                        // Insert Language Lab as first tab
                        var viewControllers = tabBarController.viewControllers ?? []
                        viewControllers.insert(navController, at: 0)
                        tabBarController.viewControllers = viewControllers
                        tabBarController.selectedIndex = 0

                        // Update tab bar item for Language Lab
                        navController.tabBarItem = UITabBarItem(
                            title: "Lab",
                            image: UIImage(systemName: "flask"),
                            selectedImage: UIImage(systemName: "flask.fill")
                        )

                        // Set as root with animation
                        window.rootViewController = tabBarController

                        UIView.transition(with: window,
                                        duration: 0.5,
                                        options: .transitionCrossDissolve,
                                        animations: nil,
                                        completion: nil)
                    }
                }
            } catch {
                // Show error alert on main thread
                await MainActor.run {
                    signInButton.isEnabled = true
                    signInButton.alpha = 1.0

                    let alert = UIAlertController(
                        title: "Sign In Failed",
                        message: "Could not authenticate: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
}