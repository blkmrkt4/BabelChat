import UIKit

class BaseOnboardingViewController: UIViewController {

    // MARK: - UI Components
    let progressView = UIProgressView(progressViewStyle: .bar)
    let headerView = UIView()  // Container for back button and title
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()  // Optional, hidden by default in compact mode
    let scrollView = UIScrollView()  // Scroll view for keyboard avoidance
    let scrollContentView = UIView()  // Content container inside scroll view
    let contentView = UIView()
    let continueButton = UIButton(type: .system)

    // MARK: - Properties
    weak var delegate: OnboardingStepDelegate?
    var step: OnboardingStep = .name
    var keyboardHeight: CGFloat = 0
    var useCompactTitle: Bool = true  // Default to compact title layout

    // Constraint references for keyboard handling
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    private var scrollViewBottomConstraint: NSLayoutConstraint?

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

        // Header view (contains back button and title)
        view.addSubview(headerView)

        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.contentHorizontalAlignment = .left
        headerView.addSubview(backButton)

        // Title (compact: inline with back button)
        titleLabel.font = useCompactTitle ? .systemFont(ofSize: 20, weight: .semibold) : .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        headerView.addSubview(titleLabel)

        // Subtitle (hidden in compact mode)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.7)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isHidden = useCompactTitle
        view.addSubview(subtitleLabel)

        // Scroll view for keyboard avoidance
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        // Scroll content view
        scrollView.addSubview(scrollContentView)

        // Content view (for subclasses to add their content)
        scrollContentView.addSubview(contentView)

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
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        // Create bottom constraint reference for keyboard handling
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16)

        NSLayoutConstraint.activate([
            // Progress view
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            // Header view (contains back button + title)
            headerView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            // Back button (left side of header)
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // Title (inline with back button)
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -48),  // Space for reset button
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Subtitle (below header, if visible)
            subtitleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: useCompactTitle ? headerView.bottomAnchor : subtitleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollViewBottomConstraint!,

            // Scroll content view (fills scroll view width, minimum height = scroll view height)
            scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollContentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),

            // Content view (inside scroll content with padding)
            contentView.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -24),

            // Continue button
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButtonBottomConstraint!,
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        #if DEBUG
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
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
        let safeAreaBottom = view.safeAreaInsets.bottom

        // Move continue button above keyboard
        UIView.animate(withDuration: duration) {
            self.continueButtonBottomConstraint?.constant = -self.keyboardHeight + safeAreaBottom - 8
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        // Reset continue button position
        UIView.animate(withDuration: duration) {
            self.continueButtonBottomConstraint?.constant = -16
            self.view.layoutIfNeeded()
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