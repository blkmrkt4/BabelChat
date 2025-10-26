import UIKit

/// Debug view to test Supabase connection
class SupabaseTestViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Supabase Test"
        view.backgroundColor = .systemBackground

        setupViews()
        runTests()
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func addTestResult(title: String, message: String, success: Bool) {
        let container = UIView()
        container.backgroundColor = success ? UIColor.systemGreen.withAlphaComponent(0.1) : UIColor.systemRed.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.numberOfLines = 0
        label.text = "\(success ? "✅" : "❌") \(title)\n\(message)"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        stackView.addArrangedSubview(container)
    }

    private func runTests() {
        // Test 1: Configuration
        let isConfigured = SupabaseConfig.isConfigured
        addTestResult(
            title: "Configuration",
            message: isConfigured ? "Supabase URL and key are set" : "Need to update SupabaseConfig.swift",
            success: isConfigured
        )

        // Test 2: Client initialization
        do {
            let client = SupabaseService.shared.client
            addTestResult(
                title: "Client Initialized",
                message: "Supabase client created successfully",
                success: true
            )
        } catch {
            addTestResult(
                title: "Client Initialization",
                message: "Error: \(error.localizedDescription)",
                success: false
            )
        }

        // Test 3: Authentication state
        let isAuthenticated = SupabaseService.shared.isAuthenticated
        addTestResult(
            title: "Authentication",
            message: isAuthenticated ? "User is signed in" : "No user signed in (this is ok)",
            success: true
        )

        // Test 4: Test sign in with email/password (optional)
        addButton(title: "Test Sign In with Email", action: #selector(testSignIn))

        // Test 5: Test profile fetch
        if isAuthenticated {
            addButton(title: "Fetch Current Profile", action: #selector(testFetchProfile))
        }

        // Test 6: Test discovery profiles
        addButton(title: "Fetch Discovery Profiles", action: #selector(testDiscoveryProfiles))

        // Test 7: Insert 40 test profiles
        addButton(title: "🚀 Insert 40 Test Profiles", action: #selector(insertTestProfiles))
    }

    @objc private func testSignIn() {
        // Create alert for email/password input
        let alert = UIAlertController(title: "Test Sign In", message: "Enter test credentials", preferredStyle: .alert)

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
                  let password = alert?.textFields?[1].text else { return }

            Task {
                do {
                    try await SupabaseService.shared.signIn(email: email, password: password)
                    await MainActor.run {
                        self?.addTestResult(
                            title: "Sign In Success",
                            message: "Signed in as: \(email)",
                            success: true
                        )
                    }
                } catch {
                    await MainActor.run {
                        self?.addTestResult(
                            title: "Sign In Failed",
                            message: error.localizedDescription,
                            success: false
                        )
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    @objc private func testFetchProfile() {
        Task {
            do {
                let profile = try await SupabaseService.shared.getCurrentProfile()
                await MainActor.run {
                    addTestResult(
                        title: "Profile Fetch Success",
                        message: "Name: \(profile.firstName), Email: \(profile.email)",
                        success: true
                    )
                }
            } catch {
                await MainActor.run {
                    addTestResult(
                        title: "Profile Fetch Failed",
                        message: error.localizedDescription,
                        success: false
                    )
                }
            }
        }
    }

    @objc private func testDiscoveryProfiles() {
        Task {
            do {
                let profiles = try await SupabaseService.shared.getDiscoveryProfiles(limit: 5)
                await MainActor.run {
                    addTestResult(
                        title: "Discovery Profiles Success",
                        message: "Found \(profiles.count) profiles",
                        success: true
                    )
                }
            } catch {
                await MainActor.run {
                    addTestResult(
                        title: "Discovery Profiles Failed",
                        message: error.localizedDescription,
                        success: false
                    )
                }
            }
        }
    }

    @objc private func insertTestProfiles() {
        // Show confirmation alert first
        let alert = UIAlertController(
            title: "Insert Test Profiles",
            message: "This will insert 40 test profiles into your Supabase database. This may take a minute. Continue?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Insert", style: .default) { [weak self] _ in
            self?.performProfileInsertion()
        })

        present(alert, animated: true)
    }

    private func performProfileInsertion() {
        // Add loading indicator
        addTestResult(
            title: "Inserting Test Profiles",
            message: "Starting insertion of 40 test profiles... Please wait ~4 seconds.",
            success: true
        )

        Task {
            do {
                let resultMessage = try await TestDataGenerator.shared.insertTestProfiles()
                await MainActor.run {
                    addTestResult(
                        title: "Test Profile Insertion Complete",
                        message: resultMessage,
                        success: true
                    )
                }
            } catch {
                await MainActor.run {
                    addTestResult(
                        title: "Test Profile Insertion Failed",
                        message: "Critical error: \(error.localizedDescription)",
                        success: false
                    )
                }
            }
        }
    }

    private func addButton(title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
}
