import UIKit

class LearningGoalsViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let goalsScrollView = UIScrollView()
    private let stackView = UIStackView()
    private let introLabel = UILabel()
    private let skipLabel = UILabel()

    // MARK: - Properties
    private var learningStyles: [(id: String, emoji: String, title: String, description: String)] {
        return [
            ("formal", "👔", "goal_formal_title".localized, "goal_formal_desc".localized),
            ("casual", "😊", "goal_casual_title".localized, "goal_casual_desc".localized),
            ("academic", "📚", "goal_academic_title".localized, "goal_academic_desc".localized),
            ("slang", "🔥", "goal_slang_title".localized, "goal_slang_desc".localized),
            ("travel", "✈️", "goal_travel_title".localized, "goal_travel_desc".localized),
            ("technical", "💻", "goal_technical_title".localized, "goal_technical_desc".localized)
        ]
    }

    private var selectedStyles: Set<String> = []

    // MARK: - Lifecycle
    override func configure() {
        step = .learningGoals
        setTitle("onboarding_goals_title".localized)
        setupViews()
        // Optional - enable continue immediately
        updateContinueButton(enabled: true)
    }

    // MARK: - Setup
    private func setupViews() {
        // Intro label
        introLabel.text = "onboarding_goals_intro".localized
        introLabel.font = .systemFont(ofSize: 14, weight: .regular)
        introLabel.textColor = .secondaryLabel
        introLabel.numberOfLines = 0
        introLabel.textAlignment = .center
        contentView.addSubview(introLabel)

        // Scroll view for styles
        goalsScrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(goalsScrollView)

        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        goalsScrollView.addSubview(stackView)

        // Create style option buttons
        for style in learningStyles {
            let optionView = createStyleOption(style)
            stackView.addArrangedSubview(optionView)
        }

        // Skip label
        skipLabel.text = "onboarding_goals_skip".localized
        skipLabel.font = .systemFont(ofSize: 13, weight: .regular)
        skipLabel.textColor = .tertiaryLabel
        skipLabel.textAlignment = .center
        skipLabel.numberOfLines = 0
        contentView.addSubview(skipLabel)

        // Layout
        introLabel.translatesAutoresizingMaskIntoConstraints = false
        goalsScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        skipLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            introLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            introLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            introLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            goalsScrollView.topAnchor.constraint(equalTo: introLabel.bottomAnchor, constant: 20),
            goalsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            goalsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            goalsScrollView.bottomAnchor.constraint(equalTo: skipLabel.topAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: goalsScrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: goalsScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: goalsScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: goalsScrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: goalsScrollView.widthAnchor),

            skipLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skipLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func createStyleOption(_ style: (id: String, emoji: String, title: String, description: String)) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.clear.cgColor
        container.tag = learningStyles.firstIndex(where: { $0.id == style.id }) ?? 0

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(styleTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        // Emoji
        let emojiLabel = UILabel()
        emojiLabel.text = style.emoji
        emojiLabel.font = .systemFont(ofSize: 28)
        container.addSubview(emojiLabel)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = style.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.tag = 101
        container.addSubview(titleLabel)

        // Description
        let descLabel = UILabel()
        descLabel.text = style.description
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        container.addSubview(descLabel)

        // Checkbox
        let checkbox = UIImageView()
        checkbox.image = UIImage(systemName: "circle")
        checkbox.tintColor = .systemGray3
        checkbox.tag = 102
        container.addSubview(checkbox)

        // Layout
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        checkbox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            emojiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 36),

            checkbox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            checkbox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 24),
            checkbox.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),

            descLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            descLabel.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -12),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func styleTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view else { return }
        let index = container.tag
        let styleId = learningStyles[index].id

        // Toggle selection
        if selectedStyles.contains(styleId) {
            selectedStyles.remove(styleId)
            updateOptionAppearance(container, selected: false)
        } else {
            selectedStyles.insert(styleId)
            updateOptionAppearance(container, selected: true)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Update skip label visibility
        skipLabel.isHidden = !selectedStyles.isEmpty
    }

    private func updateOptionAppearance(_ container: UIView, selected: Bool) {
        if selected {
            container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            container.layer.borderColor = UIColor.systemBlue.cgColor
            if let checkbox = container.viewWithTag(102) as? UIImageView {
                checkbox.image = UIImage(systemName: "checkmark.circle.fill")
                checkbox.tintColor = .systemBlue
            }
            if let title = container.viewWithTag(101) as? UILabel {
                title.textColor = .systemBlue
            }
        } else {
            container.backgroundColor = .secondarySystemBackground
            container.layer.borderColor = UIColor.clear.cgColor
            if let checkbox = container.viewWithTag(102) as? UIImageView {
                checkbox.image = UIImage(systemName: "circle")
                checkbox.tintColor = .systemGray3
            }
            if let title = container.viewWithTag(101) as? UILabel {
                title.textColor = .label
            }
        }
    }

    override func continueButtonTapped() {
        // Convert string IDs to LearningContext enum values
        let selectedContexts = selectedStyles.compactMap { LearningContext(rawValue: $0) }
        delegate?.didCompleteStep(withData: selectedContexts)
    }
}
