import UIKit

class TravelPlansViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let skipButton = UIButton(type: .system)
    private let infoLabel = UILabel()
    private let addTravelButton = UIButton(type: .system)

    // MARK: - Properties
    private var hasTravelPlans: Bool = false

    // MARK: - Lifecycle
    override func configure() {
        step = .travelPlans
        setTitle("Planning to travel?",
                subtitle: "Connect with locals where you're heading")
        setupViews()

        // Enable continue button (can skip this step)
        updateContinueButton(enabled: true)
        continueButton.setTitle("Skip", for: .normal)
    }

    // MARK: - Setup
    private func setupViews() {
        // Info label
        infoLabel.text = "Add your travel plans to match with people in those locations. This is optional and can be added later."
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        contentView.addSubview(infoLabel)

        // Add travel button
        addTravelButton.setTitle("Add Travel Plans", for: .normal)
        addTravelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addTravelButton.backgroundColor = .secondarySystemBackground
        addTravelButton.setTitleColor(.label, for: .normal)
        addTravelButton.layer.cornerRadius = 12
        addTravelButton.addTarget(self, action: #selector(addTravelButtonTapped), for: .touchUpInside)
        contentView.addSubview(addTravelButton)

        // Image/icon for travel
        let iconView = UIImageView(image: UIImage(systemName: "airplane.departure"))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)

        // Layout
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        addTravelButton.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            infoLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            addTravelButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 32),
            addTravelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addTravelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addTravelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions
    @objc private func addTravelButtonTapped() {
        // For now, just show a simple alert
        // In the future, this could show a proper destination picker
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "Travel destination picker will be available in a future update. You can skip for now and add travel plans later in settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func continueButtonTapped() {
        // For now, always pass nil (no travel plans)
        // In the future, this would pass the actual TravelDestination
        delegate?.didCompleteStep(withData: nil as TravelDestination?)
    }
}
