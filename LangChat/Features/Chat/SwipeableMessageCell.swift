import UIKit
import AVFoundation

// Protocol to notify when pane changes
protocol SwipeableMessageCellDelegate: AnyObject {
    func cell(_ cell: SwipeableMessageCell, didSwipeToPaneIndex paneIndex: Int)
}

class SwipeableMessageCell: UITableViewCell {

    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let containerView = UIView()

    // Three panes for swipeable content
    private let leftPane = UIView() // Grammar/Alternatives
    private let centerPane = UIView() // Original message
    private let rightPane = UIView() // Translation

    // Center pane elements
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let profileImageView = UIImageView()

    // Right pane (translation) elements
    private let translationScrollView = UIScrollView()
    private let translationBubbleView = UIView()
    private let translationLabel = UILabel()
    private let translationTitleLabel = UILabel()

    // Left pane (grammar/alternatives) elements
    private let grammarScrollView = UIScrollView()
    private let grammarBubbleView = UIView()
    private let grammarTitleLabel = UILabel()
    private let grammarStackView = UIStackView()
    private let alternativesLabel = UILabel()
    private let alternativesStackView = UIStackView()

    // Speech synthesizer for pronunciation
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var currentMessage: Message?
    private var granularityLevel: Int = 2 // 1-3 from settings
    weak var delegate: SwipeableMessageCellDelegate?

    // Language context for API calls
    private var learningLanguage: Language = .spanish // Language being practiced
    private var nativeLanguage: Language = .english // User's native language

    // Constraints for dynamic layout
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!

    // Static cache for translations and grammar checks (across cell reuse)
    private static var translationCache: [String: String] = [:] // messageId: translation
    private static var grammarCache: [String: String] = [:] // messageId: grammarJSON

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset to center pane when cell is reused
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 375
        scrollView.setContentOffset(CGPoint(x: screenWidth, y: 0), animated: false)

        // Clear previous content
        grammarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        alternativesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        currentMessage = nil
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        // Setup scroll view
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.delegate = self
        contentView.addSubview(scrollView)

        scrollView.addSubview(containerView)

        // Add three panes to container
        containerView.addSubview(leftPane)
        containerView.addSubview(centerPane)
        containerView.addSubview(rightPane)

        setupCenterPane()
        setupRightPane()
        setupLeftPane()

