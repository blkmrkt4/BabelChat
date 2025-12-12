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
    private var photoURLs: [String] = []

    /// When true, shows "+" on empty slots and allows tapping them. When false, hides empty slots.
    var isEditable: Bool = false {
        didSet {
            updateEmptySlotAppearance()
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
        }
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