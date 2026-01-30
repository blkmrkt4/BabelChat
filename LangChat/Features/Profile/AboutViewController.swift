import UIKit

class AboutViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "About"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        setupContent()
    }

    private func setupContent() {
        // App icon
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "globe.americas.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)

        // App name
        let nameLabel = UILabel()
        nameLabel.text = "Fluenca"
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)

        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let versionLabel = UILabel()
        versionLabel.text = "Version \(version) (\(build))"
        versionLabel.font = .systemFont(ofSize: 16)
        versionLabel.textColor = .secondaryLabel
        versionLabel.textAlignment = .center
        contentView.addSubview(versionLabel)

        // Description
        let descriptionLabel = UILabel()
        descriptionLabel.text = """
        Connect with language learners around the world.
        Practice conversations with native speakers.
        Learn naturally through real interactions.
        """
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .label
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)

        // Links section
        let linksStack = UIStackView()
        linksStack.axis = .vertical
        linksStack.spacing = 16
        linksStack.distribution = .fillEqually
        contentView.addSubview(linksStack)

        let linkButtons = [
            ("Terms of Service", #selector(showTerms)),
            ("Privacy Policy", #selector(showPrivacy)),
            ("Acknowledgments", #selector(showAcknowledgments)),
            ("Rate on App Store", #selector(rateApp)),
            ("Contact Support", #selector(contactSupport))
        ]

        for (title, action) in linkButtons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17)
            button.addTarget(self, action: action, for: .touchUpInside)
            linksStack.addArrangedSubview(button)
        }

        // Copyright
        let copyrightLabel = UILabel()
        copyrightLabel.text = "auto_2025_fluenca_all_rights_reserved".localized
        copyrightLabel.font = .systemFont(ofSize: 14)
        copyrightLabel.textColor = .tertiaryLabel
        copyrightLabel.textAlignment = .center
        contentView.addSubview(copyrightLabel)

        // Layout
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        linksStack.translatesAutoresizingMaskIntoConstraints = false
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            versionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 32),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            linksStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            linksStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
            linksStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60),

            copyrightLabel.topAnchor.constraint(equalTo: linksStack.bottomAnchor, constant: 40),
            copyrightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            copyrightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            copyrightLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    @objc private func showTerms() {
        let documentVC = DocumentViewerViewController(title: "terms_of_service_title".localized, markdownFileName: "TermsOfService")
        let navController = UINavigationController(rootViewController: documentVC)
        present(navController, animated: true)
    }

    @objc private func showPrivacy() {
        let documentVC = DocumentViewerViewController(title: "privacy_policy_title".localized, markdownFileName: "PrivacyPolicy")
        let navController = UINavigationController(rootViewController: documentVC)
        present(navController, animated: true)
    }

    @objc private func showAcknowledgments() {
        let alert = UIAlertController(
            title: "Acknowledgments",
            message: "Fluenca uses the following open source libraries:\n\n• Supabase Swift SDK\n• RevenueCat Purchases SDK",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
        present(alert, animated: true)
    }

    @objc private func rateApp() {
        if let url = Config.appStoreReviewURL {
            UIApplication.shared.open(url)
        } else {
            let alert = UIAlertController(
                title: "Coming Soon",
                message: "Rating will be available once the app is live on the App Store.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func contactSupport() {
        let email = "support@ByZyB.ai"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}