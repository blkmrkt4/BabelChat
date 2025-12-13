import UIKit

class ProficiencyRangeViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let proficiencyRangeSelector = ProficiencyRangeSelector()
    private let rangeDisplayLabel = UILabel()
    private let explanationLabel = UILabel()
    private let hintLabel = UILabel()

    // MARK: - Properties
    private var selectedRange: ProficiencyRange = .all

    // MARK: - Lifecycle
    override func configure() {
        step = .proficiencyRange
        setTitle("Who do you want to match with?",
                subtitle: "Select the proficiency range of language partners you'd like to connect with")
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        // Explanation
        explanationLabel.text = "Choose whether you prefer matching with native speakers, learners like yourself, or everyone. This helps us find the best language exchange partners for you."
        explanationLabel.font = .systemFont(ofSize: 15, weight: .regular)
        explanationLabel.textColor = .white.withAlphaComponent(0.8)
        explanationLabel.numberOfLines = 0
        explanationLabel.textAlignment = .center
        contentView.addSubview(explanationLabel)

        // Range display label
        rangeDisplayLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        rangeDisplayLabel.textColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0) // Gold
        rangeDisplayLabel.textAlignment = .center
        contentView.addSubview(rangeDisplayLabel)

        // Proficiency range selector
        proficiencyRangeSelector.delegate = self
        proficiencyRangeSelector.setSelectedRange(selectedRange, animated: false)
        contentView.addSubview(proficiencyRangeSelector)

        // Hint label
        hintLabel.text = "Tap or drag to select a range. Long press for level details."
        hintLabel.font = .systemFont(ofSize: 13, weight: .regular)
        hintLabel.textColor = .white.withAlphaComponent(0.5)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
        contentView.addSubview(hintLabel)

        // Level descriptions
        let descriptionsStack = createLevelDescriptions()
        contentView.addSubview(descriptionsStack)

        // Layout
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        proficiencyRangeSelector.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            explanationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            explanationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            explanationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            rangeDisplayLabel.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: 32),
            rangeDisplayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rangeDisplayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            proficiencyRangeSelector.topAnchor.constraint(equalTo: rangeDisplayLabel.bottomAnchor, constant: 16),
            proficiencyRangeSelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            proficiencyRangeSelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            proficiencyRangeSelector.heightAnchor.constraint(equalToConstant: 52),

            hintLabel.topAnchor.constraint(equalTo: proficiencyRangeSelector.bottomAnchor, constant: 12),
            hintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            descriptionsStack.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 32),
            descriptionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        updateRangeDisplayLabel()
        updateContinueButton(enabled: true)
    }

    private func createLevelDescriptions() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        let levels: [(String, String, String)] = [
            ("Native", "Fluent speakers who grew up with the language", "person.fill.checkmark"),
            ("Adv", "Near-fluent speakers with excellent command", "star.fill"),
            ("Int", "Comfortable with everyday conversations", "message.fill"),
            ("Beg", "Just starting to learn the basics", "book.fill")
        ]

        for (abbrev, description, icon) in levels {
            let row = createLevelRow(abbreviation: abbrev, description: description, iconName: icon)
            stack.addArrangedSubview(row)
        }

        return stack
    }

    private func createLevelRow(abbreviation: String, description: String, iconName: String) -> UIView {
        let container = UIView()

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)

        let abbrevLabel = UILabel()
        abbrevLabel.text = abbreviation
        abbrevLabel.font = .systemFont(ofSize: 14, weight: .bold)
        abbrevLabel.textColor = .white
        container.addSubview(abbrevLabel)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .white.withAlphaComponent(0.7)
        descLabel.numberOfLines = 0
        container.addSubview(descLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        abbrevLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            abbrevLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            abbrevLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            abbrevLabel.widthAnchor.constraint(equalToConstant: 50),

            descLabel.leadingAnchor.constraint(equalTo: abbrevLabel.trailingAnchor, constant: 8),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: container.topAnchor),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true

        return container
    }

    private func updateRangeDisplayLabel() {
        rangeDisplayLabel.text = selectedRange.displayString
    }

    override func continueButtonTapped() {
        // Save to UserDefaults
        selectedRange.saveToDefaults(
            minKey: "minProficiencyLevel",
            maxKey: "maxProficiencyLevel"
        )

        delegate?.didCompleteStep(withData: selectedRange)
    }
}

// MARK: - ProficiencyRangeSelectorDelegate
extension ProficiencyRangeViewController: ProficiencyRangeSelectorDelegate {
    func proficiencyRangeSelector(_ selector: ProficiencyRangeSelector, didSelectRange range: ProficiencyRange) {
        selectedRange = range
        updateRangeDisplayLabel()
    }
}