        setupConstraints()
    }

    private func setupCenterPane() {
        // Bubble view
        bubbleView.layer.cornerRadius = 16
        centerPane.addSubview(bubbleView)

        // Message label
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        bubbleView.addSubview(messageLabel)

        // Time label
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabel
        centerPane.addSubview(timeLabel)

        // Profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 16
        centerPane.addSubview(profileImageView)
    }

    private func setupRightPane() {
        // Translation pane with scroll view
        translationScrollView.showsVerticalScrollIndicator = true
        translationScrollView.bounces = true
        rightPane.addSubview(translationScrollView)

        translationBubbleView.backgroundColor = .systemIndigo.withAlphaComponent(0.1)
        translationBubbleView.layer.cornerRadius = 16
        translationScrollView.addSubview(translationBubbleView)

        translationTitleLabel.text = "Translation"
        translationTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        translationTitleLabel.textColor = .systemIndigo
        translationBubbleView.addSubview(translationTitleLabel)

        translationLabel.numberOfLines = 0
        translationLabel.font = .systemFont(ofSize: 16)
        translationLabel.textColor = .label
        translationBubbleView.addSubview(translationLabel)
    }

    private func setupLeftPane() {
        // Grammar/Alternatives pane with scroll view
        grammarScrollView.showsVerticalScrollIndicator = true
        grammarScrollView.bounces = true
        leftPane.addSubview(grammarScrollView)

        grammarBubbleView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        grammarBubbleView.layer.cornerRadius = 16
        grammarScrollView.addSubview(grammarBubbleView)

        grammarTitleLabel.text = "Grammar & Alternatives"
        grammarTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        grammarTitleLabel.textColor = .systemGreen
        grammarBubbleView.addSubview(grammarTitleLabel)

        grammarStackView.axis = .vertical
        grammarStackView.spacing = 8
        grammarStackView.distribution = .equalSpacing
        grammarBubbleView.addSubview(grammarStackView)

        alternativesLabel.text = "Alternative phrases:"
        alternativesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        alternativesLabel.textColor = .secondaryLabel
        grammarBubbleView.addSubview(alternativesLabel)

        alternativesStackView.axis = .vertical
        alternativesStackView.spacing = 4
        grammarBubbleView.addSubview(alternativesStackView)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        leftPane.translatesAutoresizingMaskIntoConstraints = false
        centerPane.translatesAutoresizingMaskIntoConstraints = false
        rightPane.translatesAutoresizingMaskIntoConstraints = false

        // Scroll view constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Container view constraints - height matches scroll view
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 375

        // Three panes side by side
        NSLayoutConstraint.activate([
            // Left pane (grammar/alternatives)
            leftPane.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftPane.topAnchor.constraint(equalTo: containerView.topAnchor),
            leftPane.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            leftPane.widthAnchor.constraint(equalToConstant: screenWidth),

            // Center pane (original message)
            centerPane.leadingAnchor.constraint(equalTo: leftPane.trailingAnchor),
            centerPane.topAnchor.constraint(equalTo: containerView.topAnchor),
            centerPane.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            centerPane.widthAnchor.constraint(equalToConstant: screenWidth),

            // Right pane (translation)
            rightPane.leadingAnchor.constraint(equalTo: centerPane.trailingAnchor),
            rightPane.topAnchor.constraint(equalTo: containerView.topAnchor),
            rightPane.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            rightPane.widthAnchor.constraint(equalToConstant: screenWidth),
            rightPane.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Setup center pane constraints
        setupCenterPaneConstraints()
        setupRightPaneConstraints()
        setupLeftPaneConstraints()
    }

    private func setupCenterPaneConstraints() {
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: centerPane.leadingAnchor, constant: 12),
            profileImageView.topAnchor.constraint(equalTo: centerPane.topAnchor, constant: 4),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),

            bubbleView.topAnchor.constraint(equalTo: centerPane.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -2),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),  // Fixed width instead of UIScreen.main

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),

            timeLabel.heightAnchor.constraint(equalToConstant: 14),
            timeLabel.bottomAnchor.constraint(equalTo: centerPane.bottomAnchor, constant: -4)
        ])

        // Dynamic constraints for sent/received messages
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: centerPane.trailingAnchor, constant: -16)
    }

    private func setupRightPaneConstraints() {
        translationScrollView.translatesAutoresizingMaskIntoConstraints = false
        translationBubbleView.translatesAutoresizingMaskIntoConstraints = false
        translationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        translationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view fills the right pane
            translationScrollView.topAnchor.constraint(equalTo: rightPane.topAnchor, constant: 8),
            translationScrollView.leadingAnchor.constraint(equalTo: rightPane.leadingAnchor, constant: 16),
            translationScrollView.trailingAnchor.constraint(equalTo: rightPane.trailingAnchor, constant: -16),
            translationScrollView.bottomAnchor.constraint(equalTo: rightPane.bottomAnchor, constant: -8),

            // Bubble view inside scroll view
            translationBubbleView.topAnchor.constraint(equalTo: translationScrollView.topAnchor),
            translationBubbleView.leadingAnchor.constraint(equalTo: translationScrollView.leadingAnchor),
            translationBubbleView.trailingAnchor.constraint(equalTo: translationScrollView.trailingAnchor),
            translationBubbleView.bottomAnchor.constraint(equalTo: translationScrollView.bottomAnchor),
            translationBubbleView.widthAnchor.constraint(equalTo: translationScrollView.widthAnchor),

            translationTitleLabel.topAnchor.constraint(equalTo: translationBubbleView.topAnchor, constant: 8),
            translationTitleLabel.leadingAnchor.constraint(equalTo: translationBubbleView.leadingAnchor, constant: 12),
            translationTitleLabel.trailingAnchor.constraint(equalTo: translationBubbleView.trailingAnchor, constant: -12),

            translationLabel.topAnchor.constraint(equalTo: translationTitleLabel.bottomAnchor, constant: 4),
            translationLabel.leadingAnchor.constraint(equalTo: translationBubbleView.leadingAnchor, constant: 12),
            translationLabel.trailingAnchor.constraint(equalTo: translationBubbleView.trailingAnchor, constant: -12),
            translationLabel.bottomAnchor.constraint(equalTo: translationBubbleView.bottomAnchor, constant: -8)
        ])
    }

    private func setupLeftPaneConstraints() {
        grammarScrollView.translatesAutoresizingMaskIntoConstraints = false
        grammarBubbleView.translatesAutoresizingMaskIntoConstraints = false
        grammarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        grammarStackView.translatesAutoresizingMaskIntoConstraints = false
        alternativesLabel.translatesAutoresizingMaskIntoConstraints = false
        alternativesStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll view fills the left pane
            grammarScrollView.topAnchor.constraint(equalTo: leftPane.topAnchor, constant: 8),
            grammarScrollView.leadingAnchor.constraint(equalTo: leftPane.leadingAnchor, constant: 16),
            grammarScrollView.trailingAnchor.constraint(equalTo: leftPane.trailingAnchor, constant: -16),
            grammarScrollView.bottomAnchor.constraint(equalTo: leftPane.bottomAnchor, constant: -8),

            // Bubble view inside scroll view
            grammarBubbleView.topAnchor.constraint(equalTo: grammarScrollView.topAnchor),
            grammarBubbleView.leadingAnchor.constraint(equalTo: grammarScrollView.leadingAnchor),
            grammarBubbleView.trailingAnchor.constraint(equalTo: grammarScrollView.trailingAnchor),
            grammarBubbleView.bottomAnchor.constraint(equalTo: grammarScrollView.bottomAnchor),
            grammarBubbleView.widthAnchor.constraint(equalTo: grammarScrollView.widthAnchor),

            grammarTitleLabel.topAnchor.constraint(equalTo: grammarBubbleView.topAnchor, constant: 8),
            grammarTitleLabel.leadingAnchor.constraint(equalTo: grammarBubbleView.leadingAnchor, constant: 12),
            grammarTitleLabel.trailingAnchor.constraint(equalTo: grammarBubbleView.trailingAnchor, constant: -12),

            grammarStackView.topAnchor.constraint(equalTo: grammarTitleLabel.bottomAnchor, constant: 8),
            grammarStackView.leadingAnchor.constraint(equalTo: grammarBubbleView.leadingAnchor, constant: 12),
            grammarStackView.trailingAnchor.constraint(equalTo: grammarBubbleView.trailingAnchor, constant: -12),

            alternativesLabel.topAnchor.constraint(equalTo: grammarStackView.bottomAnchor, constant: 12),
            alternativesLabel.leadingAnchor.constraint(equalTo: grammarBubbleView.leadingAnchor, constant: 12),
            alternativesLabel.trailingAnchor.constraint(equalTo: grammarBubbleView.trailingAnchor, constant: -12),

            alternativesStackView.topAnchor.constraint(equalTo: alternativesLabel.bottomAnchor, constant: 4),
            alternativesStackView.leadingAnchor.constraint(equalTo: grammarBubbleView.leadingAnchor, constant: 12),
            alternativesStackView.trailingAnchor.constraint(equalTo: grammarBubbleView.trailingAnchor, constant: -12),
            alternativesStackView.bottomAnchor.constraint(equalTo: grammarBubbleView.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Gestures
    private func setupGestures() {
        // Double tap for pronunciation
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(pronounceMessage))
        doubleTap.numberOfTapsRequired = 2
        centerPane.addGestureRecognizer(doubleTap)

        // Long press to save phrase
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(savePhrase))
        centerPane.addGestureRecognizer(longPress)

        // Swipe gestures on the bubble itself (alternative to scrolling)
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        leftSwipe.direction = .left
        centerPane.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        rightSwipe.direction = .right
        centerPane.addGestureRecognizer(rightSwipe)
    }

    @objc private func pronounceMessage() {
        guard let message = currentMessage else { return }

        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.bubbleView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.bubbleView.transform = .identity
            }
        }

        // Use AVSpeechSynthesizer with original language
        let utterance = AVSpeechUtterance(string: message.text)

        // Set voice based on language if available
        if let language = message.originalLanguage {
            let languageCode: String
            switch language {
            case .spanish: languageCode = "es-ES"
            case .french: languageCode = "fr-FR"
            case .german: languageCode = "de-DE"
            case .japanese: languageCode = "ja-JP"
            case .korean: languageCode = "ko-KR"
            case .chinese: languageCode = "zh-CN"
            case .portuguese: languageCode = "pt-PT"
            case .italian: languageCode = "it-IT"
            case .russian: languageCode = "ru-RU"
            default: languageCode = "en-US"
            }
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        }

        utterance.rate = 0.4 // Slower for language learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9

        speechSynthesizer.speak(utterance)

        // Show pronunciation indicator
        showToast("🔊 Playing pronunciation...")
    }

    @objc private func savePhrase(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let message = currentMessage else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Visual feedback
        UIView.animate(withDuration: 0.2) {
            self.bubbleView.backgroundColor = self.bubbleView.backgroundColor?.withAlphaComponent(0.7)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.bubbleView.backgroundColor = self.bubbleView.backgroundColor?.withAlphaComponent(1.0)
            }
        }

        // Save to user defaults (in real app, would save to CloudKit)
        var savedPhrases = UserDefaults.standard.stringArray(forKey: "savedPhrases") ?? []
        savedPhrases.append(message.text)
        UserDefaults.standard.set(savedPhrases, forKey: "savedPhrases")

        showToast("✅ Phrase saved to vocabulary")
    }

    @objc private func swipeLeft() {
        // When swiping left on center pane, show translation (right pane)
        // This follows natural iOS swipe direction
        let screenWidth = scrollView.bounds.width
        let currentPage = Int(scrollView.contentOffset.x / screenWidth)
        if currentPage == 1 { // Currently on center pane
            scrollToPane(2) // Go to right pane (translation)
        } else if currentPage == 2 { // Currently on right pane
            scrollToPane(1) // Go back to center
        }
    }

    @objc private func swipeRight() {
        // When swiping right on center pane, show grammar/alternatives (left pane)
        // This follows natural iOS swipe direction
        let screenWidth = scrollView.bounds.width
        let currentPage = Int(scrollView.contentOffset.x / screenWidth)
        if currentPage == 1 { // Currently on center pane
            scrollToPane(0) // Go to left pane (grammar)
        } else if currentPage == 0 { // Currently on left pane
            scrollToPane(1) // Go back to center
        }
    }

    private func scrollToPane(_ paneIndex: Int) {
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 375
        let xOffset = CGFloat(paneIndex) * screenWidth
        scrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }

    // MARK: - Configuration
    func configure(with message: Message, user: User, granularity: Int = 2, learningLanguage: Language, nativeLanguage: Language) {
        currentMessage = message
        granularityLevel = granularity
        self.learningLanguage = learningLanguage
        self.nativeLanguage = nativeLanguage

        // Configure center pane (original message)
        messageLabel.text = message.text
        timeLabel.text = message.formattedTime

        // Configure translation pane (initially show loading or cached)
        if let cached = Self.translationCache[message.id] {
            translationLabel.text = cached
        } else if let translation = message.translatedText {
            // Use pre-populated translation from demo data
            translationLabel.text = translation
            Self.translationCache[message.id] = translation
        } else {
            translationLabel.text = "Swipe to translate..."
        }

        // Configure grammar pane (initially show loading or cached)
        if let cachedGrammar = Self.grammarCache[message.id] {
            displayGrammarResult(cachedGrammar, granularity: granularity)
        } else if message.grammarSuggestions != nil {
            // Use demo data
            configureGrammarPane(message: message, granularity: granularity)
        } else {
            configureGrammarPane(message: message, granularity: granularity)
        }

        // Style based on sender
        if message.isSentByCurrentUser {
            configureSentMessage()
        } else {
            configureReceivedMessage(user: user)
        }

        // ALWAYS start with center pane visible (original message)
        // This ensures users see the actual message first
        DispatchQueue.main.async { [weak self] in
            let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 375
            self?.scrollView.setContentOffset(CGPoint(x: screenWidth, y: 0), animated: false)
        }
    }

    private func configureSentMessage() {
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white

        bubbleLeadingConstraint.isActive = false
        bubbleTrailingConstraint.isActive = true

        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: centerPane.leadingAnchor, constant: 60)
        bubbleLeadingConstraint.isActive = true

        timeLabel.textAlignment = .right
        timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true

        profileImageView.isHidden = true
    }

    private func configureReceivedMessage(user: User) {
        bubbleView.backgroundColor = .secondarySystemBackground
        messageLabel.textColor = .label

        bubbleTrailingConstraint.isActive = false
        bubbleLeadingConstraint.isActive = true

        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: centerPane.trailingAnchor, constant: -60)
        bubbleTrailingConstraint.isActive = true

        timeLabel.textAlignment = .left
        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true

        profileImageView.isHidden = false
        if let profileURL = user.profileImageURL {
            ImageService.shared.loadImage(
                from: profileURL,
                into: profileImageView,
                placeholder: UIImage(systemName: "person.circle.fill")
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }

    private func configureGrammarPane(message: Message, granularity: Int) {
        // Clear previous content
        grammarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        alternativesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        switch granularity {
        case 1: // Basic
            if let suggestions = message.grammarSuggestions?.prefix(2) {
                for suggestion in suggestions {
                    let label = createGrammarLabel(text: "• \(suggestion)")
                    grammarStackView.addArrangedSubview(label)
                }
            } else {
                // Simulate basic corrections for demo
                let label = createGrammarLabel(text: "• Grammar looks good!")
                grammarStackView.addArrangedSubview(label)
            }
            alternativesLabel.isHidden = true
            alternativesStackView.isHidden = true

        case 2: // Moderate
            if let suggestions = message.grammarSuggestions {
                for suggestion in suggestions {
                    let label = createGrammarLabel(text: "• \(suggestion)")
                    grammarStackView.addArrangedSubview(label)
                }
            }

            alternativesLabel.isHidden = false
            alternativesStackView.isHidden = false

            if let alternatives = message.alternatives?.prefix(3) {
                for alternative in alternatives {
                    let label = createAlternativeLabel(text: alternative)
                    alternativesStackView.addArrangedSubview(label)
                }
            } else {
                // Simulate alternatives for demo
                let alternatives = simulateAlternatives(message.text)
                for alternative in alternatives {
                    let label = createAlternativeLabel(text: alternative)
                    alternativesStackView.addArrangedSubview(label)
                }
            }

        case 3: // Verbose
            // Show everything including cultural notes
            if let suggestions = message.grammarSuggestions {
                for suggestion in suggestions {
                    let label = createGrammarLabel(text: "• \(suggestion)")
                    grammarStackView.addArrangedSubview(label)
                }
            }

            if let culturalNote = message.culturalNotes {
                let label = createGrammarLabel(text: "💡 Cultural note: \(culturalNote)")
                label.textColor = .systemOrange
                grammarStackView.addArrangedSubview(label)
            }

            alternativesLabel.isHidden = false
            alternativesStackView.isHidden = false

            if let alternatives = message.alternatives {
                for alternative in alternatives {
                    let label = createAlternativeLabel(text: alternative)
                    alternativesStackView.addArrangedSubview(label)
                }
            }

        default:
            break
        }
    }

    private func createGrammarLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }

    private func createAlternativeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = "→ \(text)"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGreen
        label.numberOfLines = 0
        return label
    }

    // MARK: - Simulation (for demo purposes)
    private func simulateTranslation(_ text: String) -> String {
        // In real app, this would call translation API
        return "[Translation]: \(text)"
    }

    private func simulateAlternatives(_ text: String) -> [String] {
        // In real app, this would be AI-generated
        return [
            "You could also say this...",
            "A more formal version would be...",
            "Native speakers often say..."
        ]
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = .black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true

        if let window = self.window {
            window.addSubview(toast)
            toast.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toast.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -100),
                toast.heightAnchor.constraint(equalToConstant: 40),
                toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
                toast.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 40),
                toast.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -40)
            ])

            toast.alpha = 0
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 2, options: [], animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }

    // MARK: - AI API Calls

    private func performTranslation(for message: Message) {
        // Show loading state
        translationLabel.text = "Translating..."

        // Detect message language
        let detectedLang = Language.detect(from: message.text)
        let sourceLanguage = detectedLang ?? learningLanguage
        let targetLanguage = (sourceLanguage == nativeLanguage) ? learningLanguage : nativeLanguage

        Task { @MainActor in
            do {
                let translation = try await AIConfigurationManager.shared.translate(
                    text: message.text,
                    learningLanguage: sourceLanguage.name,
                    nativeLanguage: targetLanguage.name
                )

                // Cache and display
                Self.translationCache[message.id] = translation
                translationLabel.text = translation
            } catch {
                translationLabel.text = "Translation failed: \(error.localizedDescription)\n\nTap to retry."
                print("Translation error: \(error)")
            }
        }
    }

    private func performGrammarCheck(for message: Message) {
        // Show loading state
        clearGrammarPane()
        let loadingLabel = createGrammarLabel(text: "Analyzing grammar...")
        grammarStackView.addArrangedSubview(loadingLabel)

        // Detect message language
        let detectedLang = Language.detect(from: message.text)
        let sourceLanguage = detectedLang ?? learningLanguage

        // Map granularity to sensitivity level
        let sensitivityLevel: GrammarSensitivityLevel = {
            switch granularityLevel {
            case 1: return .minimal
            case 3: return .verbose
            default: return .moderate
            }
        }()

        Task { @MainActor in
            do {
                let grammarJSON = try await AIConfigurationManager.shared.checkGrammar(
                    text: message.text,
                    learningLanguage: sourceLanguage.name,
                    nativeLanguage: nativeLanguage.name,
                    sensitivityLevel: sensitivityLevel
                )

                // Cache and display
                Self.grammarCache[message.id] = grammarJSON
                displayGrammarResult(grammarJSON, granularity: granularityLevel)
            } catch {
                clearGrammarPane()
                let errorLabel = createGrammarLabel(text: "Grammar check failed: \(error.localizedDescription)\n\nTap to retry.")
                errorLabel.textColor = .systemRed
                grammarStackView.addArrangedSubview(errorLabel)
                print("Grammar check error: \(error)")
            }
        }
    }

    private func displayGrammarResult(_ grammarJSON: String, granularity: Int) {
        clearGrammarPane()

        // Try to parse JSON
        guard let data = grammarJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let corrections = json["corrections"] as? [[String: Any]] else {
            // If parsing fails, show raw result
            let label = createGrammarLabel(text: grammarJSON)
            grammarStackView.addArrangedSubview(label)
            return
        }

        // Display corrections based on granularity
        let maxCorrections = granularity == 1 ? 2 : (granularity == 2 ? 5 : corrections.count)
        for correction in corrections.prefix(maxCorrections) {
            if let original = correction["original"] as? String,
               let corrected = correction["corrected"] as? String,
               let explanation = correction["explanation"] as? String {
                let text = "• \(original) → \(corrected)\n  \(explanation)"
                let label = createGrammarLabel(text: text)
                grammarStackView.addArrangedSubview(label)
            }
        }

        // Show overall feedback for verbose mode
        if granularity == 3, let feedback = json["overall_feedback"] as? String {
            let feedbackLabel = createGrammarLabel(text: "💡 \(feedback)")
            feedbackLabel.textColor = .systemOrange
            grammarStackView.addArrangedSubview(feedbackLabel)
        }

        // If no corrections, show positive message
        if corrections.isEmpty {
            let label = createGrammarLabel(text: "✓ Great grammar! No corrections needed.")
            label.textColor = .systemGreen
            grammarStackView.addArrangedSubview(label)
        }
    }

    private func clearGrammarPane() {
        grammarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        alternativesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - UIScrollViewDelegate
extension SwipeableMessageCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        let currentPage = Int(scrollView.contentOffset.x / pageWidth)

        // Haptic feedback when changing panes
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Notify delegate of pane change
        delegate?.cell(self, didSwipeToPaneIndex: currentPage)

        guard let message = currentMessage else { return }

        switch currentPage {
        case 0:
            print("User viewed grammar/alternatives")
            // Trigger grammar check if not cached
            if Self.grammarCache[message.id] == nil {
                performGrammarCheck(for: message)
            }
        case 1:
            print("User returned to original message")
        case 2:
            print("User viewed translation")
            // Trigger translation if not cached
            if Self.translationCache[message.id] == nil {
                performTranslation(for: message)
            }
        default:
            break
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Also handle programmatic scrolling (from swipe gestures)
        scrollViewDidEndDecelerating(scrollView)
    }
}