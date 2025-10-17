import UIKit

protocol SwipeCardDelegate: AnyObject {
    func didSwipe(_ card: SwipeCardView, direction: SwipeDirection)
    func didTapCard(_ card: SwipeCardView)
}

class SwipeCardView: UIView {

    weak var delegate: SwipeCardDelegate?
    var user: User? {
        didSet {
            updateUI()
        }
    }

    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let nameLabel = UILabel()
    private let ageLabel = UILabel()
    private let locationLabel = UILabel()
    private let languageStackView = UIStackView()
    private let matchScoreBadge = UIView()
    private let matchScoreLabel = UILabel()
    private let likeLabel = UILabel()
    private let nopeLabel = UILabel()
    private let superLikeLabel = UILabel()

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var initialCenter: CGPoint = .zero

    // Store match info
    var matchScore: Int?
    var matchReasons: [String]?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
    }

    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        clipsToBounds = false

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .systemGray5
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        gradientLayer.locations = [0.5, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .white
        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        ageLabel.font = .systemFont(ofSize: 24, weight: .regular)
        ageLabel.textColor = .white
        addSubview(ageLabel)
        ageLabel.translatesAutoresizingMaskIntoConstraints = false

        locationLabel.font = .systemFont(ofSize: 16, weight: .regular)
        locationLabel.textColor = .white.withAlphaComponent(0.9)
        addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        languageStackView.axis = .horizontal
        languageStackView.spacing = 8
        languageStackView.distribution = .fillProportionally
        addSubview(languageStackView)
        languageStackView.translatesAutoresizingMaskIntoConstraints = false

        // Setup match score badge
        matchScoreBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        matchScoreBadge.layer.cornerRadius = 20
        matchScoreBadge.isHidden = true
        addSubview(matchScoreBadge)
        matchScoreBadge.translatesAutoresizingMaskIntoConstraints = false

        matchScoreLabel.font = .systemFont(ofSize: 14, weight: .bold)
        matchScoreLabel.textColor = .white
        matchScoreLabel.textAlignment = .center
        matchScoreBadge.addSubview(matchScoreLabel)
        matchScoreLabel.translatesAutoresizingMaskIntoConstraints = false

        setupSwipeLabels()

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameLabel.bottomAnchor.constraint(equalTo: locationLabel.topAnchor, constant: -5),

            ageLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            ageLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),

            locationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            locationLabel.bottomAnchor.constraint(equalTo: languageStackView.topAnchor, constant: -10),

            languageStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            languageStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            languageStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            matchScoreBadge.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            matchScoreBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            matchScoreBadge.widthAnchor.constraint(equalToConstant: 70),
            matchScoreBadge.heightAnchor.constraint(equalToConstant: 40),

            matchScoreLabel.centerXAnchor.constraint(equalTo: matchScoreBadge.centerXAnchor),
            matchScoreLabel.centerYAnchor.constraint(equalTo: matchScoreBadge.centerYAnchor)
        ])
    }

    private func setupSwipeLabels() {
        likeLabel.text = "LIKE"
        likeLabel.font = .systemFont(ofSize: 40, weight: .bold)
        likeLabel.textColor = .systemGreen
        likeLabel.layer.borderColor = UIColor.systemGreen.cgColor
        likeLabel.layer.borderWidth = 4
        likeLabel.layer.cornerRadius = 10
        likeLabel.textAlignment = .center
        likeLabel.alpha = 0
        addSubview(likeLabel)
        likeLabel.translatesAutoresizingMaskIntoConstraints = false

        nopeLabel.text = "NOPE"
        nopeLabel.font = .systemFont(ofSize: 40, weight: .bold)
        nopeLabel.textColor = .systemRed
        nopeLabel.layer.borderColor = UIColor.systemRed.cgColor
        nopeLabel.layer.borderWidth = 4
        nopeLabel.layer.cornerRadius = 10
        nopeLabel.textAlignment = .center
        nopeLabel.alpha = 0
        addSubview(nopeLabel)
        nopeLabel.translatesAutoresizingMaskIntoConstraints = false

        superLikeLabel.text = "SUPER\nLIKE"
        superLikeLabel.numberOfLines = 2
        superLikeLabel.font = .systemFont(ofSize: 30, weight: .bold)
        superLikeLabel.textColor = .systemBlue
        superLikeLabel.layer.borderColor = UIColor.systemBlue.cgColor
        superLikeLabel.layer.borderWidth = 4
        superLikeLabel.layer.cornerRadius = 10
        superLikeLabel.textAlignment = .center
        superLikeLabel.alpha = 0
        addSubview(superLikeLabel)
        superLikeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            likeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            likeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            likeLabel.widthAnchor.constraint(equalToConstant: 120),
            likeLabel.heightAnchor.constraint(equalToConstant: 60),

            nopeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            nopeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nopeLabel.widthAnchor.constraint(equalToConstant: 120),
            nopeLabel.heightAnchor.constraint(equalToConstant: 60),

            superLikeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            superLikeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            superLikeLabel.widthAnchor.constraint(equalToConstant: 120),
            superLikeLabel.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGestureRecognizer)

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGestureRecognizer)
    }

    private func updateUI() {
        guard let user = user else { return }

        nameLabel.text = user.firstName

        // Display actual age or hide label if not available
        if let age = user.age {
            ageLabel.text = "\(age)"
            ageLabel.isHidden = false
        } else {
            ageLabel.isHidden = true
        }

        locationLabel.text = user.location

        // Display match score if available
        if let score = matchScore {
            matchScoreBadge.isHidden = false
            matchScoreLabel.text = "\(score)%"

            // Color code the badge based on score
            if score >= 80 {
                matchScoreBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
            } else if score >= 60 {
                matchScoreBadge.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.9)
            } else {
                matchScoreBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
            }
        } else {
            matchScoreBadge.isHidden = true
        }

        languageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let nativeBadge = LanguageBadgeView()
        nativeBadge.configure(with: user.nativeLanguage, isNative: true, showStar: false)
        languageStackView.addArrangedSubview(nativeBadge)

        for language in user.learningLanguages.prefix(2) {
            let badge = LanguageBadgeView()
            let isOpenToMatch = user.openToLanguages.contains { $0.code == language.language.code }
            badge.configure(with: language, isNative: false, showStar: isOpenToMatch)
            languageStackView.addArrangedSubview(badge)
        }

        if let imageURL = user.profileImageURL {
            ImageService.shared.loadImage(
                from: imageURL,
                into: imageView,
                placeholder: UIImage(systemName: "person.fill")
            )
        } else {
            imageView.image = UIImage(systemName: "person.fill")
            imageView.tintColor = .systemGray3
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        let velocity = gesture.velocity(in: superview)

        switch gesture.state {
        case .began:
            initialCenter = center

        case .changed:
            center = CGPoint(x: initialCenter.x + translation.x,
                           y: initialCenter.y + translation.y)

            let rotationAngle = translation.x / (superview!.frame.width / 2) * 0.3
            transform = CGAffineTransform(rotationAngle: rotationAngle)

            updateSwipeIndicators(translation: translation)

        case .ended:
            if abs(translation.x) > 100 || abs(velocity.x) > 500 {
                if translation.x > 0 {
                    swipeCard(direction: .right)
                } else {
                    swipeCard(direction: .left)
                }
            } else if translation.y < -50 && abs(translation.x) < 50 {
                swipeCard(direction: .up)
            } else {
                resetCard()
            }

        default:
            break
        }
    }

    private func updateSwipeIndicators(translation: CGPoint) {
        let threshold: CGFloat = 100

        if translation.x > threshold {
            likeLabel.alpha = min(1, (translation.x - threshold) / 100)
            nopeLabel.alpha = 0
            superLikeLabel.alpha = 0
        } else if translation.x < -threshold {
            nopeLabel.alpha = min(1, (-translation.x - threshold) / 100)
            likeLabel.alpha = 0
            superLikeLabel.alpha = 0
        } else if translation.y < -50 && abs(translation.x) < 50 {
            superLikeLabel.alpha = min(1, (-translation.y - 50) / 100)
            likeLabel.alpha = 0
            nopeLabel.alpha = 0
        } else {
            likeLabel.alpha = 0
            nopeLabel.alpha = 0
            superLikeLabel.alpha = 0
        }
    }

    func swipeCard(direction: SwipeDirection) {
        let translationX: CGFloat
        let translationY: CGFloat

        switch direction {
        case .left:
            translationX = -(superview?.frame.width ?? 500) * 1.5
            translationY = 0
        case .right:
            translationX = (superview?.frame.width ?? 500) * 1.5
            translationY = 0
        case .up:
            translationX = 0
            translationY = -(superview?.frame.height ?? 800)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.center = CGPoint(x: translationX, y: translationY)
            self.alpha = 0
        }) { _ in
            self.delegate?.didSwipe(self, direction: direction)
        }
    }

    private func resetCard() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.center = self.initialCenter
            self.transform = .identity
            self.likeLabel.alpha = 0
            self.nopeLabel.alpha = 0
            self.superLikeLabel.alpha = 0
        }
    }

    @objc private func handleTap() {
        delegate?.didTapCard(self)
    }
}

enum SwipeDirection {
    case left
    case right
    case up
}