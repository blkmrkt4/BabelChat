import UIKit

@objc protocol PhotoGridViewDelegate: AnyObject {
    func photoGridView(_ gridView: PhotoGridView, didTapPhotoAt index: Int, photoURL: String)
    @objc optional func photoGridView(_ gridView: PhotoGridView, didLongPressPhotoAt index: Int, photoURL: String)
    @objc optional func photoGridView(_ gridView: PhotoGridView, didTapEmptySlotAt index: Int)
}

class PhotoGridView: UIView {

    weak var delegate: PhotoGridViewDelegate?
    private let stackView = UIStackView()
    private var imageViews: [UIImageView] = []
    private var plusLabels: [UILabel] = []  // "+" indicators for empty slots
    private var blurIndicators: [UIView] = []  // Blur until match indicators
    private var blurEffectViews: [UIVisualEffectView] = []  // Blur preview overlays
    private var photoURLs: [String] = []
    private var blurSettings: [Bool] = []  // Per-photo blur settings

    /// When true, shows "+" on empty slots and allows tapping them. When false, hides empty slots.
    var isEditable: Bool = false {
        didSet {
            updateEmptySlotAppearance()
            updateAllBlurStates()
        }
    }

    /// When true, applies actual blur to photos with blur settings (viewing other user's profile before matching)
    var applyBlurForViewing: Bool = false {
        didSet {
            updateAllBlurStates()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear
        layer.cornerRadius = 12
        clipsToBounds = true

        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        setupGrid()
    }

    private func setupGrid() {
        for _ in 0..<2 {
            let horizontalStack = UIStackView()
            horizontalStack.axis = .horizontal
            horizontalStack.distribution = .fillEqually
            horizontalStack.spacing = 2

            for _ in 0..<3 {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.backgroundColor = .clear
                imageView.isUserInteractionEnabled = true

                // Add "+" label for empty slots (initially hidden)
                let plusLabel = UILabel()
                plusLabel.text = "+"
                plusLabel.font = .systemFont(ofSize: 32, weight: .light)
                plusLabel.textColor = .systemGray3
                plusLabel.textAlignment = .center
                plusLabel.isHidden = true
                imageView.addSubview(plusLabel)
                plusLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    plusLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                    plusLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
                ])
                plusLabels.append(plusLabel)

                // Add blur effect view for preview (fills entire image)
                let blurEffect = UIBlurEffect(style: .regular)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.isHidden = true
                blurEffectView.isUserInteractionEnabled = false
                imageView.addSubview(blurEffectView)
                blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    blurEffectView.topAnchor.constraint(equalTo: imageView.topAnchor),
                    blurEffectView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                    blurEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                    blurEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
                ])
                blurEffectViews.append(blurEffectView)

