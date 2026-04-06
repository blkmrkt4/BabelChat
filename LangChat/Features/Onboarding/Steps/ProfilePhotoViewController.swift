import UIKit
import PhotosUI

class ProfilePhotoViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let photoGridView = UIView()
    private let photoSlot = PhotoSlotView()
    private let tipsLabel = UILabel()

    // MARK: - Properties
    private var selectedImage: UIImage?

    // MARK: - Lifecycle
    override func configure() {
        step = .profilePhoto
        setTitle("onboarding_photos_title".localized)
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        // Single centered photo slot
        contentView.addSubview(photoGridView)

        photoSlot.tag = 0
        photoSlot.setPrimary(true)
        photoSlot.addTarget(self, action: #selector(photoSlotTapped), for: .touchUpInside)
        photoGridView.addSubview(photoSlot)

        // Tips label
        tipsLabel.text = "onboarding_photos_tips".localized
        tipsLabel.font = .systemFont(ofSize: 14, weight: .regular)
        tipsLabel.textColor = .white.withAlphaComponent(0.7)
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = .center
        contentView.addSubview(tipsLabel)

        // Layout
        photoGridView.translatesAutoresizingMaskIntoConstraints = false
        photoSlot.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            photoGridView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            photoGridView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            photoGridView.widthAnchor.constraint(equalToConstant: 200),
            photoGridView.heightAnchor.constraint(equalToConstant: 200),

            photoSlot.topAnchor.constraint(equalTo: photoGridView.topAnchor),
            photoSlot.leadingAnchor.constraint(equalTo: photoGridView.leadingAnchor),
            photoSlot.trailingAnchor.constraint(equalTo: photoGridView.trailingAnchor),
            photoSlot.bottomAnchor.constraint(equalTo: photoGridView.bottomAnchor),

            tipsLabel.topAnchor.constraint(equalTo: photoGridView.bottomAnchor, constant: 24),
            tipsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tipsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tipsLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Always enable continue button (can skip)
        updateContinueButton(enabled: true)
        continueButton.setTitle("common_skip_for_now".localized, for: .normal)
    }

    // MARK: - Actions
    @objc private func photoSlotTapped(_ sender: PhotoSlotView) {
        if selectedImage != nil {
            showPhotoOptions()
        } else {
            showPhotoPicker()
        }
    }

    private func showPhotoOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "onboarding_photos_replace".localized, style: .default) { [weak self] _ in
            self?.showPhotoPicker()
        })

        alert.addAction(UIAlertAction(title: "onboarding_photos_remove".localized, style: .destructive) { [weak self] _ in
            self?.selectedImage = nil
            self?.photoSlot.setImage(nil)
            self?.updateButtonState()
        })

        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = photoSlot
            popover.sourceRect = photoSlot.bounds
        }

        present(alert, animated: true)
    }

    private func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self

        present(picker, animated: true)
    }

    private func updateButtonState() {
        if selectedImage == nil {
            continueButton.setTitle("common_skip_for_now".localized, for: .normal)
        } else {
            continueButton.setTitle("common_continue".localized, for: .normal)
        }
    }

    override func continueButtonTapped() {
        let photos = [selectedImage].compactMap { $0 }
        delegate?.didCompleteStep(withData: photos)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfilePhotoViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if let result = results.first {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let originalImage = object as? UIImage {
                    let resizedImage = self?.resizeImage(originalImage, maxDimension: 1200) ?? originalImage

                    DispatchQueue.main.async {
                        self?.selectedImage = resizedImage
                        self?.photoSlot.setImage(resizedImage)
                        self?.updateButtonState()
                    }
                }
            }
        }

        dismiss(animated: true)
    }

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already small enough, return it
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use UIGraphicsImageRenderer for efficient memory handling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
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
        borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        borderView.backgroundColor = .white.withAlphaComponent(0.05)
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
        placeholderIconView.tintColor = .white.withAlphaComponent(0.4)
        placeholderIconView.contentMode = .scaleAspectFit
        placeholderIconView.isUserInteractionEnabled = false
        addSubview(placeholderIconView)

        // Primary badge - use gold color
        primaryBadge.text = "onboarding_photos_main".localized
        primaryBadge.font = .systemFont(ofSize: 11, weight: .bold)
        primaryBadge.textColor = .black
        primaryBadge.backgroundColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0) // Gold color
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
            // Gold border when photo is added
            borderView.layer.borderColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0).cgColor
            borderView.backgroundColor = .clear
        } else {
            borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            borderView.backgroundColor = .white.withAlphaComponent(0.05)
        }
    }

    func setPrimary(_ isPrimary: Bool) {
        primaryBadge.isHidden = !isPrimary
        if isPrimary {
            borderView.layer.borderWidth = 3
            // Gold border for primary slot
            borderView.layer.borderColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0).cgColor
        }
    }
}
