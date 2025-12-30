import UIKit

/// Shows configured AI model bindings with their master prompts and fallback models
class AIModelBindingsViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Left side - bindings list
    private let bindingsTableView = UITableView()

    // Right side - details viewer
    private let detailsContainerView = UIView()
    private let detailsTitleLabel = UILabel()
    private let detailsTextView = UITextView()

    private let dividerView = UIView()

    // MARK: - Data

    private var bindings: [AIBinding] = []
    private var selectedBinding: AIBinding?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupRefreshButton()
        Task {
            await loadBindings()
        }
    }

    private func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc private func refreshButtonTapped() {
        Task {
            await refreshBindings()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Scroll view for entire content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Bindings table (left half)
        bindingsTableView.translatesAutoresizingMaskIntoConstraints = false
        bindingsTableView.delegate = self
        bindingsTableView.dataSource = self
        bindingsTableView.register(BindingCell.self, forCellReuseIdentifier: "BindingCell")
        bindingsTableView.separatorStyle = .singleLine
        bindingsTableView.rowHeight = UITableView.automaticDimension
        bindingsTableView.estimatedRowHeight = 80
        contentView.addSubview(bindingsTableView)

        // Divider
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .separator
        contentView.addSubview(dividerView)

        // Details container (right half)
        detailsContainerView.translatesAutoresizingMaskIntoConstraints = false
        detailsContainerView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(detailsContainerView)

        // Details title
        detailsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        detailsTitleLabel.textColor = .secondaryLabel
        detailsTitleLabel.text = "Select a binding to view its prompt"
        detailsTitleLabel.textAlignment = .center
        detailsTitleLabel.numberOfLines = 0
        detailsContainerView.addSubview(detailsTitleLabel)

        // Details text view
        detailsTextView.translatesAutoresizingMaskIntoConstraints = false
        detailsTextView.font = .systemFont(ofSize: 14)
        detailsTextView.textColor = .label
        detailsTextView.backgroundColor = .clear
        detailsTextView.isEditable = false
        detailsTextView.isSelectable = true
        detailsTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        detailsTextView.isHidden = true
        detailsContainerView.addSubview(detailsTextView)

        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Bindings table (left half)
            bindingsTableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bindingsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bindingsTableView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            bindingsTableView.heightAnchor.constraint(equalToConstant: 600),

            // Divider
            dividerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: bindingsTableView.trailingAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalTo: bindingsTableView.heightAnchor),

            // Details container (right half)
            detailsContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailsContainerView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            detailsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            detailsContainerView.heightAnchor.constraint(equalTo: bindingsTableView.heightAnchor),
            detailsContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Details title
            detailsTitleLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: 20),
            detailsTitleLabel.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 20),
            detailsTitleLabel.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -20),

            // Details text view
            detailsTextView.topAnchor.constraint(equalTo: detailsContainerView.topAnchor),
            detailsTextView.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor),
            detailsTextView.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor),
            detailsTextView.bottomAnchor.constraint(equalTo: detailsContainerView.bottomAnchor)
        ])
    }

    // MARK: - Data Loading

    private func loadBindings() async {
        let config = AIConfigurationManager.shared

        // Translation binding
        do {
            let translationConfig = try await config.getConfiguration(for: .translation)
            bindings.append(AIBinding(
                category: .translation,
                level: nil,
                config: translationConfig
            ))
        } catch {
            print("Error loading translation config: \(error)")
        }

        // Grammar binding with sensitivity levels
        do {
            let grammarConfig = try await config.getConfiguration(for: .grammar)

            // Add grammar bindings for each sensitivity level
            for level in GrammarSensitivityLevel.allCases {
                bindings.append(AIBinding(
                    category: .grammar,
                    level: level,
                    config: grammarConfig
                ))
            }
        } catch {
            print("Error loading grammar config: \(error)")
        }

        // Scoring binding
        do {
            let scoringConfig = try await config.getConfiguration(for: .scoring)
            bindings.append(AIBinding(
                category: .scoring,
                level: nil,
                config: scoringConfig
            ))
        } catch {
            print("Error loading scoring config: \(error)")
        }

        await MainActor.run {
            bindingsTableView.reloadData()
        }
    }

    private func refreshBindings() async {
        // Show loading indicator
        await MainActor.run {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        }

        // Force refresh from Supabase (bypasses 24-hour cache)
        do {
            try await AIConfigService.shared.refreshAllConfigurations()

            // Clear existing bindings
            bindings.removeAll()

            // Reload bindings with fresh data
            await loadBindings()

            await MainActor.run {
                // Show success message briefly
                let label = UILabel()
                label.text = "✓"
                label.textColor = .systemGreen
                label.font = .systemFont(ofSize: 20)
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: label)

                // Restore refresh button after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.setupRefreshButton()
                }
            }
        } catch {
            await MainActor.run {
                // Show error
                let alert = UIAlertController(
                    title: "Refresh Failed",
                    message: "Could not fetch updated configurations: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)

                // Restore refresh button
                setupRefreshButton()
            }
        }
    }

    // MARK: - Actions

    private func showDetails(for binding: AIBinding) {
        selectedBinding = binding

        var details = ""

        // Category and level
        details += "Category: \(binding.displayTitle)\n\n"

        // Primary model
        details += "PRIMARY MODEL:\n"
        details += "  \(binding.config.modelName)\n"
        details += "  ID: \(binding.config.modelId)\n"
        details += "  Provider: \(binding.config.modelProvider)\n\n"

        // Fallback models
        details += "FALLBACK MODELS:\n"
        if let fb1Name = binding.config.fallbackModel1Name, let fb1Id = binding.config.fallbackModel1Id {
            details += "  1. \(fb1Name)\n     ID: \(fb1Id)\n"
        } else {
            details += "  1. (Not configured)\n"
        }

        if let fb2Name = binding.config.fallbackModel2Name, let fb2Id = binding.config.fallbackModel2Id {
            details += "  2. \(fb2Name)\n     ID: \(fb2Id)\n"
        } else {
            details += "  2. (Not configured)\n"
        }

        if let fb3Name = binding.config.fallbackModel3Name, let fb3Id = binding.config.fallbackModel3Id {
            details += "  3. \(fb3Name)\n     ID: \(fb3Id)\n"
        } else {
            details += "  3. (Not configured)\n"
        }

        details += "\n"

        // Configuration
        details += "CONFIGURATION:\n"
        details += "  Temperature: \(binding.config.temperature)\n"
        details += "  Max Tokens: \(binding.config.maxTokens)\n\n"

        // Prompt
        details += "PROMPT TEMPLATE:\n"
        let prompt = binding.prompt
        details += prompt

        detailsTitleLabel.isHidden = true
        detailsTextView.isHidden = false
        detailsTextView.text = details
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AIModelBindingsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bindings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BindingCell", for: indexPath) as? BindingCell else {
            return UITableViewCell()
        }
        cell.configure(with: bindings[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showDetails(for: bindings[indexPath.row])
    }
}

