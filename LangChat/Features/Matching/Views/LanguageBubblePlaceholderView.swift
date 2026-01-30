import UIKit

class LanguageBubblePlaceholderView: UIView {

    private let bubbleView = UIView()
    private let greetingLabel = UILabel()
    private let instructionLabel = UILabel()
    private let gradientLayer = CAGradientLayer()

    private let greetings = [
        "Hola!",      // Spanish - Slot 1
        "Bonjour!",   // French - Slot 2
        "Guten Tag!", // German - Slot 3
        "你好!",       // Chinese - Slot 4
        "Ciao!",      // Italian - Slot 5
        "こんにちは!"    // Japanese - Slot 6
    ]

    // Gradient color sets (Orange → Magenta → Teal)
    private let gradientColors: [[CGColor]] = [
        // Orange → Pink
        [UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.7).cgColor,
         UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.7).cgColor],
        // Magenta → Purple
        [UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.7).cgColor,
         UIColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 0.7).cgColor],
        // Teal → Blue
        [UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 0.7).cgColor,
         UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.7).cgColor],
        // Purple → Magenta
        [UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7).cgColor,
         UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.7).cgColor],
        // Pink → Orange
        [UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 0.7).cgColor,
         UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.7).cgColor],
        // Blue → Teal
        [UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.7).cgColor,
         UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 0.7).cgColor]
    ]

    init(index: Int) {
        super.init(frame: .zero)
        setupViews(for: index)
        startAnimation()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews(for: 0)
        startAnimation()
    }

    private func setupViews(for index: Int) {
        backgroundColor = .systemGray6

        // Speech bubble container
        bubbleView.layer.cornerRadius = 20
        bubbleView.clipsToBounds = true
        addSubview(bubbleView)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        // Gradient background
        let colorIndex = index % gradientColors.count
        gradientLayer.colors = gradientColors[colorIndex]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 20
        bubbleView.layer.insertSublayer(gradientLayer, at: 0)

        // Greeting text
        let greetingIndex = index % greetings.count
        greetingLabel.text = greetings[greetingIndex]
        greetingLabel.font = .systemFont(ofSize: 24, weight: .bold)
        greetingLabel.textColor = .white
        greetingLabel.textAlignment = .center
        greetingLabel.shadowColor = UIColor.black.withAlphaComponent(0.3)
        greetingLabel.shadowOffset = CGSize(width: 0, height: 1)
        bubbleView.addSubview(greetingLabel)
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false

        // Instruction text
        instructionLabel.text = "photo_long_press_hint".localized
        instructionLabel.font = .systemFont(ofSize: 11, weight: .regular)
        instructionLabel.textColor = .systemGray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 2
        addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Bubble view - centered with some padding
            bubbleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bubbleView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            bubbleView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            bubbleView.heightAnchor.constraint(equalToConstant: 50),

            // Greeting label - centered in bubble
            greetingLabel.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
            greetingLabel.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            greetingLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            greetingLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),

            // Instruction label - below bubble
            instructionLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
            instructionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            instructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bubbleView.bounds
    }

    private func startAnimation() {
        // Gentle pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 0.95
        pulseAnimation.toValue = 1.05
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        bubbleView.layer.add(pulseAnimation, forKey: "pulse")

        // Gentle floating animation
        let floatAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        floatAnimation.duration = 3.0
        floatAnimation.fromValue = -5
        floatAnimation.toValue = 5
        floatAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        floatAnimation.autoreverses = true
        floatAnimation.repeatCount = .infinity
        bubbleView.layer.add(floatAnimation, forKey: "float")
    }

    func stopAnimation() {
        bubbleView.layer.removeAllAnimations()
    }
}
