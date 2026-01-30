import UIKit

class LanguageProficiencyViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let proficiencyScrollView = UIScrollView()
    private let stackView = UIStackView()
    private let headerLabel = UILabel()

    // MARK: - Properties
    var languages: [Language] = []
    private var proficiencySelections: [Language: LanguageProficiency] = [:]

    // MARK: - Lifecycle
    override func configure() {
        step = .languageProficiency
        setTitle("onboarding_proficiency_title".localized)
        setupViews()
        createProficiencyCards()
    }

    // MARK: - Setup
    private func setupViews() {
        // Scroll view
        contentView.addSubview(proficiencyScrollView)

        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .equalSpacing
        proficiencyScrollView.addSubview(stackView)

        // Layout
        proficiencyScrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            proficiencyScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            proficiencyScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            proficiencyScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            proficiencyScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: proficiencyScrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: proficiencyScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: proficiencyScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: proficiencyScrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: proficiencyScrollView.widthAnchor)
        ])
    }

    private func createProficiencyCards() {
        for language in languages {
            let card = LanguageProficiencyCard(language: language)
            card.delegate = self
            stackView.addArrangedSubview(card)

            // Set default proficiency
            proficiencySelections[language] = .beginner
        }

        // Enable continue button since we have default selections
        updateContinueButton(enabled: true)
    }

    override func continueButtonTapped() {
        let proficiencyData = languages.compactMap { language -> (Language, LanguageProficiency)? in
            guard let proficiency = proficiencySelections[language] else { return nil }
            return (language, proficiency)
        }
        delegate?.didCompleteStep(withData: proficiencyData)
    }
}

// MARK: - LanguageProficiencyCardDelegate
extension LanguageProficiencyViewController: LanguageProficiencyCardDelegate {
    func didSelectProficiency(_ proficiency: LanguageProficiency, for language: Language) {
        proficiencySelections[language] = proficiency
    }
}

// MARK: - Language Proficiency Card
protocol LanguageProficiencyCardDelegate: AnyObject {
    func didSelectProficiency(_ proficiency: LanguageProficiency, for language: Language)
}

private class LanguageProficiencyCard: UIView {
    weak var delegate: LanguageProficiencyCardDelegate?

    private let language: Language
    private let containerView = UIView()
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let proficiencyStackView = UIStackView()
    private var proficiencyButtons: [UIButton] = []
    private var selectedProficiency: LanguageProficiency = .beginner

    init(language: Language) {
        self.language = language
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Container
        containerView.layer.cornerRadius = 16
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.shadowColor = UIColor.label.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        addSubview(containerView)

        // Flag
        flagLabel.text = language.flag
        flagLabel.font = .systemFont(ofSize: 40)
        flagLabel.textAlignment = .center
        containerView.addSubview(flagLabel)

        // Name
        nameLabel.text = language.name
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        containerView.addSubview(nameLabel)

        // Proficiency stack
        proficiencyStackView.axis = .vertical
        proficiencyStackView.spacing = 12
        proficiencyStackView.distribution = .fillEqually
        containerView.addSubview(proficiencyStackView)

        // Create proficiency buttons with localized descriptions
        let proficiencies: [(LanguageProficiency, String)] = [
            (.beginner, "proficiency_beginner_desc".localized),
            (.intermediate, "proficiency_intermediate_desc".localized),
            (.advanced, "proficiency_advanced_desc".localized)
        ]

        for (proficiency, description) in proficiencies {
            let button = createProficiencyButton(proficiency: proficiency, description: description)
            proficiencyButtons.append(button)
            proficiencyStackView.addArrangedSubview(button)
        }

        // Select beginner by default
        selectProficiency(.beginner)

        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        flagLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        proficiencyStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            flagLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            flagLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: flagLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            proficiencyStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            proficiencyStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            proficiencyStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            proficiencyStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func createProficiencyButton(proficiency: LanguageProficiency, description: String) -> UIButton {
        let button = UIButton()
        button.tag = proficiency.hashValue

        let container = UIView()
        container.isUserInteractionEnabled = false
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 2
        button.addSubview(container)

        let levelLabel = UILabel()
        levelLabel.text = proficiency.displayName
        levelLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        container.addSubview(levelLabel)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        container.addSubview(descLabel)

        container.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: button.topAnchor),
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor),

            levelLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            levelLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            levelLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        button.addTarget(self, action: #selector(proficiencyButtonTapped), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        return button
    }

    @objc private func proficiencyButtonTapped(_ sender: UIButton) {
        let proficiencies: [LanguageProficiency] = [.beginner, .intermediate, .advanced]
        for proficiency in proficiencies {
            if sender.tag == proficiency.hashValue {
                selectProficiency(proficiency)
                delegate?.didSelectProficiency(proficiency, for: language)
                break
            }
        }
    }

    private func selectProficiency(_ proficiency: LanguageProficiency) {
        selectedProficiency = proficiency

        for button in proficiencyButtons {
            if let container = button.subviews.first {
                let isSelected = button.tag == proficiency.hashValue

                if isSelected {
                    container.backgroundColor = .systemBlue.withAlphaComponent(0.1)
                    container.layer.borderColor = UIColor.systemBlue.cgColor

                    if let levelLabel = container.subviews.first(where: { $0 is UILabel }) as? UILabel {
                        levelLabel.textColor = .systemBlue
                    }
                } else {
                    container.backgroundColor = .systemBackground
                    container.layer.borderColor = UIColor.systemGray4.cgColor

                    if let levelLabel = container.subviews.first(where: { $0 is UILabel }) as? UILabel {
                        levelLabel.textColor = .label
                    }
                }
            }
        }
    }
}