// MARK: - Data Models

struct AIBinding {
    let category: AICategory
    let level: GrammarSensitivityLevel?
    let config: AIConfig

    var displayTitle: String {
        switch category {
        case .translation:
            return "Translation"
        case .grammar:
            if let level = level {
                return "Grammar > \(level.displayName)"
            }
            return "Grammar"
        case .scoring:
            return "Scoring"
        case .chatting:
            return "Chatting"
        }
    }

    var prompt: String {
        switch category {
        case .translation, .scoring, .chatting:
            return config.promptTemplate
        case .grammar:
            // Return the appropriate grammar prompt based on level
            if let level = level {
                switch level {
                case .minimal:
                    return config.grammarLevel1Prompt ?? config.promptTemplate
                case .moderate:
                    return config.grammarLevel2Prompt ?? config.promptTemplate
                case .verbose:
                    return config.grammarLevel3Prompt ?? config.promptTemplate
                }
            }
            return config.promptTemplate
        }
    }
}

// MARK: - Binding Cell

class BindingCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let primaryModelLabel = UILabel()
    private let fallbacksLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        primaryModelLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryModelLabel.font = .systemFont(ofSize: 12)
        primaryModelLabel.textColor = .label
        primaryModelLabel.numberOfLines = 1
        contentView.addSubview(primaryModelLabel)

        fallbacksLabel.translatesAutoresizingMaskIntoConstraints = false
        fallbacksLabel.font = .systemFont(ofSize: 11)
        fallbacksLabel.textColor = .secondaryLabel
        fallbacksLabel.numberOfLines = 1
        contentView.addSubview(fallbacksLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            primaryModelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            primaryModelLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            primaryModelLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            fallbacksLabel.topAnchor.constraint(equalTo: primaryModelLabel.bottomAnchor, constant: 2),
            fallbacksLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            fallbacksLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            fallbacksLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with binding: AIBinding) {
        titleLabel.text = binding.displayTitle
        primaryModelLabel.text = "Primary: \(binding.config.modelName)"

        // Count configured fallbacks
        var fallbackCount = 0
        if binding.config.fallbackModel1Name != nil { fallbackCount += 1 }
        if binding.config.fallbackModel2Name != nil { fallbackCount += 1 }
        if binding.config.fallbackModel3Name != nil { fallbackCount += 1 }

        if fallbackCount > 0 {
            fallbacksLabel.text = "Fallbacks: \(fallbackCount) configured"
            fallbacksLabel.textColor = .secondaryLabel
        } else {
            fallbacksLabel.text = "Fallbacks: None configured"
            fallbacksLabel.textColor = .systemOrange
        }
    }
}
