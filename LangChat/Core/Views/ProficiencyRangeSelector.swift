import UIKit

/// A set of selected proficiency levels (can be non-contiguous)
/// Uses the existing LanguageProficiency enum from Language.swift
struct ProficiencySelection: Codable, Equatable {
    var selectedLevels: Set<LanguageProficiency>

    /// Order of levels from left (highest) to right (lowest)
    /// Native -> Advanced -> Intermediate -> Beginner
    static let orderedLevels: [LanguageProficiency] = [.native, .advanced, .intermediate, .beginner]

    /// Default selection: all levels
    static let all = ProficiencySelection(selectedLevels: Set(orderedLevels))

    /// Empty selection
    static let none = ProficiencySelection(selectedLevels: [])

    /// Check if a level is selected
    func contains(_ level: LanguageProficiency) -> Bool {
        return selectedLevels.contains(level)
    }

    /// Returns selected levels in order
    var levels: [LanguageProficiency] {
        return ProficiencySelection.orderedLevels.filter { selectedLevels.contains($0) }
    }

    /// Display string for the selection
    var displayString: String {
        if selectedLevels.isEmpty {
            return "proficiency_none_selected".localized
        } else if selectedLevels.count == ProficiencySelection.orderedLevels.count {
            return "proficiency_all_levels".localized
        } else {
            return levels.map { $0.displayName }.joined(separator: ", ")
        }
    }

    /// Toggle a level on/off
    mutating func toggle(_ level: LanguageProficiency) {
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            selectedLevels.insert(level)
        }
    }
}

// MARK: - Legacy ProficiencyRange support (for backward compatibility)

/// A range of proficiency levels (always contiguous) - kept for backward compatibility
struct ProficiencyRange: Codable, Equatable {
    var minLevel: LanguageProficiency
    var maxLevel: LanguageProficiency

    static let orderedLevels: [LanguageProficiency] = [.native, .advanced, .intermediate, .beginner]

    static func index(of level: LanguageProficiency) -> Int {
        return orderedLevels.firstIndex(of: level) ?? 0
    }

    static let all = ProficiencyRange(minLevel: .native, maxLevel: .beginner)

    func contains(_ level: LanguageProficiency) -> Bool {
        let levelIndex = ProficiencyRange.index(of: level)
        let minIndex = ProficiencyRange.index(of: minLevel)
        let maxIndex = ProficiencyRange.index(of: maxLevel)
        return levelIndex >= minIndex && levelIndex <= maxIndex
    }

    var levels: [LanguageProficiency] {
        return ProficiencyRange.orderedLevels.filter { contains($0) }
    }

    var displayString: String {
        if minLevel == maxLevel {
            return minLevel.displayName
        } else {
            return "\(minLevel.displayName) to \(maxLevel.displayName)"
        }
    }

    /// Convert to ProficiencySelection
    func toSelection() -> ProficiencySelection {
        return ProficiencySelection(selectedLevels: Set(levels))
    }
}

protocol ProficiencyLevelSelectorDelegate: AnyObject {
    func proficiencyLevelSelector(_ selector: ProficiencyLevelSelector, didSelectLevels selection: ProficiencySelection)
}

// Keep old delegate for backward compatibility
protocol ProficiencyRangeSelectorDelegate: AnyObject {
    func proficiencyRangeSelector(_ selector: ProficiencyRangeSelector, didSelectRange range: ProficiencyRange)
}

/// A custom control for selecting individual proficiency levels (multi-select toggles)
class ProficiencyLevelSelector: UIView {

    // MARK: - Properties

    weak var delegate: ProficiencyLevelSelectorDelegate?

    private(set) var selection: ProficiencySelection = .all {
        didSet {
            updateSelectionUI()
            delegate?.proficiencyLevelSelector(self, didSelectLevels: selection)
        }
    }

    /// Ordered levels: Native (left) -> Advanced -> Intermediate -> Beginner (right)
    private let levels = ProficiencySelection.orderedLevels
    private var levelButtons: [UIButton] = []
    private let stackView = UIStackView()

