import UIKit

class AIModelCell: UITableViewCell {
    static let identifier = "AIModelCell"

    private let nameLabel = UILabel()
    private let providerLabel = UILabel()
    private let costLabel = UILabel()
    private let scoreLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    var config: AIModelConfig? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        layer.cornerRadius = 8
        selectionStyle = .none

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.lineBreakMode = .byTruncatingTail

        providerLabel.font = .systemFont(ofSize: 14)
        providerLabel.textColor = .secondaryLabel
        providerLabel.isHidden = true  // Not using separate provider label anymore

        costLabel.font = .systemFont(ofSize: 12)
        costLabel.textColor = .secondaryLabel
        costLabel.numberOfLines = 2
        costLabel.adjustsFontSizeToFitWidth = false
        costLabel.lineBreakMode = .byTruncatingTail

        scoreLabel.font = .systemFont(ofSize: 14, weight: .medium)
        scoreLabel.textColor = .systemBlue
        scoreLabel.textAlignment = .right

        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.isHidden = true

        [nameLabel, providerLabel, costLabel, scoreLabel, checkmarkImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Name label (now contains "Model Name : Provider")
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -8),

            // Cost label moved up (was below provider, now below name)
            costLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            costLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            costLabel.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -8),
            costLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // Score label on right side
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            scoreLabel.widthAnchor.constraint(equalToConstant: 45),

            // Checkmark (hidden by default)
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func updateUI() {
        guard let config = config else { return }

        // Combine name and provider: "Model Name : Provider"
        nameLabel.text = "\(config.modelName) : \(config.modelProvider)"

        if let costDisplay = config.costDisplay {
            costLabel.text = costDisplay
            costLabel.isHidden = false
        } else {
            costLabel.isHidden = true
        }

        if let score = config.userScore {
            scoreLabel.text = String(format: "(%.1f)", score)
            scoreLabel.isHidden = false
        } else {
            scoreLabel.isHidden = true
        }

        checkmarkImageView.isHidden = !config.isDefault
    }

    func configure(with model: AIModel, score: Float?) {
        // Combine name and provider: "Model Name : Provider"
        nameLabel.text = "\(model.name) : \(model.provider)"
        costLabel.text = model.costDisplay
        costLabel.isHidden = false

        if let score = score {
            scoreLabel.text = String(format: "%.1f", score)
            scoreLabel.textColor = .systemBlue
        } else {
            scoreLabel.text = "{UT}"
            scoreLabel.textColor = .systemOrange
        }
        scoreLabel.isHidden = false

        checkmarkImageView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else {
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        }
    }
}