                // Add blur indicator (eye.slash icon in corner)
                let blurIndicator = createBlurIndicator(at: imageViews.count)
                imageView.addSubview(blurIndicator)
                blurIndicator.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    blurIndicator.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 4),
                    blurIndicator.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
                    blurIndicator.widthAnchor.constraint(equalToConstant: 24),
                    blurIndicator.heightAnchor.constraint(equalToConstant: 24)
                ])
                blurIndicators.append(blurIndicator)

                // Add tap gesture recognizer
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                imageView.addGestureRecognizer(tapGesture)

                // Add long press gesture recognizer
                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(imageLongPressed(_:)))
                longPressGesture.minimumPressDuration = 0.5
                imageView.addGestureRecognizer(longPressGesture)

                horizontalStack.addArrangedSubview(imageView)
                imageViews.append(imageView)
            }

            stackView.addArrangedSubview(horizontalStack)
        }
    }

    private func createBlurIndicator(at index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        container.layer.cornerRadius = 12
        container.isHidden = true
        container.tag = index  // Store index for tap handling
        container.isUserInteractionEnabled = true

        let iconView = UIImageView(image: UIImage(systemName: "eye.slash.fill"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false  // Let container handle taps
        container.addSubview(iconView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14)
        ])

        // Add tap gesture to preview blur
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blurIndicatorTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        return container
    }

    @objc private func blurIndicatorTapped(_ sender: UITapGestureRecognizer) {
        guard let container = sender.view else { return }
        let index = container.tag

        // Show blur preview for this photo
        showBlurPreview(at: index)
    }

    /// Shows a temporary blur effect on the photo at the given index
    func showBlurPreview(at index: Int) {
        guard index < blurEffectViews.count else { return }

        let blurEffectView = blurEffectViews[index]

        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        // Show blur with animation
        blurEffectView.alpha = 0
        blurEffectView.isHidden = false

        UIView.animate(withDuration: 0.2) {
            blurEffectView.alpha = 1
        }

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                blurEffectView.alpha = 0
            } completion: { _ in
                blurEffectView.isHidden = true
            }
        }
    }

    func configure(with photoURLs: [String]) {
        self.photoURLs = photoURLs
        for (index, imageView) in imageViews.enumerated() {
            let hasPhoto = index < photoURLs.count && !photoURLs[index].isEmpty
            if hasPhoto {
                loadImage(from: photoURLs[index], into: imageView)
                plusLabels[index].isHidden = true
                imageView.backgroundColor = .clear
            } else {
                imageView.image = nil
                updateEmptySlot(at: index)
            }
            // Update blur indicator visibility
            updateBlurIndicator(at: index)
        }
    }

    /// Set blur settings for each photo
    func setBlurSettings(_ settings: [Bool]) {
        self.blurSettings = settings
        updateAllBlurStates()
    }

    private func updateAllBlurStates() {
        for index in 0..<imageViews.count {
            updateBlurIndicator(at: index)
            updateBlurEffect(at: index)
        }
    }

    private func updateBlurIndicator(at index: Int) {
        guard index < blurIndicators.count else { return }
        let hasPhoto = index < photoURLs.count && !photoURLs[index].isEmpty
        let isBlurred = index < blurSettings.count ? blurSettings[index] : false

        // Only show blur indicator if there's a photo, it's set to blur, and the grid is editable (own profile)
        blurIndicators[index].isHidden = !(hasPhoto && isBlurred && isEditable)
    }

    private func updateBlurEffect(at index: Int) {
        guard index < blurEffectViews.count else { return }
        let hasPhoto = index < photoURLs.count && !photoURLs[index].isEmpty
        let isBlurred = index < blurSettings.count ? blurSettings[index] : false

        // Apply actual blur if viewing another user's profile and this photo is set to blur
        let shouldShowBlur = hasPhoto && isBlurred && applyBlurForViewing && !isEditable
        blurEffectViews[index].isHidden = !shouldShowBlur
    }

    private func updateEmptySlotAppearance() {
        for (index, imageView) in imageViews.enumerated() {
            let hasPhoto = index < photoURLs.count && !photoURLs[index].isEmpty
            if !hasPhoto {
                updateEmptySlot(at: index)
            }
        }
    }

    private func updateEmptySlot(at index: Int) {
        guard index < imageViews.count else { return }
        let imageView = imageViews[index]
        let plusLabel = plusLabels[index]

        if isEditable {
            // Show subtle "+" indicator on light background for editable grids (user's own profile)
            imageView.backgroundColor = .systemGray6
            plusLabel.isHidden = false
        } else {
            // Hide empty slots completely for non-editable grids (other users)
            imageView.backgroundColor = .clear
            plusLabel.isHidden = true
        }
    }

    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView,
              let index = imageViews.firstIndex(of: imageView) else {
            return
        }

        let hasPhoto = index < photoURLs.count && !photoURLs[index].isEmpty
        if hasPhoto {
            delegate?.photoGridView(self, didTapPhotoAt: index, photoURL: photoURLs[index])
        } else if isEditable {
            // Tapped on empty slot in editable mode
            delegate?.photoGridView?(self, didTapEmptySlotAt: index)
        }
    }

    @objc private func imageLongPressed(_ sender: UILongPressGestureRecognizer) {
        // Only trigger on began state to avoid multiple calls
        guard sender.state == .began,
              let imageView = sender.view as? UIImageView,
              let index = imageViews.firstIndex(of: imageView) else {
            return
        }

        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        let photoURL = index < photoURLs.count ? photoURLs[index] : ""
        delegate?.photoGridView?(self, didLongPressPhotoAt: index, photoURL: photoURL)
    }

    private func loadImage(from urlString: String, into imageView: UIImageView) {
        ImageService.shared.loadImage(
            from: urlString,
            into: imageView,
            placeholder: UIImage(systemName: "photo")
        )
    }
}