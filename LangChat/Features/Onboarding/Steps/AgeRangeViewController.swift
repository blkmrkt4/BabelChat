import UIKit

class AgeRangeViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let rangeLabel = UILabel()
    private let minAgeLabel = UILabel()
    private let maxAgeLabel = UILabel()
    private let minAgeSlider = UISlider()
    private let maxAgeSlider = UISlider()
    private let stackView = UIStackView()

    // MARK: - Properties
    private var minAge: Int = 18
    private var maxAge: Int = 80

    // MARK: - Lifecycle
    override func configure() {
        step = .ageRange
        setTitle("Age range?")
        setupSliders()
        updateContinueButton(enabled: true)
    }

    // MARK: - Setup
    private func setupSliders() {
        // Range display label
        rangeLabel.font = .systemFont(ofSize: 36, weight: .bold)
        rangeLabel.textColor = .label
        rangeLabel.textAlignment = .center
        rangeLabel.text = "\(minAge)-\(maxAge)"
        contentView.addSubview(rangeLabel)

        // Stack view for sliders
        stackView.axis = .vertical
        stackView.spacing = 32
        contentView.addSubview(stackView)

        // Min age section
        let minSection = createSliderSection(
            title: "Minimum Age",
            valueLabel: minAgeLabel,
            slider: minAgeSlider,
            minValue: 18,
            maxValue: 80,
            initialValue: Float(minAge),
            action: #selector(minAgeChanged)
        )
        stackView.addArrangedSubview(minSection)

        // Max age section
        let maxSection = createSliderSection(
            title: "Maximum Age",
            valueLabel: maxAgeLabel,
            slider: maxAgeSlider,
            minValue: 18,
            maxValue: 80,
            initialValue: Float(maxAge),
            action: #selector(maxAgeChanged)
        )
        stackView.addArrangedSubview(maxSection)

        // Layout
        rangeLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rangeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rangeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: rangeLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createSliderSection(
        title: String,
        valueLabel: UILabel,
        slider: UISlider,
        minValue: Float,
        maxValue: Float,
        initialValue: Float,
        action: Selector
    ) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        container.addSubview(titleLabel)

        valueLabel.text = "\(Int(initialValue))"
        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = .label
        container.addSubview(valueLabel)

        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = initialValue
        slider.tintColor = .systemBlue
        slider.addTarget(self, action: action, for: .valueChanged)
        container.addSubview(slider)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions
    @objc private func minAgeChanged() {
        minAge = Int(minAgeSlider.value)
        minAgeLabel.text = "\(minAge)"

        // Ensure min doesn't exceed max
        if minAge > maxAge {
            maxAge = minAge
            maxAgeSlider.value = Float(maxAge)
            maxAgeLabel.text = "\(maxAge)"
        }

        updateRangeLabel()
    }

    @objc private func maxAgeChanged() {
        maxAge = Int(maxAgeSlider.value)
        maxAgeLabel.text = "\(maxAge)"

        // Ensure max isn't below min
        if maxAge < minAge {
            minAge = maxAge
            minAgeSlider.value = Float(minAge)
            minAgeLabel.text = "\(minAge)"
        }

        updateRangeLabel()
    }

    private func updateRangeLabel() {
        rangeLabel.text = "\(minAge)-\(maxAge)"

        // Animate the change
        UIView.animate(withDuration: 0.2) {
            self.rangeLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.rangeLabel.transform = .identity
            }
        }
    }

    override func continueButtonTapped() {
        delegate?.didCompleteStep(withData: (minAge, maxAge))
    }
}
