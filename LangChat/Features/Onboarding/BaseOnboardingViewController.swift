import UIKit

class BaseOnboardingViewController: UIViewController {

    // MARK: - UI Components
    let progressView = UIProgressView(progressViewStyle: .bar)
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let contentView = UIView()
    let continueButton = UIButton(type: .system)

    // MARK: - Properties
    weak var delegate: OnboardingStepDelegate?
    var step: OnboardingStep = .name
    var keyboardHeight: CGFloat = 0

    #if DEBUG
    private let resetButton = UIButton(type: .system)
    #endif

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📍 BaseOnboardingViewController(\(type(of: self))): viewDidLoad START")
        print("📍 Adding ripple background...")
        addRippleBackground()
        print("📍 Setting up views...")
        setupViews()
        print("📍 Setting up constraints...")
        setupConstraints()
        print("📍 Setting up keyboard observers...")
        setupKeyboardObservers()
        print("📍 Calling configure...")
        configure()
        print("📍 BaseOnboardingViewController(\(type(of: self))): viewDidLoad END")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateProgress()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupViews() {
        // Background will be set by ripple background
        view.backgroundColor = .clear

        // Force dark appearance for better contrast with ripple background
        overrideUserInterfaceStyle = .dark

        // Progress view
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        view.addSubview(progressView)

        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // Title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)

        // Content view (for subclasses to add their content)
        view.addSubview(contentView)

        // Continue button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        continueButton.layer.cornerRadius = 25
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        view.addSubview(continueButton)

        #if DEBUG
        // Reset button (development only)
        resetButton.setTitle("🔄", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        resetButton.backgroundColor = .systemRed.withAlphaComponent(0.8)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 20
        resetButton.addTarget(self, action: #selector(resetAllDataTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        #endif

        updateContinueButton(enabled: false)
    }

    private func setupConstraints() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Progress view
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            // Back button
            backButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // Title
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Content view
            contentView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -24),

            // Continue button
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        #if DEBUG
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resetButton.widthAnchor.constraint(equalToConstant: 40),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        #endif
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Configuration
    func configure() {
        // Override in subclasses
    }

    func updateProgress() {
        progressView.setProgress(step.progress, animated: true)
    }

    func updateContinueButton(enabled: Bool) {
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled ? .systemBlue : .systemGray4
    }

    func setTitle(_ title: String, subtitle: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        delegate?.didRequestPreviousStep()
    }

    @objc func continueButtonTapped() {
        // Override in subclasses
    }

    #if DEBUG
    @objc private func resetAllDataTapped() {
        print("🔄 DEBUG: Reset tapped from onboarding screen")

        let alert = UIAlertController(
            title: "Reset All Data?",
            message: "This will sign you out and take you back to the welcome screen.",
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

                    // Navigate back to welcome screen
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

                        print("✅ Reset complete - showing welcome screen")
                    }
                }
            }
        })

        present(alert, animated: true)
    }
    #endif

    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        keyboardHeight = keyboardFrame.height

        UIView.animate(withDuration: duration) {
            self.continueButton.transform = CGAffineTransform(translationX: 0, y: -self.keyboardHeight + self.view.safeAreaInsets.bottom)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.continueButton.transform = .identity
        }
    }

    // MARK: - Validation Helpers
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPhoneNumber(_ phone: String) -> Bool {
        // Remove spaces, dashes, parentheses
        let cleanPhone = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Check if it has at least 10 digits (including country code)
        let digitCount = cleanPhone.filter { $0.isNumber }.count
        return digitCount >= 10 && digitCount <= 15
    }
}