    // Colors
    private let selectedColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0) // Gold
    private let unselectedColor = UIColor.systemGray5
    private let selectedTextColor = UIColor.black
    private let unselectedTextColor = UIColor.label

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // Stack view for level buttons
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Create toggle buttons for each level
        for (index, level) in levels.enumerated() {
            let button = createLevelButton(for: level, at: index)
            levelButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        // Initial selection UI
        updateSelectionUI()
    }

    private func createLevelButton(for level: LanguageProficiency, at index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(levelTapped(_:)), for: .touchUpInside)

        // Configure button with text and optional icon
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseForegroundColor = selectedTextColor
        config.baseBackgroundColor = selectedColor

        if level == .native {
            // Native gets person.fill.checkmark icon + "Native" text
            config.image = UIImage(systemName: "person.fill.checkmark")
            config.imagePadding = 4
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
            config.title = "Native"
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                return outgoing
            }
        } else {
            config.title = level.abbreviation
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
                return outgoing
            }
        }

        button.configuration = config

        // Add long press for more info
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(levelLongPressed(_:)))
        longPress.minimumPressDuration = 0.5
        button.addGestureRecognizer(longPress)

        return button
    }

    // MARK: - Public Methods

    func setSelection(_ newSelection: ProficiencySelection, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.selection = newSelection
            }
        } else {
            selection = newSelection
        }
    }

    /// Set from legacy ProficiencyRange
    func setSelectedRange(_ range: ProficiencyRange, animated: Bool = true) {
        setSelection(range.toSelection(), animated: animated)
    }

    // MARK: - Actions

    @objc private func levelTapped(_ sender: UIButton) {
        let tappedLevel = levels[sender.tag]

        // Toggle this level
        var newSelection = selection
        newSelection.toggle(tappedLevel)

        // Ensure at least one level is selected
        if newSelection.selectedLevels.isEmpty {
            // Don't allow deselecting the last level
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        selection = newSelection

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    @objc private func levelLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view as? UIButton else { return }
        let level = levels[button.tag]

        // Show full name tooltip
        let tooltip = UILabel()
        tooltip.text = level.displayName
        tooltip.font = .systemFont(ofSize: 14, weight: .medium)
        tooltip.textColor = .white
        tooltip.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        tooltip.textAlignment = .center
        tooltip.layer.cornerRadius = 6
        tooltip.clipsToBounds = true
        tooltip.alpha = 0

        // Position above button
        superview?.addSubview(tooltip)
        tooltip.translatesAutoresizingMaskIntoConstraints = false

        if let superview = superview {
            tooltip.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
            tooltip.heightAnchor.constraint(equalToConstant: 30).isActive = true

            let buttonCenter = button.convert(CGPoint(x: button.bounds.midX, y: 0), to: superview)
            tooltip.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: buttonCenter.x).isActive = true
            tooltip.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -8).isActive = true
        }

        // Animate in
        UIView.animate(withDuration: 0.2, animations: {
            tooltip.alpha = 1
        }) { _ in
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.2, animations: {
                    tooltip.alpha = 0
                }) { _ in
                    tooltip.removeFromSuperview()
                }
            }
        }

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // MARK: - UI Updates

    private func updateSelectionUI() {
        for (index, button) in levelButtons.enumerated() {
            let level = levels[index]
            let isSelected = selection.contains(level)

            UIView.animate(withDuration: 0.2) {
                if var config = button.configuration {
                    config.baseBackgroundColor = isSelected ? self.selectedColor : self.unselectedColor
                    config.baseForegroundColor = isSelected ? self.selectedTextColor : self.unselectedTextColor
                    button.configuration = config
                }
            }
        }
    }
}

// MARK: - Legacy ProficiencyRangeSelector (wrapper for backward compatibility)

class ProficiencyRangeSelector: UIView {

    weak var delegate: ProficiencyRangeSelectorDelegate?

    private let levelSelector = ProficiencyLevelSelector()

    private(set) var selectedRange: ProficiencyRange = .all

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(levelSelector)
        levelSelector.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            levelSelector.topAnchor.constraint(equalTo: topAnchor),
            levelSelector.leadingAnchor.constraint(equalTo: leadingAnchor),
            levelSelector.trailingAnchor.constraint(equalTo: trailingAnchor),
            levelSelector.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        levelSelector.delegate = self
    }

    func setSelectedRange(_ range: ProficiencyRange, animated: Bool = true) {
        selectedRange = range
        levelSelector.setSelectedRange(range, animated: animated)
    }

    /// Get the current selection as ProficiencySelection
    var currentSelection: ProficiencySelection {
        return levelSelector.selection
    }
}

