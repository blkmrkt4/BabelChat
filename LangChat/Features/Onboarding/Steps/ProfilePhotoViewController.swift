import UIKit
import PhotosUI

class ProfilePhotoViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let photoGridView = UIView()
    private let photoSlots: [PhotoSlotView] = (0..<6).map { _ in PhotoSlotView() }
    private let tipsLabel = UILabel()

    // MARK: - Properties
    private var selectedImages: [UIImage?] = Array(repeating: nil, count: 6)
    private var photoCount = 0

    // MARK: - Lifecycle
    override func configure() {
        step = .profilePhoto
        setTitle("Add photos of yourself",
                subtitle: "Add at least 3 photos to help others get to know you")
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        // Photo grid container
        contentView.addSubview(photoGridView)

        // Create 2x3 grid
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually

            for col in 0..<2 {
                let index = row * 2 + col
                let photoSlot = photoSlots[index]
                photoSlot.tag = index
                photoSlot.addTarget(self, action: #selector(photoSlotTapped), for: .touchUpInside)

                // Make first slot primary
                if index == 0 {
                    photoSlot.setPrimary(true)
                }

                rowStack.addArrangedSubview(photoSlot)
            }

            stackView.addArrangedSubview(rowStack)
        }

        photoGridView.addSubview(stackView)

        // Tips label
        tipsLabel.text = "💡 Tips: Show your personality • Include clear face photos • Smile, you're here to make friends!"
        tipsLabel.font = .systemFont(ofSize: 14, weight: .regular)
        tipsLabel.textColor = .secondaryLabel
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = .center
        contentView.addSubview(tipsLabel)

        // Layout
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            photoGridView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            photoGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoGridView.heightAnchor.constraint(equalTo: photoGridView.widthAnchor, multiplier: 1.5),

            stackView.topAnchor.constraint(equalTo: photoGridView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: photoGridView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: photoGridView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: photoGridView.bottomAnchor),

            tipsLabel.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 24),
            tipsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tipsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        updateContinueButton(enabled: false)
    }

    // MARK: - Actions
    @objc private func photoSlotTapped(_ sender: PhotoSlotView) {
        let index = sender.tag

        if selectedImages[index] != nil {
            // Show options to replace or remove
            showPhotoOptions(for: index)
        } else {
            // Show picker
            showPhotoPicker(for: index)
        }
    }

    private func showPhotoOptions(for index: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Replace Photo", style: .default) { [weak self] _ in
            self?.showPhotoPicker(for: index)
        })

        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
            self?.removePhoto(at: index)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = photoSlots[index]
            popover.sourceRect = photoSlots[index].bounds
        }

        present(alert, animated: true)
    }

    private func showPhotoPicker(for index: Int) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.view.tag = index // Store index in tag

        present(picker, animated: true)
    }

    private func removePhoto(at index: Int) {
        selectedImages[index] = nil
        photoSlots[index].setImage(nil)
        updatePhotoCount()
    }

    private func updatePhotoCount() {
        photoCount = selectedImages.compactMap { $0 }.count
        updateContinueButton(enabled: photoCount >= 3)

        // Update subtitle based on count
        if photoCount < 3 {
            subtitleLabel.text = "Add at least \(3 - photoCount) more photo\(photoCount == 2 ? "" : "s") to continue"
        } else {
            subtitleLabel.text = "Great! You can add more photos or continue"
        }
    }

    override func continueButtonTapped() {
        let photos = selectedImages.compactMap { $0 }
        delegate?.didCompleteStep(withData: photos)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfilePhotoViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let index = picker.view.tag

        if let result = results.first {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.selectedImages[index] = image
                        self?.photoSlots[index].setImage(image)
                        self?.updatePhotoCount()
                    }
                }
            }
        }

        dismiss(animated: true)
    }
}

// MARK: - Photo Slot View
private class PhotoSlotView: UIButton {
    private let photoImageView = UIImageView()
    private let placeholderIconView = UIImageView()
    private let primaryBadge = UILabel()
    private let borderView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Border view
        borderView.layer.cornerRadius = 12
        borderView.layer.borderWidth = 2
        borderView.layer.borderColor = UIColor.systemGray4.cgColor
        borderView.backgroundColor = .secondarySystemBackground
        borderView.isUserInteractionEnabled = false
        addSubview(borderView)

        // Image view
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 12
        photoImageView.isUserInteractionEnabled = false
        addSubview(photoImageView)

        // Placeholder icon
        placeholderIconView.image = UIImage(systemName: "camera.fill")
        placeholderIconView.tintColor = .systemGray3
        placeholderIconView.contentMode = .scaleAspectFit
        placeholderIconView.isUserInteractionEnabled = false
        addSubview(placeholderIconView)

        // Primary badge
        primaryBadge.text = "Main"
        primaryBadge.font = .systemFont(ofSize: 11, weight: .bold)
        primaryBadge.textColor = .white
        primaryBadge.backgroundColor = .systemBlue
        primaryBadge.textAlignment = .center
        primaryBadge.layer.cornerRadius = 8
        primaryBadge.clipsToBounds = true
        primaryBadge.isHidden = true
        addSubview(primaryBadge)

        // Layout
        borderView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderIconView.translatesAutoresizingMaskIntoConstraints = false
        primaryBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            photoImageView.topAnchor.constraint(equalTo: topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            placeholderIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderIconView.widthAnchor.constraint(equalToConstant: 40),
            placeholderIconView.heightAnchor.constraint(equalToConstant: 40),

            primaryBadge.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            primaryBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            primaryBadge.widthAnchor.constraint(equalToConstant: 40),
            primaryBadge.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func setImage(_ image: UIImage?) {
        photoImageView.image = image
        placeholderIconView.isHidden = image != nil

        if image != nil {
            borderView.layer.borderColor = UIColor.systemBlue.cgColor
            borderView.backgroundColor = .clear
        } else {
            borderView.layer.borderColor = UIColor.systemGray4.cgColor
            borderView.backgroundColor = .secondarySystemBackground
        }
    }

    func setPrimary(_ isPrimary: Bool) {
        primaryBadge.isHidden = !isPrimary
        if isPrimary {
            borderView.layer.borderWidth = 3
            borderView.layer.borderColor = UIColor.systemBlue.cgColor
        }
    }
}
