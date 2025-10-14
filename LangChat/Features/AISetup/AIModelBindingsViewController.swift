import UIKit

/// Shows all configured AI model bindings with their master prompts
class AIModelBindingsViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Left side - bindings list
    private let bindingsTableView = UITableView()

    // Right side - prompt viewer
    private let promptContainerView = UIView()
    private let promptTitleLabel = UILabel()
    private let promptTextView = UITextView()

    private let dividerView = UIView()

    // MARK: - Data

    private var bindings: [AIBinding] = []
    private var selectedBinding: AIBinding?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadBindings()
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
        bindingsTableView.rowHeight = 60
        contentView.addSubview(bindingsTableView)

        // Divider
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .separator
        contentView.addSubview(dividerView)

        // Prompt container (right half)
        promptContainerView.translatesAutoresizingMaskIntoConstraints = false
        promptContainerView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(promptContainerView)

        // Prompt title
        promptTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        promptTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        promptTitleLabel.textColor = .secondaryLabel
        promptTitleLabel.text = "Select a binding to view its prompt"
        promptTitleLabel.textAlignment = .center
        promptTitleLabel.numberOfLines = 0
        promptContainerView.addSubview(promptTitleLabel)

        // Prompt text view
        promptTextView.translatesAutoresizingMaskIntoConstraints = false
        promptTextView.font = .systemFont(ofSize: 14)
        promptTextView.textColor = .label
        promptTextView.backgroundColor = .clear
        promptTextView.isEditable = false
        promptTextView.isSelectable = true
        promptTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        promptTextView.isHidden = true
        promptContainerView.addSubview(promptTextView)

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

            // Prompt container (right half)
            promptContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            promptContainerView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            promptContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            promptContainerView.heightAnchor.constraint(equalTo: bindingsTableView.heightAnchor),
            promptContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Prompt title
            promptTitleLabel.topAnchor.constraint(equalTo: promptContainerView.topAnchor, constant: 20),
            promptTitleLabel.leadingAnchor.constraint(equalTo: promptContainerView.leadingAnchor, constant: 20),
            promptTitleLabel.trailingAnchor.constraint(equalTo: promptContainerView.trailingAnchor, constant: -20),

            // Prompt text view
            promptTextView.topAnchor.constraint(equalTo: promptContainerView.topAnchor),
            promptTextView.leadingAnchor.constraint(equalTo: promptContainerView.leadingAnchor),
            promptTextView.trailingAnchor.constraint(equalTo: promptContainerView.trailingAnchor),
            promptTextView.bottomAnchor.constraint(equalTo: promptContainerView.bottomAnchor)
        ])
    }

    // MARK: - Data Loading

    private func loadBindings() {
        let config = AIConfigurationManager.shared

        // Translation binding
        if let translationConfig = config.getConfiguration(for: .translation) {
            bindings.append(AIBinding(
                category: .translation,
                level: nil,
                modelName: translationConfig.modelName,
                prompt: translationConfig.promptTemplate
            ))
        } else {
            bindings.append(AIBinding(
                category: .translation,
                level: nil,
                modelName: "None Selected",
                prompt: nil
            ))
        }

        // Grammar binding with sensitivity levels
        if let grammarConfig = config.getConfiguration(for: .grammar),
           let grammarData = UserDefaults.standard.data(forKey: "GrammarConfiguration"),
           let grammarLevels = try? JSONDecoder().decode(GrammarConfiguration.self, from: grammarData) {

            // Add grammar bindings for each sensitivity level
            for level in GrammarSensitivityLevel.allCases {
                bindings.append(AIBinding(
                    category: .grammar,
                    level: level,
                    modelName: grammarConfig.modelName,
                    prompt: grammarLevels.getPrompt(for: level)
                ))
            }
        } else {
            // No grammar configuration saved
            for level in GrammarSensitivityLevel.allCases {
                bindings.append(AIBinding(
                    category: .grammar,
                    level: level,
                    modelName: "None Selected",
                    prompt: nil
                ))
            }
        }

        // Scoring binding
        if let scoringConfig = config.getConfiguration(for: .scoring) {
            bindings.append(AIBinding(
                category: .scoring,
                level: nil,
                modelName: scoringConfig.modelName,
                prompt: scoringConfig.promptTemplate
            ))
        } else {
            bindings.append(AIBinding(
                category: .scoring,
                level: nil,
                modelName: "None Selected",
                prompt: nil
            ))
        }

        bindingsTableView.reloadData()
    }

    // MARK: - Actions

    private func showPrompt(for binding: AIBinding) {
        selectedBinding = binding

        if let prompt = binding.prompt {
            promptTitleLabel.isHidden = true
            promptTextView.isHidden = false
            promptTextView.text = prompt
        } else {
            promptTitleLabel.isHidden = false
            promptTextView.isHidden = true
            promptTitleLabel.text = "No prompt configured for this binding"
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AIModelBindingsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bindings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindingCell", for: indexPath) as! BindingCell
        cell.configure(with: bindings[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showPrompt(for: bindings[indexPath.row])
    }
}

// MARK: - Data Models

struct AIBinding {
    let category: AICategory
    let level: GrammarSensitivityLevel?
    let modelName: String
    let prompt: String?

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
        }
    }
}

// MARK: - Binding Cell

class BindingCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let modelLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        modelLabel.font = .systemFont(ofSize: 12)
        modelLabel.textColor = .secondaryLabel
        modelLabel.numberOfLines = 1
        contentView.addSubview(modelLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            modelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            modelLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            modelLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            modelLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with binding: AIBinding) {
        titleLabel.text = binding.displayTitle

        if binding.modelName == "None Selected" {
            modelLabel.text = "Model: None Selected"
            modelLabel.textColor = .systemRed
        } else {
            modelLabel.text = "Model: \(binding.modelName)"
            modelLabel.textColor = .secondaryLabel
        }
    }
}
