import UIKit

class AISetupViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Category selector
    private let categorySegmentedControl = UISegmentedControl(items: ["Translation", "Grammar", "Scoring"])
    private let activeConfigLabel = UILabel()

    // Sort selector
    private let sortLabel = UILabel()
    private let sortButtonStack = UIStackView()
    private let sortByNameButton = UIButton(type: .system)
    private let sortByCostButton = UIButton(type: .system)
    private let sortByScoreButton = UIButton(type: .system)

    // Model selection
    private let modelTableView = UITableView()
    private let selectedModelCard = UIView()
    private let selectedModelNameLabel = UILabel()
    private let selectedModelProviderLabel = UILabel()
    private let selectedModelCostLabel = UILabel()
    private let selectedModelScoreLabel = UILabel()
    private let noSelectionLabel = UILabel()

    // Master prompt
    private let masterPromptTextView = UITextView()
    private let masterPromptLabel = UILabel()

    // Grammar sensitivity (only shown for grammar category)
    private let sensitivityLabel = UILabel()
    private let sensitivitySegmentedControl = UISegmentedControl(items: ["Minimal", "Moderate", "Verbose"])
    private let sensitivityDescriptionLabel = UILabel()

    // Test area (Message)
    private let messageLabel = UILabel()
    private let messageCopyButton = UIButton(type: .system)
    private let testInputTextView = UITextView()
    private let testButton = UIButton(type: .system)

    // Response area
    private let responseLabel = UILabel()
    private let responseCopyButton = UIButton(type: .system)
    private let testOutputTextView = UITextView()

    // Scoring area
    private let scoreLabel = UILabel()
    private let scoreSlider = UISlider()
    private let scoreValueLabel = UILabel()

    // Save section
    private let saveButton = UIButton(type: .system)
    private let setAsDefaultSwitch = UISwitch()
    private let setAsDefaultLabel = UILabel()

    // MARK: - Properties
    private var models: [AIModel] = []
    private var selectedModel: AIModel?
    private var currentCategory = "translation"
    private var savedConfigs: [String: AIModelConfig] = [:] // category: config
    private var modelTestCounts: [String: Int] = [:] // modelId: test count
    private var modelScores: [String: Float] = [:] // modelId: user score (1-10)
    private var currentSortOption: SortOption = .name

    // Grammar-specific properties
    private var grammarConfig: GrammarConfiguration = .defaultConfiguration
    private var currentSensitivityLevel: GrammarSensitivityLevel = .moderate

    private enum SortOption {
        case name
        case cost
        case score
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadModels()
        loadSavedConfigs()
        loadGrammarConfiguration()
        updateUIForCategory()
    }

    // MARK: - Setup
    private func setupViews() {
        title = "AI Model Setup"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // Scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Category selector
        categorySegmentedControl.selectedSegmentIndex = 0
        categorySegmentedControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        contentView.addSubview(categorySegmentedControl)

        // Active configuration label
        activeConfigLabel.font = .systemFont(ofSize: 13, weight: .medium)
        activeConfigLabel.textColor = .systemGreen
        activeConfigLabel.textAlignment = .center
        activeConfigLabel.numberOfLines = 2
        contentView.addSubview(activeConfigLabel)

        // Sort selector
        sortLabel.text = "Sort by:"
        sortLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sortLabel.textColor = .secondaryLabel
        contentView.addSubview(sortLabel)

        // Sort button stack
        sortButtonStack.axis = .horizontal
        sortButtonStack.spacing = 8
        sortButtonStack.distribution = .fillEqually
        contentView.addSubview(sortButtonStack)

        // Configure sort buttons
        configureSortButton(sortByNameButton, title: "Name", tag: 0)
        configureSortButton(sortByCostButton, title: "Cost", tag: 1)
        configureSortButton(sortByScoreButton, title: "Score", tag: 2)

        sortButtonStack.addArrangedSubview(sortByNameButton)
        sortButtonStack.addArrangedSubview(sortByCostButton)
        sortButtonStack.addArrangedSubview(sortByScoreButton)

        // Select first button by default
        updateSortButtonSelection(sortByNameButton)

        // Selected model card
        selectedModelCard.backgroundColor = UIColor.systemBackground
        selectedModelCard.layer.cornerRadius = 12
        selectedModelCard.layer.borderWidth = 2
        selectedModelCard.layer.borderColor = UIColor.systemBlue.cgColor
        selectedModelCard.isHidden = true
        contentView.addSubview(selectedModelCard)

        selectedModelNameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        selectedModelNameLabel.textColor = .label
        selectedModelCard.addSubview(selectedModelNameLabel)

        selectedModelProviderLabel.font = .systemFont(ofSize: 14, weight: .medium)
        selectedModelProviderLabel.textColor = .systemBlue
        selectedModelCard.addSubview(selectedModelProviderLabel)

        selectedModelCostLabel.font = .systemFont(ofSize: 12)
        selectedModelCostLabel.textColor = .secondaryLabel
        selectedModelCostLabel.numberOfLines = 2
        selectedModelCard.addSubview(selectedModelCostLabel)

        selectedModelScoreLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        selectedModelScoreLabel.textAlignment = .right
        selectedModelCard.addSubview(selectedModelScoreLabel)

        // No selection label
        noSelectionLabel.text = "👆 Select a model from the list above"
        noSelectionLabel.font = .systemFont(ofSize: 15)
        noSelectionLabel.textColor = .secondaryLabel
        noSelectionLabel.textAlignment = .center
        contentView.addSubview(noSelectionLabel)

        // Model table
        modelTableView.delegate = self
        modelTableView.dataSource = self
        modelTableView.register(AIModelCell.self, forCellReuseIdentifier: "AIModelCell")
        modelTableView.layer.cornerRadius = 12
        modelTableView.layer.borderWidth = 1
        modelTableView.layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(modelTableView)

        // Master prompt
        masterPromptLabel.text = "Master Prompt (Hidden from users)"
        masterPromptLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        masterPromptLabel.textColor = .secondaryLabel
        contentView.addSubview(masterPromptLabel)

        masterPromptTextView.font = .systemFont(ofSize: 14)
        masterPromptTextView.layer.cornerRadius = 8
        masterPromptTextView.layer.borderWidth = 1
        masterPromptTextView.layer.borderColor = UIColor.separator.cgColor
        masterPromptTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        contentView.addSubview(masterPromptTextView)

        // Grammar sensitivity controls (only shown for grammar category)
        sensitivityLabel.text = "Sensitivity Level"
        sensitivityLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        sensitivityLabel.textColor = .secondaryLabel
        sensitivityLabel.isHidden = true
        contentView.addSubview(sensitivityLabel)

        sensitivitySegmentedControl.selectedSegmentIndex = 1 // Moderate by default
        sensitivitySegmentedControl.addTarget(self, action: #selector(sensitivityChanged), for: .valueChanged)
        sensitivitySegmentedControl.isHidden = true
        contentView.addSubview(sensitivitySegmentedControl)

        sensitivityDescriptionLabel.font = .systemFont(ofSize: 12)
        sensitivityDescriptionLabel.textColor = .tertiaryLabel
        sensitivityDescriptionLabel.textAlignment = .center
        sensitivityDescriptionLabel.text = currentSensitivityLevel.description
        sensitivityDescriptionLabel.isHidden = true
        contentView.addSubview(sensitivityDescriptionLabel)

        // Message section
        messageLabel.text = "Message"
        messageLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        messageLabel.textColor = .secondaryLabel
        contentView.addSubview(messageLabel)

        messageCopyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        messageCopyButton.tintColor = .systemBlue
        messageCopyButton.addTarget(self, action: #selector(copyMessage), for: .touchUpInside)
        contentView.addSubview(messageCopyButton)

        testInputTextView.font = .systemFont(ofSize: 14)
        testInputTextView.layer.cornerRadius = 8
        testInputTextView.backgroundColor = .secondarySystemBackground
        testInputTextView.text = "Enter text to translate (e.g., 'Hello, how are you?')"
        testInputTextView.textColor = .placeholderText
        testInputTextView.delegate = self
        contentView.addSubview(testInputTextView)

        testButton.setTitle("Test Model", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        testButton.backgroundColor = .systemBlue
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 8
        testButton.addTarget(self, action: #selector(testModel), for: .touchUpInside)
        contentView.addSubview(testButton)

        // Response section
        responseLabel.text = "Response"
        responseLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        responseLabel.textColor = .secondaryLabel
        contentView.addSubview(responseLabel)

        responseCopyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        responseCopyButton.tintColor = .systemBlue
        responseCopyButton.addTarget(self, action: #selector(copyResponse), for: .touchUpInside)
        contentView.addSubview(responseCopyButton)

        testOutputTextView.font = .systemFont(ofSize: 14)
        testOutputTextView.layer.cornerRadius = 8
        testOutputTextView.backgroundColor = .tertiarySystemBackground
        testOutputTextView.isEditable = false
        testOutputTextView.text = "Translation/response from LLM will appear here..."
        testOutputTextView.textColor = .placeholderText
        contentView.addSubview(testOutputTextView)

        // Scoring section
        scoreLabel.text = "Rate Model (1-10)"
        scoreLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        scoreLabel.textColor = .secondaryLabel
        contentView.addSubview(scoreLabel)

        scoreSlider.minimumValue = 1
        scoreSlider.maximumValue = 10
        scoreSlider.value = 5
        scoreSlider.addTarget(self, action: #selector(scoreChanged), for: .valueChanged)
        contentView.addSubview(scoreSlider)

        scoreValueLabel.text = "5.0"
        scoreValueLabel.font = .systemFont(ofSize: 16, weight: .medium)
        scoreValueLabel.textColor = .systemBlue
        scoreValueLabel.textAlignment = .right
        contentView.addSubview(scoreValueLabel)

        // Save button
        saveButton.setTitle("Save Prompt + Score", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveConfiguration), for: .touchUpInside)
        contentView.addSubview(saveButton)

        // Set as default switch and label
        setAsDefaultLabel.text = "Use as default for this category"
        setAsDefaultLabel.font = .systemFont(ofSize: 15, weight: .medium)
        setAsDefaultLabel.textColor = .label
        setAsDefaultLabel.numberOfLines = 2
        contentView.addSubview(setAsDefaultLabel)

        setAsDefaultSwitch.onTintColor = .systemGreen
        setAsDefaultSwitch.addTarget(self, action: #selector(defaultSwitchChanged), for: .valueChanged)
        contentView.addSubview(setAsDefaultSwitch)
    }

    private func configureSortButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.secondarySystemFill
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = tag
        button.addTarget(self, action: #selector(sortButtonTapped(_:)), for: .touchUpInside)
    }

    private func updateSortButtonSelection(_ selectedButton: UIButton) {
        // Reset all buttons
        [sortByNameButton, sortByCostButton, sortByScoreButton].forEach { button in
            button.backgroundColor = UIColor.secondarySystemFill
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.layer.borderColor = UIColor.clear.cgColor
        }

        // Highlight selected button
        selectedButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        selectedButton.setTitleColor(.systemBlue, for: .normal)
        selectedButton.layer.borderColor = UIColor.systemBlue.cgColor
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        activeConfigLabel.translatesAutoresizingMaskIntoConstraints = false
        sortLabel.translatesAutoresizingMaskIntoConstraints = false
        sortButtonStack.translatesAutoresizingMaskIntoConstraints = false
        selectedModelCard.translatesAutoresizingMaskIntoConstraints = false
        selectedModelNameLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedModelProviderLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedModelCostLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedModelScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        noSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        modelTableView.translatesAutoresizingMaskIntoConstraints = false
        masterPromptLabel.translatesAutoresizingMaskIntoConstraints = false
        masterPromptTextView.translatesAutoresizingMaskIntoConstraints = false
        sensitivityLabel.translatesAutoresizingMaskIntoConstraints = false
        sensitivitySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        sensitivityDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageCopyButton.translatesAutoresizingMaskIntoConstraints = false
        testInputTextView.translatesAutoresizingMaskIntoConstraints = false
        testButton.translatesAutoresizingMaskIntoConstraints = false
        responseLabel.translatesAutoresizingMaskIntoConstraints = false
        responseCopyButton.translatesAutoresizingMaskIntoConstraints = false
        testOutputTextView.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreSlider.translatesAutoresizingMaskIntoConstraints = false
        scoreValueLabel.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        setAsDefaultSwitch.translatesAutoresizingMaskIntoConstraints = false
        setAsDefaultLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Category selector
            categorySegmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            categorySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Active configuration label
            activeConfigLabel.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 8),
            activeConfigLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activeConfigLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Sort selector
            sortLabel.topAnchor.constraint(equalTo: activeConfigLabel.bottomAnchor, constant: 12),
            sortLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            sortButtonStack.topAnchor.constraint(equalTo: sortLabel.bottomAnchor, constant: 8),
            sortButtonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sortButtonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sortButtonStack.heightAnchor.constraint(equalToConstant: 36),

            // Model table
            modelTableView.topAnchor.constraint(equalTo: sortButtonStack.bottomAnchor, constant: 16),
            modelTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            modelTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            modelTableView.heightAnchor.constraint(equalToConstant: 200),

            // No selection label (shown when no model selected)
            noSelectionLabel.topAnchor.constraint(equalTo: modelTableView.bottomAnchor, constant: 12),
            noSelectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            noSelectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Selected model card (shown when model is selected)
            selectedModelCard.topAnchor.constraint(equalTo: modelTableView.bottomAnchor, constant: 12),
            selectedModelCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            selectedModelCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            selectedModelCard.heightAnchor.constraint(equalToConstant: 90),

            // Card content - Name and Provider on left
            selectedModelNameLabel.topAnchor.constraint(equalTo: selectedModelCard.topAnchor, constant: 12),
            selectedModelNameLabel.leadingAnchor.constraint(equalTo: selectedModelCard.leadingAnchor, constant: 16),
            selectedModelNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectedModelScoreLabel.leadingAnchor, constant: -12),

            selectedModelProviderLabel.topAnchor.constraint(equalTo: selectedModelNameLabel.bottomAnchor, constant: 4),
            selectedModelProviderLabel.leadingAnchor.constraint(equalTo: selectedModelCard.leadingAnchor, constant: 16),

            selectedModelCostLabel.topAnchor.constraint(equalTo: selectedModelProviderLabel.bottomAnchor, constant: 4),
            selectedModelCostLabel.leadingAnchor.constraint(equalTo: selectedModelCard.leadingAnchor, constant: 16),
            selectedModelCostLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectedModelCard.trailingAnchor, constant: -80),
            selectedModelCostLabel.bottomAnchor.constraint(lessThanOrEqualTo: selectedModelCard.bottomAnchor, constant: -12),

            // Score on right
            selectedModelScoreLabel.centerYAnchor.constraint(equalTo: selectedModelCard.centerYAnchor),
            selectedModelScoreLabel.trailingAnchor.constraint(equalTo: selectedModelCard.trailingAnchor, constant: -16),
            selectedModelScoreLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),

            // Master prompt (positioned below both card and no-selection label since they occupy same space)
            masterPromptLabel.topAnchor.constraint(equalTo: selectedModelCard.bottomAnchor, constant: 20),
            masterPromptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            masterPromptTextView.topAnchor.constraint(equalTo: masterPromptLabel.bottomAnchor, constant: 8),
            masterPromptTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            masterPromptTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            masterPromptTextView.heightAnchor.constraint(equalToConstant: 100),

            // Grammar sensitivity controls (conditionally shown)
            sensitivityLabel.topAnchor.constraint(equalTo: masterPromptTextView.bottomAnchor, constant: 16),
            sensitivityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            sensitivitySegmentedControl.topAnchor.constraint(equalTo: sensitivityLabel.bottomAnchor, constant: 8),
            sensitivitySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sensitivitySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            sensitivityDescriptionLabel.topAnchor.constraint(equalTo: sensitivitySegmentedControl.bottomAnchor, constant: 6),
            sensitivityDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sensitivityDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Message section (positioned below sensitivity controls, which are hidden for non-grammar categories)
            messageLabel.topAnchor.constraint(equalTo: sensitivityDescriptionLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            messageCopyButton.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            messageCopyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            messageCopyButton.widthAnchor.constraint(equalToConstant: 30),
            messageCopyButton.heightAnchor.constraint(equalToConstant: 30),

            testInputTextView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            testInputTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            testInputTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            testInputTextView.heightAnchor.constraint(equalToConstant: 80),

            // Test Model button
            testButton.topAnchor.constraint(equalTo: testInputTextView.bottomAnchor, constant: 16),
            testButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            testButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalToConstant: 50),

            // Response section
            responseLabel.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 20),
            responseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            responseCopyButton.centerYAnchor.constraint(equalTo: responseLabel.centerYAnchor),
            responseCopyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            responseCopyButton.widthAnchor.constraint(equalToConstant: 30),
            responseCopyButton.heightAnchor.constraint(equalToConstant: 30),

            testOutputTextView.topAnchor.constraint(equalTo: responseLabel.bottomAnchor, constant: 8),
            testOutputTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            testOutputTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            testOutputTextView.heightAnchor.constraint(equalToConstant: 120),

            // Scoring section
            scoreLabel.topAnchor.constraint(equalTo: testOutputTextView.bottomAnchor, constant: 16),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            scoreSlider.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            scoreSlider.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 16),
            scoreSlider.trailingAnchor.constraint(equalTo: scoreValueLabel.leadingAnchor, constant: -12),

            scoreValueLabel.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor),
            scoreValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scoreValueLabel.widthAnchor.constraint(equalToConstant: 50),

            // Save button (smaller, on left)
            saveButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.widthAnchor.constraint(equalToConstant: 170),
            saveButton.heightAnchor.constraint(equalToConstant: 44),

            // Set as default switch and label (on right side)
            setAsDefaultSwitch.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            setAsDefaultSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            setAsDefaultLabel.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            setAsDefaultLabel.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 12),
            setAsDefaultLabel.trailingAnchor.constraint(equalTo: setAsDefaultSwitch.leadingAnchor, constant: -8),

            // Bottom anchor for scroll content
            setAsDefaultSwitch.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    // MARK: - Data Loading
    private func loadModels() {
        // Load models based on current category
        // This would normally fetch from OpenRouter API
        models = AIModel.getSampleModels(for: currentCategory)
        sortModels()
        modelTableView.reloadData()
    }

    private func sortModels() {
        switch currentSortOption {
        case .name:
            models.sort { $0.name < $1.name }
        case .cost:
            models.sort { $0.inputCostPerToken < $1.inputCostPerToken }
        case .score:
            // Sort by user score (highest first, then by name)
            models.sort {
                let score1 = modelScores[$0.id] ?? 0
                let score2 = modelScores[$1.id] ?? 0
                if score1 != score2 {
                    return score1 > score2
                }
                return $0.name < $1.name
            }
        }
    }

    private func loadSavedConfigs() {
        // Load saved configurations from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "AIModelConfigs") {
            if let decoded = try? JSONDecoder().decode([String: SavedConfig].self, from: data) {
                // Convert saved configs back to AIModelConfig
                for (category, saved) in decoded {
                    if let categoryEnum = AIModelCategory(rawValue: category) {
                        let config = AIModelConfig(
                            modelId: saved.modelId,
                            modelName: saved.modelName,
                            modelProvider: saved.modelProvider,
                            category: categoryEnum,
                            masterPrompt: saved.masterPrompt
                        )
                        savedConfigs[category] = config
                    }
                }
            }
        }

        // Load test counts
        if let counts = UserDefaults.standard.dictionary(forKey: "ModelTestCounts") as? [String: Int] {
            modelTestCounts = counts
        }

        // Load model scores
        if let scores = UserDefaults.standard.dictionary(forKey: "ModelScores") as? [String: Float] {
            modelScores = scores
        }
    }

    // Helper struct for UserDefaults persistence
    private struct SavedConfig: Codable {
        let modelId: String
        let modelName: String
        let modelProvider: String
        let masterPrompt: String
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func categoryChanged() {
        switch categorySegmentedControl.selectedSegmentIndex {
        case 0: currentCategory = "translation"
        case 1: currentCategory = "grammar"
        case 2: currentCategory = "scoring"
        default: break
        }

        // Show/hide sensitivity controls for grammar category
        let isGrammar = (currentCategory == "grammar")
        sensitivityLabel.isHidden = !isGrammar
        sensitivitySegmentedControl.isHidden = !isGrammar
        sensitivityDescriptionLabel.isHidden = !isGrammar

        loadModels()
        updateUIForCategory()
    }

    @objc private func sensitivityChanged() {
        switch sensitivitySegmentedControl.selectedSegmentIndex {
        case 0: currentSensitivityLevel = .minimal
        case 1: currentSensitivityLevel = .moderate
        case 2: currentSensitivityLevel = .verbose
        default: break
        }

        // Update description
        sensitivityDescriptionLabel.text = currentSensitivityLevel.description

        // Load the prompt for this sensitivity level
        if currentCategory == "grammar" {
            masterPromptTextView.text = grammarConfig.getPrompt(for: currentSensitivityLevel)
        }
    }

    @objc private func sortButtonTapped(_ sender: UIButton) {
        // Update button selection visually
        updateSortButtonSelection(sender)

        // Update sort option based on button tag
        switch sender.tag {
        case 0: currentSortOption = .name
        case 1: currentSortOption = .cost
        case 2: currentSortOption = .score
        default: break
        }
        sortModels()
        modelTableView.reloadData()
    }

    @objc private func testModel() {
        guard let model = selectedModel else {
            showAlert(title: "No Model", message: "Please select a model first")
            return
        }

        guard testInputTextView.textColor != .placeholderText,
              !testInputTextView.text.isEmpty else {
            showAlert(title: "No Input", message: "Please enter text to translate first")
            return
        }

        // Test the model with OpenRouter API
        testButton.isEnabled = false
        testOutputTextView.text = "Testing model...\nMaking API call to OpenRouter..."
        testOutputTextView.textColor = .label

        let inputText = testInputTextView.text ?? ""
        let prompt = masterPromptTextView.text ?? getDefaultPrompt(for: currentCategory)

        Task {
            do {
                // Use the master prompt and test input
                let messages = [
                    ChatMessage(role: "system", content: prompt),
                    ChatMessage(role: "user", content: inputText)
                ]

                let response = try await OpenRouterService.shared.sendChatCompletion(
                    model: model.id,
                    messages: messages,
                    temperature: 0.7,
                    maxTokens: 500
                )

                await MainActor.run {
                    self.testButton.isEnabled = true
                    if let firstChoice = response.choices.first {
                        self.testOutputTextView.text = firstChoice.message.content

                        // Show token usage if available
                        if let usage = response.usage {
                            self.testOutputTextView.text += "\n\n---\nTokens: \(usage.total_tokens) (in: \(usage.prompt_tokens), out: \(usage.completion_tokens))"
                        }

                        // Increment test count for this model
                        self.modelTestCounts[model.id, default: 0] += 1
                        UserDefaults.standard.set(self.modelTestCounts, forKey: "ModelTestCounts")
                    } else {
                        self.testOutputTextView.text = "No response from model"
                    }
                }
            } catch {
                await MainActor.run {
                    self.testButton.isEnabled = true
                    self.testOutputTextView.text = "❌ Error: \(error.localizedDescription)\n\nPlease check:\n1. API key is set correctly in .env\n2. Model ID is valid\n3. Internet connection is working"
                    self.testOutputTextView.textColor = .systemRed
                }
            }
        }
    }

    @objc private func saveConfiguration() {
        guard let model = selectedModel else {
            showAlert(title: "No Model", message: "Please select a model first")
            return
        }

        // For grammar category, save the current prompt to the appropriate sensitivity level
        if currentCategory == "grammar" {
            grammarConfig.setPrompt(masterPromptTextView.text, for: currentSensitivityLevel)
            // Save grammar config to UserDefaults
            saveGrammarConfiguration()
        }

        // Only set as active/default if switch is ON
        if setAsDefaultSwitch.isOn {
            let category = AIModelCategory(rawValue: currentCategory) ?? .translation
            let config = AIModelConfig(
                modelId: model.id,
                modelName: model.name,
                modelProvider: model.provider,
                category: category,
                inputCostPerToken: model.inputCostPerToken,
                outputCostPerToken: model.outputCostPerToken,
                masterPrompt: masterPromptTextView.text
            )

            savedConfigs[currentCategory] = config

            // Save to database/UserDefaults
            saveToDatabase(config: config)

            // Update UI to show active config
            updateUIForCategory()

            let message = currentCategory == "grammar"
                ? "Set as default for Grammar (\(currentSensitivityLevel.displayName) sensitivity)"
                : "Set as default for \(currentCategory.capitalized)"
            showAlert(title: "Saved", message: message)
        } else {
            // Just save the prompt and score (score already saved via slider)
            let message = currentCategory == "grammar"
                ? "Prompt saved for \(currentSensitivityLevel.displayName) sensitivity"
                : "Prompt and score saved for \(model.name)"
            showAlert(title: "Saved", message: message)
        }
    }

    private func saveGrammarConfiguration() {
        if let encoded = try? JSONEncoder().encode(grammarConfig) {
            UserDefaults.standard.set(encoded, forKey: "GrammarConfiguration")
        }
    }

    private func loadGrammarConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "GrammarConfiguration"),
           let decoded = try? JSONDecoder().decode(GrammarConfiguration.self, from: data) {
            grammarConfig = decoded
        }
    }

    @objc private func defaultSwitchChanged() {
        // When switch is toggled on, show confirmation
        if setAsDefaultSwitch.isOn {
            guard selectedModel != nil else {
                setAsDefaultSwitch.isOn = false
                showAlert(title: "No Model Selected", message: "Please select a model first")
                return
            }
        }
    }

    @objc private func copyMessage() {
        guard testInputTextView.textColor != .placeholderText,
              !testInputTextView.text.isEmpty else {
            showAlert(title: "Nothing to Copy", message: "Please enter a message first")
            return
        }
        UIPasteboard.general.string = testInputTextView.text
        // Show visual feedback
        messageCopyButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.messageCopyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        }
    }

    @objc private func copyResponse() {
        guard testOutputTextView.textColor != .placeholderText,
              !testOutputTextView.text.isEmpty,
              !testOutputTextView.text.contains("will appear here") else {
            showAlert(title: "Nothing to Copy", message: "No response to copy yet")
            return
        }
        UIPasteboard.general.string = testOutputTextView.text
        // Show visual feedback
        responseCopyButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.responseCopyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        }
    }

    @objc private func scoreChanged() {
        let score = scoreSlider.value
        scoreValueLabel.text = String(format: "%.1f", score)

        // Save the score for the currently selected model
        if let model = selectedModel {
            modelScores[model.id] = score
            // Persist to UserDefaults
            UserDefaults.standard.set(modelScores, forKey: "ModelScores")
            // Update table view to show new score
            modelTableView.reloadData()
        }
    }

    private func updateUIForCategory() {
        if let config = savedConfigs[currentCategory] {
            masterPromptTextView.text = config.masterPrompt
            activeConfigLabel.text = "✓ Active: \(config.modelName)"
            activeConfigLabel.textColor = .systemGreen
        } else {
            masterPromptTextView.text = getDefaultPrompt(for: currentCategory)
            activeConfigLabel.text = "⚠ No model configured for this category"
            activeConfigLabel.textColor = .systemOrange
        }
    }

    private func getDefaultPrompt(for category: String) -> String {
        switch category {
        case "translation":
            return "You are a professional translator. Translate the following text from {learning_language} to {native_language}. Maintain the tone and style. Return only the translation."
        case "grammar":
            // For grammar, return the prompt for the current sensitivity level
            return grammarConfig.getPrompt(for: currentSensitivityLevel)
        case "scoring":
            return "Rate this text written in {learning_language} for correctness (0-100). The user is learning {learning_language} and their native language is {native_language}. Return JSON with score and feedback."
        default:
            return ""
        }
    }

    private func saveToDatabase(config: AIModelConfig) {
        // Convert to SavedConfig for UserDefaults
        var allConfigs: [String: SavedConfig] = [:]

        // Load existing configs
        if let data = UserDefaults.standard.data(forKey: "AIModelConfigs"),
           let decoded = try? JSONDecoder().decode([String: SavedConfig].self, from: data) {
            allConfigs = decoded
        }

        // Add/update current config
        let savedConfig = SavedConfig(
            modelId: config.modelId,
            modelName: config.modelName,
            modelProvider: config.modelProvider,
            masterPrompt: config.masterPrompt
        )
        allConfigs[currentCategory] = savedConfig

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(allConfigs) {
            UserDefaults.standard.set(encoded, forKey: "AIModelConfigs")
        }

        print("Saved config for \(currentCategory): \(config.modelName)")
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AISetupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AIModelCell", for: indexPath) as! AIModelCell
        let model = models[indexPath.row]
        let userScore = modelScores[model.id]
        cell.configure(with: model, score: userScore)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AISetupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedModel = models[indexPath.row]

        // Show card, hide no selection label
        selectedModelCard.isHidden = false
        noSelectionLabel.isHidden = true

        // Populate card with model info
        selectedModelNameLabel.text = selectedModel!.name
        selectedModelProviderLabel.text = selectedModel!.provider
        selectedModelCostLabel.text = selectedModel!.costDisplay

        // Show score
        if let score = modelScores[selectedModel!.id] {
            selectedModelScoreLabel.text = String(format: "%.1f", score)
            selectedModelScoreLabel.textColor = .systemBlue
        } else {
            selectedModelScoreLabel.text = "{UT}"
            selectedModelScoreLabel.textColor = .systemOrange
        }

        // Update score slider with saved score for this model
        if let score = modelScores[selectedModel!.id] {
            scoreSlider.value = score
            scoreValueLabel.text = String(format: "%.1f", score)
        } else {
            scoreSlider.value = 5.0
            scoreValueLabel.text = "5.0"
        }

        // Check if this is the active default model for this category
        if let activeConfig = savedConfigs[currentCategory],
           activeConfig.modelId == selectedModel!.id {
            setAsDefaultSwitch.isOn = true
        } else {
            setAsDefaultSwitch.isOn = false
        }

        // Animate the card appearance
        selectedModelCard.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.selectedModelCard.alpha = 1
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - UITextViewDelegate
extension AISetupViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == testInputTextView && textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == testInputTextView && textView.text.isEmpty {
            textView.text = "Enter text to translate (e.g., 'Hello, how are you?')"
            textView.textColor = .placeholderText
        }
    }
}