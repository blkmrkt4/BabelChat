import UIKit

class LearningGoalsViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        return collectionView
    }()

    private let selectionCountLabel = UILabel()

    // MARK: - Properties
    private let goals: [(emoji: String, title: String, description: String)] = [
        ("💼", "Business/Professional", "Advance your career with language skills"),
        ("😄", "Casual", "Make friends and chat naturally"),
        ("👨‍👩‍👧", "Family", "Connect with family and heritage"),
        ("💑", "Relationships", "Meet new people and build connections"),
        ("📚", "Academic", "Support your studies and research")
    ]

    private var selectedGoals: Set<Int> = []

    // MARK: - Lifecycle
    override func configure() {
        step = .learningGoals
        setTitle("What brings you here?",
                subtitle: "This helps others understand your language learning style")
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        // Selection count label
        selectionCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        selectionCountLabel.textAlignment = .center
        updateSelectionLabel()
        contentView.addSubview(selectionCountLabel)

        // Collection view
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GoalCell.self, forCellWithReuseIdentifier: "GoalCell")
        collectionView.allowsMultipleSelection = true
        contentView.addSubview(collectionView)

        // Layout
        selectionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectionCountLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionCountLabel.heightAnchor.constraint(equalToConstant: 30),

            collectionView.topAnchor.constraint(equalTo: selectionCountLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func updateSelectionLabel() {
        let count = selectedGoals.count
        if count == 0 {
            selectionCountLabel.text = "Select at least one goal"
            selectionCountLabel.textColor = .secondaryLabel
        } else if count == 1 {
            selectionCountLabel.text = "1 goal selected"
            selectionCountLabel.textColor = .systemBlue
        } else {
            selectionCountLabel.text = "\(count) goals selected"
            selectionCountLabel.textColor = .systemBlue
        }
    }

    override func continueButtonTapped() {
        let selectedGoalStrings = selectedGoals.map { goals[$0].title }
        delegate?.didCompleteStep(withData: selectedGoalStrings)
    }
}

// MARK: - UICollectionViewDataSource
extension LearningGoalsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return goals.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GoalCell", for: indexPath) as! GoalCell
        let goal = goals[indexPath.item]
        let isSelected = selectedGoals.contains(indexPath.item)
        cell.configure(emoji: goal.emoji, title: goal.title, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension LearningGoalsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedGoals.contains(indexPath.item) {
            selectedGoals.remove(indexPath.item)
        } else {
            selectedGoals.insert(indexPath.item)
        }

        collectionView.reloadItems(at: [indexPath])
        updateSelectionLabel()
        updateContinueButton(enabled: !selectedGoals.isEmpty)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LearningGoalsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 12) / 2
        return CGSize(width: width, height: 120)
    }
}

// MARK: - Goal Cell
private class GoalCell: UICollectionViewCell {
    private let containerView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Container
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        contentView.addSubview(containerView)

        // Emoji
        emojiLabel.font = .systemFont(ofSize: 36)
        emojiLabel.textAlignment = .center
        containerView.addSubview(emojiLabel)

        // Title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        containerView.addSubview(titleLabel)

        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.isHidden = true
        containerView.addSubview(checkmarkImageView)

        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emojiLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 12),

            checkmarkImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(emoji: String, title: String, isSelected: Bool) {
        emojiLabel.text = emoji
        titleLabel.text = title

        if isSelected {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            titleLabel.textColor = .systemBlue
            checkmarkImageView.isHidden = false
        } else {
            containerView.backgroundColor = .secondarySystemBackground
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            titleLabel.textColor = .label
            checkmarkImageView.isHidden = true
        }
    }
}
