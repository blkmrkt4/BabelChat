import UIKit

/// Onboarding step that requires users to accept Terms of Service and Privacy Policy
/// before they can proceed with creating an account.
class TermsAcceptanceViewController: BaseOnboardingViewController {

    private let contentStack = UIStackView()

    private let termsCheckbox = CheckboxButton()
    private let privacyCheckbox = CheckboxButton()
    private let ageCheckbox = CheckboxButton()

    private let termsLinkButton = UIButton(type: .system)
    private let eulaLinkButton = UIButton(type: .system)
    private let privacyLinkButton = UIButton(type: .system)
    private let communityGuidelinesButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func configure() {
        super.configure()

        step = .termsAcceptance
        setTitle("terms_acceptance_title".localized)

        setupContent()
        updateAcceptButtonState()
    }

    private func setupContent() {
        // Content stack for checkboxes and links
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        // Description label
        let descriptionLabel = UILabel()
        descriptionLabel.text = "terms_acceptance_description".localized
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .white.withAlphaComponent(0.8)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        // Terms & EULA checkbox
        termsCheckbox.setTitle("terms_eula_checkbox_label".localized, for: .normal)
        termsCheckbox.addTarget(self, action: #selector(checkboxChanged), for: .touchUpInside)

        // Privacy checkbox
        privacyCheckbox.setTitle("privacy_checkbox_label".localized, for: .normal)
        privacyCheckbox.addTarget(self, action: #selector(checkboxChanged), for: .touchUpInside)

        // Age checkbox
        ageCheckbox.setTitle("age_checkbox_label".localized, for: .normal)
        ageCheckbox.addTarget(self, action: #selector(checkboxChanged), for: .touchUpInside)

        // Link buttons
        setupLinkButton(termsLinkButton, title: "view_terms_of_service".localized, action: #selector(viewTermsTapped))
        setupLinkButton(eulaLinkButton, title: "view_eula".localized, action: #selector(viewEulaTapped))
        setupLinkButton(privacyLinkButton, title: "view_privacy_policy".localized, action: #selector(viewPrivacyTapped))
        setupLinkButton(communityGuidelinesButton, title: "view_community_guidelines".localized, action: #selector(viewGuidelinesTapped))

        // Add to content stack
        contentStack.addArrangedSubview(descriptionLabel)

        // Spacer
        let spacer1 = UIView()
        spacer1.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(spacer1)

        // Checkboxes
        contentStack.addArrangedSubview(termsCheckbox)
        contentStack.addArrangedSubview(privacyCheckbox)
        contentStack.addArrangedSubview(ageCheckbox)

        // Spacer
        let spacer2 = UIView()
        spacer2.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer2)

        // Links
        contentStack.addArrangedSubview(termsLinkButton)
        contentStack.addArrangedSubview(eulaLinkButton)
        contentStack.addArrangedSubview(privacyLinkButton)
        contentStack.addArrangedSubview(communityGuidelinesButton)

        // Add to the base class contentView
        contentView.addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    private func setupLinkButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func updateAcceptButtonState() {
        let allChecked = termsCheckbox.isChecked && privacyCheckbox.isChecked && ageCheckbox.isChecked
        updateContinueButton(enabled: allChecked)
    }

    // MARK: - Actions

    @objc private func checkboxChanged() {
        updateAcceptButtonState()
    }

    override func continueButtonTapped() {
        // Record acceptance timestamp
        let acceptanceDate = Date()
        UserDefaults.standard.set(acceptanceDate, forKey: "termsAcceptedDate")
        UserDefaults.standard.set(true, forKey: "termsAccepted")

        // Save to Supabase asynchronously (if authenticated)
        Task {
            await saveTermsAcceptanceToSupabase(acceptedAt: acceptanceDate)
        }

        // Proceed to next step
        delegate?.didCompleteStep(withData: acceptanceDate)
    }

    @objc private func viewTermsTapped() {
        showDocument(title: "terms_of_service_title".localized, markdownFile: "TermsOfService")
    }

    @objc private func viewEulaTapped() {
        showDocument(title: "eula_title".localized, markdownFile: "EULA")
    }

    @objc private func viewPrivacyTapped() {
        showDocument(title: "privacy_policy_title".localized, markdownFile: "PrivacyPolicy")
    }

    @objc private func viewGuidelinesTapped() {
        showDocument(title: "community_guidelines_title".localized, markdownFile: "CommunityGuidelines")
    }

    private func showDocument(title: String, markdownFile: String) {
        let documentVC = DocumentViewerViewController(title: title, markdownFileName: markdownFile)
        let navController = UINavigationController(rootViewController: documentVC)
        present(navController, animated: true)
    }

    private func saveTermsAcceptanceToSupabase(acceptedAt: Date) async {
        // This will be called later when user completes authentication
        // For now, just store locally
        print("Terms accepted at: \(acceptedAt)")
    }
}

// MARK: - CheckboxButton

class CheckboxButton: UIButton {
    var isChecked: Bool = false {
        didSet {
            updateCheckboxUI()
        }
    }

    private let checkboxImageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Checkbox image
        checkboxImageView.contentMode = .scaleAspectFit
        checkboxImageView.tintColor = .systemBlue
        addSubview(checkboxImageView)

        // Label - use white for dark onboarding theme
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.numberOfLines = 0
        addSubview(label)

        checkboxImageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            checkboxImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkboxImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxImageView.widthAnchor.constraint(equalToConstant: 28),
            checkboxImageView.heightAnchor.constraint(equalToConstant: 28),

            label.leadingAnchor.constraint(equalTo: checkboxImageView.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        updateCheckboxUI()

        addTarget(self, action: #selector(toggleChecked), for: .touchUpInside)
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        label.text = title
    }

    @objc private func toggleChecked() {
        isChecked.toggle()
        sendActions(for: .valueChanged)
    }

    private func updateCheckboxUI() {
        let imageName = isChecked ? "checkmark.square.fill" : "square"
        checkboxImageView.image = UIImage(systemName: imageName)
        checkboxImageView.tintColor = isChecked ? .systemBlue : .white.withAlphaComponent(0.5)
    }
}

// MARK: - DocumentViewerViewController

class DocumentViewerViewController: UIViewController {
    private let textView = UITextView()
    private let documentTitle: String
    private let markdownFileName: String

    init(title: String, markdownFileName: String) {
        self.documentTitle = title
        self.markdownFileName = markdownFileName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDocument()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = documentTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )

        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        view.addSubview(textView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadDocument() {
        if let path = Bundle.main.path(forResource: markdownFileName, ofType: "md"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            // Simple markdown to attributed string conversion
            textView.text = content
        } else {
            textView.text = "error_document_not_found".localized
        }
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