extension ProficiencyRangeSelector: ProficiencyLevelSelectorDelegate {
    func proficiencyLevelSelector(_ selector: ProficiencyLevelSelector, didSelectLevels selection: ProficiencySelection) {
        // Convert selection to range for backward compatibility
        // Use the first and last selected levels
        let selectedLevels = selection.levels
        if let first = selectedLevels.first, let last = selectedLevels.last {
            selectedRange = ProficiencyRange(minLevel: first, maxLevel: last)
        }

        // Notify delegate with the selection (as a pseudo-range)
        delegate?.proficiencyRangeSelector(self, didSelectRange: selectedRange)
    }
}

// MARK: - Convenience Extensions

extension ProficiencySelection {
    /// Create from UserDefaults stored values
    static func fromDefaults(key: String = "selectedProficiencyLevels") -> ProficiencySelection {
        guard let savedLevels = UserDefaults.standard.stringArray(forKey: key) else {
            // Fall back to legacy range format
            return ProficiencyRange.fromDefaults().toSelection()
        }

        let levels = savedLevels.compactMap { LanguageProficiency(rawValue: $0) }
        if levels.isEmpty {
            return .all
        }
        return ProficiencySelection(selectedLevels: Set(levels))
    }

    /// Save to UserDefaults
    func saveToDefaults(key: String = "selectedProficiencyLevels") {
        let levelStrings = selectedLevels.map { $0.rawValue }
        UserDefaults.standard.set(levelStrings, forKey: key)

        // Also save in legacy format for backward compatibility
        let orderedSelected = levels
        if let first = orderedSelected.first, let last = orderedSelected.last {
            UserDefaults.standard.set(first.rawValue, forKey: "minProficiencyLevel")
            UserDefaults.standard.set(last.rawValue, forKey: "maxProficiencyLevel")
        }

        // Derive allowNonNativeMatches
        let allowNonNative = selectedLevels.contains { $0 != .native }
        UserDefaults.standard.set(allowNonNative, forKey: "allowNonNativeMatches")
    }
}

extension ProficiencyRange {
    /// Create from UserDefaults stored values
    static func fromDefaults(minKey: String = "minProficiencyLevel", maxKey: String = "maxProficiencyLevel") -> ProficiencyRange {
        guard let minRaw = UserDefaults.standard.string(forKey: minKey),
              let maxRaw = UserDefaults.standard.string(forKey: maxKey),
              let lowestProf = LanguageProficiency(rawValue: minRaw),
              let highestProf = LanguageProficiency(rawValue: maxRaw) else {
            return .all
        }

        return ProficiencyRange(minLevel: highestProf, maxLevel: lowestProf)
    }

    /// Save to UserDefaults
    func saveToDefaults(minKey: String = "minProficiencyLevel", maxKey: String = "maxProficiencyLevel") {
        let (lowestProf, highestProf) = getOrdinalMinMax()
        UserDefaults.standard.set(lowestProf.rawValue, forKey: minKey)
        UserDefaults.standard.set(highestProf.rawValue, forKey: maxKey)
        UserDefaults.standard.set(true, forKey: "proficiencyRangeSet")
    }

    func getOrdinalMinMax() -> (min: LanguageProficiency, max: LanguageProficiency) {
        if minLevel.ordinalValue <= maxLevel.ordinalValue {
            return (minLevel, maxLevel)
        } else {
            return (maxLevel, minLevel)
        }
    }

    func toMatchingPreferencesLevels() -> (min: LanguageProficiency, max: LanguageProficiency) {
        return getOrdinalMinMax()
    }
}

// MARK: - Integration with MatchingPreferences

extension MatchingPreferences {
    var proficiencyRange: ProficiencyRange {
        return ProficiencyRange(minLevel: minProficiencyLevel, maxLevel: maxProficiencyLevel)
    }
}
