import UIKit
import PhotosUI

class PhotosViewController: UIViewController {

    private let collectionView: UICollectionView
    private var photos: [String] = []

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        let itemsPerRow: CGFloat = 3
        let totalSpacing = spacing * (itemsPerRow + 1)
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / itemsPerRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadPhotos()
    }

    private func setupViews() {
        title = "My Photos"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPhotoTapped)
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionCell.self, forCellWithReuseIdentifier: "PhotoCell")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadPhotos() {
        // Load from UserDefaults
        if let savedPhotos = UserDefaults.standard.stringArray(forKey: "userPhotos"), !savedPhotos.isEmpty {
            photos = savedPhotos
        } else {
            // Default empty state - user can add photos
            photos = []
        }
        collectionView.reloadData()
    }

    @objc private func addPhotoTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 6 - photos.count // Max 6 photos total
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func savePhotos() {
        UserDefaults.standard.set(photos, forKey: "userPhotos")
    }
}

// MARK: - UICollectionViewDataSource
extension PhotosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(photos.count + 1, 6) // +1 for add button, max 6 total
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < photos.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionCell
            cell.configure(with: photos[indexPath.item])
            return cell
        } else {
            // Add photo cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionCell
            cell.configureAsAddButton()
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < photos.count {
            // Show delete option
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { [weak self] _ in
                self?.photos.remove(at: indexPath.item)
                self?.savePhotos()
                self?.collectionView.reloadData()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let popover = alert.popoverPresentationController,
               let cell = collectionView.cellForItem(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }

            present(alert, animated: true)
        } else {
            // Add new photo
            addPhotoTapped()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotosViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        // For demo, use placeholder URLs
                        // In production, upload image and get URL
                        let placeholderURL = "https://picsum.photos/seed/\(UUID().uuidString)/400/400"
                        self?.photos.append(placeholderURL)
                        self?.savePhotos()
                        self?.collectionView.reloadData()
                    }
                }
            }
        }
    }
}

// MARK: - Photo Cell
class PhotoCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let addButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.backgroundColor = .systemGray6
        addButton.layer.cornerRadius = 8
        addButton.isHidden = true
        addButton.isUserInteractionEnabled = false

        contentView.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            addButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with urlString: String) {
        imageView.isHidden = false
        addButton.isHidden = true
        ImageService.shared.loadImage(
            from: urlString,
            into: imageView,
            placeholder: UIImage(systemName: "photo")
        )
    }

    func configureAsAddButton() {
        imageView.isHidden = true
        addButton.isHidden = false
    }
}