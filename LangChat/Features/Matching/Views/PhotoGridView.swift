import UIKit

class PhotoGridView: UIView {

    private let stackView = UIStackView()
    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .systemGray6
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
                imageView.backgroundColor = .systemGray5

                horizontalStack.addArrangedSubview(imageView)
                imageViews.append(imageView)
            }

            stackView.addArrangedSubview(horizontalStack)
        }
    }

    func configure(with photoURLs: [String]) {
        for (index, imageView) in imageViews.enumerated() {
            if index < photoURLs.count {
                loadImage(from: photoURLs[index], into: imageView)
            } else {
                imageView.image = nil
                imageView.backgroundColor = .systemGray5
            }
        }
    }

    private func loadImage(from urlString: String, into imageView: UIImageView) {
        ImageService.shared.loadImage(
            from: urlString,
            into: imageView,
            placeholder: UIImage(systemName: "photo")
        )
    }
}